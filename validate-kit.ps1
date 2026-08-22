<#
.SYNOPSIS
Validates the portable planning methodology kit's own files.

.DESCRIPTION
Checks that the kit's required files exist, that its content preserves the
documented methodology contract, that it contains no leftover vocabulary from
a different toolchain (no Codex/Sol/Terra/Luna, no .toml agent profiles, no
separate workflow-document validator), and that its PowerShell templates
parse. Like the workspace linter it ships, this checks shape and the presence
of documented contracts, never semantic truth.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$kitRoot = $PSScriptRoot
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
    return Get-Content -Raw -Encoding UTF8 -LiteralPath $path
}

$agentFiles = @('repo-scout.md', 'plan-reviewer.md', 'validator.md')
$required = @(
    'README.md',
    'ADOPTION-CHECKLIST.md',
    'templates/AGENTS.md',
    'templates/agent-workflow.md',
    'templates/ROUTING.md',
    'templates/PROJECT-CONTRACTS.md',
    'templates/VALIDATION-COMMANDS.md',
    'templates/plans-README.md',
    'templates/MIGRATION.md',
    'templates/planning/SPEC.md',
    'templates/planning/PLAN.md',
    'templates/planning/PACKETS.md',
    'templates/planning/STATUS.md',
    'templates/planning/EVIDENCE.md',
    'templates/validate-plan-workspace.ps1'
)
$required += @($agentFiles | ForEach-Object { "templates/agents/$_" })

foreach ($path in $required) {
    [void](Read-KitFile $path)
}

$readme = Read-KitFile 'README.md'
$adoption = Read-KitFile 'ADOPTION-CHECKLIST.md'
$agents = Read-KitFile 'templates/AGENTS.md'
$workflow = Read-KitFile 'templates/agent-workflow.md'
$routing = Read-KitFile 'templates/ROUTING.md'
$plan = Read-KitFile 'templates/planning/PLAN.md'
$packets = Read-KitFile 'templates/planning/PACKETS.md'
$plansReadme = Read-KitFile 'templates/plans-README.md'
$workspaceLinter = Read-KitFile 'templates/validate-plan-workspace.ps1'

# --- Methodology contract: content that must still be present -------------

foreach ($phrase in @(
    'Setup prompt: new project',
    'Setup prompt: migrate an older planning workflow',
    'Do not change\s+application behavior',
    'Frozen',
    'Bounded-choice',
    'consumer census',
    'validate_plan_workspace\.ps1',
    '\.claude/agents'
)) {
    Add-Check ($readme -match $phrase) "README is missing: $phrase"
}

foreach ($pattern in @(
    'docs/planning/ROUTING\.md',
    "Non-planning requests preserve the user's active model and reasoning effort",
    'Three are allowed only when every\s+stage is `Frozen`',
    '`Open` is planning-incomplete and may not hand off',
    'first attempt to split\s+the stage',
    'verbatim inline stage packet'
)) {
    Add-Check ($agents -match $pattern) "AGENTS template is missing contract: $pattern"
}

foreach ($pattern in @(
    'consumer census during\s+planning',
    'Frozen.*Bounded-choice.*Open',
    'checks shape, never truth',
    'Prompt-scenario contract'
)) {
    Add-Check ($workflow -match $pattern) "Workflow template is missing contract: $pattern"
}

foreach ($pattern in @(
    '## Model-tier routing table',
    'Long-context need is first',
    '## Roster',
    '## Dispatch-ready packets',
    'Three are permitted only when',
    'Use one focused independent review'
)) {
    Add-Check ($routing -match $pattern) "Routing template is missing contract: $pattern"
}

foreach ($pattern in @(
    '## Ownership matrix',
    'Design state',
    'Contract IDs',
    'Assigned tier',
    'Routing inputs',
    'Pre-authorized ownership expansion',
    '#### Split attempt',
    'Cheap-tier share',
    '### Stage Model Allocation'
)) {
    Add-Check ($plan -match $pattern) "PLAN template is missing contract: $pattern"
}
foreach ($pattern in @(
    '## Frozen contracts',
    'Contract source:',
    'Enumerated edit sites:',
    'Consumer census:',
    'Pre-authorized ownership expansion:',
    '## Stage packets',
    'Line-anchored edit sites:',
    'Owner / assigned tier'
)) {
    Add-Check ($packets -match $pattern) "PACKETS template is missing contract: $pattern"
}

