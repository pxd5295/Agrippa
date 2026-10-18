<#
.SYNOPSIS
Prints the Agrippa core rules as hook context.

.DESCRIPTION
Runs as the plugin's SessionStart and SubagentStart hook. Reads core-rules.md
from this script's folder and writes one JSON object to stdout whose
hookSpecificOutput.additionalContext is that file's text. Claude Code adds the
text to the session at startup, resume, clear, and after compaction, and to
each subagent before its first prompt. Subagents do not receive SessionStart
context, so they need the second hook.

Claude Code caps each context string at 10,000 characters and shows only a
preview above that, so dev/validate-kit.ps1 keeps core-rules.md under it. If
the file is missing, the script writes a short notice instead, so the session
learns the rules did not load. Windows PowerShell 5.1-clean.

.PARAMETER HookEvent
The hook event this run answers: SessionStart or SubagentStart.
#>
[CmdletBinding()]
param(
    [ValidateSet('SessionStart', 'SubagentStart')]
    [string]$HookEvent = 'SessionStart'
)

$ErrorActionPreference = 'Stop'
$rulesPath = Join-Path $PSScriptRoot 'core-rules.md'
if (Test-Path -LiteralPath $rulesPath -PathType Leaf) {
    $context = [IO.File]::ReadAllText($rulesPath, [Text.Encoding]::UTF8)
} else {
    $context = "The agrippa plugin could not load its core rules: $rulesPath is missing. Tell the user before planning or editing."
}

$payload = @{
    hookSpecificOutput = @{
        hookEventName     = $HookEvent
        additionalContext = $context
    }
}
$json = ConvertTo-Json -InputObject $payload -Compress -Depth 3

# Write UTF-8 bytes directly. Windows PowerShell 5.1 otherwise encodes piped
# stdout in the console code page.
$bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($json)
$stdout = [Console]::OpenStandardOutput()
$stdout.Write($bytes, 0, $bytes.Length)
$stdout.Flush()
exit 0
