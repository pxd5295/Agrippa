// Validates the agrippa plugin's own files and the development files that test
// it.
//
// Checks the plugin layout: every kit file under plugins/agrippa/ and every
// development file under dev/ exists, the plugin root holds only the known
// folders and files, agents/ and skills/ hold exactly the plugin's agents and
// skills, and every template, script, hook, agent, skill, and bin file is listed
// in the kit README layout table. It checks that the marketplace lists the one
// plugin and that plugin.json and the marketplace entry carry the same version.
// It checks agent and skill frontmatter and namespacing: names match their
// files, carry no prefix of their own, are named with the agrippa: prefix in the
// core rules, and are never pointed to at a project copy path. The agents remove
// the editing tools with disallowedTools instead of listing an allowlist. No
// shipped file outside templates/ and the README contains a [PROJECT: ...] slot.
// The plans and decisions README templates stay short pointers, and their
// rules are in the plan and design-first skills' reference files.
// The core rules and templates still carry the methodology's required clauses,
// the core rules stay under the 10,000-character hook context cap, and the
// injection hook prints them when run with node. The spawn logger is wired and
// does nothing without AGRIPPA_SPAWN_LOG=1, and the agrippa-lint wrapper is an
// executable LF Node script that runs the plugin's linter. No vocabulary from
// an older toolchain survives outside UPGRADING.md and this script, text files
// are clean UTF-8 without trailing whitespace, every Node script parses, and
// the two copies of LICENSE and of NOTICE are identical. It then builds a
// simulated project in a temporary git repository with no copy of the linter
// and runs `dev/fixtures/run-smoke-test.mjs` against it, which proves the
// plugin's linter accepts the valid fixture and rejects the broken one.
//
// Like the workspace linter it ships, this checks shape and the presence of
// documented contracts, never semantic truth. Uses only Node's built-in
// modules.
//
// Usage: node dev/validate-kit.mjs [-InstalledRepo <path>]
//
// -InstalledRepo (or --installed-repo) names the root of a project that uses
// the plugin. Its committed .claude/settings.json must declare the agrippa
// marketplace and enable agrippa@agrippa, it must have
// docs/agent_memory/project-contracts.md and validation-commands.md, and it
// must keep no local copy of what the plugin provides: the agents, the plugin's
// skills, the shared linter, the spawn logger, its hook_payload.ps1 helper
// unless a project script still uses it, a settings.json hook or permission
// that runs them, or a PowerShell tools/validate_plan_workspace.local.ps1 that
// the 0.2.0 linter no longer loads. It must also keep no full copy of the rules
// that now ship in the plan and design-first skills: plans/README.md and
// docs/decisions/README.md are short pointers, and the old
// docs/planning/CLAUDE.md is gone. Each failure names the file or setting and
// says what to do. The check is skipped when this is omitted.
//
// Errors are printed one per stdout line, kit errors as `ERROR: ...` and
// installed-repository errors as `INSTALLED REPO: ...`, warnings to stderr as
// `WARNING: ...`, then one PASS or FAIL summary line. Exit 0 on PASS, 1 on
// FAIL, 2 on a usage error.

import { spawnSync } from 'node:child_process';
import { randomBytes } from 'node:crypto';
import {
    copyFileSync, existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync,
} from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, dirname, extname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

// --- Arguments --------------------------------------------------------------

function parseArguments(argv) {
    let installedRepo = '';
    for (let i = 0; i < argv.length; i++) {
        const argument = argv[i];
        const flag = /^--?([A-Za-z][\w-]*)(?:[=:](.*))?$/s.exec(argument);
        if (!flag) {
            return { error: `unexpected argument '${argument}'` };
        }
        const name = flag[1].toLowerCase();
        if (name !== 'installedrepo' && name !== 'installed-repo') {
            return { error: `unknown option '${argument}'` };
        }
        let value = flag[2];
        if (value === undefined) {
            i++;
            value = argv[i];
            if (value === undefined) {
                return { error: `${argument} needs a value` };
            }
        }
        installedRepo = value;
    }
    return { installedRepo };
}

const parsed = parseArguments(process.argv.slice(2));
if (parsed.error) {
    process.stderr.write(`validate-kit: ${parsed.error}\nusage: node dev/validate-kit.mjs [-InstalledRepo <path>]\n`);
    process.exit(2);
}
const installedRepo = parsed.installedRepo;

// --- Shared helpers ---------------------------------------------------------

// This script lives in dev/ at the Agrippa repository root.
const devRoot = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(devRoot, '..');
const kitRoot = resolve(repoRoot, 'plugins', 'agrippa');
const errors = [];
const warnings = [];
let checks = 0;

function addCheck(condition, message) {
    checks++;
    if (!condition) {
        errors.push(message);
    }
}

function isFile(path) {
    try {
        return statSync(path).isFile();
    } catch {
        return false;
    }
}

function isDirectory(path) {
    try {
        return statSync(path).isDirectory();
    } catch {
        return false;
    }
}

// Reads a text file as UTF-8 without a leading byte-order mark, the way the
// kit's files are stored.
function readText(path) {
    return readFileSync(path, 'utf8').replace(new RegExp('^' + String.fromCharCode(0xFEFF)), '');
}

function relativeTo(root, path) {
    return path.slice(root.length).replace(/^[\\/]+/, '').replace(/\\/g, '/');
}

// Every file under a folder, recursively, as absolute paths. Hidden entries
// are included: the kit's dot-folders are ordinary folders.
function listFiles(root) {
    const files = [];
    if (!isDirectory(root)) {
        return files;
    }
    const pending = [root];
    while (pending.length > 0) {
        const folder = pending.shift();
        const entries = readdirSync(folder, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name));
        for (const entry of entries) {
            const path = join(folder, entry.name);
            if (entry.isDirectory()) {
                pending.push(path);
            } else if (entry.isFile()) {
                files.push(path);
            }
        }
    }
    return files;
}

function listEntries(root) {
    if (!isDirectory(root)) {
        return [];
    }
    return readdirSync(root).sort((a, b) => a.localeCompare(b));
}

function escapeRegex(text) {
    return text.replace(/[.*+?^${}()|[\]\\/]/g, '\\$&');
}

// Case-insensitive membership, as PowerShell's -contains and -in compare.
function containsName(list, name) {
    const lowered = String(name).toLowerCase();
    return list.some((item) => item.toLowerCase() === lowered);
}

function asArray(value) {
    if (value === undefined || value === null) {
        return [];
    }
    return Array.isArray(value) ? value : [value];
}

function run(command, args, options = {}) {
    const result = spawnSync(command, args, { encoding: 'utf8', ...options });
    return {
        exitCode: result.status === null ? 1 : result.status,
        stdout: result.stdout || '',
        stderr: result.stderr || '',
        output: `${result.stdout || ''}${result.stderr || ''}`.trim(),
    };
}

function readRepoFile(root, relativePath) {
    const path = join(root, relativePath);
    const shown = relativeTo(repoRoot, path);
    const present = isFile(path);
    addCheck(present, `Missing file: ${shown}`);
    if (!present) {
        return '';
    }
    return readText(path);
}

function readKitFile(relativePath) {
    return readRepoFile(kitRoot, relativePath);
}