Add-Check ($plansReadme -match '(?s)SPEC\.md.*PLAN\.md.*PACKETS\.md.*STATUS\.md.*EVIDENCE\.md') 'plans README must name all five workspace artifacts.'
Add-Check ($adoption -match 'representative filled workspace') 'Adoption checklist must require a workspace-linter smoke test.'
Add-Check ($workspaceLinter -match 'Get-PacketSections') 'Workspace linter lacks packet parsing.'
Add-Check ($workspaceLinter -match 'Shape validation never proves contract truth|checks shape, never truth') 'Workspace linter lacks the shape-not-truth disclaimer.'

foreach ($agentFile in $agentFiles) {
    $text = Read-KitFile "templates/agents/$agentFile"
    $expectedName = [IO.Path]::GetFileNameWithoutExtension($agentFile)
    Add-Check ($text -match "(?m)^name:\s*$([regex]::Escape($expectedName))\s*$") "$agentFile frontmatter name does not match its filename."
    Add-Check ($text -match '(?m)^description:\s*\S') "$agentFile is missing a frontmatter description."
    Add-Check ($text -match '(?m)^tools:\s*\S') "$agentFile is missing a frontmatter tools list."
    Add-Check ($text -match '(?m)^model:\s*(haiku|sonnet|opus)\s*$') "$agentFile frontmatter model must be haiku, sonnet, or opus."
    Add-Check ($routing -match "``$([regex]::Escape($agentFile))``") "ROUTING roster table does not list $agentFile."
}

# --- Toolchain-neutrality: forbidden vocabulary from a different toolchain -

$allFiles = @(Get-ChildItem -LiteralPath $kitRoot -Recurse -File)

# Word-bounded terms avoid false positives on ordinary English words that
# happen to contain these letters as a substring (for example "isolation",
# "console", "absolute", or "resolve" all contain "sol").
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
    'assigned profile'
)

foreach ($file in $allFiles) {
    # This checker script itself legitimately names the forbidden terms (to
    # define and search for them); exclude it from its own scan.
    if ($file.FullName -eq $PSCommandPath) {
        continue
    }
    $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
    $relative = $file.FullName.Substring($kitRoot.Length).TrimStart('\', '/')

    if ($text -match $boundedPattern) {
        Add-Check $false "Forbidden toolchain term '$($Matches[1])' found in $relative."
    } else {
        $checks++
    }
    foreach ($term in $substringTerms) {
        Add-Check ($text -notmatch [regex]::Escape($term)) "Forbidden toolchain term '$term' found in $relative."
    }

    Add-Check ($text -notmatch '(?m)[ \t]+$') "Trailing whitespace: $relative"
    Add-Check (-not $text.Contains([string][char]0x00E2)) "Possible mojibake detected: $relative"
}

Add-Check ((Get-ChildItem -LiteralPath $kitRoot -Recurse -Filter '*.toml' -File).Count -eq 0) 'Kit must contain no .toml agent profiles.'
Add-Check (-not (Test-Path -LiteralPath (Join-Path $kitRoot 'templates/config.toml'))) 'Kit must not install a toolchain config.toml.'
Add-Check (-not (Test-Path -LiteralPath (Join-Path $kitRoot 'templates/validate-planning-workflow.ps1'))) 'Kit must not install a separate workflow-document validator.'

# --- PowerShell templates must parse ---------------------------------------

foreach ($script in @(
    'validate-kit.ps1',
    'templates/validate-plan-workspace.ps1'
)) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        (Join-Path $kitRoot $script),
        [ref]$tokens,
        [ref]$parseErrors
    )
    Add-Check ($parseErrors.Count -eq 0) "$script has PowerShell parse errors: $($parseErrors.Message -join '; ')"
}

if ($agents.Length -gt 10000) { $warnings.Add("AGENTS template exceeds the 10,000-character soft target: $($agents.Length).") }
if ($workflow.Length -gt 9000) { $warnings.Add("Workflow template exceeds the 9,000-character soft target: $($workflow.Length).") }
if ($routing.Length -gt 9000) { $warnings.Add("ROUTING template exceeds the 9,000-character soft target: $($routing.Length).") }

foreach ($warning in $warnings) {
    Write-Warning $warning
}
if ($errors.Count -gt 0) {
    foreach ($message in $errors) {
        Write-Error $message -ErrorAction Continue
    }
    Write-Output "FAIL: $($errors.Count) kit error(s), $($warnings.Count) warning(s), $checks checks."
    exit 1
}

Write-Output "PASS: $checks kit checks, $($required.Count) required files, $($warnings.Count) warning(s)."
