// Prints the Agrippa core rules as hook context.
//
// Runs as the plugin's SessionStart and SubagentStart hook:
//
//     node scripts/inject_core_rules.mjs SessionStart
//     node scripts/inject_core_rules.mjs SubagentStart
//
// Reads core-rules.md from this script's folder and writes one JSON object to
// stdout whose hookSpecificOutput.additionalContext is that file's text.
// Claude Code adds the text to the session at startup, resume, clear, and
// after compaction, and to each subagent before its first prompt. Subagents do
// not receive SessionStart context, so they need the second hook.
//
// When the project sets AGRIPPA_LOW_USAGE=1, normally in the `env` block of
// its `.claude/settings.json`, one more line follows the rules: the two
// low-usage rules every session needs (the design-reviewer size floor and the
// reviewers' escalation) and a pointer to low-usage.md in the plan skill for
// the rest. Nothing is appended otherwise, so a project that has not opted in
// gets the rules unchanged.
//
// Claude Code caps each context string at 10,000 characters and shows only a
// preview above that, so dev/validate-kit.mjs keeps core-rules.md, with and
// without the low-usage line, under it. If the file is missing, the script
// writes a short notice instead, so the session learns the rules did not
// load. Uses only Node's built-in modules.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const hookEvents = ['SessionStart', 'SubagentStart'];
const hookEvent = process.argv[2] === undefined ? 'SessionStart' : process.argv[2];
if (!hookEvents.includes(hookEvent)) {
    process.stderr.write(`inject_core_rules: the hook event must be ${hookEvents.join(' or ')}, not '${hookEvent}'\n`);
    process.exit(1);
}

// The line a low-usage project gets after the rules. dev/validate-kit.mjs
// checks the hook's output against the same text.
export const lowUsageLine = 'Low-usage mode is on: the design-reviewer size floor is 80 lines, not 30; reviewers never self-escalate; before planning read low-usage.md in agrippa:plan.';

const rulesPath = join(dirname(fileURLToPath(import.meta.url)), 'core-rules.md');
let context;
try {
    // Drop a byte-order mark so the context starts with the rules' own text.
    context = readFileSync(rulesPath, 'utf8').replace(/^﻿/, '');
    if (process.env.AGRIPPA_LOW_USAGE === '1') {
        context = `${context.replace(/\s+$/, '')}\n\n${lowUsageLine}\n`;
    }
} catch {
    context = `The agrippa plugin could not load its core rules: ${rulesPath} is missing. Tell the user before planning or editing.`;
}

const payload = {
    hookSpecificOutput: {
        hookEventName: hookEvent,
        additionalContext: context,
    },
};

// Leave the process to end on its own. Calling process.exit() here could cut
// off a pipe write that has not finished.
process.stdout.write(JSON.stringify(payload));
