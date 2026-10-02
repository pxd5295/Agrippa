<#
.SYNOPSIS
Proves the installed plan-workspace linter accepts a valid workspace and
rejects a broken one, then removes what it created.

.DESCRIPTION
Copies `smoke-workspace/` into `<RepoRoot>/plans/<today>-kit-smoke-test`
(adding -2, -3, ... on a name collision), replaces the `__TODAY__` and
`__PLAN__` tokens, and runs `<RepoRoot>/tools/validate_plan_workspace.ps1`
against it. The run must PASS. It then marks stage M1 `Open` and deletes the
M1 packet's `Return only` line, and the same linter must FAIL with both
errors. The workspace is deleted afterwards either way; a `plans/` folder the
script had to create is deleted too while it is still empty.

It runs the shared linter with -SkipLocalChecks, because the generic fixture
cannot satisfy a project's own invariants in
`tools/validate_plan_workspace.local.ps1`; prove those by linting one real
plan workspace instead.

The fixture references only files the kit installs: `AGENTS.md`,
`docs/agent-workflow.md` (its first line is the consumer-census snippet), and
`tools/validate_plan_workspace.ps1`. If an adapted `docs/agent-workflow.md`
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
$linter = Join-Path $root 'tools/validate_plan_workspace.ps1'
$failures = New-Object 'System.Collections.Generic.List[string]'

if (-not (Test-Path -LiteralPath $linter -PathType Leaf)) {
    Write-Output "FAIL: linter not installed at tools/validate_plan_workspace.ps1."
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
    # Run the linter under the same PowerShell that runs this script, so the
    # test also works with pwsh on macOS and Linux.
    $shell = (Get-Process -Id $PID).Path
    $output = & $shell -NoProfile -ExecutionPolicy Bypass -File $linter -PlanPath $planRelative -SkipLocalChecks 2>&1 | ForEach-Object { [string]$_ }
    return [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        # Error records wrap at console width; collapse whitespace so a message
        # split across lines still matches.
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
