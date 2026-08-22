<#
.SYNOPSIS
Validates a planning workspace's dispatch shape.

.DESCRIPTION
This linter checks shape, never truth. A wrong constant, incomplete design
choice, or incorrect contract can satisfy every static check. Human planning
and review remain responsible for semantic correctness.

This is the portable version of the linter: it is deliberately free of any
one project's toolchain assumptions (no hardcoded engine binary, script
runner, or test working directory). Checks 14-17 in the source repository
this template was adapted from encoded exactly those project-specific
invariants; see the "Project-specific extension point" comment below for
where the target repository should add its own equivalents, if it has any.

Assumes installation at `tools/validate_plan_workspace.ps1`, one level below
the repository root, matching this kit's prescribed destination.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PlanPath
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$errors = New-Object 'System.Collections.Generic.List[string]'
$warnings = New-Object 'System.Collections.Generic.List[string]'
$checks = 0

function Add-Check {
    param([bool]$Condition, [string]$Message)
    $script:checks++
    if (-not $Condition) {
        $script:errors.Add($Message)
    }
}

function Normalize-Text {
    param([AllowEmptyString()][string]$Text)
    return (($Text -replace '\s+', ' ').Trim())
}

function Read-RequiredFile {
    param([string]$Path, [string]$Label)
    Add-Check (Test-Path -LiteralPath $Path -PathType Leaf) "[Files] Missing $Label."
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return ''
    }
    return Get-Content -Raw -LiteralPath $Path
}

function Split-MarkdownRow {
    param([string]$Line)
    $body = $Line.Trim().Trim('|')
    $cell = ''
    $inCode = $false
    $escaped = $false
    for ($i = 0; $i -lt $body.Length; $i++) {
        $char = $body[$i]
        if ($escaped) {
            $cell += $char
            $escaped = $false
            continue
        }
        if ($char -eq '\') {
            $cell += $char
            $escaped = $true
            continue
        }
        if ([int]$char -eq 96) {
            $inCode = -not $inCode
            $cell += $char
            continue
        }
        if ($char -eq '|' -and -not $inCode) {
            Write-Output $cell.Trim()
            $cell = ''
            continue
        }
        $cell += $char
    }
    Write-Output $cell.Trim()
}

function Get-Table {
    param([string]$Text, [string]$HeaderPattern)
    $lines = @($Text -split '\r?\n')
    $headerIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match $HeaderPattern) {
            $headerIndex = $i
            break
        }
    }
    if ($headerIndex -lt 0) {
        return @()
    }

    $headers = @(Split-MarkdownRow $lines[$headerIndex])
    $rows = New-Object 'System.Collections.Generic.List[object]'
    for ($i = $headerIndex + 2; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^\s*\|') {
            break
        }
        $cells = @(Split-MarkdownRow $lines[$i])
        if ($cells.Count -ne $headers.Count) {
            $script:errors.Add("[Table] Row has $($cells.Count) cells; expected $($headers.Count): $($lines[$i])")
            continue
        }
        $row = [ordered]@{}
        for ($j = 0; $j -lt $headers.Count; $j++) {
            $row[$headers[$j]] = $cells[$j]
        }
        $rows.Add([pscustomobject]$row)
    }
    return $rows.ToArray()
}

function Get-StageSections {
    param([string]$Text)
    $pattern = '(?ms)^#{2,3}\s+((?:M\d+\s*:|Milestone\s+\d+|Integration)[^\r\n]*)\r?\n(.*?)(?=^#{2,3}\s+(?:M\d+\s*:|Milestone\s+\d+|Integration)|\z)'
    $result = New-Object 'System.Collections.Generic.List[object]'
    foreach ($match in [regex]::Matches($Text, $pattern)) {
        $heading = $match.Groups[1].Value.Trim()
        if ($heading -match '^M(\d+)') {
            $id = "M$($Matches[1])"
        } elseif ($heading -match '^Milestone\s+(\d+)') {
            $id = "M$($Matches[1])"
        } else {
            $id = 'Integration'
        }

        $fields = @{}
        foreach ($fieldMatch in [regex]::Matches($match.Groups[2].Value, '(?m)^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$')) {
            $key = $fieldMatch.Groups[1].Value.Trim()
            if ($key -notin @('Field', '---')) {
                $fields[$key] = $fieldMatch.Groups[2].Value.Trim()
            }
        }

        $result.Add([pscustomobject]@{
            Id = $id
            Heading = $heading
            Text = $match.Groups[2].Value
            Fields = $fields
        })
    }
    return $result.ToArray()
}

