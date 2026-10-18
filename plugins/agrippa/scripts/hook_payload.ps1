<#
.SYNOPSIS
    Shared helpers for reading a Claude Code hook payload from stdin.

.DESCRIPTION
    Dot-sourced by the plugin's hook scripts, and by a project's own hook
    scripts that keep a copy; it is not run on its own:

        . (Join-Path $PSScriptRoot 'hook_payload.ps1')

    It owns one thing: the boundary between the harness and this repository.
    The payload shape belongs to Claude Code, so both helpers treat anything
    unexpected -- no stdin, empty stdin, invalid JSON, a missing property -- as
    absent rather than throwing. A hook script that dies on an unfamiliar
    payload fails the action it was watching.

    What a missing payload *means* stays with the caller, because callers
    disagree: an edit-lint hook falls back to its -Path argument, while
    `log_subagent_spawns.ps1` exits 0 without logging.

.NOTES
    Windows PowerShell 5.1 clean: no && / || chains, no ternary, no
    null-coalescing.
#>

function Read-HookPayload {
    <#
    .SYNOPSIS
        Parse the JSON hook payload on stdin. Returns $null when there is none.
    #>

    if (-not [Console]::IsInputRedirected) { return $null }

    $raw = [Console]::In.ReadToEnd()
    if ([string]::IsNullOrWhiteSpace($raw)) { return $null }

    $payload = $null
    try { $payload = $raw | ConvertFrom-Json } catch { return $null }
    return $payload
}

function Get-HookField {
    <#
    .SYNOPSIS
        Read one property off a payload object. A missing property is $null,
        not an error, so callers can hop through the payload one level at a
        time without guarding each access themselves.
    #>
    param($Object, [string] $Name)

    if ($null -eq $Object) { return $null }
    if ($Object.PSObject.Properties.Name -notcontains $Name) { return $null }
    return $Object.$Name
}
