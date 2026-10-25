#!/bin/sh
# Records every subagent spawn to a log file. Observational only.
#
# Runs as one of the agrippa plugin's hooks, wired in `hooks/hooks.json`. It is
# opt-in: it does nothing unless the project sets `AGRIPPA_SPAWN_LOG=1`,
# normally in the `env` block of its `.claude/settings.json`. A plugin hook
# runs in every project that enables the plugin, and a project that has not
# ignored the log file would otherwise get an untracked file.
#
# It runs under two events and branches on `hook_event_name`, so the log
# path, line format, and append logic have one owner instead of being copied
# into a second script:
#
#   PreToolUse    (matcher `Agent|Task`) -- one line per Agent tool call. Its
#                 payload carries `tool_input`, so this is the only event that
#                 can record whether the caller passed an explicit `model` or
#                 left the subagent to inherit the lead's tier.
#
#   SubagentStart (matcher `.*`) -- one line per spawn whatever route it took.
#                 No hook event exposes a subagent's model, so this line
#                 records the agent type only.
#
# Reading the two together is the point. A `SubagentStart` row with no
# matching `PreToolUse` row means the spawn did not go through the Agent tool,
# which is the expected shape for agents a dynamic workflow spawns. If a
# `/deep-research` run produces no rows at all, workflow agents do not fire
# hooks and no hook can ever govern their model.
#
# The count that decides everything else is `model=NONE` on a `PreToolUse`
# row: that spawn named no tier and inherited the lead's.
#
# It writes no decision to stdout and always exits 0, so it never blocks,
# allows, or rewrites a call -- a `PreToolUse` hook intervenes only on exit
# code 2 or an explicit permission decision, and this script emits neither by
# design. Every failure is swallowed for the same reason: a logger that breaks
# a spawn is worse than a logger that misses a line.
#
# The log is `subagent-spawns.log` at the project root, which Claude Code
# passes to hooks as `CLAUDE_PROJECT_DIR`; the payload's `cwd` is the
# fallback. A project that opts in adds `subagent-spawns.log` (or `*.log`) to
# its `.gitignore`.
#
# Pass --explain to report what the script decided, on stdout, for debugging
# the hook wiring. Never set it in the hook command itself.
#
# POSIX sh, sed, and tr only, so it runs under Git Bash on Windows and under
# /bin/sh elsewhere. The payload is matched textually rather than parsed: a
# string field is read at object-key position (its key preceded by `{` or
# `,`), which an escaped quote inside another string cannot produce, and the
# first match wins. The two nested fields, `subagent_type` and `model`, are
# expected only inside `tool_input`; a value holding an escaped quote is cut
# at it, and one holding a `\u` escape is treated as missing. That is enough
# for agent names, model tiers, session ids, and paths. Log lines end in LF
# on every OS.

# Git for Windows puts sed and tr in /usr/bin, which its bin/sh.exe launcher
# (the shell Claude Code uses) adds to PATH but its bare usr/bin/sh.exe does
# not. Prepending it is harmless elsewhere, where /usr/bin is on PATH already.
PATH=/usr/bin:$PATH
export PATH

explain=0
for argument in "$@"; do
    [ "$argument" = --explain ] && explain=1
done

note() {
    if [ "$explain" = 1 ]; then
        printf '[log_subagent_spawns] %s\n' "$1"
    fi
    return 0
}

# The opt-in comes first, so a project that has not opted in pays only for
# starting sh.
if [ "${AGRIPPA_SPAWN_LOG:-}" != 1 ]; then
    note 'AGRIPPA_SPAWN_LOG is not 1, so nothing is logged'
    exit 0
fi

if [ -t 0 ]; then
    note 'no usable payload on stdin; this script runs as a hook'
    exit 0
fi
payload=$(cat 2>/dev/null) || payload=
# A writer can lead with a byte-order mark.
bom=$(printf '\357\273\277')
payload=${payload#"$bom"}
if [ -z "$(printf '%s' "$payload" | tr -d '[:space:]')" ]; then
    note 'no usable payload on stdin; this script runs as a hook'
    exit 0
fi

mark=$(printf '\001')

# Prints the first string value of the named key at object-key position, or
# nothing when the payload has no such key. Newlines are flattened first so
# a pretty-printed payload reads the same as a compact one.
json_field() {
    printf '%s' "$payload" | tr '\n\r' '  ' | LC_ALL=C sed -n \
        -e "s/[{,][[:space:]]*\"$1\"[[:space:]]*:[[:space:]]*\"/$mark/" \
        -e "/$mark/!d" \
        -e "s/^[^$mark]*$mark//" \
        -e 's/^\([^"]*\)".*$/\1/' \
        -e 'p'
}

# Undoes the JSON escapes a path or name can carry. A value with a \u escape
# is reported as empty, which the caller shows as missing.
json_unescape() {
    case $1 in
        *\\u*) printf '' ;;
        *) printf '%s' "$1" | LC_ALL=C sed -e 's/\\\\/\\/g' -e 's/\\\//\//g' -e 's/\\"/"/g' ;;
    esac
}

# Prints the field's value with whitespace runs turned into `_`, so one spawn
# stays on one line, or the second argument when the field is missing or
# blank.
format_field() {
    value=$(json_unescape "$(json_field "$1")" | tr -s '[:space:]' '_')
    value=${value#_}
    value=${value%_}
    if [ -z "$value" ]; then
        printf '%s' "$2"
    else
        printf '%s' "$value"
    fi
}

project_root=${CLAUDE_PROJECT_DIR:-}
if [ -z "$(printf '%s' "$project_root" | tr -d '[:space:]')" ]; then
    project_root=$(json_unescape "$(json_field cwd)")
fi
if [ -z "$project_root" ] || [ ! -d "$project_root" ]; then
    note 'no project folder in CLAUDE_PROJECT_DIR or the payload cwd'
    exit 0
fi
log_path=$project_root/subagent-spawns.log

hook_event=$(format_field hook_event_name unknown)
session=$(printf '%.8s' "$(format_field session_id -)")
stamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

case $hook_event in
    PreToolUse)
        agent=$(format_field subagent_type unset)
        # NONE is the value this log exists to count.
        model=$(format_field model NONE)
        line="$stamp $session PreToolUse    agent=$agent model=$model"
        ;;
    SubagentStart)
        agent=$(format_field agent_type unset)
        line="$stamp $session SubagentStart agent=$agent model=unavailable"
        ;;
    *)
        note "ignoring event: $hook_event"
        exit 0
        ;;
esac

# Up to 16 workflow agents can start at once, so two hook processes can reach
# the file together. Retry briefly rather than losing the line.
attempt=0
while [ "$attempt" -lt 8 ]; do
    if printf '%s\n' "$line" >> "$log_path" 2>/dev/null; then
        note "wrote: $line"
        exit 0
    fi
    attempt=$((attempt + 1))
    sleep 0.05 2>/dev/null || sleep 1
done
note 'could not write the log line'
exit 0
