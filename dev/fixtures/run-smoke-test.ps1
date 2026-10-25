<#
.SYNOPSIS
Proves the agrippa plugin's plan-workspace linter accepts a valid workspace in
a project and rejects a broken one, then removes what it created.

.DESCRIPTION
Copies `smoke-workspace/` into `<RepoRoot>/plans/<today>-kit-smoke-test`
(adding -2, -3, ... on a name collision), replaces the `__TODAY__` and
`__PLAN__` tokens, and runs the plugin's
`plugins/agrippa/scripts/validate_plan_workspace.mjs` from this Agrippa
checkout against it with `node`. The run must PASS. It then marks stage M1
`Open` and deletes the M1 packet's `Return only` line, and the same linter
must FAIL with both errors. The workspace is deleted afterwards either way; a
`plans/` folder the script had to create is deleted too while it is still
empty.

The linter runs from the project root without -RepoRoot, the way the
`agrippa-lint` wrapper runs it, so it finds the root through git. RepoRoot
must therefore be the top-level folder of a git repository. The project needs
no copy of the linter. `node` must be on PATH.

It runs the linter with -SkipLocalChecks, because the generic fixture cannot
satisfy a project's own invariants in
`tools/validate_plan_workspace.local.mjs`; prove those by linting one real
plan workspace instead.

The fixture references only the project's root `AGENTS.md`, whose first line
is the consumer-census snippet `# Agent Workflow`. If an adapted `AGENTS.md`
has a different first line, the pass run fails on check 25; fix the fixture's
census snippet, not the linter.

Exit 0 when both runs behave as expected, 1 otherwise. Read-only apart from
the temporary workspace. Windows PowerShell 5.1-clean.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $RepoRoot).Path
$fixture = Join-Path $PSScriptRoot 'smoke-workspace'
# This script lives in dev/fixtures/ of the Agrippa repository.
$linter = Join-Path $PSScriptRoot '../../plugins/agrippa/scripts/validate_plan_workspace.mjs'
$failures = New-Object 'System.Collections.Generic.List[string]'

if (-not (Test-Path -LiteralPath $linter -PathType Leaf)) {
    Write-Output "FAIL: the plugin linter is missing at $linter."
    exit 1
}
$nodeCommand = Get-Command -Name node -CommandType Application -ErrorAction SilentlyContinue
if ($null -eq $nodeCommand) {
    Write-Output 'FAIL: node is not on PATH, and the plugin linter runs on Node.'
    exit 1
}
$node = $nodeCommand.Source
if (-not (Test-Path -LiteralPath (Join-Path $root '.git'))) {
    Write-Output "FAIL: $root is not the top-level folder of a git repository, so the linter cannot find it without -RepoRoot."
    exit 1
}

$plansDir = Join-Path $root 'plans'
$createdPlansDir = $false
if (-not (Test-Path -LiteralPath $plansDir -PathType Container)) {
    New-Item -ItemType Directory -Path $plansDir | Out-Null
    $createdPlansDir = $true
}

$today = (Get-Date).ToString('yyyy-MM-dd')
$name = "$today-kit-smoke-test"
$suffix = 1
while (Test-Path -LiteralPath (Join-Path $plansDir $name)) {
    $suffix++
    $name = "$today-kit-smoke-test-$suffix"
}
$workspace = Join-Path $plansDir $name
$planRelative = "plans/$name"

function Invoke-Linter {
    # Windows PowerShell 5.1 turns a native command's redirected stderr into a
    # terminating error under 'Stop', and the linter reports through stderr.
    $ErrorActionPreference = 'Continue'
    # The caller has set the location to the project root, and no -RepoRoot is
    # passed, so the linter finds the root through git as the wrapper does.
    $output = & $node $linter -PlanPath $planRelative -SkipLocalChecks 2>&1 | ForEach-Object { [string]$_ }
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        # Collapse whitespace so a message is matched the same way however the
        # host presents stderr lines.
        Text = (($output -join ' ') -replace '\s+', ' ')
    }
}

function Set-FirstOccurrence {
    param([string]$Path, [string]$Old, [string]$New)
    $text = [IO.File]::ReadAllText($Path)
    $index = $text.IndexOf($Old)
    if ($index -lt 0) {
        return $false
    }
    $text = $text.Substring(0, $index) + $New + $text.Substring($index + $Old.Length)
    [IO.File]::WriteAllText($Path, $text, (New-Object System.Text.UTF8Encoding($false)))
    return $true
}

try {
    New-Item -ItemType Directory -Path $workspace | Out-Null
    foreach ($file in Get-ChildItem -LiteralPath $fixture -File) {
        $text = [IO.File]::ReadAllText($file.FullName)
        $text = $text.Replace('__TODAY__', $today).Replace('__PLAN__', $planRelative)
        [IO.File]::WriteAllText((Join-Path $workspace $file.Name), $text, (New-Object System.Text.UTF8Encoding($false)))
    }

    Push-Location $root
    try {
        $pass = Invoke-Linter
        if ($pass.ExitCode -ne 0 -or $pass.Text -notmatch 'PASS:') {
            $failures.Add("Valid fixture did not pass:`n$($pass.Text)")
        }

        $broken = (Set-FirstOccurrence (Join-Path $workspace 'PLAN.md') '| Design state | Frozen |' '| Design state | Open |') -and
            (Set-FirstOccurrence (Join-Path $workspace 'PACKETS.md') 'Return only:' 'Returns:')
        if (-not $broken) {
            throw 'The fixture no longer contains the text the broken run replaces.'
        }

        $fail = Invoke-Linter
        if ($fail.ExitCode -eq 0) {
            $failures.Add('Broken fixture passed; the linter accepted an Open stage and a packet without Return only.')
        }
        if ($fail.Text -notmatch '\[Check 5\] M1') {
            $failures.Add("Broken fixture did not report the Open stage (check 5):`n$($fail.Text)")
        }
        if ($fail.Text -notmatch "M1 packet is missing 'Return only'") {
            $failures.Add("Broken fixture did not report the missing packet label:`n$($fail.Text)")
        }
    } finally {
        Pop-Location
    }
} finally {
    if (Test-Path -LiteralPath $workspace) {
        Remove-Item -LiteralPath $workspace -Recurse -Force
    }
    # Remove a plans/ folder this script created, but only while it is empty,
    # so a plan another session wrote meanwhile survives.
    if ($createdPlansDir -and (Test-Path -LiteralPath $plansDir) -and
        @(Get-ChildItem -LiteralPath $plansDir -Force).Count -eq 0) {
        Remove-Item -LiteralPath $plansDir -Force
    }
}

if ($failures.Count -gt 0) {
    foreach ($message in $failures) {
        Write-Output $message
    }
    Write-Output "FAIL: smoke test, $($failures.Count) problem(s)."
    exit 1
}
Write-Output "PASS: valid fixture passed and broken fixture failed with the expected errors ($planRelative, removed)."
exit 0