function Get-PacketSections {
    param([string]$Text)
    $pattern = '(?ms)^###\s+Packet\s+(M\d+|Integration)\s*\r?\n(.*?)(?=^###\s+|\z)'
    $result = New-Object 'System.Collections.Generic.List[object]'
    foreach ($match in [regex]::Matches($Text, $pattern)) {
        $result.Add([pscustomobject]@{
            Id = $match.Groups[1].Value
            Text = $match.Groups[2].Value
        })
    }
    return $result.ToArray()
}

function Get-Field {
    param([object]$Stage, [string]$Name)
    if ($Stage.Fields.ContainsKey($Name)) {
        return [string]$Stage.Fields[$Name]
    }
    return ''
}

# Generic path-with-extension detector: matches any backtick-quoted token
# ending in a dot-extension (optionally followed by :line, :line-line, or
# :symbol). No project-specific file-type allow-list, so this works across
# languages and toolchains.
function Get-CodePaths {
    param([string]$Text)
    $paths = New-Object 'System.Collections.Generic.List[string]'
    foreach ($match in [regex]::Matches($Text, '`([^`]+)`')) {
        $candidate = $match.Groups[1].Value.Trim()
        if ($candidate -match '(?i)\.[A-Za-z0-9]{1,10}(?::[^/\s]+|:\d+(?:-\d+)?)?$') {
            $paths.Add($candidate)
        }
    }
    return $paths.ToArray()
}

function Get-OwnedPathTokens {
    param([string]$Text)
    $tokens = New-Object 'System.Collections.Generic.List[string]'
    foreach ($path in Get-CodePaths $Text) {
        $tokens.Add($path)
    }
    foreach ($match in [regex]::Matches($Text, '(?i)(?:^|[\s,`])((?:\.?[\w.-]+/)*[\w.*-]+\.[A-Za-z0-9]{1,10}(?::[^,\s`]+)?)(?=$|[\s,`])')) {
        if ($match.Groups[1].Value -notin $tokens) {
            $tokens.Add($match.Groups[1].Value)
        }
    }
    return $tokens.ToArray()
}

function Get-RepoRelativeFile {
    param([string]$OwnedPath)
    # Strip a generic URI-style scheme prefix (e.g. a game engine's virtual
    # resource root, or any other project-specific virtual path scheme)
    # rather than one hardcoded project's exact prefix.
    $path = $OwnedPath -replace '^[A-Za-z][A-Za-z0-9+.-]*://', ''
    $path = $path -replace ':\d+(?:-\d+)?$', ''
    if ($path -match '^(.+\.[A-Za-z0-9]{1,10}):[^/\\]+$') {
        $path = $Matches[1]
    }
    return $path.Replace('/', [IO.Path]::DirectorySeparatorChar)
}

$requestedPath = $PlanPath
if (-not [IO.Path]::IsPathRooted($requestedPath)) {
    $requestedPath = Join-Path $repoRoot $requestedPath
}
Add-Check (Test-Path -LiteralPath $requestedPath -PathType Container) "[Files] PlanPath is not a directory: $PlanPath"
if (-not (Test-Path -LiteralPath $requestedPath -PathType Container)) {
    Write-Output "FAIL: $($errors.Count) error(s), $checks checks."
    exit 1
}

$planRoot = (Resolve-Path -LiteralPath $requestedPath).Path
Add-Check ($planRoot.StartsWith($repoRoot, [StringComparison]::OrdinalIgnoreCase)) "[Files] PlanPath must be inside the repository."

$spec = Read-RequiredFile (Join-Path $planRoot 'SPEC.md') 'SPEC.md'
$plan = Read-RequiredFile (Join-Path $planRoot 'PLAN.md') 'PLAN.md'
$packets = Read-RequiredFile (Join-Path $planRoot 'PACKETS.md') 'PACKETS.md'
$status = Read-RequiredFile (Join-Path $planRoot 'STATUS.md') 'STATUS.md'
$workspaceText = (($spec, $plan, $packets, $status) -join "`n")