// Agents load from agents/ and skills from skills/ at the plugin root, under
// the agrippa: prefix. A project never keeps a copy of them. The four kit
// skills are the methodology's working skills; plan and handoff are entry
// points. install and upgrade set a project up; an older kit never copied
// them, so a project skill with one of those names is not a leftover copy.
const agentNames = ['repo-scout', 'plan-reviewer', 'design-reviewer', 'validator'];
const skillNames = ['design-first', 'systematic-debugging', 'verify-before-done', 'receiving-review'];
const pluginSkillNames = ['plan', 'handoff'];
const allSkillNames = [...skillNames, ...pluginSkillNames];
const setupSkillNames = ['install', 'upgrade'];
const shippedSkillNames = [...allSkillNames, ...setupSkillNames];
const planningNames = ['SPEC', 'PLAN', 'PACKETS', 'STATUS', 'EVIDENCE'];

const required = [
    '.claude-plugin/plugin.json',
    'README.md',
    'ADOPTION-CHECKLIST.md',
    'UPGRADING.md',
    'LICENSE',
    'NOTICE',
    'bin/agrippa-lint',
    'scripts/core-rules.md',
    'scripts/inject_core_rules.mjs',
    'scripts/validate_plan_workspace.mjs',
    'scripts/log_subagent_spawns.mjs',
    'hooks/hooks.json',
    'skills/plan/reference/agent-workflow.md',
    'skills/plan/reference/ROUTING.md',
    'skills/plan/reference/workspace-files.md',
    'skills/design-first/reference/decision-records.md',
    'templates/AGENTS.md',
    'templates/CLAUDE.md',
    'templates/directory-CLAUDE.md',
    'templates/PROJECT-CONTRACTS.md',
    'templates/VALIDATION-COMMANDS.md',
    'templates/LIVE-APP.md',
    'templates/agent-memory-CLAUDE.md',
    'templates/decisions-README.md',
    'templates/plans-README.md',
    'templates/MIGRATION.md',
    'templates/validate-plan-workspace.local.mjs',
    'templates/hooks/README.md',
    ...agentNames.map((name) => `agents/${name}.md`),
    ...shippedSkillNames.map((name) => `skills/${name}/SKILL.md`),
    ...planningNames.map((name) => `skills/plan/templates/${name}.md`),
];

// Development files are not shipped with the plugin.
const devRequired = [
    'validate-kit.mjs',
    'fixtures/run-smoke-test.mjs',
    ...planningNames.map((name) => `fixtures/smoke-workspace/${name}.md`),
];

for (const path of required) {
    readKitFile(path);
}
for (const path of devRequired) {
    readRepoFile(devRoot, path);
}
const rootRequired = ['.claude-plugin/marketplace.json', 'README.md', 'LICENSE', 'NOTICE'];
for (const path of rootRequired) {
    readRepoFile(repoRoot, path);
}
const requiredCount = required.length + devRequired.length + rootRequired.length;

// --- Plugin layout ----------------------------------------------------------

// The plugin root holds only these entries. A new top-level file or folder must
// be added here and to the README layout table, so nothing ships unnoticed.
const pluginEntries = ['.claude-plugin', 'agents', 'skills', 'hooks', 'bin', 'scripts', 'templates', 'README.md', 'ADOPTION-CHECKLIST.md', 'UPGRADING.md', 'LICENSE', 'NOTICE'];
for (const entry of listEntries(kitRoot)) {
    addCheck(containsName(pluginEntries, entry), `Unexpected entry at the plugin root: plugins/agrippa/${entry}. Move it into a known folder, or add it to the plugin layout in dev/validate-kit.mjs and the README layout table.`);
}
for (const file of listEntries(join(kitRoot, 'agents'))) {
    const stem = file.replace(/\.[^.]*$/, '');
    addCheck(containsName(agentNames, stem) && file.endsWith('.md'), `Unexpected file in plugins/agrippa/agents/: ${file}. Only the agents ${agentNames.join(', ')} ship there.`);
}
for (const folder of listEntries(join(kitRoot, 'skills'))) {
    addCheck(containsName(shippedSkillNames, folder), `Unexpected entry in plugins/agrippa/skills/: ${folder}. Only the skills ${shippedSkillNames.join(', ')} ship there.`);
}
// The agents and kit skills used to be templates copied into each project.
for (const oldFolder of ['templates/agents', 'templates/skills', 'commands']) {
    addCheck(!existsSync(join(kitRoot, oldFolder)), `plugins/agrippa/${oldFolder} must not exist: agents ship in agents/ and skills in skills/.`);
}

// The marketplace lists the one plugin, and both manifests carry the same
// version, so a release tag names exactly one plugin version.
function readJson(text, label) {
    try {
        return JSON.parse(text);
    } catch (error) {
        addCheck(false, `${label} is not valid JSON: ${error.message}`);
        return null;
    }
}
const pluginManifest = readJson(readKitFile('.claude-plugin/plugin.json'), 'plugins/agrippa/.claude-plugin/plugin.json');
const marketplace = readJson(readRepoFile(repoRoot, '.claude-plugin/marketplace.json'), '.claude-plugin/marketplace.json');
if (pluginManifest !== null && marketplace !== null) {
    addCheck(pluginManifest.name === 'agrippa', `plugin.json name must be 'agrippa', found '${pluginManifest.name}'.`);
    addCheck(marketplace.name === 'agrippa', `marketplace.json name must be 'agrippa', found '${marketplace.name}'.`);
    const entries = asArray(marketplace.plugins);
    addCheck(entries.length === 1, `marketplace.json must list exactly one plugin, found ${entries.length}.`);
    const entry = entries.find((item) => item && item.name === 'agrippa');
    addCheck(entry !== undefined, "marketplace.json does not list the plugin 'agrippa'.");
    if (entry !== undefined) {
        addCheck(entry.source === './plugins/agrippa', `marketplace.json entry 'agrippa' must have source './plugins/agrippa', found '${entry.source}'.`);
        addCheck(/^\d+\.\d+\.\d+$/i.test(String(pluginManifest.version ?? '')), `plugin.json version must be a semantic version such as 1.0.0, found '${pluginManifest.version}'.`);
        addCheck(String(entry.version ?? '') === String(pluginManifest.version ?? ''), `marketplace.json entry 'agrippa' has version '${entry.version}' but plugin.json has '${pluginManifest.version}'. Set both to the release version.`);
    }
}

// Each copy of the license and notice must match its root original, so the
// plugin folder carries the same terms wherever it is installed.
for (const name of ['LICENSE', 'NOTICE']) {
    const rootCopy = join(repoRoot, name);
    const pluginCopy = join(kitRoot, name);
    if (isFile(rootCopy) && isFile(pluginCopy)) {
        const rootText = readText(rootCopy).replace(/\r\n/g, '\n');
        const pluginText = readText(pluginCopy).replace(/\r\n/g, '\n');
        addCheck(rootText === pluginText, `${name} and plugins/agrippa/${name} differ. Copy the root ${name} over the plugin's copy.`);
    }
}

const readme = readKitFile('README.md');
const adoption = readKitFile('ADOPTION-CHECKLIST.md');
const upgrading = readKitFile('UPGRADING.md');
const coreRules = readKitFile('scripts/core-rules.md');
const hooksJson = readKitFile('hooks/hooks.json');
const agents = readKitFile('templates/AGENTS.md');
const claude = readKitFile('templates/CLAUDE.md');
const workflow = readKitFile('skills/plan/reference/agent-workflow.md');
const routing = readKitFile('skills/plan/reference/ROUTING.md');
const plan = readKitFile('skills/plan/templates/PLAN.md');
const packets = readKitFile('skills/plan/templates/PACKETS.md');
const spec = readKitFile('skills/plan/templates/SPEC.md');
const workspaceFiles = readKitFile('skills/plan/reference/workspace-files.md');
const decisionRecords = readKitFile('skills/design-first/reference/decision-records.md');
const workspaceLinter = readKitFile('scripts/validate_plan_workspace.mjs');

