<#
.SYNOPSIS
    Record every subagent spawn to a log file. Observational only.

.DESCRIPTION
    Runs as one of the agrippa plugin's hooks, wired in `hooks/hooks.json`.
    It is opt-in: it does nothing unless the project sets
    `AGRIPPA_SPAWN_LOG=1`, normally in the `env` block of its
    `.claude/settings.json`. A plugin hook runs in every project that enables
    the plugin, and a project that has not ignored the log file would
    otherwise get an untracked file.

    It runs under two events and branches on
    `hook_event_name`, so the log path, line format, and append logic have one
    owner instead of being copied into a second script:

      PreToolUse    (matcher `Agent|Task`) -- one line per Agent tool call. Its
                    payload carries `tool_input`, so this is the only event that
                    can record whether the caller passed an explicit `model` or
                    left the subagent to inherit the lead's tier.

      SubagentStart (matcher `.*`) -- one line per spawn whatever route it took.
                    No hook event exposes a subagent's model, so this line
                    records the agent type only.

    Reading the two together is the point. A `SubagentStart` row with no
    matching `PreToolUse` row means the spawn did not go through the Agent tool,
    which is the expected shape for agents a dynamic workflow spawns. If a
    `/deep-research` run produces no rows at all, workflow agents do not fire
    hooks and no hook can ever govern their model.

    The count that decides everything else is `model=NONE` on a `PreToolUse`
    row: that spawn named no tier and inherited the lead's.

    It writes no decision to stdout and always exits 0, so it never blocks,
    allows, or rewrites a call -- a `PreToolUse` hook intervenes only on exit
    code 2 or an explicit permission decision, and this script emits neither by
    design. Every failure is swallowed for the same reason: a logger that breaks
    a spawn is worse than a logger that misses a line.

.PARAMETER Explain
    Report what the script decided, on stdout, for debugging the hook wiring.
    Never set it in the hook command itself.

.OUTPUTS
    Exit 0, always. The log is `subagent-spawns.log` at the project root,
    which Claude Code passes to hooks as `CLAUDE_PROJECT_DIR`; the payload's
    `cwd` is the fallback. A project that opts in adds `subagent-spawns.log`
    (or `*.log`) to its `.gitignore`.

.NOTES
    Windows PowerShell 5.1 clean: no && / || chains, no ternary, no
    null-coalescing. The payload shape is owned by the harness, not by this
    repository, so every hop into it is guarded.
#>
[CmdletBinding()]
param(
    [switch] $Explain
)

$ErrorActionPreference = 'Stop'
$LogPath = $null

function Write-Note {
    param([string] $Text)
    if ($Explain) { Write-Host "[log_subagent_spawns] $Text" }
}

# The opt-in comes first, so a project that has not opted in pays only for
# starting PowerShell.
if ($env:AGRIPPA_SPAWN_LOG -ne '1') {
    Write-Note 'AGRIPPA_SPAWN_LOG is not 1, so nothing is logged'
    exit 0
}

# Reading the hook payload off stdin is shared with the other hook scripts.
. (Join-Path $PSScriptRoot 'hook_payload.ps1')

function Format-Value {
    param($Value, [string] $WhenMissing)

    if ($null -eq $Value) { return $WhenMissing }
    $text = [string] $Value
    if ([string]::IsNullOrWhiteSpace($text)) { return $WhenMissing }

    # Keep one spawn on one line whatever the harness sends.
    return ($text -replace '\s+', '_')
}

function Add-LogLine {
    param([string] $Text)

    # Up to 16 workflow agents can start at once, so two hook processes can
    # reach the file together. Retry briefly rather than losing the line.
    for ($attempt = 0; $attempt -lt 8; $attempt++) {
        try {
            [System.IO.File]::AppendAllText($LogPath, $Text + [Environment]::NewLine)
            return $true
        }
        catch {
            Start-Sleep -Milliseconds 25
        }
    }
    return $false
}

try {
    $payload = Read-HookPayload
    if ($null -eq $payload) {
        Write-Note 'no usable payload on stdin; this script runs as a hook'
        exit 0
    }

    $projectRoot = $env:CLAUDE_PROJECT_DIR
    if ([string]::IsNullOrWhiteSpace($projectRoot)) {
        $projectRoot = [string] (Get-HookField $payload 'cwd')
    }
    if ([string]::IsNullOrWhiteSpace($projectRoot) -or -not (Test-Path -LiteralPath $projectRoot -PathType Container)) {
        Write-Note 'no project folder in CLAUDE_PROJECT_DIR or the payload cwd'
        exit 0
    }
    $LogPath = Join-Path $projectRoot 'subagent-spawns.log'

    $evt = Format-Value (Get-HookField $payload 'hook_event_name') 'unknown'
    $session = Format-Value (Get-HookField $payload 'session_id') '-'
    if ($session.Length -gt 8) { $session = $session.Substring(0, 8) }

    $stamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    $line = $null

    if ($evt -eq 'PreToolUse') {
        $toolInput = Get-HookField $payload 'tool_input'
        $agent = Format-Value (Get-HookField $toolInput 'subagent_type') 'unset'
        # NONE is the value this log exists to count.
        $model = Format-Value (Get-HookField $toolInput 'model') 'NONE'
        $line = '{0} {1} PreToolUse    agent={2} model={3}' -f $stamp, $session, $agent, $model
    }
    elseif ($evt -eq 'SubagentStart') {
        $agent = Format-Value (Get-HookField $payload 'agent_type') 'unset'
        $line = '{0} {1} SubagentStart agent={2} model=unavailable' -f $stamp, $session, $agent
    }
    else {
        Write-Note "ignoring event: $evt"
        exit 0
    }

    if (Add-LogLine $line) { Write-Note "wrote: $line" }
    else { Write-Note 'could not write the log line' }
}
catch {
    # Never let an observational hook disturb a spawn.
    Write-Note "swallowed: $($_.Exception.Message)"
}

exit 0