# 1-4: ID traceability and exact acceptance quoting.
$acceptanceMatches = @([regex]::Matches($spec, '(?m)^\s*-\s*\[[ xX]\]\s*\*\*(A\d+):\*\*'))
$acceptanceIds = @($acceptanceMatches | ForEach-Object { $_.Groups[1].Value })
$validationRows = @(Get-Table $plan '^\s*\|\s*Validation ID\s*\|')
$validationIds = @($validationRows | ForEach-Object { $_.'Validation ID' } | Where-Object { $_ -match '^V\d+$' })
$contractMatches = @([regex]::Matches($packets, '(?m)^###\s+(C\d+):'))
$contractIds = @($contractMatches | ForEach-Object { $_.Groups[1].Value })

Add-Check (($acceptanceIds | Select-Object -Unique).Count -eq $acceptanceIds.Count) '[Check 2] Duplicate Acceptance ID definition.'
Add-Check (($validationIds | Select-Object -Unique).Count -eq $validationIds.Count) '[Check 2] Duplicate Validation ID definition.'
Add-Check (($contractIds | Select-Object -Unique).Count -eq $contractIds.Count) '[Check 3] Duplicate Contract ID definition.'

foreach ($acceptanceId in ($acceptanceIds | Select-Object -Unique)) {
    $mapped = $false
    foreach ($row in $validationRows) {
        if ([string]$row.'Acceptance IDs' -match "\b$([regex]::Escape($acceptanceId))\b") {
            $mapped = $true
        }
    }
    Add-Check $mapped "[Check 1] $acceptanceId is not mapped by any validation row."
}

foreach ($kind in @(
    @('A', $acceptanceIds),
    @('V', $validationIds),
    @('C', $contractIds)
)) {
    $prefix = [string]$kind[0]
    $defined = @($kind[1] | Select-Object -Unique)
    $referenced = @([regex]::Matches($workspaceText, "\b$prefix\d+\b") | ForEach-Object { $_.Value } | Select-Object -Unique)
    foreach ($id in $referenced) {
        Add-Check ($id -in $defined) "[Check $((@{'A'=2;'V'=2;'C'=3})[$prefix])] Referenced $id is undefined."
    }
    foreach ($id in $defined) {
        $occurrences = [regex]::Matches($workspaceText, "\b$([regex]::Escape($id))\b").Count
        Add-Check ($occurrences -gt 1) "[Check $((@{'A'=2;'V'=2;'C'=3})[$prefix])] Defined $id is orphaned."
    }
}

$normalizedSpec = Normalize-Text $spec
foreach ($quote in [regex]::Matches($packets, '(?m)^\s*-\s*(A\d+):\s*(.+)$')) {
    $id = $quote.Groups[1].Value
    $text = Normalize-Text $quote.Groups[2].Value
    if ($text -notmatch '^\[') {
        Add-Check ($normalizedSpec.Contains($text)) "[Check 4] Packet text for $id is not a whitespace-normalized SPEC.md substring."
    }
}

# 5-12 and 19-23: stage design, routing, ownership, and validation assignment.
$stages = @(Get-StageSections $plan)
Add-Check ($stages.Count -gt 0) '[Stages] No milestone or integration records found.'
$packetSections = @(Get-PacketSections $packets)
$packetIds = @($packetSections | ForEach-Object { $_.Id })
Add-Check (($packetIds | Select-Object -Unique).Count -eq $packetIds.Count) '[Packets] Duplicate stage packet.'
$planRelativePath = $planRoot.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/')
# Claude-native allocation vocabulary. A stage's Assigned tier is a model tier
# (lead/haiku/sonnet/opus, optionally with an effort suffix) or a named role
# from .claude/agents (repo-scout/plan-reviewer/validator).
$tierPattern = '^(lead|haiku|sonnet|opus|repo-scout|plan-reviewer|validator)\b'