// --- Every template, script, hook, agent, skill, and bin file is listed in the README layout table

for (const folder of ['templates', 'scripts', 'hooks', 'agents', 'skills', 'bin']) {
    for (const file of listFiles(join(kitRoot, folder))) {
        const relative = relativeTo(kitRoot, file);
        let listedAs = relative;
        if (/^agents\/[^/]*\.md$/i.test(relative)) {
            listedAs = 'agents/*.md';
        } else if (/^skills\/plan\/templates\/[^/]*\.md$/i.test(relative)) {
            listedAs = 'skills/plan/templates/*.md';
        } else if (/^skills\/[^/]+\/SKILL\.md$/i.test(relative) && containsName(skillNames, relative.split('/')[1])) {
            listedAs = 'skills/*/SKILL.md';
        }
        addCheck(readme.includes(listedAs), `README layout table does not list ${relative} (expected '${listedAs}').`);
    }
}

// --- Methodology contract: clauses that must still be present -------------

// Clause patterns are regular expressions matched case-insensitively, with
// the `(?m)` and `(?s)` prefixes selecting multi-line and dot-all matching.
function clauseRegex(pattern, extraFlags = '') {
    let flags = `i${extraFlags}`;
    let source = pattern;
    for (;;) {
        if (source.startsWith('(?m)')) {
            flags += 'm';
            source = source.slice(4);
        } else if (source.startsWith('(?s)')) {
            flags += 's';
            source = source.slice(4);
        } else if (source.startsWith('(?i)')) {
            source = source.slice(4);
        } else {
            break;
        }
    }
    return new RegExp(source, flags);
}

function matches(text, pattern) {
    return clauseRegex(pattern).test(text);
}

function testClauses(label, text, patterns) {
    for (const pattern of patterns) {
        addCheck(matches(text, pattern), `${label} is missing: ${pattern}`);
    }
}

testClauses('README', readme, [
    '/agrippa:install',
    '/agrippa:upgrade',
    'never application\\s+behavior changes',
    '\\[PROJECT: \\.\\.\\.\\]',
    'run-smoke-test\\.mjs',
    'Install-marker scan',
    'validate_plan_workspace\\.local\\.mjs',
    'UPGRADING\\.md',
    'AskUserQuestion',
]);
// The methodology's always-loaded rules live in the core rules the plugin
// injects. The AGENTS and CLAUDE templates hold project content only, so they
// must not carry a second copy of a core section.
testClauses('Core rules', coreRules, [
    '## Request boundaries',
    '## Engineering standards',
    '### Definition of done',
    'Size floor',
    'State the design before the first edit',
    'One owner per shared value',
    'Refactor or file it',
    'Architecture owners',
    'is an answer\\s+request',
    "Non-planning requests preserve the user's active model and reasoning effort",
    '## Planning trigger',
    'Skip the workspace\\s+entirely',
    'single-stage\\s+shape',
    'No stage may hand off as `Open`',
    '## Implementation launch',
    'engineering:architecture',
    '`agrippa:plan`',
    'ROUTING\\.md',
    'agrippa-lint -PlanPath',
    'through the Bash tool',
    '## Roster and skills',
    '## Planner read ladder',
    '## Validation reach',
    'checks shape,\\s+never truth',
]);
// The roster names each plugin agent and skill by its namespaced name, which is
// the name a spawn or skill load must use.
for (const name of [...agentNames, ...skillNames]) {
    addCheck(coreRules.includes(`\`agrippa:${name}\``), `Core rules do not name \`agrippa:${name}\` in the roster.`);
}
addCheck(coreRules.length < 10000, `Core rules exceed the 10,000-character hook context cap: ${coreRules.length}.`);
testClauses('AGENTS template', agents, [
    '## Project contracts',
    'docs/agent_memory/project-contracts\\.md',
    'docs/agent_memory/validation-commands\\.md',
]);
testClauses('CLAUDE template', claude, [
    '@AGENTS\\.md',
]);
for (const section of ['## Engineering standards', '### Definition of done', '## Planning trigger', '## Planner read ladder', '## Validation reach']) {
    addCheck(!agents.includes(section), `AGENTS template repeats the core rules section '${section}'.`);
    addCheck(!claude.includes(section), `CLAUDE template repeats the core rules section '${section}'.`);
}

// The hooks are Node scripts, so the same hook command works on every OS. This
// script already runs on Node, so the same executable runs the hooks, the
// linter, and the smoke test.
const node = process.execPath;
addCheck(isFile(node), 'node is not on PATH. The plugin hooks run on Node.js; install it to run the hook checks.');

// The hook must run the injection script on session and subagent start, and
// the script must print the core rules unchanged as hook context.
let hookConfig = null;
try {
    hookConfig = JSON.parse(hooksJson);
} catch {
    hookConfig = null;
}
addCheck(hookConfig !== null, 'hooks/hooks.json is not valid JSON.');
function hookGroups(event) {
    if (hookConfig === null || !hookConfig.hooks || hookConfig.hooks[event] === undefined || hookConfig.hooks[event] === null) {
        return [];
    }
    return asArray(hookConfig.hooks[event]);
}
function hookCommands(groups) {
    return groups
        .flatMap((group) => asArray(group && group.hooks))
        .map((hook) => (hook && hook.command !== undefined && hook.command !== null ? String(hook.command) : ''));
}
for (const hookEvent of ['SessionStart', 'SubagentStart']) {
    const commands = hookCommands(hookGroups(hookEvent));
    const eventSuffix = new RegExp(` ${hookEvent}$`, 'i');
    const wired = commands.filter((command) => /^node "\$\{CLAUDE_PLUGIN_ROOT\}\/scripts\/inject_core_rules\.mjs"/i.test(command) && eventSuffix.test(command));
    addCheck(wired.length === 1, `hooks/hooks.json must run node scripts/inject_core_rules.mjs ${hookEvent} once on ${hookEvent}.`);
    const hookRun = run(node, [join(kitRoot, 'scripts', 'inject_core_rules.mjs'), hookEvent]);
    let hookPayload = null;
    try {
        hookPayload = JSON.parse(hookRun.stdout);
    } catch {
        hookPayload = null;
    }
    let printed = '';
    if (hookPayload !== null && hookPayload.hookSpecificOutput
        && String(hookPayload.hookSpecificOutput.hookEventName).toLowerCase() === hookEvent.toLowerCase()) {
        printed = String(hookPayload.hookSpecificOutput.additionalContext ?? '');
    }
    addCheck(hookRun.exitCode === 0 && printed.replace(/\r\n/g, '\n') === coreRules.replace(/\r\n/g, '\n'), `inject_core_rules.mjs ${hookEvent} did not print core-rules.md as ${hookEvent} additionalContext:\n${hookRun.output}`);
}

