// Records every subagent spawn to a log file. Observational only.
//
// Runs as one of the agrippa plugin's hooks, wired in `hooks/hooks.json`. It is
// opt-in: it does nothing unless the project sets `AGRIPPA_SPAWN_LOG=1`,
// normally in the `env` block of its `.claude/settings.json`. A plugin hook
// runs in every project that enables the plugin, and a project that has not
// ignored the log file would otherwise get an untracked file.
//
// It runs under two events and branches on `hook_event_name`, so the log
// path, line format, and append logic have one owner instead of being copied
// into a second script:
//
//   PreToolUse    (matcher `Agent|Task`) -- one line per Agent tool call. Its
//                 payload carries `tool_input`, so this is the only event that
//                 can record whether the caller passed an explicit `model` or
//                 left the subagent to inherit the lead's tier.
//
//   SubagentStart (matcher `.*`) -- one line per spawn whatever route it took.
//                 No hook event exposes a subagent's model, so this line
//                 records the agent type only.
//
// Reading the two together is the point. A `SubagentStart` row with no
// matching `PreToolUse` row means the spawn did not go through the Agent tool,
// which is the expected shape for agents a dynamic workflow spawns. If a
// `/deep-research` run produces no rows at all, workflow agents do not fire
// hooks and no hook can ever govern their model.
//
// The count that decides everything else is `model=NONE` on a `PreToolUse`
// row: that spawn named no tier and inherited the lead's.
//
// It writes no decision to stdout and always exits 0, so it never blocks,
// allows, or rewrites a call -- a `PreToolUse` hook intervenes only on exit
// code 2 or an explicit permission decision, and this script emits neither by
// design. Every failure is swallowed for the same reason: a logger that breaks
// a spawn is worse than a logger that misses a line.
//
// The log is `subagent-spawns.log` at the project root, which Claude Code
// passes to hooks as `CLAUDE_PROJECT_DIR`; the payload's `cwd` is the
// fallback. A project that opts in adds `subagent-spawns.log` (or `*.log`) to
// its `.gitignore`.
//
// Pass --explain to report what the script decided, on stdout, for debugging
// the hook wiring. Never set it in the hook command itself.
//
// The payload shape is owned by the harness, not by this repository, so every
// hop into it is guarded. Uses only Node's built-in modules.

import { appendFileSync, readFileSync, statSync } from 'node:fs';
import { EOL } from 'node:os';
import { join } from 'node:path';

const explain = process.argv.includes('--explain');

function note(text) {
    if (explain) {
        console.log(`[log_subagent_spawns] ${text}`);
    }
}

// Parses the JSON hook payload on stdin. Anything unexpected -- no stdin,
// empty stdin, invalid JSON, a value that is not an object -- is treated as
// no payload rather than thrown, because a hook that dies on an unfamiliar
// payload fails the action it was watching.
function readHookPayload() {
    if (process.stdin.isTTY) {
        return null;
    }
    let raw;
    try {
        // A writer such as Windows PowerShell can lead with a byte-order
        // mark, which JSON.parse rejects.
        raw = readFileSync(0, 'utf8').replace(/^﻿/, '');
    } catch {
        return null;
    }
    if (raw.trim() === '') {
        return null;
    }
    try {
        const payload = JSON.parse(raw);
        return isObject(payload) ? payload : null;
    } catch {
        return null;
    }
}

function isObject(value) {
    return typeof value === 'object' && value !== null;
}

// Reads one property off a payload object. A missing property, or a parent
// that is not an object, is null, so callers can hop through the payload one
// level at a time without guarding each access themselves.
function field(object, name) {
    if (!isObject(object) || !Object.prototype.hasOwnProperty.call(object, name)) {
        return null;
    }
    return object[name];
}

function formatValue(value, whenMissing) {
    if (value === null || value === undefined) {
        return whenMissing;
    }
    const text = String(value);
    if (text.trim() === '') {
        return whenMissing;
    }
    // Keep one spawn on one line whatever the harness sends.
    return text.replace(/\s+/g, '_');
}

function isDirectory(path) {
    try {
        return statSync(path).isDirectory();
    } catch {
        return false;
    }
}

function appendLogLine(logPath, text) {
    // Up to 16 workflow agents can start at once, so two hook processes can
    // reach the file together. Retry briefly rather than losing the line.
    const pause = new Int32Array(new SharedArrayBuffer(4));
    for (let attempt = 0; attempt < 8; attempt++) {
        try {
            appendFileSync(logPath, text + EOL);
            return true;
        } catch {
            Atomics.wait(pause, 0, 0, 25);
        }
    }
    return false;
}

function run() {
    // The opt-in comes first, so a project that has not opted in pays only
    // for starting Node.
    if (process.env.AGRIPPA_SPAWN_LOG !== '1') {
        note('AGRIPPA_SPAWN_LOG is not 1, so nothing is logged');
        return;
    }

    const payload = readHookPayload();
    if (payload === null) {
        note('no usable payload on stdin; this script runs as a hook');
        return;
    }

    let projectRoot = process.env.CLAUDE_PROJECT_DIR;
    if (projectRoot === undefined || projectRoot.trim() === '') {
        projectRoot = String(field(payload, 'cwd') ?? '');
    }
    if (projectRoot.trim() === '' || !isDirectory(projectRoot)) {
        note('no project folder in CLAUDE_PROJECT_DIR or the payload cwd');
        return;
    }
    const logPath = join(projectRoot, 'subagent-spawns.log');

    const hookEvent = formatValue(field(payload, 'hook_event_name'), 'unknown');
    const session = formatValue(field(payload, 'session_id'), '-').slice(0, 8);
    const stamp = new Date().toISOString().replace(/\.\d{3}Z$/, 'Z');

    let line;
    if (hookEvent === 'PreToolUse') {
        const toolInput = field(payload, 'tool_input');
        const agent = formatValue(field(toolInput, 'subagent_type'), 'unset');
        // NONE is the value this log exists to count.
        const model = formatValue(field(toolInput, 'model'), 'NONE');
        line = `${stamp} ${session} PreToolUse    agent=${agent} model=${model}`;
    } else if (hookEvent === 'SubagentStart') {
        const agent = formatValue(field(payload, 'agent_type'), 'unset');
        line = `${stamp} ${session} SubagentStart agent=${agent} model=unavailable`;
    } else {
        note(`ignoring event: ${hookEvent}`);
        return;
    }

    if (appendLogLine(logPath, line)) {
        note(`wrote: ${line}`);
    } else {
        note('could not write the log line');
    }
}

try {
    run();
} catch (error) {
    // Never let an observational hook disturb a spawn.
    note(`swallowed: ${error instanceof Error ? error.message : String(error)}`);
}
process.exitCode = 0;