$waveStages = @{}
# Every stage names an explicit Assigned tier, so there is no plan-wide high
# default to infer; per-stage opus assignment drives the split-attempt gate.
$planUsesHighDefault = $false
foreach ($stage in $stages) {
    $designState = Get-Field $stage 'Design state'
    Add-Check ($designState -in @('Frozen', 'Bounded-choice')) "[Check 5] $($stage.Id) Design state must be Frozen or Bounded-choice; Open/missing cannot hand off."
    $contracts = Get-Field $stage 'Contract IDs'
    if ($designState -eq 'Frozen') {
        Add-Check ($contracts -match '\bC\d+\b') "[Check 6] Frozen stage $($stage.Id) must name at least one Contract ID."
    }
    if ($designState -eq 'Bounded-choice') {
        $choice = Get-Field $stage 'Bounded choice'
        if (-not $choice) {
            $choice = $stage.Text
        }
        Add-Check ($choice -match '(?i)Options\s*:') "[Check 7] $($stage.Id) bounded choice must enumerate Options."
        Add-Check ($choice -match '(?i)Default\s*:') "[Check 7] $($stage.Id) bounded choice must name a Default."
        Add-Check ($choice -match '(?i)Change observation\s*:') "[Check 7] $($stage.Id) bounded choice must name the exact Change observation."
        $choiceBlock = ''
        if ($stage.Text -match '(?ms)Bounded choice\s*\|(.+?)(?:\r?\n\||\z)') {
            $choiceBlock = $Matches[1]
        }
        if ($choiceBlock) {
            Add-Check ($choiceBlock -notmatch '\bC\d+\b|(?:^|\s)(?:res://|[\w.-]+/)[^\s,;]+') "[Check 7] $($stage.Id) bounded-choice block contains a Contract ID or bare path."
        }
    }

    $profile = Get-Field $stage 'Assigned tier'
    $profileBase = $null
    if ($profile -match $tierPattern) {
        $profileBase = $Matches[1]
    }
    Add-Check ([bool]$profileBase) "[Check 19] $($stage.Id) Assigned tier '$profile' is not a known tier (lead/haiku/sonnet/opus) or role (repo-scout/plan-reviewer/validator)."
    $isHigh = $profileBase -eq 'opus'
    if (-not $profile -and $planUsesHighDefault) {
        $isHigh = $true
    }
    if ($isHigh) {
        $splitText = ''
        if ($stage.Text -match '(?ms)^####\s+Split attempt\s*\r?\n(.+?)(?=^####|^#{2,3}\s|\z)') {
            $splitText = Normalize-Text $Matches[1]
        }
        Add-Check ($splitText -and $splitText -notmatch '(?i)^not attempted|not required') "[Check 8] $($stage.Id) high-tier stage requires a substantive Split attempt."
    }

    $forbidden = Get-Field $stage 'Forbidden scope'
    $expansion = Get-Field $stage 'Pre-authorized ownership expansion'
    Add-Check ([bool]$forbidden) "[Check 12] $($stage.Id) must name Forbidden scope."
    Add-Check ([bool]$expansion) "[Check 12] $($stage.Id) must name a pre-authorized ownership-expansion bound."

    $validationRefs = Get-Field $stage 'Validation IDs'
    Add-Check ($validationRefs -match '\bV\d+\b') "[Check 22] $($stage.Id) must name at least one Validation ID."

    $riskFlags = Get-Field $stage 'Risk flags'
    if ($profileBase -eq 'haiku' -and $riskFlags -match '(?i)native|persist|security|concurr|perf|layout') {
        Add-Check $false "[Check 20] $($stage.Id) risk flags require sonnet or stronger, not haiku."
    }

    $owned = Get-Field $stage 'Owned files/modules'
    if ($profileBase -eq 'validator') {
        Add-Check ($owned -match '(?i)^None$') "[Check 23] validator stage $($stage.Id) must declare Owned files/modules: None."
    }
    if ($profileBase -eq 'haiku') {
        $anchorText = Get-Field $stage 'Line-anchored edit sites'
        foreach ($ownedPath in Get-CodePaths $owned) {
            $fileOnly = Get-RepoRelativeFile $ownedPath
            $slashPath = $fileOnly.Replace([IO.Path]::DirectorySeparatorChar, '/')
            $hasAnchor = $anchorText -match "$([regex]::Escape($slashPath)):\d+"
            Add-Check $hasAnchor "[Check 21] Haiku stage $($stage.Id) lacks a line anchor for $slashPath."
            $absoluteOwned = Join-Path $repoRoot $fileOnly
            if (Test-Path -LiteralPath $absoluteOwned -PathType Leaf) {
                $lineCount = @(Get-Content -LiteralPath $absoluteOwned).Count
                if ($lineCount -gt 800) {
                    Add-Check $hasAnchor "[Check 21] Haiku stage $($stage.Id) owns $lineCount-line $slashPath without an anchor."
                }
            }
        }
        Add-Check ((Get-Field $stage 'Validation output') -match '(?i)^Bounded$') "[Check 21] Haiku stage $($stage.Id) must declare bounded validation output."
    }

    $wave = Get-Field $stage 'Wave'
    if ($wave -and $stage.Id -ne 'Integration') {
        if (-not $waveStages.ContainsKey($wave)) {
            $waveStages[$wave] = New-Object 'System.Collections.Generic.List[object]'
        }
        $waveStages[$wave].Add($stage)
    }

    $stagePackets = @($packetSections | Where-Object { $_.Id -eq $stage.Id })
    Add-Check ($stagePackets.Count -eq 1) "[Packets] $($stage.Id) must have exactly one dispatch packet."
    if ($stagePackets.Count -eq 1) {
        $packetText = $stagePackets[0].Text
        foreach ($requiredLabel in @(
            'Plan', 'Stage', 'Goal', 'Dependencies', 'Owner / assigned tier',
            'Design state', 'Contract IDs', 'Owned files', 'Forbidden scope',
            'Allowed interfaces', 'Pre-authorized ownership expansion',
            'Acceptance', 'Validation', 'Validation output',
            'Relevant references', 'Dirty/user-owned warnings',
            'Stop/escalate when', 'Return only'
        )) {
            Add-Check ($packetText -match "(?m)^$([regex]::Escape($requiredLabel))\s*:") "[Packets] $($stage.Id) packet is missing '$requiredLabel'."
        }
        Add-Check ($packetText -match "(?m)^Plan:\s*$([regex]::Escape($planRelativePath))\s*$") "[Packets] $($stage.Id) packet Plan path does not match $planRelativePath."
        Add-Check ($packetText -match "(?m)^Stage:\s*$([regex]::Escape($stage.Id))\b") "[Packets] $($stage.Id) packet Stage field does not match."
        Add-Check ($packetText -match "(?m)^Owner / assigned tier:\s*$([regex]::Escape($profile))\s*$") "[Packets] $($stage.Id) packet assigned tier does not match PLAN.md."
        Add-Check ($packetText -match "(?m)^Design state:\s*$([regex]::Escape($designState))\s*$") "[Packets] $($stage.Id) packet design state does not match PLAN.md."

        $planContractIds = @([regex]::Matches($contracts, '\bC\d+\b') | ForEach-Object { $_.Value } | Select-Object -Unique)
        $packetContractIds = @()
        if ($packetText -match '(?m)^Contract IDs:\s*(.+)$') {
            $packetContractIds = @([regex]::Matches($Matches[1], '\bC\d+\b') | ForEach-Object { $_.Value } | Select-Object -Unique)
        }
        Add-Check (@(Compare-Object $planContractIds $packetContractIds).Count -eq 0) "[Packets] $($stage.Id) Contract IDs differ between PLAN.md and PACKETS.md."

        $stageAcceptanceIds = @([regex]::Matches((Get-Field $stage 'Acceptance IDs'), '\bA\d+\b') | ForEach-Object { $_.Value } | Select-Object -Unique)
        foreach ($acceptanceId in $stageAcceptanceIds) {
            Add-Check ($packetText -match "(?m)^\s*-\s*$([regex]::Escape($acceptanceId)):\s*\S") "[Packets] $($stage.Id) omits acceptance text for $acceptanceId."
        }
        $stageValidationIds = @([regex]::Matches($validationRefs, '\bV\d+\b') | ForEach-Object { $_.Value } | Select-Object -Unique)
        foreach ($validationId in $stageValidationIds) {
            Add-Check ($packetText -match "(?m)^\s*-\s*$([regex]::Escape($validationId)):\s*\S") "[Packets] $($stage.Id) omits validation text for $validationId."
        }

        $planOwnedPaths = @(Get-OwnedPathTokens $owned | ForEach-Object { (Get-RepoRelativeFile $_).ToLowerInvariant() } | Select-Object -Unique)
        $packetOwnedPaths = @()
        if ($packetText -match '(?m)^Owned files:\s*(.+)$') {
            $packetOwnedPaths = @(Get-OwnedPathTokens $Matches[1] | ForEach-Object { (Get-RepoRelativeFile $_).ToLowerInvariant() } | Select-Object -Unique)
        }
        if ($owned -match '(?i)^None$') {
            Add-Check ($packetText -match '(?m)^Owned files:\s*None\s*$') "[Packets] $($stage.Id) no-file ownership must match in its packet."
        } else {
            Add-Check (@(Compare-Object $planOwnedPaths $packetOwnedPaths).Count -eq 0) "[Packets] $($stage.Id) owned files differ between PLAN.md and PACKETS.md."
        }
    }
}

