<#
.SYNOPSIS
Validates the portable planning methodology kit's own files.

.DESCRIPTION
Checks that every kit file exists and is listed in the README layout table,
that the templates still carry the methodology's required clauses, that agent
and skill frontmatter is well formed and cross-referenced, that no vocabulary
from an older toolchain survives outside UPGRADING.md, that text files are
clean UTF-8 without trailing whitespace, and that every PowerShell script
parses. Given a repository that has installed the linter, it also checks that
the installed copy is byte-identical to the kit's. It then simulates an
install in a temporary folder and runs `fixtures/run-smoke-test.ps1` against
it, which proves the shipped linter
accepts the valid fixture and rejects the broken one.

Like the workspace linter it ships, this checks shape and the presence of
documented contracts, never semantic truth. Windows PowerShell 5.1-clean.

.PARAMETER InstalledRepo
Root of a repository that has installed this kit. Its
tools/validate_plan_workspace.ps1 must match the kit's linter exactly, apart
from line endings.
Defaults to the folder two levels above the kit, which is the repository root
when the kit was copied to docs/<kit>/; the check is skipped when the default
has no installed linter.
#>
[CmdletBinding()]
param(
    [string]$InstalledRepo
)

$ErrorActionPreference = 'Stop'
$kitRoot = $PSScriptRoot
# Windows PowerShell 5.1 leaves $PSScriptRoot empty in parameter defaults.
if (-not $InstalledRepo) {
    $InstalledRepo = Join-Path $kitRoot '../..'
}
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

function Read-KitFile {
    param([string]$RelativePath)
    $path = Join-Path $kitRoot $RelativePath
    Add-Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing kit file: $RelativePath"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return ''
    }
    return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

$agentNames = @('repo-scout', 'plan-reviewer', 'design-reviewer', 'validator')
$skillNames = @('design-first', 'systematic-debugging', 'verify-before-done', 'receiving-review')
$planningNames = @('SPEC', 'PLAN', 'PACKETS', 'STATUS', 'EVIDENCE')

$required = @(
    'README.md',
    'ADOPTION-CHECKLIST.md',
    'UPGRADING.md',
    'validate-kit.ps1',
    'templates/AGENTS.md',
    'templates/CLAUDE.md',
    'templates/directory-CLAUDE.md',
    'templates/agent-workflow.md',
    'templates/ROUTING.md',
    'templates/planning-CLAUDE.md',
    'templates/PROJECT-CONTRACTS.md',
    'templates/VALIDATION-COMMANDS.md',
    'templates/agent-memory-CLAUDE.md',
    'templates/decisions-README.md',
    'templates/plans-README.md',
    'templates/MIGRATION.md',
    'templates/commands/handoff.md',
    'templates/validate-plan-workspace.ps1',
    'templates/validate-plan-workspace.local.ps1',
    'templates/hooks/README.md',
    'templates/hooks/hook_payload.ps1',
    'templates/hooks/log_subagent_spawns.ps1',
    'fixtures/run-smoke-test.ps1'
)
$required += @($agentNames | ForEach-Object { "templates/agents/$_.md" })
$required += @($skillNames | ForEach-Object { "templates/skills/$_/SKILL.md" })
$required += @($planningNames | ForEach-Object { "templates/planning/$_.md" })
$required += @($planningNames | ForEach-Object { "fixtures/smoke-workspace/$_.md" })

foreach ($path in $required) {
    [void](Read-KitFile $path)
}

$readme = Read-KitFile 'README.md'
$adoption = Read-KitFile 'ADOPTION-CHECKLIST.md'
$upgrading = Read-KitFile 'UPGRADING.md'
$agents = Read-KitFile 'templates/AGENTS.md'
$claude = Read-KitFile 'templates/CLAUDE.md'
$workflow = Read-KitFile 'templates/agent-workflow.md'
$routing = Read-KitFile 'templates/ROUTING.md'
$plan = Read-KitFile 'templates/planning/PLAN.md'
$packets = Read-KitFile 'templates/planning/PACKETS.md'
$spec = Read-KitFile 'templates/planning/SPEC.md'
$plansReadme = Read-KitFile 'templates/plans-README.md'
$workspaceLinter = Read-KitFile 'templates/validate-plan-workspace.ps1'

# --- Every template is listed in the README layout table ------------------

