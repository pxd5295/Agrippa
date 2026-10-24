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
// Claude Code caps each context string at 10,000 characters and shows only a
// preview above that, so dev/validate-kit.ps1 keeps core-rules.md under it. If
// the file is missing, the script writes a short notice instead, so the
// session learns the rules did not load. Uses only Node's built-in modules.

import { readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const hookEvents = ['SessionStart', 'SubagentStart'];
const hookEvent = process.argv[2] === undefined ? 'SessionStart' : process.argv[2];
if (!hookEvents.includes(hookEvent)) {
    process.stderr.write(`inject_core_rules: the hook event must be ${hookEvents.join(' or ')}, not '${hookEvent}'\n`);
    process.exit(1);
}

const rulesPath = join(dirname(fileURLToPath(import.meta.url)), 'core-rules.md');
let context;
try {
    // Drop a byte-order mark so the context starts with the rules' own text.
    context = readFileSync(rulesPath, 'utf8').replace(/^﻿/, '');
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