foreach ($packetId in ($packetIds | Select-Object -Unique)) {
    Add-Check ($packetId -in @($stages | ForEach-Object { $_.Id })) "[Packets] Packet $packetId has no matching PLAN.md stage."
}

foreach ($wave in $waveStages.Keys) {
    $writers = @($waveStages[$wave] | Where-Object { (Get-Field $_ 'Owned files/modules') -notmatch '(?i)^None$' })
    Add-Check ($writers.Count -le 3) "[Check 10] Wave $wave declares $($writers.Count) writers; maximum is 3."
    if ($writers.Count -gt 2) {
        foreach ($writer in $writers) {
            Add-Check ((Get-Field $writer 'Design state') -eq 'Frozen') "[Check 10] Every stage in three-writer Wave $wave must be Frozen."
        }
    }

    $ownersByPath = @{}
    foreach ($writer in $writers) {
        foreach ($ownedPath in Get-CodePaths (Get-Field $writer 'Owned files/modules')) {
            $fileOnly = (Get-RepoRelativeFile $ownedPath).ToLowerInvariant()
            if (-not $ownersByPath.ContainsKey($fileOnly)) {
                $ownersByPath[$fileOnly] = New-Object 'System.Collections.Generic.List[object]'
            }
            $ownersByPath[$fileOnly].Add([pscustomobject]@{ Stage = $writer; Raw = $ownedPath })
        }
    }
    foreach ($path in $ownersByPath.Keys) {
        $owners = $ownersByPath[$path].ToArray()
        Add-Check ($owners.Count -le 1) "[Check 9] Wave $wave has overlapping ownership of $path."
        if ($owners.Count -gt 1 -and ($owners | Where-Object { $_.Raw -match '\.[A-Za-z0-9]+:[^\d][^/\\]*$' }).Count -gt 0) {
            foreach ($owner in $owners) {
                Add-Check ((Get-Field $owner.Stage 'Worktree') -notmatch '(?i)^No$|^None$|^$') "[Check 11] Concurrent file:symbol ownership of $path requires a declared worktree."
            }
        }
    }
}