foreach ($file in Get-ChildItem -LiteralPath (Join-Path $kitRoot 'templates') -Recurse -File) {
    $relative = 'templates/' + $file.FullName.Substring((Join-Path $kitRoot 'templates').Length).TrimStart('\', '/').Replace('\', '/')
    $listedAs = $relative
    if ($relative -like 'templates/agents/*.md') { $listedAs = 'templates/agents/*.md' }
    elseif ($relative -like 'templates/skills/*/SKILL.md') { $listedAs = 'templates/skills/*/SKILL.md' }
    elseif ($relative -like 'templates/planning/*.md') { $listedAs = 'templates/planning/*.md' }
    elseif ($relative -like 'templates/hooks/*.ps1') { $listedAs = 'templates/hooks/*.ps1' }
    elseif ($relative -eq 'templates/hooks/README.md') { $listedAs = 'templates/hooks/README.md' }
    Add-Check ($readme.Contains($listedAs)) "README layout table does not list $relative (expected '$listedAs')."
}

# --- Methodology contract: clauses that must still be present -------------

function Test-Clauses {
    param([string]$Label, [string]$Text, [string[]]$Patterns)
    foreach ($pattern in $Patterns) {
        Add-Check ($Text -match $pattern) "$Label is missing: $pattern"
    }
}

Test-Clauses 'README' $readme @(
    'Setup prompt: project with no planning methodology',
    'Setup prompt: upgrade an older planning methodology',
    'never application\s+behavior changes',
    '\[PROJECT: \.\.\.\]',
    'run-smoke-test\.ps1',
    'Install-marker scan',
    'validate_plan_workspace\.local\.ps1',
    'UPGRADING\.md',
    'AskUserQuestion'
)
Test-Clauses 'AGENTS template' $agents @(
    '## Engineering standards',
    '### Definition of done',
    'Size floor',
    'State the design before the first edit',
    'One owner per shared value',
    'Refactor or file it',
    'is an answer\s+request',
    "Non-planning requests preserve the user's active model and reasoning effort",
    'Skip the workspace\s+entirely',
    'single-stage\s+shape',
    'No stage may hand off as `Open`',
    'engineering:architecture',
    'docs/planning/ROUTING\.md'
)
Test-Clauses 'CLAUDE template' $claude @(
    '@AGENTS\.md',
    '## Planner read ladder',
    '## Validation reach',
    'checks shape,\s+never truth'
)
foreach ($name in ($agentNames + $skillNames)) {
    Add-Check ($claude -match [regex]::Escape($name)) "CLAUDE template does not list $name."
}
Test-Clauses 'Workflow template' $workflow @(
    'consumer census during\s+planning',
    'Covering tests:',
    '`Frozen`.*\r?\n?.*`Bounded-choice`',
    'Plans that start from a design reference',
    'single-stage shape',
    'cost\s+multiplier',
    'checks shape, never truth',
    'Prompt-scenario contract',
    'Planning on Claude Fable 5\.1'
)
Test-Clauses 'Routing template' $routing @(
    '## Model-tier routing table',
    'Long-context need is first',
    '## Fork or fresh subagent',
    '## Roster',
    '## Dispatch-ready packets',
    'Covering tests:',
    'Three are permitted only when',
    'token-cost multiplier',
    'Use one focused independent review',
    'design-reviewer',
    'receiving-review'
)
Test-Clauses 'PLAN template' $plan @(
    '## Ownership matrix',
    '\| Sandbox \|',
    'Design state',
    'Contract IDs',
    'Assigned tier',
    'Routing inputs',
    'Pre-authorized ownership expansion',
    '#### Split attempt',
    'Cheap-tier share',
    'Cost multiplier',
    '### Stage Model Allocation'
)
Test-Clauses 'PACKETS template' $packets @(
    '## Frozen contracts',
    'Contract source:',
    'Enumerated edit sites:',
    'Consumer census:',
    'Pre-authorized ownership expansion:',
    'Covering tests:',
    '## Stage packets',
    'Line-anchored edit sites:',
    'Owner / assigned tier'
)
Test-Clauses 'SPEC template' $spec @(
    '## Design reference',
    '## Design rationale',
    'Decision record',
    '\*\*A1:\*\*'
)
Test-Clauses 'UPGRADING' $upgrading @(
    '## Recognize the generation',
    '### From G1',
    '### From G2',
    'Never edit, move, rename, or bulk-convert'
)
Add-Check ($plansReadme -match '(?s)SPEC\.md.*PLAN\.md.*PACKETS\.md.*STATUS\.md.*EVIDENCE\.md') 'plans README must name all five workspace artifacts.'
Add-Check ($adoption -match 'run-smoke-test\.ps1') 'Adoption checklist must require the smoke test.'
Add-Check ($workspaceLinter -match 'checks shape, never truth') 'Workspace linter lacks the shape-not-truth disclaimer.'
Add-Check ($workspaceLinter -match 'validate_plan_workspace\.local\.ps1') 'Workspace linter does not load the local extension file.'
$localTemplate = Read-KitFile 'templates/validate-plan-workspace.local.ps1'
Add-Check ($localTemplate -match 'function Test-LocalValidationRow' -and $workspaceLinter -match 'Test-LocalValidationRow') 'Local-check template and linter disagree on Test-LocalValidationRow.'
Add-Check ($localTemplate -match 'function Test-LocalValidationMatrix' -and $workspaceLinter -match 'Test-LocalValidationMatrix') 'Local-check template and linter disagree on Test-LocalValidationMatrix.'

# A repository that has installed the linter must keep it identical to the
# kit's, apart from line endings, which git may convert on checkout; project
# rules belong in the local extension file instead. An explicit -InstalledRepo
# must have the linter; the default may not.
$installedLinter = Join-Path $InstalledRepo 'tools/validate_plan_workspace.ps1'
if ($PSBoundParameters.ContainsKey('InstalledRepo')) {
    Add-Check (Test-Path -LiteralPath $installedLinter -PathType Leaf) "-InstalledRepo has no tools/validate_plan_workspace.ps1: $InstalledRepo"
}
if (Test-Path -LiteralPath $installedLinter -PathType Leaf) {
    $installedText = [IO.File]::ReadAllText($installedLinter, [Text.Encoding]::UTF8).Replace("`r`n", "`n")
    Add-Check ($installedText -ceq $workspaceLinter.Replace("`r`n", "`n")) 'Installed tools/validate_plan_workspace.ps1 differs from templates/validate-plan-workspace.ps1; copy the kit linter over it unchanged.'
}

# The linter owns the template vocabulary it parses. Read its required packet
# labels and stage fields from its own source, so a linter change is checked
# against the templates without a second hand-kept list here.
$labelBlock = [regex]::Match($workspaceLinter, '(?s)foreach \(\$requiredLabel in @\((.+?)\)\) \{')
Add-Check $labelBlock.Success 'Could not find the required packet-label array in the workspace linter.'
$packetLabels = @([regex]::Matches($labelBlock.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
Add-Check ($packetLabels.Count -gt 0) 'The workspace linter requires no packet labels.'
foreach ($label in $packetLabels) {
    Add-Check ($packets -match "(?m)^$([regex]::Escape($label))\s*:") "PACKETS template lacks the packet label '$label' the linter requires."
}
$stageFields = @([regex]::Matches($workspaceLinter, "Get-Field \`$\w+ '([^']+)'") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
Add-Check ($stageFields.Count -gt 0) 'The workspace linter reads no stage fields.'
foreach ($field in $stageFields) {
    # 'Bounded choice' is an optional field the linter falls back from.
    if ($field -eq 'Bounded choice') {
        continue
    }
    Add-Check ($plan -match "(?m)^\|\s*$([regex]::Escape($field))\s*\|") "PLAN template lacks the stage field '$field' the linter reads."
}

# --- Agent and skill frontmatter ------------------------------------------

foreach ($name in $agentNames) {
    $text = Read-KitFile "templates/agents/$name.md"
    Add-Check ($text -match "(?m)^name:\s*$([regex]::Escape($name))\s*$") "$name.md frontmatter name does not match its filename."
    Add-Check ($text -match '(?m)^description:\s*\S') "$name.md is missing a frontmatter description."
    Add-Check ($text -match '(?m)^tools:\s*\S') "$name.md is missing a frontmatter tools list."
    Add-Check ($text -match '(?m)^model:\s*(haiku|sonnet|opus)\s*$') "$name.md frontmatter model must be haiku, sonnet, or opus."
    Add-Check ($routing -match "``$([regex]::Escape($name)).md``") "ROUTING roster table does not list $name.md."
}
foreach ($name in $skillNames) {
    $text = Read-KitFile "templates/skills/$name/SKILL.md"
    Add-Check ($text -match "(?m)^name:\s*$([regex]::Escape($name))\s*$") "Skill $name frontmatter name does not match its folder."
    Add-Check ($text -match '(?m)^description:\s*\S') "Skill $name is missing a frontmatter description."
}
$handoff = Read-KitFile 'templates/commands/handoff.md'
Add-Check ($handoff -match '(?m)^description:\s*\S') 'handoff command is missing a frontmatter description.'

# --- Older-toolchain vocabulary, encoding, and whitespace -----------------

$boundedTerms = @('Sol', 'Terra', 'Luna', 'Codex', 'composer')
$boundedPattern = '(?i)\b(' + (($boundedTerms | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\b'
$substringTerms = @(
    'gpt-5',
    '.codex/',
    'default_mode_request_user_input',
    'Implement plan use workers',
    'terra_',
    'luna_',
    'sol_',
    'assigned profile',
    'workspace-write'
)
# UPGRADING.md must name the old markers to recognize them, and this script
# names them to search for them.
$vocabularyExempt = @('UPGRADING.md', 'validate-kit.ps1')

foreach ($file in Get-ChildItem -LiteralPath $kitRoot -Recurse -File) {
    $relative = $file.FullName.Substring($kitRoot.Length).TrimStart('\', '/').Replace('\', '/')
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    Add-Check (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) "UTF-8 byte-order mark: $relative"
    $text = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    Add-Check ($text -notmatch '(?m)[ \t]+\r?$') "Trailing whitespace: $relative"
    Add-Check (-not $text.Contains([string][char]0x00E2)) "Possible mojibake: $relative"
    Add-Check (-not $text.Contains([string][char]0xFFFD)) "Replacement character (bad encoding): $relative"

    if ($relative -in $vocabularyExempt) {
        continue
    }
    if ($text -match $boundedPattern) {
        Add-Check $false "Older-toolchain term '$($Matches[1])' found in $relative."
    } else {
        $checks++
    }
    foreach ($term in $substringTerms) {
        Add-Check ($text -notmatch [regex]::Escape($term)) "Older-toolchain term '$term' found in $relative."
    }
}

Add-Check ((Get-ChildItem -LiteralPath $kitRoot -Recurse -Filter '*.toml' -File).Count -eq 0) 'Kit must contain no .toml agent profiles.'
Add-Check (-not (Test-Path -LiteralPath (Join-Path $kitRoot 'templates/config.toml'))) 'Kit must not install a toolchain config.toml.'

# --- PowerShell scripts must parse -----------------------------------------

foreach ($script in Get-ChildItem -LiteralPath $kitRoot -Recurse -Filter '*.ps1' -File) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    Add-Check ($parseErrors.Count -eq 0) "$($script.Name) has PowerShell parse errors: $($parseErrors.Message -join '; ')"
}

# --- End-to-end: simulated install plus the smoke test ---------------------

$simRoot = Join-Path ([IO.Path]::GetTempPath()) ('kit-sim-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    New-Item -ItemType Directory -Path (Join-Path $simRoot 'docs'), (Join-Path $simRoot 'tools') | Out-Null
    Copy-Item -LiteralPath (Join-Path $kitRoot 'templates/AGENTS.md') -Destination (Join-Path $simRoot 'AGENTS.md')
    Copy-Item -LiteralPath (Join-Path $kitRoot 'templates/agent-workflow.md') -Destination (Join-Path $simRoot 'docs/agent-workflow.md')
    Copy-Item -LiteralPath (Join-Path $kitRoot 'templates/validate-plan-workspace.ps1') -Destination (Join-Path $simRoot 'tools/validate_plan_workspace.ps1')
    $shell = (Get-Process -Id $PID).Path
    $ErrorActionPreference = 'Continue'
    $smoke = & $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $kitRoot 'fixtures/run-smoke-test.ps1') -RepoRoot $simRoot 2>&1 | ForEach-Object { [string]$_ }
    $smokeExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Add-Check ($smokeExit -eq 0) "Smoke test against a simulated install failed:`n$($smoke -join "`n")"
} finally {
    if (Test-Path -LiteralPath $simRoot) {
        Remove-Item -LiteralPath $simRoot -Recurse -Force
    }
}

if ($agents.Length -gt 10000) { $warnings.Add("AGENTS template exceeds the 10,000-character soft target: $($agents.Length).") }
if ($workflow.Length -gt 9000) { $warnings.Add("Workflow template exceeds the 9,000-character soft target: $($workflow.Length).") }
if ($routing.Length -gt 9000) { $warnings.Add("ROUTING template exceeds the 9,000-character soft target: $($routing.Length).") }

foreach ($warning in $warnings) {
    Write-Warning $warning
}
if ($errors.Count -gt 0) {
    foreach ($message in $errors) {
        Write-Output "ERROR: $message"
    }
    Write-Output "FAIL: $($errors.Count) kit error(s), $($warnings.Count) warning(s), $checks checks."
    exit 1
}

Write-Output "PASS: $checks kit checks, $($required.Count) required files, smoke test passed, $($warnings.Count) warning(s)."