// The spawn logger runs on PreToolUse for the Agent tool and on every
// SubagentStart, and stays silent unless the project sets AGRIPPA_SPAWN_LOG=1.
for (const [hookEvent, matcher] of [['PreToolUse', 'Agent|Task'], ['SubagentStart', '.*']]) {
    const groups = hookGroups(hookEvent).filter((group) => group && group.matcher !== undefined && group.matcher !== null && String(group.matcher).toLowerCase() === matcher.toLowerCase());
    const logCommands = hookCommands(groups).filter((command) => /^node "\$\{CLAUDE_PLUGIN_ROOT\}\/scripts\/log_subagent_spawns\.mjs"$/i.test(command));
    addCheck(logCommands.length === 1, `hooks/hooks.json must run node scripts/log_subagent_spawns.mjs once on ${hookEvent} with matcher '${matcher}'.`);
}
const logProject = join(tmpdir(), `kit-log-${randomBytes(4).toString('hex')}`);
try {
    mkdirSync(logProject);
    const logFile = join(logProject, 'subagent-spawns.log');
    const logPayload = '{"hook_event_name":"PreToolUse","session_id":"kitcheck","tool_input":{"subagent_type":"agrippa:validator","model":"sonnet"}}\n';
    const logScript = join(kitRoot, 'scripts', 'log_subagent_spawns.mjs');
    const logEnvironment = { ...process.env, CLAUDE_PROJECT_DIR: logProject };
    delete logEnvironment.AGRIPPA_SPAWN_LOG;
    const offRun = run(node, [logScript], { input: logPayload, env: logEnvironment });
    const offWrote = existsSync(logFile);
    const onRun = run(node, [logScript], { input: logPayload, env: { ...logEnvironment, AGRIPPA_SPAWN_LOG: '1' } });
    addCheck(offRun.exitCode === 0 && !offWrote && offRun.output === '', `log_subagent_spawns.mjs must exit 0 silently and write no log without AGRIPPA_SPAWN_LOG=1:\n${offRun.output}`);
    let logged = '';
    if (existsSync(logFile)) {
        logged = readFileSync(logFile, 'utf8');
    }
    addCheck(onRun.exitCode === 0 && onRun.output === '' && /PreToolUse\s+agent=agrippa:validator model=sonnet/i.test(logged), `log_subagent_spawns.mjs with AGRIPPA_SPAWN_LOG=1 did not log the spawn to CLAUDE_PROJECT_DIR/subagent-spawns.log:\n${onRun.output}${logged}`);
} finally {
    if (existsSync(logProject)) {
        rmSync(logProject, { recursive: true, force: true });
    }
}

