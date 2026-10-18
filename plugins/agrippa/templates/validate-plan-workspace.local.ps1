<#
.SYNOPSIS
Project-specific checks for the agrippa plugin's plan-workspace linter.
Optional.

.DESCRIPTION
Install as `tools/validate_plan_workspace.local.ps1` only when this repository
has command invariants worth enforcing in every plan's validation matrix; with
no such invariant, do not install it. The linter, which runs from the plugin
as `agrippa-lint`, loads this file from `<repository root>/tools/` and
dot-sources it, so Add-Check, $repoRoot, $planRoot, and
$CommandPathExtensions are in scope. A plugin upgrade replaces the linter and
never this file.

Typical invariants: one required launcher or wrapper binary instead of a bare
name on PATH, an invocation shape per test kind, a required working directory
for one runner, a required Sandbox value, and a prerequisite command that must
come before the first test. Label failures "[Check 14]" to "[Check 17]" so
they sort with the linter's own checks.

The function bodies below are the worked example from the Godot repository the
kit was extracted from. Replace them with this repository's rules; keep the
two function names and parameters.
#>

# Optional: narrow or extend the command-path extensions check 13 verifies.
# $CommandPathExtensions = @('gd', 'tscn', 'py', 'ps1', 'toml', 'md')

function Test-LocalValidationRow {
    param([object]$Row, [string]$Command, [string]$Sandbox)
    $id = $Row.'Validation ID'

    # Every engine row uses one exact console binary and runs outside the
    # sandbox, because the engine writes caches outside the workspace.
    $isEngine = $Command -match '(?i)Godot_[^\s`]*_console\.exe|--headless\s+[^`]*res://[^\s`]+\.(?:gd|tscn)'
    if ($isEngine) {
        Add-Check ($Command -match [regex]::Escape('[PROJECT: exact console binary path]')) "[Check 14] $id must use the real console binary."
        Add-Check ($Command -notmatch '(?i)(?:^|[;&]\s*|`)\s*godot\s') "[Check 14] $id uses a bare launcher name."
        Add-Check ($Sandbox -eq 'outside-sandbox') "[Check 14] $id must declare outside-sandbox."
    }

    # A script target takes -s and no frame cap; a scene target takes a
    # numeric frame cap.
    if ($Command -match '(?i)res://[^\s`]+\.gd') {
        Add-Check ($Command -match '(?:^|\s)-s(?:\s|$)') "[Check 15] $id targets a script without -s."
        Add-Check ($Command -notmatch '--quit-after') "[Check 15] $id script invocation must not use --quit-after."
    }
    if ($Command -match '(?i)res://[^\s`]+\.tscn') {
        Add-Check ($Command -match '--quit-after\s+\d+') "[Check 15] $id scene invocation requires a numeric --quit-after."
    }
}

function Test-LocalValidationMatrix {
    param([object[]]$Rows)

    # The class-cache prelude must be the first engine row.
    $engineRows = @($Rows | Where-Object {
        [string]$_.'Exact command or check' -match '(?i)Godot_[^\s`]*_console\.exe'
    })
    if ($engineRows.Count -gt 0) {
        $first = [string]$engineRows[0].'Exact command or check'
        Add-Check ($first -match '--headless\s+--editor\s+--path\s+\.\s+--quit-after\s+\d+') '[Check 16] The class-cache prelude must precede the first engine test.'
    }
}