# The ownership matrix is authoritative and must exactly mirror stage ownership.
$ownershipRows = @(Get-Table $plan '^\s*\|\s*Path\s*\|\s*Wave\s*\|\s*Owning stage\s*\|')
Add-Check ($ownershipRows.Count -gt 0) '[Ownership matrix] Missing or empty Ownership matrix.'
$expectedOwnership = New-Object 'System.Collections.Generic.List[object]'
foreach ($stage in $stages) {
    $wave = Get-Field $stage 'Wave'
    foreach ($ownedPath in Get-CodePaths (Get-Field $stage 'Owned files/modules')) {
        $expectedOwnership.Add([pscustomobject]@{
            Path = (Get-RepoRelativeFile $ownedPath).ToLowerInvariant()
            Wave = $wave
            Stage = $stage.Id
        })
    }
}
$actualOwnership = New-Object 'System.Collections.Generic.List[object]'
foreach ($row in $ownershipRows) {
    $matrixPaths = @(Get-CodePaths ([string]$row.Path) |
        ForEach-Object { (Get-RepoRelativeFile $_).ToLowerInvariant() })
    Add-Check ($matrixPaths.Count -eq 1) "[Ownership matrix] Each row must name exactly one code path: $($row.Path)"
    if ($matrixPaths.Count -eq 1) {
        $actualOwnership.Add([pscustomobject]@{
            Path = $matrixPaths[0]
            Wave = [string]$row.Wave
            Stage = [string]$row.'Owning stage'
        })
    }
}
foreach ($expected in $expectedOwnership) {
    $matches = @($actualOwnership | Where-Object {
        $_.Path -eq $expected.Path -and $_.Wave -eq $expected.Wave -and $_.Stage -eq $expected.Stage
    })
    Add-Check ($matches.Count -eq 1) "[Ownership matrix] Missing or duplicate mapping for $($expected.Path), Wave $($expected.Wave), $($expected.Stage)."
}
foreach ($actual in $actualOwnership) {
    $matches = @($expectedOwnership | Where-Object {
        $_.Path -eq $actual.Path -and $_.Wave -eq $actual.Wave -and $_.Stage -eq $actual.Stage
    })
    Add-Check ($matches.Count -eq 1) "[Ownership matrix] Extraneous or mismatched mapping for $($actual.Path), Wave $($actual.Wave), $($actual.Stage)."
}

