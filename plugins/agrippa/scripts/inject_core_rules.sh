#!/bin/sh
# Prints the Agrippa core rules as hook context.
#
# Runs as the plugin's SessionStart and SubagentStart hook:
#
#     sh scripts/inject_core_rules.sh SessionStart
#     sh scripts/inject_core_rules.sh SubagentStart
#
# Reads core-rules.md from this script's folder and writes one JSON object to
# stdout whose hookSpecificOutput.additionalContext is that file's text.
# Claude Code adds the text to the session at startup, resume, clear, and
# after compaction, and to each subagent before its first prompt. Subagents do
# not receive SessionStart context, so they need the second hook.
#
# When the project sets AGRIPPA_LOW_USAGE=1, normally in the `env` block of
# its `.claude/settings.json`, one more line follows the rules: the two
# low-usage rules every session needs (the design-reviewer size floor and the
# reviewers' escalation) and a pointer to low-usage.md in the plan skill for
# the rest. Nothing is appended otherwise, so a project that has not opted in
# gets the rules unchanged.
#
# Claude Code caps each context string at 10,000 characters and shows only a
# preview above that, so dev/validate-kit.mjs keeps core-rules.md, with and
# without the low-usage line, under it. If the file is missing, the script
# writes a short notice instead, so the session learns the rules did not
# load.
#
# POSIX sh, sed, and awk only, so it runs under Git Bash on Windows (where
# Claude Code runs hook commands) and under /bin/sh on macOS and Linux. The
# JSON escaping covers backslash, double quote, tab, carriage return, and
# newline; core-rules.md holds no other control character, which the kit
# self-check enforces. Hooks run with the project folder as the working
# directory, so the rules file is located from $0, which hooks.json passes as
# an absolute path.

# Git for Windows puts sed and awk in /usr/bin, which its bin/sh.exe launcher
# (the shell Claude Code uses) adds to PATH but its bare usr/bin/sh.exe does
# not. Prepending it is harmless elsewhere, where /usr/bin is on PATH already.
PATH=/usr/bin:$PATH
export PATH

hook_event=${1:-SessionStart}
case $hook_event in
    SessionStart|SubagentStart) ;;
    *)
        printf '%s\n' "inject_core_rules: the hook event must be SessionStart or SubagentStart, not '$hook_event'" >&2
        exit 1
        ;;
esac

# The line a low-usage project gets after the rules. dev/validate-kit.mjs
# checks the hook's output against the same text.
low_usage_line='Low-usage mode is on: the design-reviewer size floor is 80 lines, not 30; reviewers never self-escalate; before planning read low-usage.md in agrippa:plan.'

rules_path=$(dirname "$0")/core-rules.md

tab=$(printf '\t')
cr=$(printf '\r')
bom=$(printf '\357\273\277')

# Escapes stdin for a JSON string one line at a time: a byte-order mark on the
# first line is dropped, then backslash, double quote, tab, and carriage
# return are escaped. Newlines are handled by json_join_lines.
json_escape_lines() {
    LC_ALL=C sed -e "1s/^$bom//" -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e "s/$tab/\\\\t/g" -e "s/$cr/\\\\r/g"
}

# Joins escaped lines with \n and no trailing newline. With an argument of 1,
# first drops trailing blank lines and trailing whitespace on the last line,
# which is what the low-usage mode needs before it appends its line.
json_join_lines() {
    LC_ALL=C awk -v low="$1" '
        { lines[NR] = $0 }
        END {
            n = NR
            if (low == "1") {
                while (n > 0 && lines[n] ~ /^[[:space:]]*$/) n--
                if (n > 0) sub(/[[:space:]]+$/, "", lines[n])
            }
            for (i = 1; i <= n; i++) {
                if (i > 1) printf "\\n"
                printf "%s", lines[i]
            }
        }'
}

# True when the file's last byte is a line feed, which the join above drops.
ends_with_newline() {
    [ "$(tail -c 1 "$1" | od -An -t x1 | tr -d ' \n')" = "0a" ]
}

if [ -f "$rules_path" ]; then
    if [ "${AGRIPPA_LOW_USAGE:-}" = 1 ]; then
        context=$(json_escape_lines < "$rules_path" | json_join_lines 1)
        appended=$(printf '%s' "$low_usage_line" | json_escape_lines)
        context="$context\\n\\n$appended\\n"
    else
        context=$(json_escape_lines < "$rules_path" | json_join_lines 0)
        if ends_with_newline "$rules_path"; then
            context="$context\\n"
        fi
    fi
else
    notice="The agrippa plugin could not load its core rules: $rules_path is missing. Tell the user before planning or editing."
    context=$(printf '%s' "$notice" | json_escape_lines)
fi

printf '%s' "{\"hookSpecificOutput\":{\"hookEventName\":\"$hook_event\",\"additionalContext\":\"$context\"}}"
