<#
.SYNOPSIS
Validates the agrippa plugin's own files and the development files that test it.

.DESCRIPTION
Checks the plugin layout: every kit file under plugins/agrippa/ and every
development file under dev/ exists, the plugin root holds only the known
folders and files, agents/ and skills/ hold exactly the plugin's agents and
skills, and every template, script, hook, agent, skill, and bin file is listed
in the kit README layout table. It checks that the marketplace lists the one
plugin and that plugin.json and the marketplace entry carry the same version.
It checks agent and skill frontmatter and namespacing: names match their
files, carry no prefix of their own, are named with the agrippa: prefix in the
core rules, and are never pointed to at a project copy path. The agents remove
the editing tools with disallowedTools instead of listing an allowlist. No
shipped file outside templates/ and the README contains a [PROJECT: ...] slot.
The plans and decisions README templates stay short pointers, and their
rules are in the plan and design-first skills' reference files.
The core rules and templates still carry the methodology's required clauses,
the core rules stay under the 10,000-character hook context cap, and the
injection hook prints them when run with node. The spawn logger is wired and
does nothing without AGRIPPA_SPAWN_LOG=1, and the agrippa-lint wrapper is an
executable LF Node script that runs the plugin's linter. No vocabulary from
an older toolchain survives outside UPGRADING.md and this script, text files
are clean UTF-8 without trailing whitespace, every PowerShell and Node script
parses, and the two copies of LICENSE and of NOTICE are identical. It then builds a simulated
project in a temporary git repository with no copy of the linter and runs
`dev/fixtures/run-smoke-test.ps1` against it, which proves the plugin's linter
accepts the valid fixture and rejects the broken one.

Like the workspace linter it ships, this checks shape and the presence of
documented contracts, never semantic truth. Windows PowerShell 5.1-clean.

.PARAMETER InstalledRepo
Root of a project that uses the plugin. Its committed .claude/settings.json
must declare the agrippa marketplace and enable agrippa@agrippa, it must have
docs/agent_memory/project-contracts.md and validation-commands.md, and it must
keep no local copy of what the plugin provides: the agents, the plugin's
skills, the shared linter, the spawn logger, its hook_payload.ps1 helper
unless a project script still uses it, a settings.json hook or permission
that runs them, or a PowerShell tools/validate_plan_workspace.local.ps1 that
the 0.2.0 linter no longer loads. It must also keep no full copy of the rules that now ship in
the plan and design-first skills: plans/README.md and docs/decisions/README.md
are short pointers, and the old docs/planning/CLAUDE.md is gone. Each failure
names the file or setting and says what to do. The check is skipped when this
is omitted.
#>
[CmdletBinding()]
param(
    [string]$InstalledRepo
)

$ErrorActionPreference = 'Stop'
# This script lives in dev/ at the Agrippa repository root. Windows PowerShell
# 5.1 leaves $PSScriptRoot empty in parameter defaults, so resolve it here.
$devRoot = $PSScriptRoot
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $devRoot '..')).Path
$kitRoot = (Resolve-Path -LiteralPath (Join-Path $repoRoot 'plugins/agrippa')).Path
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

function Read-RepoFile {
    param([string]$Root, [string]$RelativePath)
    $path = Join-Path $Root $RelativePath
    $shown = $path.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/')
    Add-Check (Test-Path -LiteralPath $path -PathType Leaf) "Missing file: $shown"
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        return ''
    }
    return [IO.File]::ReadAllText($path, [Text.Encoding]::UTF8)
}

function Read-KitFile {
    param([string]$RelativePath)
    return Read-RepoFile $kitRoot $RelativePath
}

# Agents load from agents/ and skills from skills/ at the plugin root, under
# the agrippa: prefix. A project never keeps a copy of them. The four kit
# skills are the methodology's working skills; plan and handoff are entry
# points. install and upgrade set a project up; an older kit never copied
# them, so a project skill with one of those names is not a leftover copy.
$agentNames = @('repo-scout', 'plan-reviewer', 'design-reviewer', 'validator')
$skillNames = @('design-first', 'systematic-debugging', 'verify-before-done', 'receiving-review')
$pluginSkillNames = @('plan', 'handoff')
$allSkillNames = $skillNames + $pluginSkillNames
$setupSkillNames = @('install', 'upgrade')
$shippedSkillNames = $allSkillNames + $setupSkillNames
$planningNames = @('SPEC', 'PLAN', 'PACKETS', 'STATUS', 'EVIDENCE')

$required = @(
    '.claude-plugin/plugin.json',
    'README.md',
    'ADOPTION-CHECKLIST.md',
    'UPGRADING.md',
    'LICENSE',
    'NOTICE',
    'bin/agrippa-lint',
    'scripts/core-rules.md',
    'scripts/inject_core_rules.mjs',
    'scripts/validate_plan_workspace.mjs',
    'scripts/log_subagent_spawns.mjs',
    'hooks/hooks.json',
    'skills/plan/reference/agent-workflow.md',
    'skills/plan/reference/ROUTING.md',
    'skills/plan/reference/workspace-files.md',
    'skills/design-first/reference/decision-records.md',
    'templates/AGENTS.md',
    'templates/CLAUDE.md',
    'templates/directory-CLAUDE.md',
    'templates/PROJECT-CONTRACTS.md',
    'templates/VALIDATION-COMMANDS.md',
    'templates/LIVE-APP.md',
    'templates/agent-memory-CLAUDE.md',
    'templates/decisions-README.md',
    'templates/plans-README.md',
    'templates/MIGRATION.md',
    'templates/validate-plan-workspace.local.mjs',
    'templates/hooks/README.md'
)
$required += @($agentNames | ForEach-Object { "agents/$_.md" })
$required += @($shippedSkillNames | ForEach-Object { "skills/$_/SKILL.md" })
$required += @($planningNames | ForEach-Object { "skills/plan/templates/$_.md" })

# Development files are not shipped with the plugin.
$devRequired = @(
    'validate-kit.ps1',
    'fixtures/run-smoke-test.ps1'
)
$devRequired += @($planningNames | ForEach-Object { "fixtures/smoke-workspace/$_.md" })

foreach ($path in $required) {
    [void](Read-KitFile $path)
}
foreach ($path in $devRequired) {
    [void](Read-RepoFile $devRoot $path)
}
$rootRequired = @('.claude-plugin/marketplace.json', 'README.md', 'LICENSE', 'NOTICE')
foreach ($path in $rootRequired) {
    [void](Read-RepoFile $repoRoot $path)
}
$requiredCount = $required.Count + $devRequired.Count + $rootRequired.Count

# --- Plugin layout ----------------------------------------------------------