$integration = @($stages | Where-Object { $_.Id -eq 'Integration' } | Select-Object -First 1)
Add-Check ($integration.Count -eq 1) '[Check 22] Exactly one Integration stage is required.'
if ($integration.Count -eq 1) {
    Add-Check ($integration[0].Text -match '(?i)full applicable suite') '[Check 22] Integration must run the full applicable suite.'
    $integrationIds = Get-Field $integration[0] 'Validation IDs'
    $hasIntegrationRow = $false
    foreach ($row in $validationRows) {
        if ($row.When -match '(?i)Integration' -and $integrationIds -match "\b$([regex]::Escape([string]$row.'Validation ID'))\b") {
            $hasIntegrationRow = $true
        }
    }
    Add-Check $hasIntegrationRow '[Check 22] Integration Validation IDs must include a matrix row scheduled for Integration.'
}

# 13, 18: validation commands are runnable and honestly classified.
#
# Project-specific extension point: the source repository this linter was
# adapted from also enforced (a) that every game-engine test command used one
# exact console-binary path rather than a bare launcher on PATH, (b) that a
# script-style test used one invocation shape and a scene-style test used
# another, (c) that a required cache-priming command preceded the first such
# test in a session, and (d) that a Python test suite changed into one exact
# working directory first. None of that generalizes to an arbitrary project,
# so it is intentionally omitted here rather than left as dead project-specific
# logic. If this repository has an analogous invariant -- a required
# launcher/wrapper binary, a mandatory prelude command, a fixed working
# directory for a given test runner, or a required invocation flag -- add an
# `Add-Check` block for it in this loop, following the pattern already used
# below for referenced-path existence. Leaving this extension point empty is
# a valid default: it means "no such invariant has been added yet."
$allowedDeterminism = @('deterministic', 'noisy-retry', 'skips-headless', 'manual')
Add-Check ($validationRows.Count -gt 0) '[Validation] Validation matrix is missing or empty.'
foreach ($row in $validationRows) {
    $command = [string]$row.'Exact command or check'
    $style = [string]$row.Style
    $environment = [string]$row.Environment
    $determinism = [string]$row.Determinism
    Add-Check ([bool]$style) "[Check 18] $($row.'Validation ID') is missing Style."
    Add-Check ([bool]$environment) "[Check 18] $($row.'Validation ID') is missing Environment."
    Add-Check ($determinism -in $allowedDeterminism) "[Check 18] $($row.'Validation ID') has invalid Determinism '$determinism'."

    foreach ($target in [regex]::Matches($command, '(?i)((?:[\w.-]+/)+[\w.-]+\.[A-Za-z0-9]{1,10})')) {
        $relative = $target.Groups[1].Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
        Add-Check (Test-Path -LiteralPath (Join-Path $repoRoot $relative) -PathType Leaf) "[Check 13] $($row.'Validation ID') names missing path $relative."
    }

    # Project-specific extension point: add invocation-shape checks for this
    # row here (for example `Add-Check ($command -match '...') "..."`) if the
    # target repository has a fixed command shape worth enforcing.
}