// The wrapper runs from the Bash tool's PATH, so git must record it as
// executable and it must keep LF line endings for its shebang to work. It has
// no extension, so Node loads it as CommonJS; it must not use ES-module syntax.
const wrapperPath = join(kitRoot, 'bin', 'agrippa-lint');
if (isFile(wrapperPath)) {
    const wrapper = readText(wrapperPath);
    addCheck(wrapper.startsWith('#!/usr/bin/env node\n'), 'bin/agrippa-lint must start with #!/usr/bin/env node and use LF line endings.');
    addCheck(!wrapper.includes('\r'), 'bin/agrippa-lint must use LF line endings.');
    addCheck(wrapper.includes("'validate_plan_workspace.mjs'") && wrapper.includes('process.argv.slice(2)'), 'bin/agrippa-lint must run ../scripts/validate_plan_workspace.mjs and pass its arguments through.');
    addCheck(!/^\s*(import|export)\s/im.test(wrapper), 'bin/agrippa-lint is loaded as CommonJS and must not use import or export statements.');
    const wrapperIndex = run('git', ['-C', repoRoot, 'ls-files', '-s', '--', 'plugins/agrippa/bin/agrippa-lint']).stdout.split(/\r?\n/).filter((line) => line !== '');
    addCheck(wrapperIndex.length === 1 && /^100755 /.test(wrapperIndex[0]), 'bin/agrippa-lint must be committed as executable (git add --chmod=+x).');
}
testClauses('Workflow template', workflow, [
    'consumer census during\\s+planning',
    'Covering tests:',
    '`Frozen`.*\\r?\\n?.*`Bounded-choice`',
    'Plans that start from a design reference',
    'single-stage shape',
    'cost\\s+multiplier',
    'checks shape, never truth',
    'Prompt-scenario contract',
    'Planning on Claude Fable 5\\.1',
]);
testClauses('Routing template', routing, [
    '## Model-tier routing table',
    'Long-context need is first',
    '## Fork or fresh subagent',
    '## Roster',
    '## Dispatch-ready packets',
    'Covering tests:',
    'Three are permitted only when',
    'token-cost multiplier',
    'Use one focused independent review',
    'design-reviewer',
    'receiving-review',
]);
testClauses('PLAN template', plan, [
    '## Ownership matrix',
    '\\| Sandbox \\|',
    'Design state',
    'Contract IDs',
    'Assigned tier',
    'Routing inputs',
    'Pre-authorized ownership expansion',
    '#### Split attempt',
    'Cheap-tier share',
    'Cost multiplier',
    '### Stage Model Allocation',
]);
testClauses('PACKETS template', packets, [
    '## Frozen contracts',
    'Contract source:',
    'Enumerated edit sites:',
    'Consumer census:',
    'Pre-authorized ownership expansion:',
    'Covering tests:',
    '## Stage packets',
    'Line-anchored edit sites:',
    'Owner / assigned tier',
]);
testClauses('SPEC template', spec, [
    '## Design reference',
    '## Design rationale',
    'Decision record',
    '\\*\\*A1:\\*\\*',
]);
testClauses('UPGRADING', upgrading, [
    '## Recognize the generation',
    '\\| G4: plugin',
    '### From G1',
    '### From G2',
    '### From G3',
    '### From G4 v0\\.1\\.0',
    '### From G4 v0\\.1\\.1',
    'docs/planning/CLAUDE\\.md` \\| Delete',
    'tools/log_subagent_spawns\\.ps1` \\| Delete',
    'tools/hook_payload\\.ps1` \\| Delete',
    'tools/validate_plan_workspace\\.ps1` \\| Delete',
    'Never edit, move, rename, or bulk-convert',
]);
// The install and upgrade skills replace the setup prompts and keep their
// safeguards: read-only discovery, questions for material choices, every
// settings change shown before it is written, and, for upgrades, the dated-plan
// manifest, the mapping shown before any edit, and a confirmed deletion.
const installSkill = readKitFile('skills/install/SKILL.md');
const upgradeSkill = readKitFile('skills/upgrade/SKILL.md');
const setupClauses = [
    '(?m)^description:.*only when the user explicitly asks',
    'Never change application code',
    'AskUserQuestion',
    'read-only',
    'extraKnownMarketplaces\\.agrippa',
    '`ref`',
    'agrippa@agrippa',
    'complete\\s+proposed content',
    'write\\s+nothing until',
    'Never add a permission rule',
    'Install-marker scan',
    'dev/validate-kit\\.mjs -InstalledRepo',
    'run-smoke-test\\.mjs -RepoRoot',
    '\\$\\{CLAUDE_PLUGIN_ROOT\\}/templates/',
];
testClauses('Skill install', installSkill, [...setupClauses,
    'Never copy the plugin',
    '/agrippa:upgrade',
]);
testClauses('Skill upgrade', upgradeSkill, [...setupClauses,
    'SHA-256 manifest',
    'Get-FileHash -Algorithm SHA256',
    'mapping is shown to the user before any edit',
    'Every deletion is confirmed',
    'Never\\s+offer a single\\s+"delete all" choice',
    'never edited, moved, renamed, or converted',
    'From G3',
    '\\$\\{CLAUDE_PLUGIN_ROOT\\}/UPGRADING\\.md',
    'docs/planning/MIGRATION\\.md',
]);
addCheck(matches(workspaceFiles, '(?s)SPEC\\.md.*PLAN\\.md.*PACKETS\\.md.*STATUS\\.md.*EVIDENCE\\.md'), 'Plan skill workspace-files.md must name all five workspace artifacts.');
testClauses('Plan skill workspace-files.md', workspaceFiles, [
    '## Artifact contract',
    '## Selective reads and soft budgets',
    'handoff-YYYY-MM-DD',
    'agrippa-lint -PlanPath',
    'checks shape,\\s+never truth',
]);
testClauses('Design-first skill decision-records.md', decisionRecords, [
    'docs/decisions/',
    '## When a record is required',
    '## Shape',
    'engineering:architecture',
    'engineering:system-design',
    'never edited to change its decision',
]);
addCheck(matches(coreRules, 'use the shape in `agrippa:design-first`'), 'Core rules must point to agrippa:design-first for the decision-record shape.');
// The plans and decisions READMEs a project gets are pointers for people who
// browse it without the plugin. The rules they used to hold ship in the plan
// and design-first skills, so a pointer must stay short and hold no sections.
for (const pointer of ['templates/plans-README.md', 'templates/decisions-README.md']) {
    const pointerText = readKitFile(pointer);
    addCheck(pointerText.length < 600 && !/^## /im.test(pointerText), `plugins/agrippa/${pointer} must stay a short pointer with no sections; its rules belong in a plugin skill.`);
    addCheck(pointerText.includes('https://github.com/pxd5295/Agrippa'), `plugins/agrippa/${pointer} must link to the Agrippa repository.`);
}
addCheck(matches(adoption, 'run-smoke-test\\.mjs'), 'Adoption checklist must require the smoke test.');
addCheck(matches(workspaceLinter, 'checks shape, never truth'), 'Workspace linter lacks the shape-not-truth disclaimer.');
addCheck(matches(workspaceLinter, 'validate_plan_workspace\\.local\\.mjs'), 'Workspace linter does not load the local extension file.');
const localTemplate = readKitFile('templates/validate-plan-workspace.local.mjs');
addCheck(matches(localTemplate, 'export function checkValidationRow') && matches(workspaceLinter, 'checkValidationRow'), 'Local-check template and linter disagree on checkValidationRow.');
addCheck(matches(localTemplate, 'export function checkValidationMatrix') && matches(workspaceLinter, 'checkValidationMatrix'), 'Local-check template and linter disagree on checkValidationMatrix.');
addCheck(matches(localTemplate, 'commandPathExtensions') && matches(workspaceLinter, 'local\\.commandPathExtensions'), 'Local-check template and linter disagree on commandPathExtensions.');

// The linter owns the template vocabulary it parses. Read its required packet
// labels and stage fields from its own source, so a linter change is checked
// against the templates without a second hand-kept list here.
const labelBlock = /const requiredPacketLabels = \[(.+?)\];/s.exec(workspaceLinter);
addCheck(labelBlock !== null, 'Could not find the required packet-label array in the workspace linter.');
const packetLabels = labelBlock === null ? [] : [...labelBlock[1].matchAll(/'([^']+)'/g)].map((match) => match[1]);
addCheck(packetLabels.length > 0, 'The workspace linter requires no packet labels.');
for (const label of packetLabels) {
    addCheck(new RegExp(`^${escapeRegex(label)}\\s*:`, 'im').test(packets), `PACKETS template lacks the packet label '${label}' the linter requires.`);
}
const stageFields = [...new Set([...workspaceLinter.matchAll(/getField\(\w+, '([^']+)'\)/g)].map((match) => match[1]))];
addCheck(stageFields.length > 0, 'The workspace linter reads no stage fields.');
for (const field of stageFields) {
    // 'Bounded choice' is an optional field the linter falls back from.
    if (field.toLowerCase() === 'bounded choice') {
        continue;
    }
    addCheck(new RegExp(`^\\|\\s*${escapeRegex(field)}\\s*\\|`, 'im').test(plan), `PLAN template lacks the stage field '${field}' the linter reads.`);
}

// --- Agent and skill frontmatter ------------------------------------------

// The agents carry no tools allowlist, so a project's MCP tools reach them.
// Instead disallowedTools removes every editing tool, and each agent is told
// to read live-app.md for the bridge tools it must never call.
const editingTools = ['Write', 'Edit', 'NotebookEdit'];
for (const name of agentNames) {
    const text = readKitFile(`agents/${name}.md`);
    // Claude Code adds the agrippa: prefix itself, so the frontmatter name is
    // the bare file name.
    addCheck(new RegExp(`^name:\\s*${escapeRegex(name)}\\s*$`, 'im').test(text), `agents/${name}.md frontmatter name must be '${name}', matching its filename with no prefix.`);
    addCheck(/^description:\s*\S/im.test(text), `${name}.md is missing a frontmatter description.`);
    addCheck(!/^tools:/im.test(text), `${name}.md must not have a frontmatter tools allowlist; use disallowedTools.`);
    const disallowedLine = /^disallowedTools:\s*(.+?)\s*$/m.exec(text);
    addCheck(disallowedLine !== null, `${name}.md is missing a frontmatter disallowedTools list.`);
    const disallowed = disallowedLine === null ? [] : disallowedLine[1].split(',').map((tool) => tool.trim());
    for (const tool of editingTools) {
        addCheck(containsName(disallowed, tool), `${name}.md disallowedTools does not remove the editing tool ${tool}.`);
    }
    addCheck(/^model:\s*(haiku|sonnet|opus)\s*$/im.test(text), `${name}.md frontmatter model must be haiku, sonnet, or opus.`);
    addCheck(/docs\/agent_memory\/live-app\.md/i.test(text) && /"Authoring tools"/i.test(text), `${name}.md must point to the "Authoring tools" section of docs/agent_memory/live-app.md.`);
    addCheck(!/optional live-app block/i.test(text), `${name}.md still has an optional live-app block.`);
    addCheck(new RegExp(`\`${escapeRegex(name)}.md\``, 'i').test(routing), `ROUTING roster table does not list ${name}.md.`);
}

// The plugin is project-neutral. A project fact belongs in a project document
// that an agent or skill reads, never in a [PROJECT: ...] slot. Only the
// project-side templates, which an install fills in, and the README, which
// explains the convention, may carry one.
const kitFiles = listFiles(kitRoot);
for (const file of kitFiles) {
    const relative = relativeTo(kitRoot, file);
    if (/^templates\//i.test(relative) || relative.toLowerCase() === 'readme.md') {
        continue;
    }
    const content = readText(file);
    addCheck(!content.includes('[PROJECT:'), `plugins/agrippa/${relative} must be project-neutral: it contains a [PROJECT: ...] slot. Move the fact into a project document and read it from there.`);
}
// Every install-time blank in a project-side template is a [PROJECT: ...] slot,
// so the install-marker scan finds any that are left. A plain [...] is a
// per-plan placeholder and belongs only in the plan skill's templates. Slots
// may nest brackets, and Install note comments may quote code, so both are
// removed before the search.
for (const file of listFiles(join(kitRoot, 'templates')).filter((path) => /\.md$/i.test(path))) {
    const relative = relativeTo(kitRoot, file);
    const content = readText(file).replace(/<!--.*?-->/gs, '');
    let outside = '';
    let depth = 0;
    for (let i = 0; i < content.length; i++) {
        if (depth === 0 && content.startsWith('[PROJECT:', i)) {
            depth = 1;
            i += 8;
            continue;
        }
        if (depth > 0) {
            if (content[i] === '[') {
                depth++;
            } else if (content[i] === ']') {
                depth--;
            }
            continue;
        }
        outside += content[i];
    }
    const plain = /\[[^[\]\r\n]*\](?!\()/.exec(outside);
    addCheck(plain === null, `plugins/agrippa/${relative} has the plain placeholder ${plain === null ? '' : plain[0]} outside a [PROJECT: ...] slot. Make it a [PROJECT: ...] slot so the install-marker scan finds it when it is left unfilled.`);
}
for (const name of shippedSkillNames) {
    const text = readKitFile(`skills/${name}/SKILL.md`);
    addCheck(new RegExp(`^name:\\s*${escapeRegex(name)}\\s*$`, 'im').test(text), `skills/${name}/SKILL.md frontmatter name must be '${name}', matching its folder with no prefix.`);
    addCheck(/^description:\s*\S/im.test(text), `skills/${name}/SKILL.md is missing a frontmatter description.`);
    // A plugin skill with this flag is not offered at all in the desktop app,
    // not even as a slash command. A skill that must wait for the user says so
    // in its description instead.
    addCheck(!/^disable-model-invocation:/im.test(text), `skills/${name}/SKILL.md must not set disable-model-invocation: the desktop app then hides the plugin skill entirely. Say in the description that it runs only when the user explicitly asks.`);
}
addCheck(/^description:.*only when the user explicitly asks/im.test(readKitFile('skills/handoff/SKILL.md')), 'Skill handoff description must say it runs only when the user explicitly asks.');
// Plugin text points to its own agents and skills by their agrippa: names, never
// at the project copy paths an older kit installed. UPGRADING.md names those
// paths so an upgrade can delete them, and the README names them for the
// -InstalledRepo check.
const copyPathPattern = new RegExp(`\\.claude/(agents/(${agentNames.map(escapeRegex).join('|')})\\.md|skills/(${allSkillNames.map(escapeRegex).join('|')})/|commands/(${pluginSkillNames.map(escapeRegex).join('|')})\\.md)`);
for (const file of kitFiles) {
    const relative = relativeTo(kitRoot, file);
    if (relative.toLowerCase() === 'upgrading.md' || relative.toLowerCase() === 'readme.md') {
        continue;
    }
    const copyPath = copyPathPattern.exec(readText(file));
    addCheck(copyPath === null, `plugins/agrippa/${relative} points to the project copy path ${copyPath === null ? '' : copyPath[0]}; name the plugin agent or skill with its agrippa: prefix instead.`);
}
// The plan skill points to its reference files and templates through
// ${CLAUDE_SKILL_DIR}, which Claude Code substitutes, so they resolve wherever
// the plugin is installed.
const planSkill = readKitFile('skills/plan/SKILL.md');
for (const reference of ['reference/agent-workflow.md', 'reference/ROUTING.md', 'reference/workspace-files.md', 'templates/']) {
    addCheck(planSkill.includes(`\${CLAUDE_SKILL_DIR}/${reference}`), `Skill plan does not point to \${CLAUDE_SKILL_DIR}/${reference}.`);
}
const designFirstSkill = readKitFile('skills/design-first/SKILL.md');
addCheck(designFirstSkill.includes('${CLAUDE_SKILL_DIR}/reference/decision-records.md'), 'Skill design-first does not point to ${CLAUDE_SKILL_DIR}/reference/decision-records.md.');
addCheck(/agrippa-lint -PlanPath/i.test(planSkill) && /Bash tool/i.test(planSkill), 'Skill plan must lint with agrippa-lint through the Bash tool.');
addCheck(/agrippa-lint -PlanPath/i.test(plan) && /Bash tool/i.test(plan), 'PLAN template must name the agrippa-lint row and say it runs through the Bash tool.');
const validatorAgent = readKitFile('agents/validator.md');
addCheck(/agrippa-lint/i.test(validatorAgent) && /Bash\s+tool/i.test(validatorAgent), 'validator agent must say the agrippa-lint row runs through the Bash tool.');

// --- Older-toolchain vocabulary, encoding, and whitespace -----------------

const boundedTerms = ['Sol', 'Terra', 'Luna', 'Codex', 'composer'];
const boundedPattern = new RegExp(`\\b(${boundedTerms.map(escapeRegex).join('|')})\\b`, 'i');
const substringTerms = [
    'gpt-5',
    '.codex/',
    'default_mode_request_user_input',
    'Implement plan use workers',
    'terra_',
    'luna_',
    'sol_',
    'assigned profile',
    'workspace-write',
];
// UPGRADING.md must name the old markers to recognize them, and this script
// names them to search for them. Paths are relative to the repository root.
const vocabularyExempt = ['plugins/agrippa/UPGRADING.md', 'dev/validate-kit.mjs'];

// The shipped plugin, the development files, and the repository's root files.
// docs/ and history/ are records of why the kit changed, are not shipped, and
// may describe the older toolchains.
const checkedFiles = [...kitFiles, ...listFiles(devRoot)];
// A worktree's .git is a file that points to the main repository.
checkedFiles.push(...listEntries(repoRoot).filter((name) => name !== '.git').map((name) => join(repoRoot, name)).filter(isFile));
checkedFiles.push(...listEntries(join(repoRoot, '.claude-plugin')).map((name) => join(repoRoot, '.claude-plugin', name)).filter(isFile));
for (const file of checkedFiles) {
    const relative = relativeTo(repoRoot, file);
    const bytes = readFileSync(file);
    addCheck(!(bytes.length >= 3 && bytes[0] === 0xEF && bytes[1] === 0xBB && bytes[2] === 0xBF), `UTF-8 byte-order mark: ${relative}`);
    const text = readText(file);
    addCheck(!/[ \t]+\r?$/m.test(text), `Trailing whitespace: ${relative}`);
    addCheck(!text.includes(String.fromCharCode(0x00E2)), `Possible mojibake: ${relative}`);
    addCheck(!text.includes(String.fromCharCode(0xFFFD)), `Replacement character (bad encoding): ${relative}`);

    if (containsName(vocabularyExempt, relative)) {
        continue;
    }
    const bounded = boundedPattern.exec(text);
    if (bounded !== null) {
        addCheck(false, `Older-toolchain term '${bounded[1]}' found in ${relative}.`);
    } else {
        checks++;
    }
    for (const term of substringTerms) {
        addCheck(!new RegExp(escapeRegex(term), 'i').test(text), `Older-toolchain term '${term}' found in ${relative}.`);
    }
}

addCheck(kitFiles.filter((path) => /\.toml$/i.test(path)).length === 0, 'Kit must contain no .toml agent profiles.');
addCheck(!existsSync(join(kitRoot, 'templates', 'config.toml')), 'Kit must not install a toolchain config.toml.');

// --- Node scripts must parse -----------------------------------------------

for (const script of checkedFiles.filter((path) => extname(path).toLowerCase() === '.mjs' || basename(path) === 'agrippa-lint')) {
    const syntax = run(node, ['--check', script]);
    addCheck(syntax.exitCode === 0, `${basename(script)} has Node syntax errors:\n${syntax.output}`);
}

// --- End-to-end: simulated project plus the smoke test ---------------------

// The simulated project is a git repository with only its own AGENTS.md. It
// has no tools/ folder, so the smoke test proves the plugin's linter needs no
// copy in the project and finds the repository root through git.
const simRoot = join(tmpdir(), `kit-sim-${randomBytes(4).toString('hex')}`);
try {
    mkdirSync(simRoot);
    copyFileSync(join(kitRoot, 'templates', 'AGENTS.md'), join(simRoot, 'AGENTS.md'));
    const gitInit = run('git', ['init', '-q', simRoot]);
    addCheck(gitInit.exitCode === 0, `git init failed for the simulated project:\n${gitInit.output}`);
    addCheck(!existsSync(join(simRoot, 'tools')), 'The simulated project must have no tools/ folder.');
    const smoke = run(node, [join(devRoot, 'fixtures', 'run-smoke-test.mjs'), '-RepoRoot', simRoot]);
    addCheck(smoke.exitCode === 0, `Smoke test against a simulated project failed:\n${smoke.output}`);
} finally {
    if (existsSync(simRoot)) {
        rmSync(simRoot, { recursive: true, force: true });
    }
}

if (workflow.length > 9000) {
    warnings.push(`Workflow template exceeds the 9,000-character soft target: ${workflow.length}.`);
}
if (routing.length > 9000) {
    warnings.push(`ROUTING template exceeds the 9,000-character soft target: ${routing.length}.`);
}

// --- A project that uses the plugin ----------------------------------------

// A project declares the plugin in its committed settings, keeps its own facts
// in the project documents, and keeps no copy of anything the plugin provides,
// because a copy shadows the plugin's version or drifts from it. These errors
// are listed apart from the kit's, as the project's remaining migration steps.
const projectErrors = [];
let projectChecks = 0;

function addProjectCheck(condition, message) {
    projectChecks++;
    if (!condition) {
        projectErrors.push(message);
    }
}

// A pattern from the generic-rules table is a regular expression when it
// starts with `(?m)`; otherwise it is literal text whose every space matches
// any run of whitespace, because an install may have rewrapped the lines.
function ruleRegex(pattern) {
    if (pattern.startsWith('(?m)')) {
        return clauseRegex(pattern);
    }
    return new RegExp(escapeRegex(pattern).replace(/ /g, '\\s+'), 'i');
}

if (installedRepo) {
    if (!isDirectory(installedRepo)) {
        addProjectCheck(false, `-InstalledRepo is not a folder: ${installedRepo}`);
    } else {
        const projectRoot = resolve(installedRepo);
        const enableHelp = 'as the kit README section "Enabling the plugin in a project" shows';

        const settingsPath = join(projectRoot, '.claude', 'settings.json');
        let settings = null;
        if (!isFile(settingsPath)) {
            addProjectCheck(false, `.claude/settings.json is missing. Create it with the extraKnownMarketplaces and enabledPlugins entries ${enableHelp}, and commit it.`);
        } else {
            const tracked = run('git', ['-C', projectRoot, 'ls-files', '--', '.claude/settings.json']).stdout.split(/\r?\n/).filter((line) => line !== '');
            addProjectCheck(tracked.length === 1, '.claude/settings.json is not committed. Commit it so every collaborator gets the plugin; .claude/settings.local.json does not count.');
            try {
                settings = JSON.parse(readText(settingsPath));
            } catch (error) {
                addProjectCheck(false, `.claude/settings.json is not valid JSON: ${error.message}`);
            }
        }
        if (settings !== null) {
            let marketplaceEntry = null;
            if (settings.extraKnownMarketplaces !== undefined && settings.extraKnownMarketplaces !== null) {
                marketplaceEntry = settings.extraKnownMarketplaces.agrippa ?? null;
            }
            addProjectCheck(marketplaceEntry !== null && marketplaceEntry.source !== undefined && marketplaceEntry.source !== null, `.claude/settings.json does not declare the agrippa marketplace. Add extraKnownMarketplaces.agrippa with its source, pinned to a release tag with ref, ${enableHelp}.`);
            let enabled = null;
            if (settings.enabledPlugins !== undefined && settings.enabledPlugins !== null) {
                enabled = settings.enabledPlugins['agrippa@agrippa'] ?? null;
            }
            addProjectCheck(enabled === true, '.claude/settings.json does not enable the plugin. Add "agrippa@agrippa": true under enabledPlugins.');

            // The plugin's hooks.json runs the spawn logger, and the linter
            // runs as agrippa-lint, so settings that run local copies are left
            // over.
            if (settings.hooks !== undefined && settings.hooks !== null) {
                for (const [hookEvent, groups] of Object.entries(settings.hooks)) {
                    const commands = hookCommands(asArray(groups));
                    const loggerCommands = commands.filter((command) => /log_subagent_spawns\.ps1/i.test(command));
                    addProjectCheck(loggerCommands.length === 0, `.claude/settings.json hooks.${hookEvent} runs a local spawn logger (${loggerCommands.join('; ')}). Remove that hook entry; the plugin runs the spawn logger when the env block sets AGRIPPA_SPAWN_LOG=1.`);
                }
            }
            if (settings.permissions !== undefined && settings.permissions !== null) {
                for (const list of ['allow', 'ask', 'deny']) {
                    for (const rule of asArray(settings.permissions[list])) {
                        if (rule === null || rule === undefined) {
                            continue;
                        }
                        addProjectCheck(!/validate_plan_workspace\.ps1/i.test(String(rule)), `.claude/settings.json permissions.${list} rule '${rule}' runs the local copy of the linter. Replace it with Bash(agrippa-lint:*).`);
                    }
                }
            }
        }

        const projectDocuments = [
            ['docs/agent_memory/project-contracts.md', 'templates/PROJECT-CONTRACTS.md'],
            ['docs/agent_memory/validation-commands.md', 'templates/VALIDATION-COMMANDS.md'],
        ];
        for (const [document, template] of projectDocuments) {
            addProjectCheck(isFile(join(projectRoot, document)), `${document} is missing. Write it from plugins/agrippa/${template}; the plugin's agents and skills read the project's facts from it.`);
        }

        const moveFacts = 'Move any project facts it holds into docs/agent_memory/project-contracts.md, validation-commands.md, or live-app.md, then delete it';
        for (const name of agentNames) {
            const path = `.claude/agents/${name}.md`;
            addProjectCheck(!existsSync(join(projectRoot, path)), `${path} is a local copy of the plugin agent agrippa:${name}. ${moveFacts}.`);
        }
        for (const name of allSkillNames) {
            const path = `.claude/skills/${name}`;
            addProjectCheck(!existsSync(join(projectRoot, path)), `${path}/ is a local copy of the plugin skill agrippa:${name}. ${moveFacts}.`);
        }
        for (const name of pluginSkillNames) {
            const path = `.claude/commands/${name}.md`;
            addProjectCheck(!existsSync(join(projectRoot, path)), `${path} is a local command that the plugin skill /agrippa:${name} replaces. Delete it.`);
        }
        addProjectCheck(!existsSync(join(projectRoot, 'tools', 'validate_plan_workspace.ps1')), 'tools/validate_plan_workspace.ps1 is a local copy of the shared linter. Delete it; plans run agrippa-lint from the plugin, and project rules stay in tools/validate_plan_workspace.local.mjs.');
        // The 0.2.0 linter imports the .mjs local file and fails on a .ps1 one,
        // so a leftover .ps1 means the project's rules are not running.
        addProjectCheck(!existsSync(join(projectRoot, 'tools', 'validate_plan_workspace.local.ps1')), 'tools/validate_plan_workspace.local.ps1 is the PowerShell local-checks file that linters before 0.2.0 loaded. Port it to tools/validate_plan_workspace.local.mjs with the "From G4 v0.1.2" table in UPGRADING.md and delete it; agrippa-lint fails while only the .ps1 exists.');

        // Up to v0.1.0 an install copied the plan-workspace and decision-record
        // rules into these READMEs. The rules now ship in the plan and
        // design-first skills, and the project keeps a short pointer. A
        // section heading that only the full copy had marks a leftover.
        const fullCopies = [
            ['plans/README.md', '(?m)^## (Artifact contract|Selective reads)', 'templates/plans-README.md', 'plan'],
            ['docs/decisions/README.md', '(?m)^## (When a record is required|Shape)\\s*$', 'templates/decisions-README.md', 'design-first'],
        ];
        for (const [document, pattern, template, skill] of fullCopies) {
            const copyPath = join(projectRoot, document);
            if (isFile(copyPath)) {
                addProjectCheck(!matches(readText(copyPath), pattern), `${document} is a full copy of rules that now ship in the plugin skill agrippa:${skill}. Move any project rule in it into "Project rules" in AGENTS.md, then replace it with the short pointer plugins/agrippa/${template}, as "From G4 v0.1.0" in UPGRADING.md says.`);
            }
        }
        // Up to v0.1.1 the project-document templates carried generic rule
        // text beside the project's facts, so every install copied it. The
        // rules now ship in the plan skill, verify-before-done, and the agents.
        // A leftover is recognized by the template's wording; an install may
        // have rewrapped the lines, so every space matches any whitespace.
        const genericRules = [
            ['docs/agent_memory/validation-commands.md', 'Retry rule: performance and benchmark gates are `noisy-retry`', 'the noisy-retry rule, now in the plugin skill agrippa:verify-before-done ("Retries")'],
            ['docs/agent_memory/validation-commands.md', 'Existing-failure rule: prove a failure is pre-existing', 'the pre-existing-failure rule, now in the plugin skill agrippa:verify-before-done; keep the red-target list as a "Known red targets at `HEAD`" bullet'],
            ['docs/agent_memory/validation-commands.md', 'Every plan-matrix row records a Sandbox value', 'the Sandbox value definitions, now under "Validation matrix values" in the plan skill\'s agent-workflow.md'],
            ['docs/agent_memory/validation-commands.md', 'Allowed plan-matrix determinism values are', 'the allowed Determinism values, now under "Validation matrix values" in the plan skill\'s agent-workflow.md'],
            ['docs/agent_memory/validation-commands.md', 'Do not use a single representative test as the complete suite', 'the "Full-suite inventory" opening paragraph, now under "Validation matrix values" in the plan skill\'s agent-workflow.md'],
            ['docs/agent_memory/validation-commands.md', 'Commands are copied verbatim into a plan\'s validation matrix', 'the "Plan-matrix contract" section, now under "Validation matrix values" in the plan skill\'s agent-workflow.md'],
            ['docs/agent_memory/project-contracts.md', 'Treat these as separate writer boundaries unless a plan explicitly combines', 'the "Ownership areas" opening paragraph, which restates the core rules'],
            ['docs/agent_memory/project-contracts.md', 'List the owners here so placement is a lookup', 'the "Architecture owners" opening paragraph, which the template now carries only as an install note'],
            ['docs/agent_memory/project-contracts.md', 'Plans and reviewers cite them by path', 'the "Contract documents" rule sentence, which the agents already follow'],
            ['docs/agent_memory/project-contracts.md', 'records an `rg` consumer census with file:line snippets', 'the "Shared and public interfaces" opening paragraph, now in the core rules, the design-first skill, and the plan skill\'s agent-workflow.md'],
            ['docs/agent_memory/project-contracts.md', 'a risk flag keeps a stage off Haiku', 'the risk-flag rule, now in the plan skill\'s ROUTING.md'],
            ['docs/agent_memory/project-contracts.md', 'distinguish existing failures or environment limits from regressions', 'the last two "Environment boundaries" bullets, which the plugin skill agrippa:verify-before-done already states'],
            ['docs/agent_memory/live-app.md', 'They may call only the tools listed under', 'the opening paragraph about which tools the agents may call, which every plugin agent already states'],
            ['docs/agent_memory/live-app.md', 'Which agents run the app:', 'the "Which agents run the app" paragraph, which the plugin agents already state'],
            ['docs/agent_memory/live-app.md', 'Cite a bridge-sourced fact as', 'the citation sentences under "Serialized files", which the plugin agent agrippa:repo-scout already states'],
            ['docs/agent_memory/live-app.md', '(?m)^## Rules\\s*$', 'the "Rules" section, now in the plugin agents and the plugin skill agrippa:verify-before-done ("Live-app bridge")'],
            ['AGENTS.md', 'adds its core rules to every session: request boundaries, Engineering', 'the opening paragraph\'s list of core-rule sections, which goes stale; the template now has one sentence'],
            ['AGENTS.md', 'never report a visual or GPU-dependent check as done when the bridge was down', 'the live-app paragraph\'s bridge rules, now in the plugin agents and agrippa:verify-before-done; keep one or two sentences pointing to live-app.md'],
        ];
        for (const [document, pattern, description] of genericRules) {
            const rulePath = join(projectRoot, document);
            if (isFile(rulePath)) {
                addProjectCheck(!ruleRegex(pattern).test(readText(rulePath)), `${document} still holds ${description}. Delete the copy, keeping the heading and the project's facts, as "From G4 v0.1.1" in UPGRADING.md says.`);
            }
        }

        const planningNote = join(projectRoot, 'docs', 'planning', 'CLAUDE.md');
        if (isFile(planningNote)) {
            addProjectCheck(!/^\s*# docs\/planning\//i.test(readText(planningNote)), 'docs/planning/CLAUDE.md is the kit\'s old note about the planning guides and templates, which now ship in the plugin skill agrippa:plan. Delete it, as "From G4 v0.1.0" in UPGRADING.md says.');
        }

        // The spawn logger's payload helper may also serve the project's own
        // edit-lint hook. It is left over only when no other script in either
        // hook folder and no settings.json hook command names it.
        const hookFolders = ['tools', '.claude/hooks'];
        const helperUsers = [];
        for (const folder of hookFolders) {
            const folderPath = join(projectRoot, folder);
            if (isDirectory(folderPath)) {
                for (const name of listEntries(folderPath)) {
                    const lowered = name.toLowerCase();
                    if (!lowered.endsWith('.ps1') || lowered === 'hook_payload.ps1' || lowered === 'log_subagent_spawns.ps1' || !isFile(join(folderPath, name))) {
                        continue;
                    }
                    if (readText(join(folderPath, name)).includes('hook_payload.ps1')) {
                        helperUsers.push(`${folder}/${name}`);
                    }
                }
            }
        }
        if (settings !== null && settings.hooks !== undefined && settings.hooks !== null) {
            for (const groups of Object.values(settings.hooks)) {
                helperUsers.push(...hookCommands(asArray(groups)).filter((command) => /hook_payload\.ps1/i.test(command)));
            }
        }
        for (const folder of hookFolders) {
            const loggerPath = `${folder}/log_subagent_spawns.ps1`;
            addProjectCheck(!existsSync(join(projectRoot, loggerPath)), `${loggerPath} is a local copy of the spawn logger. Delete it; the plugin runs its own when the env block of .claude/settings.json sets AGRIPPA_SPAWN_LOG=1.`);
            const helperPath = `${folder}/hook_payload.ps1`;
            if (isFile(join(projectRoot, helperPath))) {
                addProjectCheck(helperUsers.length > 0, `${helperPath} is a local copy of the old spawn logger's payload helper, and no project script or settings.json hook uses it. Delete it; the plugin's spawn logger does not need it.`);
            }
        }
    }
}

// --- Report -----------------------------------------------------------------

for (const warning of warnings) {
    process.stderr.write(`WARNING: ${warning}\n`);
}
for (const message of errors) {
    console.log(`ERROR: ${message}`);
}
for (const message of projectErrors) {
    console.log(`INSTALLED REPO: ${message}`);
}
let projectSummary = '';
if (installedRepo) {
    projectSummary = `, ${projectErrors.length} error(s) in ${installedRepo} from ${projectChecks} checks`;
}
if (errors.length > 0 || projectErrors.length > 0) {
    console.log(`FAIL: ${errors.length} kit error(s) from ${checks} checks${projectSummary}, ${warnings.length} warning(s).`);
    process.exit(1);
}

if (installedRepo) {
    projectSummary = `, ${installedRepo} passed ${projectChecks} checks`;
}
console.log(`PASS: ${checks} kit checks, ${requiredCount} required files, smoke test passed${projectSummary}, ${warnings.length} warning(s).`);