# The plugin root holds only these entries. A new top-level file or folder must
# be added here and to the README layout table, so nothing ships unnoticed.
$pluginEntries = @('.claude-plugin', 'agents', 'skills', 'hooks', 'bin', 'scripts', 'templates', 'README.md', 'ADOPTION-CHECKLIST.md', 'UPGRADING.md', 'LICENSE', 'NOTICE')
foreach ($entry in (Get-ChildItem -LiteralPath $kitRoot -Force)) {
    Add-Check ($pluginEntries -contains $entry.Name) "Unexpected entry at the plugin root: plugins/agrippa/$($entry.Name). Move it into a known folder, or add it to the plugin layout in dev/validate-kit.ps1 and the README layout table."
}
$agentFiles = @(Get-ChildItem -LiteralPath (Join-Path $kitRoot 'agents') -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
foreach ($file in $agentFiles) {
    Add-Check ($agentNames -contains [IO.Path]::GetFileNameWithoutExtension($file) -and $file.EndsWith('.md')) "Unexpected file in plugins/agrippa/agents/: $file. Only the agents $($agentNames -join ', ') ship there."
}
$skillFolders = @(Get-ChildItem -LiteralPath (Join-Path $kitRoot 'skills') -Force -ErrorAction SilentlyContinue | ForEach-Object { $_.Name })
foreach ($folder in $skillFolders) {
    Add-Check ($shippedSkillNames -contains $folder) "Unexpected entry in plugins/agrippa/skills/: $folder. Only the skills $($shippedSkillNames -join ', ') ship there."
}
# The agents and kit skills used to be templates copied into each project.
foreach ($oldFolder in @('templates/agents', 'templates/skills', 'commands')) {
    Add-Check (-not (Test-Path -LiteralPath (Join-Path $kitRoot $oldFolder))) "plugins/agrippa/$oldFolder must not exist: agents ship in agents/ and skills in skills/."
}

# The marketplace lists the one plugin, and both manifests carry the same
# version, so a release tag names exactly one plugin version.
function Read-Json {
    param([string]$Text, [string]$Label)
    try {
        return ConvertFrom-Json -InputObject $Text
    } catch {
        Add-Check $false "$Label is not valid JSON: $($_.Exception.Message)"
        return $null
    }
}
$pluginManifest = Read-Json (Read-KitFile '.claude-plugin/plugin.json') 'plugins/agrippa/.claude-plugin/plugin.json'
$marketplace = Read-Json (Read-RepoFile $repoRoot '.claude-plugin/marketplace.json') '.claude-plugin/marketplace.json'
if ($null -ne $pluginManifest -and $null -ne $marketplace) {
    Add-Check ($pluginManifest.name -ceq 'agrippa') "plugin.json name must be 'agrippa', found '$($pluginManifest.name)'."
    Add-Check ($marketplace.name -ceq 'agrippa') "marketplace.json name must be 'agrippa', found '$($marketplace.name)'."
    $entries = @($marketplace.plugins)
    Add-Check ($entries.Count -eq 1) "marketplace.json must list exactly one plugin, found $($entries.Count)."
    $entry = $entries | Where-Object { $_.name -ceq 'agrippa' } | Select-Object -First 1
    Add-Check ($null -ne $entry) "marketplace.json does not list the plugin 'agrippa'."
    if ($null -ne $entry) {
        Add-Check ($entry.source -ceq './plugins/agrippa') "marketplace.json entry 'agrippa' must have source './plugins/agrippa', found '$($entry.source)'."
        Add-Check ([string]$pluginManifest.version -match '^\d+\.\d+\.\d+$') "plugin.json version must be a semantic version such as 1.0.0, found '$($pluginManifest.version)'."
        Add-Check ([string]$entry.version -ceq [string]$pluginManifest.version) "marketplace.json entry 'agrippa' has version '$($entry.version)' but plugin.json has '$($pluginManifest.version)'. Set both to the release version."
    }
}

# Each copy of the license and notice must match its root original, so the
# plugin folder carries the same terms wherever it is installed.
foreach ($name in @('LICENSE', 'NOTICE')) {
    $rootCopy = Join-Path $repoRoot $name
    $pluginCopy = Join-Path $kitRoot $name
    if ((Test-Path -LiteralPath $rootCopy -PathType Leaf) -and (Test-Path -LiteralPath $pluginCopy -PathType Leaf)) {
        $rootText = [IO.File]::ReadAllText($rootCopy, [Text.Encoding]::UTF8).Replace("`r`n", "`n")
        $pluginText = [IO.File]::ReadAllText($pluginCopy, [Text.Encoding]::UTF8).Replace("`r`n", "`n")
        Add-Check ($rootText -ceq $pluginText) "$name and plugins/agrippa/$name differ. Copy the root $name over the plugin's copy."
    }
}

$readme = Read-KitFile 'README.md'
$adoption = Read-KitFile 'ADOPTION-CHECKLIST.md'
$upgrading = Read-KitFile 'UPGRADING.md'
$coreRules = Read-KitFile 'scripts/core-rules.md'
$hooksJson = Read-KitFile 'hooks/hooks.json'
$agents = Read-KitFile 'templates/AGENTS.md'
$claude = Read-KitFile 'templates/CLAUDE.md'
$workflow = Read-KitFile 'skills/plan/reference/agent-workflow.md'
$routing = Read-KitFile 'skills/plan/reference/ROUTING.md'
$plan = Read-KitFile 'skills/plan/templates/PLAN.md'
$packets = Read-KitFile 'skills/plan/templates/PACKETS.md'
$spec = Read-KitFile 'skills/plan/templates/SPEC.md'
$workspaceFiles = Read-KitFile 'skills/plan/reference/workspace-files.md'
$decisionRecords = Read-KitFile 'skills/design-first/reference/decision-records.md'
$workspaceLinter = Read-KitFile 'scripts/validate_plan_workspace.mjs'

# --- Every template, script, hook, agent, skill, and bin file is listed in the README layout table

$listedFiles = foreach ($folder in @('templates', 'scripts', 'hooks', 'agents', 'skills', 'bin')) {
    Get-ChildItem -LiteralPath (Join-Path $kitRoot $folder) -Recurse -File
}
foreach ($file in $listedFiles) {
    $relative = $file.FullName.Substring($kitRoot.Length).TrimStart('\', '/').Replace('\', '/')
    $listedAs = $relative
    if ($relative -like 'agents/*.md') { $listedAs = 'agents/*.md' }
    elseif ($relative -like 'skills/plan/templates/*.md') { $listedAs = 'skills/plan/templates/*.md' }
    elseif ($relative -match '^skills/[^/]+/SKILL\.md$' -and $skillNames -contains $relative.Split('/')[1]) { $listedAs = 'skills/*/SKILL.md' }
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
    '/agrippa:install',
    '/agrippa:upgrade',
    'never application\s+behavior changes',
    '\[PROJECT: \.\.\.\]',
    'run-smoke-test\.ps1',
    'Install-marker scan',
    'validate_plan_workspace\.local\.mjs',
    'UPGRADING\.md',
    'AskUserQuestion'
)
# The methodology's always-loaded rules live in the core rules the plugin
# injects. The AGENTS and CLAUDE templates hold project content only, so they
# must not carry a second copy of a core section.
Test-Clauses 'Core rules' $coreRules @(
    '## Request boundaries',
    '## Engineering standards',
    '### Definition of done',
    'Size floor',
    'State the design before the first edit',
    'One owner per shared value',
    'Refactor or file it',
    'Architecture owners',
    'is an answer\s+request',
    "Non-planning requests preserve the user's active model and reasoning effort",
    '## Planning trigger',
    'Skip the workspace\s+entirely',
    'single-stage\s+shape',
    'No stage may hand off as `Open`',
    '## Implementation launch',
    'engineering:architecture',
    '`agrippa:plan`',
    'ROUTING\.md',
    'agrippa-lint -PlanPath',
    'through the Bash tool',
    '## Roster and skills',
    '## Planner read ladder',
    '## Validation reach',
    'checks shape,\s+never truth'
)
# The roster names each plugin agent and skill by its namespaced name, which is
# the name a spawn or skill load must use.
foreach ($name in ($agentNames + $skillNames)) {
    Add-Check ($coreRules.Contains("``agrippa:$name``")) "Core rules do not name ``agrippa:$name`` in the roster."
}
Add-Check ($coreRules.Length -lt 10000) "Core rules exceed the 10,000-character hook context cap: $($coreRules.Length)."
Test-Clauses 'AGENTS template' $agents @(
    '## Project contracts',
    'docs/agent_memory/project-contracts\.md',
    'docs/agent_memory/validation-commands\.md'
)
Test-Clauses 'CLAUDE template' $claude @(
    '@AGENTS\.md'
)
foreach ($section in @('## Engineering standards', '### Definition of done', '## Planning trigger', '## Planner read ladder', '## Validation reach')) {
    Add-Check (-not $agents.Contains($section)) "AGENTS template repeats the core rules section '$section'."
    Add-Check (-not $claude.Contains($section)) "CLAUDE template repeats the core rules section '$section'."
}

# The hooks are Node scripts, so the same hook command works on every OS.
# Without Node on PATH the hook checks below cannot run them.
$node = Get-Command node -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
Add-Check ($null -ne $node) 'node is not on PATH. The plugin hooks run on Node.js; install it to run the hook checks.'
if ($null -ne $node) {
    $node = $node.Source
} else {
    $node = 'node'
}

# The hook must run the injection script on session and subagent start, and
# the script must print the core rules unchanged as hook context.
try {
    $hookConfig = ConvertFrom-Json -InputObject $hooksJson
} catch {
    $hookConfig = $null
}
Add-Check ($null -ne $hookConfig) 'hooks/hooks.json is not valid JSON.'
foreach ($hookEvent in @('SessionStart', 'SubagentStart')) {
    $commands = @()
    if ($null -ne $hookConfig -and $null -ne $hookConfig.hooks.$hookEvent) {
        $commands = @($hookConfig.hooks.$hookEvent | ForEach-Object { $_.hooks } | ForEach-Object { $_.command })
    }
    $wired = @($commands | Where-Object { $_ -match '^node "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/inject_core_rules\.mjs"' -and $_ -match " $hookEvent$" })
    Add-Check ($wired.Count -eq 1) "hooks/hooks.json must run node scripts/inject_core_rules.mjs $hookEvent once on $hookEvent."
    $ErrorActionPreference = 'Continue'
    $hookOutput = & $node (Join-Path $kitRoot 'scripts/inject_core_rules.mjs') $hookEvent 2>&1 | ForEach-Object { [string]$_ }
    $hookExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    $hookPayload = $null
    try {
        $hookPayload = ConvertFrom-Json -InputObject ($hookOutput -join "`n")
    } catch {
        $hookPayload = $null
    }
    $printed = ''
    if ($null -ne $hookPayload -and $hookPayload.hookSpecificOutput.hookEventName -eq $hookEvent) {
        $printed = [string]$hookPayload.hookSpecificOutput.additionalContext
    }
    Add-Check ($hookExit -eq 0 -and $printed.Replace("`r`n", "`n") -ceq $coreRules.Replace("`r`n", "`n")) "inject_core_rules.mjs $hookEvent did not print core-rules.md as $hookEvent additionalContext:`n$($hookOutput -join "`n")"
}

# The spawn logger runs on PreToolUse for the Agent tool and on every
# SubagentStart, and stays silent unless the project sets AGRIPPA_SPAWN_LOG=1.
foreach ($wiring in @(@('PreToolUse', 'Agent|Task'), @('SubagentStart', '.*'))) {
    $hookEvent = $wiring[0]
    $groups = @()
    if ($null -ne $hookConfig -and $null -ne $hookConfig.hooks.$hookEvent) {
        $groups = @($hookConfig.hooks.$hookEvent | Where-Object { $_.matcher -eq $wiring[1] })
    }
    $logCommands = @($groups | ForEach-Object { $_.hooks } | Where-Object { $_.command -match '^node "\$\{CLAUDE_PLUGIN_ROOT\}/scripts/log_subagent_spawns\.mjs"$' })
    Add-Check ($logCommands.Count -eq 1) "hooks/hooks.json must run node scripts/log_subagent_spawns.mjs once on $hookEvent with matcher '$($wiring[1])'."
}
$logProject = Join-Path ([IO.Path]::GetTempPath()) ('kit-log-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
$savedOptIn = $env:AGRIPPA_SPAWN_LOG
$savedProject = $env:CLAUDE_PROJECT_DIR
try {
    New-Item -ItemType Directory -Path $logProject | Out-Null
    $logFile = Join-Path $logProject 'subagent-spawns.log'
    $logPayload = '{"hook_event_name":"PreToolUse","session_id":"kitcheck","tool_input":{"subagent_type":"agrippa:validator","model":"sonnet"}}'
    $env:CLAUDE_PROJECT_DIR = $logProject
    $logScript = Join-Path $kitRoot 'scripts/log_subagent_spawns.mjs'
    $ErrorActionPreference = 'Continue'
    $env:AGRIPPA_SPAWN_LOG = $null
    $offOutput = $logPayload | & $node $logScript 2>&1 | ForEach-Object { [string]$_ }
    $offExit = $LASTEXITCODE
    $offWrote = Test-Path -LiteralPath $logFile
    $env:AGRIPPA_SPAWN_LOG = '1'
    $onOutput = $logPayload | & $node $logScript 2>&1 | ForEach-Object { [string]$_ }
    $onExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Add-Check ($offExit -eq 0 -and -not $offWrote -and -not $offOutput) "log_subagent_spawns.mjs must exit 0 silently and write no log without AGRIPPA_SPAWN_LOG=1:`n$($offOutput -join "`n")"
    $logged = ''
    if (Test-Path -LiteralPath $logFile) {
        $logged = [IO.File]::ReadAllText($logFile)
    }
    Add-Check ($onExit -eq 0 -and -not $onOutput -and $logged -match 'PreToolUse\s+agent=agrippa:validator model=sonnet') "log_subagent_spawns.mjs with AGRIPPA_SPAWN_LOG=1 did not log the spawn to CLAUDE_PROJECT_DIR/subagent-spawns.log:`n$($onOutput -join "`n")$logged"
} finally {
    $ErrorActionPreference = 'Stop'
    $env:AGRIPPA_SPAWN_LOG = $savedOptIn
    $env:CLAUDE_PROJECT_DIR = $savedProject
    if (Test-Path -LiteralPath $logProject) {
        Remove-Item -LiteralPath $logProject -Recurse -Force
    }
}

# The wrapper runs from the Bash tool's PATH, so git must record it as
# executable and it must keep LF line endings for its shebang to work. It has
# no extension, so Node loads it as CommonJS; it must not use ES-module syntax.
$wrapperPath = Join-Path $kitRoot 'bin/agrippa-lint'
if (Test-Path -LiteralPath $wrapperPath -PathType Leaf) {
    $wrapper = [IO.File]::ReadAllText($wrapperPath, [Text.Encoding]::UTF8)
    Add-Check ($wrapper.StartsWith("#!/usr/bin/env node`n")) 'bin/agrippa-lint must start with #!/usr/bin/env node and use LF line endings.'
    Add-Check (-not $wrapper.Contains("`r")) 'bin/agrippa-lint must use LF line endings.'
    Add-Check ($wrapper.Contains("'validate_plan_workspace.mjs'") -and $wrapper.Contains('process.argv.slice(2)')) 'bin/agrippa-lint must run ../scripts/validate_plan_workspace.mjs and pass its arguments through.'
    Add-Check ($wrapper -notmatch '(?m)^\s*(import|export)\s') 'bin/agrippa-lint is loaded as CommonJS and must not use import or export statements.'
    $ErrorActionPreference = 'Continue'
    $wrapperIndex = @(git -C $repoRoot ls-files -s -- 'plugins/agrippa/bin/agrippa-lint' 2>$null)
    $ErrorActionPreference = 'Stop'
    Add-Check ($wrapperIndex.Count -eq 1 -and $wrapperIndex[0] -match '^100755 ') 'bin/agrippa-lint must be committed as executable (git add --chmod=+x).'
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
    '\| G4: plugin',
    '### From G1',
    '### From G2',
    '### From G3',
    '### From G4 v0\.1\.0',
    '### From G4 v0\.1\.1',
    'docs/planning/CLAUDE\.md` \| Delete',
    'tools/log_subagent_spawns\.ps1` \| Delete',
    'tools/hook_payload\.ps1` \| Delete',
    'tools/validate_plan_workspace\.ps1` \| Delete',
    'Never edit, move, rename, or bulk-convert'
)
# The install and upgrade skills replace the setup prompts and keep their
# safeguards: read-only discovery, questions for material choices, every
# settings change shown before it is written, and, for upgrades, the dated-plan
# manifest, the mapping shown before any edit, and a confirmed deletion.
$installSkill = Read-KitFile 'skills/install/SKILL.md'
$upgradeSkill = Read-KitFile 'skills/upgrade/SKILL.md'
$setupClauses = @(
    '(?m)^description:.*only when the user explicitly asks',
    'Never change application code',
    'AskUserQuestion',
    'read-only',
    'extraKnownMarketplaces\.agrippa',
    '`ref`',
    'agrippa@agrippa',
    'complete\s+proposed content',
    'write\s+nothing until',
    'Never add a permission rule',
    'Install-marker scan',
    'dev/validate-kit\.ps1 -InstalledRepo',
    'run-smoke-test\.ps1 -RepoRoot',
    '\$\{CLAUDE_PLUGIN_ROOT\}/templates/'
)
Test-Clauses 'Skill install' $installSkill ($setupClauses + @(
    'Never copy the plugin',
    '/agrippa:upgrade'
))
Test-Clauses 'Skill upgrade' $upgradeSkill ($setupClauses + @(
    'SHA-256 manifest',
    'Get-FileHash -Algorithm SHA256',
    'mapping is shown to the user before any edit',
    'Every deletion is confirmed',
    'Never\s+offer a single\s+"delete all" choice',
    'never edited, moved, renamed, or converted',
    'From G3',
    '\$\{CLAUDE_PLUGIN_ROOT\}/UPGRADING\.md',
    'docs/planning/MIGRATION\.md'
))
Add-Check ($workspaceFiles -match '(?s)SPEC\.md.*PLAN\.md.*PACKETS\.md.*STATUS\.md.*EVIDENCE\.md') 'Plan skill workspace-files.md must name all five workspace artifacts.'
Test-Clauses 'Plan skill workspace-files.md' $workspaceFiles @(
    '## Artifact contract',
    '## Selective reads and soft budgets',
    'handoff-YYYY-MM-DD',
    'agrippa-lint -PlanPath',
    'checks shape,\s+never truth'
)
Test-Clauses 'Design-first skill decision-records.md' $decisionRecords @(
    'docs/decisions/',
    '## When a record is required',
    '## Shape',
    'engineering:architecture',
    'engineering:system-design',
    'never edited to change its decision'
)
Add-Check ($coreRules -match 'use the shape in `agrippa:design-first`') 'Core rules must point to agrippa:design-first for the decision-record shape.'
# The plans and decisions READMEs a project gets are pointers for people who
# browse it without the plugin. The rules they used to hold ship in the plan
# and design-first skills, so a pointer must stay short and hold no sections.
foreach ($pointer in @('templates/plans-README.md', 'templates/decisions-README.md')) {
    $pointerText = Read-KitFile $pointer
    Add-Check ($pointerText.Length -lt 600 -and $pointerText -notmatch '(?m)^## ') "plugins/agrippa/$pointer must stay a short pointer with no sections; its rules belong in a plugin skill."
    Add-Check ($pointerText.Contains('https://github.com/pxd5295/Agrippa')) "plugins/agrippa/$pointer must link to the Agrippa repository."
}
Add-Check ($adoption -match 'run-smoke-test\.ps1') 'Adoption checklist must require the smoke test.'
Add-Check ($workspaceLinter -match 'checks shape, never truth') 'Workspace linter lacks the shape-not-truth disclaimer.'
Add-Check ($workspaceLinter -match 'validate_plan_workspace\.local\.mjs') 'Workspace linter does not load the local extension file.'
$localTemplate = Read-KitFile 'templates/validate-plan-workspace.local.mjs'
Add-Check ($localTemplate -match 'export function checkValidationRow' -and $workspaceLinter -match 'checkValidationRow') 'Local-check template and linter disagree on checkValidationRow.'
Add-Check ($localTemplate -match 'export function checkValidationMatrix' -and $workspaceLinter -match 'checkValidationMatrix') 'Local-check template and linter disagree on checkValidationMatrix.'
Add-Check ($localTemplate -match 'commandPathExtensions' -and $workspaceLinter -match 'local\.commandPathExtensions') 'Local-check template and linter disagree on commandPathExtensions.'

# The linter owns the template vocabulary it parses. Read its required packet
# labels and stage fields from its own source, so a linter change is checked
# against the templates without a second hand-kept list here.
$labelBlock = [regex]::Match($workspaceLinter, '(?s)const requiredPacketLabels = \[(.+?)\];')
Add-Check $labelBlock.Success 'Could not find the required packet-label array in the workspace linter.'
$packetLabels = @([regex]::Matches($labelBlock.Groups[1].Value, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value })
Add-Check ($packetLabels.Count -gt 0) 'The workspace linter requires no packet labels.'
foreach ($label in $packetLabels) {
    Add-Check ($packets -match "(?m)^$([regex]::Escape($label))\s*:") "PACKETS template lacks the packet label '$label' the linter requires."
}
$stageFields = @([regex]::Matches($workspaceLinter, "getField\(\w+, '([^']+)'\)") | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique)
Add-Check ($stageFields.Count -gt 0) 'The workspace linter reads no stage fields.'
foreach ($field in $stageFields) {
    # 'Bounded choice' is an optional field the linter falls back from.
    if ($field -eq 'Bounded choice') {
        continue
    }
    Add-Check ($plan -match "(?m)^\|\s*$([regex]::Escape($field))\s*\|") "PLAN template lacks the stage field '$field' the linter reads."
}

# --- Agent and skill frontmatter ------------------------------------------

# The agents carry no tools allowlist, so a project's MCP tools reach them.
# Instead disallowedTools removes every editing tool, and each agent is told
# to read live-app.md for the bridge tools it must never call.
$editingTools = @('Write', 'Edit', 'NotebookEdit')
foreach ($name in $agentNames) {
    $text = Read-KitFile "agents/$name.md"
    # Claude Code adds the agrippa: prefix itself, so the frontmatter name is
    # the bare file name.
    Add-Check ($text -match "(?m)^name:\s*$([regex]::Escape($name))\s*$") "agents/$name.md frontmatter name must be '$name', matching its filename with no prefix."
    Add-Check ($text -match '(?m)^description:\s*\S') "$name.md is missing a frontmatter description."
    Add-Check ($text -notmatch '(?m)^tools:') "$name.md must not have a frontmatter tools allowlist; use disallowedTools."
    $disallowedLine = [regex]::Match($text, '(?m)^disallowedTools:\s*(.+?)\s*$')
    Add-Check $disallowedLine.Success "$name.md is missing a frontmatter disallowedTools list."
    $disallowed = @()
    if ($disallowedLine.Success) {
        $disallowed = @($disallowedLine.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() })
    }
    foreach ($tool in $editingTools) {
        Add-Check ($disallowed -contains $tool) "$name.md disallowedTools does not remove the editing tool $tool."
    }
    Add-Check ($text -match '(?m)^model:\s*(haiku|sonnet|opus)\s*$') "$name.md frontmatter model must be haiku, sonnet, or opus."
    Add-Check ($text -match 'docs/agent_memory/live-app\.md' -and $text -match '"Authoring tools"') "$name.md must point to the ""Authoring tools"" section of docs/agent_memory/live-app.md."
    Add-Check ($text -notmatch 'optional live-app block') "$name.md still has an optional live-app block."
    Add-Check ($routing -match "``$([regex]::Escape($name)).md``") "ROUTING roster table does not list $name.md."
}

# The plugin is project-neutral. A project fact belongs in a project document
# that an agent or skill reads, never in a [PROJECT: ...] slot. Only the
# project-side templates, which an install fills in, and the README, which
# explains the convention, may carry one.
foreach ($file in (Get-ChildItem -LiteralPath $kitRoot -Recurse -File)) {
    $relative = $file.FullName.Substring($kitRoot.Length).TrimStart('\', '/').Replace('\', '/')
    if ($relative -like 'templates/*' -or $relative -eq 'README.md') {
        continue
    }
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    Add-Check (-not $content.Contains('[PROJECT:')) "plugins/agrippa/$relative must be project-neutral: it contains a [PROJECT: ...] slot. Move the fact into a project document and read it from there."
}
# Every install-time blank in a project-side template is a [PROJECT: ...] slot,
# so the install-marker scan finds any that are left. A plain [...] is a
# per-plan placeholder and belongs only in the plan skill's templates. Slots
# may nest brackets, and Install note comments may quote code, so both are
# removed before the search.
foreach ($file in (Get-ChildItem -LiteralPath (Join-Path $kitRoot 'templates') -Recurse -File -Filter '*.md')) {
    $relative = $file.FullName.Substring($kitRoot.Length).TrimStart('\', '/').Replace('\', '/')
    $content = [regex]::Replace([IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8), '(?s)<!--.*?-->', '')
    $outside = New-Object System.Text.StringBuilder
    $depth = 0
    for ($i = 0; $i -lt $content.Length; $i++) {
        if ($depth -eq 0 -and [string]::CompareOrdinal($content, $i, '[PROJECT:', 0, 9) -eq 0) {
            $depth = 1
            $i += 8
            continue
        }
        if ($depth -gt 0) {
            if ($content[$i] -eq '[') { $depth++ }
            elseif ($content[$i] -eq ']') { $depth-- }
            continue
        }
        [void]$outside.Append($content[$i])
    }
    $plain = [regex]::Match($outside.ToString(), '\[[^\[\]\r\n]*\](?!\()')
    Add-Check (-not $plain.Success) "plugins/agrippa/$relative has the plain placeholder $($plain.Value) outside a [PROJECT: ...] slot. Make it a [PROJECT: ...] slot so the install-marker scan finds it when it is left unfilled."
}
foreach ($name in $shippedSkillNames) {
    $text = Read-KitFile "skills/$name/SKILL.md"
    Add-Check ($text -match "(?m)^name:\s*$([regex]::Escape($name))\s*$") "skills/$name/SKILL.md frontmatter name must be '$name', matching its folder with no prefix."
    Add-Check ($text -match '(?m)^description:\s*\S') "skills/$name/SKILL.md is missing a frontmatter description."
    # A plugin skill with this flag is not offered at all in the desktop app,
    # not even as a slash command. A skill that must wait for the user says so
    # in its description instead.
    Add-Check ($text -notmatch '(?m)^disable-model-invocation:') "skills/$name/SKILL.md must not set disable-model-invocation: the desktop app then hides the plugin skill entirely. Say in the description that it runs only when the user explicitly asks."
}
Add-Check ((Read-KitFile 'skills/handoff/SKILL.md') -match '(?m)^description:.*only when the user explicitly asks') 'Skill handoff description must say it runs only when the user explicitly asks.'
# Plugin text points to its own agents and skills by their agrippa: names, never
# at the project copy paths an older kit installed. UPGRADING.md names those
# paths so an upgrade can delete them, and the README names them for the
# -InstalledRepo check.
$copyPathPattern = '\.claude/(agents/(' + (($agentNames | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\.md|skills/(' + (($allSkillNames | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')/|commands/(' + (($pluginSkillNames | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\.md)'
foreach ($file in (Get-ChildItem -LiteralPath $kitRoot -Recurse -File)) {
    $relative = $file.FullName.Substring($kitRoot.Length).TrimStart('\', '/').Replace('\', '/')
    if ($relative -eq 'UPGRADING.md' -or $relative -eq 'README.md') {
        continue
    }
    $content = [IO.File]::ReadAllText($file.FullName, [Text.Encoding]::UTF8)
    $copyPath = [regex]::Match($content, $copyPathPattern)
    Add-Check (-not $copyPath.Success) "plugins/agrippa/$relative points to the project copy path $($copyPath.Value); name the plugin agent or skill with its agrippa: prefix instead."
}
# The plan skill points to its reference files and templates through
# ${CLAUDE_SKILL_DIR}, which Claude Code substitutes, so they resolve wherever
# the plugin is installed.
$planSkill = Read-KitFile 'skills/plan/SKILL.md'
foreach ($reference in @('reference/agent-workflow.md', 'reference/ROUTING.md', 'reference/workspace-files.md', 'templates/')) {
    Add-Check ($planSkill.Contains('${CLAUDE_SKILL_DIR}/' + $reference)) "Skill plan does not point to `${CLAUDE_SKILL_DIR}/$reference."
}
$designFirstSkill = Read-KitFile 'skills/design-first/SKILL.md'
Add-Check ($designFirstSkill.Contains('${CLAUDE_SKILL_DIR}/reference/decision-records.md')) 'Skill design-first does not point to ${CLAUDE_SKILL_DIR}/reference/decision-records.md.'
Add-Check ($planSkill -match 'agrippa-lint -PlanPath' -and $planSkill -match 'Bash tool') 'Skill plan must lint with agrippa-lint through the Bash tool.'
Add-Check ($plan -match 'agrippa-lint -PlanPath' -and $plan -match 'Bash tool') 'PLAN template must name the agrippa-lint row and say it runs through the Bash tool.'
$validatorAgent = Read-KitFile 'agents/validator.md'
Add-Check ($validatorAgent -match 'agrippa-lint' -and $validatorAgent -match 'Bash\s+tool') 'validator agent must say the agrippa-lint row runs through the Bash tool.'

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
# names them to search for them. Paths are relative to the repository root.
$vocabularyExempt = @('plugins/agrippa/UPGRADING.md', 'dev/validate-kit.ps1')

# The shipped plugin, the development files, and the repository's root files.
# docs/ and history/ are records of why the kit changed, are not shipped, and
# may describe the older toolchains.
$checkedFiles = @(Get-ChildItem -LiteralPath $kitRoot -Recurse -File) + @(Get-ChildItem -LiteralPath $devRoot -Recurse -File)
# A worktree's .git is a file that points to the main repository.
$checkedFiles += @(Get-ChildItem -LiteralPath $repoRoot -File | Where-Object { $_.Name -ne '.git' })
$checkedFiles += @(Get-ChildItem -LiteralPath (Join-Path $repoRoot '.claude-plugin') -File)
foreach ($file in $checkedFiles) {
    $relative = $file.FullName.Substring($repoRoot.Length).TrimStart('\', '/').Replace('\', '/')
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

foreach ($script in ($checkedFiles | Where-Object { $_.Extension -eq '.ps1' })) {
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile($script.FullName, [ref]$tokens, [ref]$parseErrors)
    Add-Check ($parseErrors.Count -eq 0) "$($script.Name) has PowerShell parse errors: $($parseErrors.Message -join '; ')"
}

# --- Node scripts must parse -----------------------------------------------

foreach ($script in ($checkedFiles | Where-Object { $_.Extension -eq '.mjs' -or $_.Name -eq 'agrippa-lint' })) {
    $ErrorActionPreference = 'Continue'
    $syntaxOutput = & $node --check $script.FullName 2>&1 | ForEach-Object { [string]$_ }
    $syntaxExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Add-Check ($syntaxExit -eq 0) "$($script.Name) has Node syntax errors:`n$($syntaxOutput -join "`n")"
}

# --- End-to-end: simulated project plus the smoke test ---------------------

# The simulated project is a git repository with only its own AGENTS.md. It
# has no tools/ folder, so the smoke test proves the plugin's linter needs no
# copy in the project and finds the repository root through git.
$simRoot = Join-Path ([IO.Path]::GetTempPath()) ('kit-sim-' + [guid]::NewGuid().ToString('N').Substring(0, 8))
try {
    New-Item -ItemType Directory -Path $simRoot | Out-Null
    Copy-Item -LiteralPath (Join-Path $kitRoot 'templates/AGENTS.md') -Destination (Join-Path $simRoot 'AGENTS.md')
    $ErrorActionPreference = 'Continue'
    $gitInit = git init -q $simRoot 2>&1 | ForEach-Object { [string]$_ }
    $gitInitExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Add-Check ($gitInitExit -eq 0) "git init failed for the simulated project:`n$($gitInit -join "`n")"
    Add-Check (-not (Test-Path -LiteralPath (Join-Path $simRoot 'tools'))) 'The simulated project must have no tools/ folder.'
    $shell = (Get-Process -Id $PID).Path
    $ErrorActionPreference = 'Continue'
    $smoke = & $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $devRoot 'fixtures/run-smoke-test.ps1') -RepoRoot $simRoot 2>&1 | ForEach-Object { [string]$_ }
    $smokeExit = $LASTEXITCODE
    $ErrorActionPreference = 'Stop'
    Add-Check ($smokeExit -eq 0) "Smoke test against a simulated project failed:`n$($smoke -join "`n")"
} finally {
    if (Test-Path -LiteralPath $simRoot) {
        Remove-Item -LiteralPath $simRoot -Recurse -Force
    }
}

if ($workflow.Length -gt 9000) { $warnings.Add("Workflow template exceeds the 9,000-character soft target: $($workflow.Length).") }
if ($routing.Length -gt 9000) { $warnings.Add("ROUTING template exceeds the 9,000-character soft target: $($routing.Length).") }

# --- A project that uses the plugin ----------------------------------------

# A project declares the plugin in its committed settings, keeps its own facts
# in the project documents, and keeps no copy of anything the plugin provides,
# because a copy shadows the plugin's version or drifts from it. These errors
# are listed apart from the kit's, as the project's remaining migration steps.
$projectErrors = New-Object 'System.Collections.Generic.List[string]'
$projectChecks = 0

function Add-ProjectCheck {
    param([bool]$Condition, [string]$Message)
    $script:projectChecks++
    if (-not $Condition) {
        $script:projectErrors.Add($Message)
    }
}

if ($InstalledRepo) {
    if (-not (Test-Path -LiteralPath $InstalledRepo -PathType Container)) {
        Add-ProjectCheck $false "-InstalledRepo is not a folder: $InstalledRepo"
    } else {
        $projectRoot = (Resolve-Path -LiteralPath $InstalledRepo).Path
        $enableHelp = 'as the kit README section "Enabling the plugin in a project" shows'

        $settingsPath = Join-Path $projectRoot '.claude/settings.json'
        $settings = $null
        if (-not (Test-Path -LiteralPath $settingsPath -PathType Leaf)) {
            Add-ProjectCheck $false ".claude/settings.json is missing. Create it with the extraKnownMarketplaces and enabledPlugins entries $enableHelp, and commit it."
        } else {
            $ErrorActionPreference = 'Continue'
            $tracked = @(git -C $projectRoot ls-files -- '.claude/settings.json' 2>$null)
            $ErrorActionPreference = 'Stop'
            Add-ProjectCheck ($tracked.Count -eq 1) '.claude/settings.json is not committed. Commit it so every collaborator gets the plugin; .claude/settings.local.json does not count.'
            try {
                $settings = ConvertFrom-Json -InputObject ([IO.File]::ReadAllText($settingsPath, [Text.Encoding]::UTF8))
            } catch {
                Add-ProjectCheck $false ".claude/settings.json is not valid JSON: $($_.Exception.Message)"
            }
        }
        if ($null -ne $settings) {
            $marketplaceEntry = $null
            if ($null -ne $settings.extraKnownMarketplaces) {
                $marketplaceEntry = $settings.extraKnownMarketplaces.agrippa
            }
            Add-ProjectCheck ($null -ne $marketplaceEntry -and $null -ne $marketplaceEntry.source) ".claude/settings.json does not declare the agrippa marketplace. Add extraKnownMarketplaces.agrippa with its source, pinned to a release tag with ref, $enableHelp."
            $enabled = $null
            if ($null -ne $settings.enabledPlugins) {
                $enabled = $settings.enabledPlugins.'agrippa@agrippa'
            }
            Add-ProjectCheck ($enabled -is [bool] -and $enabled) '.claude/settings.json does not enable the plugin. Add "agrippa@agrippa": true under enabledPlugins.'

            # The plugin's hooks.json runs the spawn logger, and the linter
            # runs as agrippa-lint, so settings that run local copies are left
            # over.
            if ($null -ne $settings.hooks) {
                foreach ($hookEvent in $settings.hooks.PSObject.Properties) {
                    $commands = @(@($hookEvent.Value) | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command })
                    $loggerCommands = @($commands | Where-Object { $_ -match 'log_subagent_spawns\.ps1' })
                    Add-ProjectCheck ($loggerCommands.Count -eq 0) ".claude/settings.json hooks.$($hookEvent.Name) runs a local spawn logger ($($loggerCommands -join '; ')). Remove that hook entry; the plugin runs the spawn logger when the env block sets AGRIPPA_SPAWN_LOG=1."
                }
            }
            if ($null -ne $settings.permissions) {
                foreach ($list in @('allow', 'ask', 'deny')) {
                    foreach ($rule in @($settings.permissions.$list)) {
                        if ($null -eq $rule) {
                            continue
                        }
                        Add-ProjectCheck ([string]$rule -notmatch 'validate_plan_workspace\.ps1') ".claude/settings.json permissions.$list rule '$rule' runs the local copy of the linter. Replace it with Bash(agrippa-lint:*)."
                    }
                }
            }
        }

        $projectDocuments = @(
            @('docs/agent_memory/project-contracts.md', 'templates/PROJECT-CONTRACTS.md'),
            @('docs/agent_memory/validation-commands.md', 'templates/VALIDATION-COMMANDS.md')
        )
        foreach ($document in $projectDocuments) {
            Add-ProjectCheck (Test-Path -LiteralPath (Join-Path $projectRoot $document[0]) -PathType Leaf) "$($document[0]) is missing. Write it from plugins/agrippa/$($document[1]); the plugin's agents and skills read the project's facts from it."
        }

        $moveFacts = 'Move any project facts it holds into docs/agent_memory/project-contracts.md, validation-commands.md, or live-app.md, then delete it'
        foreach ($name in $agentNames) {
            $path = ".claude/agents/$name.md"
            Add-ProjectCheck (-not (Test-Path -LiteralPath (Join-Path $projectRoot $path))) "$path is a local copy of the plugin agent agrippa:$name. $moveFacts."
        }
        foreach ($name in $allSkillNames) {
            $path = ".claude/skills/$name"
            Add-ProjectCheck (-not (Test-Path -LiteralPath (Join-Path $projectRoot $path))) "$path/ is a local copy of the plugin skill agrippa:$name. $moveFacts."
        }
        foreach ($name in $pluginSkillNames) {
            $path = ".claude/commands/$name.md"
            Add-ProjectCheck (-not (Test-Path -LiteralPath (Join-Path $projectRoot $path))) "$path is a local command that the plugin skill /agrippa:$name replaces. Delete it."
        }
        Add-ProjectCheck (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'tools/validate_plan_workspace.ps1'))) 'tools/validate_plan_workspace.ps1 is a local copy of the shared linter. Delete it; plans run agrippa-lint from the plugin, and project rules stay in tools/validate_plan_workspace.local.mjs.'
        # The 0.2.0 linter imports the .mjs local file and fails on a .ps1 one,
        # so a leftover .ps1 means the project's rules are not running.
        Add-ProjectCheck (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'tools/validate_plan_workspace.local.ps1'))) 'tools/validate_plan_workspace.local.ps1 is the PowerShell local-checks file that linters before 0.2.0 loaded. Port it to tools/validate_plan_workspace.local.mjs with the "From G4 v0.1.2" table in UPGRADING.md and delete it; agrippa-lint fails while only the .ps1 exists.'

        # Up to v0.1.0 an install copied the plan-workspace and decision-record
        # rules into these READMEs. The rules now ship in the plan and
        # design-first skills, and the project keeps a short pointer. A
        # section heading that only the full copy had marks a leftover.
        $fullCopies = @(
            @('plans/README.md', '(?m)^## (Artifact contract|Selective reads)', 'templates/plans-README.md', 'plan'),
            @('docs/decisions/README.md', '(?m)^## (When a record is required|Shape)\s*$', 'templates/decisions-README.md', 'design-first')
        )
        foreach ($copy in $fullCopies) {
            $copyPath = Join-Path $projectRoot $copy[0]
            if (Test-Path -LiteralPath $copyPath -PathType Leaf) {
                $copyText = [IO.File]::ReadAllText($copyPath, [Text.Encoding]::UTF8)
                Add-ProjectCheck ($copyText -notmatch $copy[1]) "$($copy[0]) is a full copy of rules that now ship in the plugin skill agrippa:$($copy[3]). Move any project rule in it into ""Project rules"" in AGENTS.md, then replace it with the short pointer plugins/agrippa/$($copy[2]), as ""From G4 v0.1.0"" in UPGRADING.md says."
            }
        }
        # Up to v0.1.1 the project-document templates carried generic rule
        # text beside the project's facts, so every install copied it. The
        # rules now ship in the plan skill, verify-before-done, and the agents.
        # A leftover is recognized by the template's wording; an install may
        # have rewrapped the lines, so every space matches any whitespace.
        $genericRules = @(
            @('docs/agent_memory/validation-commands.md', 'Retry rule: performance and benchmark gates are `noisy-retry`', 'the noisy-retry rule, now in the plugin skill agrippa:verify-before-done ("Retries")'),
            @('docs/agent_memory/validation-commands.md', 'Existing-failure rule: prove a failure is pre-existing', 'the pre-existing-failure rule, now in the plugin skill agrippa:verify-before-done; keep the red-target list as a "Known red targets at `HEAD`" bullet'),
            @('docs/agent_memory/validation-commands.md', 'Every plan-matrix row records a Sandbox value', 'the Sandbox value definitions, now under "Validation matrix values" in the plan skill''s agent-workflow.md'),
            @('docs/agent_memory/validation-commands.md', 'Allowed plan-matrix determinism values are', 'the allowed Determinism values, now under "Validation matrix values" in the plan skill''s agent-workflow.md'),
            @('docs/agent_memory/validation-commands.md', 'Do not use a single representative test as the complete suite', 'the "Full-suite inventory" opening paragraph, now under "Validation matrix values" in the plan skill''s agent-workflow.md'),
            @('docs/agent_memory/validation-commands.md', 'Commands are copied verbatim into a plan''s validation matrix', 'the "Plan-matrix contract" section, now under "Validation matrix values" in the plan skill''s agent-workflow.md'),
            @('docs/agent_memory/project-contracts.md', 'Treat these as separate writer boundaries unless a plan explicitly combines', 'the "Ownership areas" opening paragraph, which restates the core rules'),
            @('docs/agent_memory/project-contracts.md', 'List the owners here so placement is a lookup', 'the "Architecture owners" opening paragraph, which the template now carries only as an install note'),
            @('docs/agent_memory/project-contracts.md', 'Plans and reviewers cite them by path', 'the "Contract documents" rule sentence, which the agents already follow'),
            @('docs/agent_memory/project-contracts.md', 'records an `rg` consumer census with file:line snippets', 'the "Shared and public interfaces" opening paragraph, now in the core rules, the design-first skill, and the plan skill''s agent-workflow.md'),
            @('docs/agent_memory/project-contracts.md', 'a risk flag keeps a stage off Haiku', 'the risk-flag rule, now in the plan skill''s ROUTING.md'),
            @('docs/agent_memory/project-contracts.md', 'distinguish existing failures or environment limits from regressions', 'the last two "Environment boundaries" bullets, which the plugin skill agrippa:verify-before-done already states'),
            @('docs/agent_memory/live-app.md', 'They may call only the tools listed under', 'the opening paragraph about which tools the agents may call, which every plugin agent already states'),
            @('docs/agent_memory/live-app.md', 'Which agents run the app:', 'the "Which agents run the app" paragraph, which the plugin agents already state'),
            @('docs/agent_memory/live-app.md', 'Cite a bridge-sourced fact as', 'the citation sentences under "Serialized files", which the plugin agent agrippa:repo-scout already states'),
            @('docs/agent_memory/live-app.md', '(?m)^## Rules\s*$', 'the "Rules" section, now in the plugin agents and the plugin skill agrippa:verify-before-done ("Live-app bridge")'),
            @('AGENTS.md', 'adds its core rules to every session: request boundaries, Engineering', 'the opening paragraph''s list of core-rule sections, which goes stale; the template now has one sentence'),
            @('AGENTS.md', 'never report a visual or GPU-dependent check as done when the bridge was down', 'the live-app paragraph''s bridge rules, now in the plugin agents and agrippa:verify-before-done; keep one or two sentences pointing to live-app.md')
        )
        foreach ($rule in $genericRules) {
            $rulePath = Join-Path $projectRoot $rule[0]
            if (Test-Path -LiteralPath $rulePath -PathType Leaf) {
                $ruleText = [IO.File]::ReadAllText($rulePath, [Text.Encoding]::UTF8)
                $pattern = $rule[1]
                if (-not $pattern.StartsWith('(?m)')) {
                    $pattern = ([regex]::Escape($pattern) -replace '\\ ', '\s+')
                }
                Add-ProjectCheck ($ruleText -notmatch $pattern) "$($rule[0]) still holds $($rule[2]). Delete the copy, keeping the heading and the project's facts, as ""From G4 v0.1.1"" in UPGRADING.md says."
            }
        }

        $planningNote = Join-Path $projectRoot 'docs/planning/CLAUDE.md'
        if (Test-Path -LiteralPath $planningNote -PathType Leaf) {
            $planningText = [IO.File]::ReadAllText($planningNote, [Text.Encoding]::UTF8)
            Add-ProjectCheck ($planningText -notmatch '^\s*# docs/planning/') 'docs/planning/CLAUDE.md is the kit''s old note about the planning guides and templates, which now ship in the plugin skill agrippa:plan. Delete it, as "From G4 v0.1.0" in UPGRADING.md says.'
        }

        # The spawn logger's payload helper may also serve the project's own
        # edit-lint hook. It is left over only when no other script in either
        # hook folder and no settings.json hook command names it.
        $hookFolders = @('tools', '.claude/hooks')
        $helperUsers = @()
        foreach ($folder in $hookFolders) {
            $folderPath = Join-Path $projectRoot $folder
            if (Test-Path -LiteralPath $folderPath -PathType Container) {
                $helperUsers += @(Get-ChildItem -LiteralPath $folderPath -Filter '*.ps1' -File |
                    Where-Object { $_.Name -ne 'hook_payload.ps1' -and $_.Name -ne 'log_subagent_spawns.ps1' } |
                    Where-Object { [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8).Contains('hook_payload.ps1') } |
                    ForEach-Object { "$folder/$($_.Name)" })
            }
        }
        if ($null -ne $settings -and $null -ne $settings.hooks) {
            foreach ($hookEvent in $settings.hooks.PSObject.Properties) {
                $helperUsers += @(@($hookEvent.Value) | ForEach-Object { @($_.hooks) } | ForEach-Object { [string]$_.command } | Where-Object { $_ -match 'hook_payload\.ps1' })
            }
        }
        foreach ($folder in $hookFolders) {
            $loggerPath = "$folder/log_subagent_spawns.ps1"
            Add-ProjectCheck (-not (Test-Path -LiteralPath (Join-Path $projectRoot $loggerPath))) "$loggerPath is a local copy of the spawn logger. Delete it; the plugin runs its own when the env block of .claude/settings.json sets AGRIPPA_SPAWN_LOG=1."
            $helperPath = "$folder/hook_payload.ps1"
            if (Test-Path -LiteralPath (Join-Path $projectRoot $helperPath) -PathType Leaf) {
                Add-ProjectCheck ($helperUsers.Count -gt 0) "$helperPath is a local copy of the old spawn logger's payload helper, and no project script or settings.json hook uses it. Delete it; the plugin's spawn logger does not need it."
            }
        }
    }
}

foreach ($warning in $warnings) {
    Write-Warning $warning
}
foreach ($message in $errors) {
    Write-Output "ERROR: $message"
}
foreach ($message in $projectErrors) {
    Write-Output "INSTALLED REPO: $message"
}
$projectSummary = ''
if ($InstalledRepo) {
    $projectSummary = ", $($projectErrors.Count) error(s) in $InstalledRepo from $projectChecks checks"
}
if ($errors.Count -gt 0 -or $projectErrors.Count -gt 0) {
    Write-Output "FAIL: $($errors.Count) kit error(s) from $checks checks$projectSummary, $($warnings.Count) warning(s)."
    exit 1
}

if ($InstalledRepo) {
    $projectSummary = ", $InstalledRepo passed $projectChecks checks"
}
Write-Output "PASS: $checks kit checks, $requiredCount required files, smoke test passed$projectSummary, $($warnings.Count) warning(s)."