# 24-25: contract source freshness and consumer census resolution.
foreach ($contractMatch in [regex]::Matches($packets, '(?ms)^###\s+(C\d+):[^\r\n]*\r?\n(.*?)(?=^###\s+|\z)')) {
    $contractId = $contractMatch.Groups[1].Value
    $body = $contractMatch.Groups[2].Value
    if ($body -match 'Contract source:\s*`?([^`\r\n:]+\.[A-Za-z0-9]+):(\d+)`?\s*\(read\s+(\d{4}-\d{2}-\d{2})\)') {
        $sourceRelative = $Matches[1]
        $sourceLine = [int]$Matches[2]
        $readDate = [datetime]::ParseExact($Matches[3], 'yyyy-MM-dd', [Globalization.CultureInfo]::InvariantCulture)
        $sourcePath = Join-Path $repoRoot ($sourceRelative.Replace('/', [IO.Path]::DirectorySeparatorChar))
        Add-Check (Test-Path -LiteralPath $sourcePath -PathType Leaf) "[Check 24] $contractId source file does not exist: $sourceRelative."
        if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
            $sourceLines = @(Get-Content -LiteralPath $sourcePath)
            Add-Check ($sourceLine -ge 1 -and $sourceLine -le $sourceLines.Count) "[Check 24] $contractId source line $sourceLine is outside $sourceRelative."
            $mtimeDate = (Get-Item -LiteralPath $sourcePath).LastWriteTime.Date
            Add-Check ($mtimeDate -le $readDate.Date) "[Check 24] $contractId is stale: $sourceRelative changed after $($readDate.ToString('yyyy-MM-dd'))."
        }
    } else {
        Add-Check $false "[Check 24] $contractId lacks Contract source: file:line (read YYYY-MM-DD)."
    }

    if ($body -match '(?ms)Consumer census:\s*(.+?)(?=Pre-authorized ownership expansion:|\z)') {
        $census = $Matches[1]
        foreach ($entry in [regex]::Matches($census, '(?m)`([^`:\r\n]+\.[A-Za-z0-9]+):(\d+)`(?:\s*:\s*`([^`\r\n]+)`)?')) {
            $relative = $entry.Groups[1].Value
            $lineNumber = [int]$entry.Groups[2].Value
            $snippet = Normalize-Text $entry.Groups[3].Value
            $consumerPath = Join-Path $repoRoot ($relative.Replace('/', [IO.Path]::DirectorySeparatorChar))
            Add-Check (Test-Path -LiteralPath $consumerPath -PathType Leaf) "[Check 25] $contractId consumer file does not exist: $relative."
            if (Test-Path -LiteralPath $consumerPath -PathType Leaf) {
                $consumerLines = @(Get-Content -LiteralPath $consumerPath)
                Add-Check ($lineNumber -ge 1 -and $lineNumber -le $consumerLines.Count) "[Check 25] $contractId consumer line $lineNumber is outside $relative."
                if ($snippet -and $lineNumber -le $consumerLines.Count) {
                    Add-Check ((Normalize-Text $consumerLines[$lineNumber - 1]).Contains($snippet)) "[Check 25] $contractId consumer snippet no longer matches $relative`:$lineNumber."
                }
            }
        }
    } else {
        Add-Check $false "[Check 25] $contractId lacks a Consumer census."
    }
}

foreach ($warning in $warnings) {
    Write-Warning $warning
}
if ($errors.Count -gt 0) {
    foreach ($message in $errors) {
        Write-Error $message -ErrorAction Continue
    }
    Write-Output "FAIL: $($errors.Count) shape error(s), $checks checks. Shape validation never proves contract truth."
    exit 1
}

Write-Output "PASS: $checks workspace-shape checks. This result does not validate contract truth."
