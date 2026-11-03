// Proves the agrippa plugin's plan-workspace linter accepts a valid workspace
// and a valid medium plan in a project and rejects broken ones, then removes
// what it created.
//
// Copies `smoke-workspace/` into `<RepoRoot>/plans/<today>-kit-smoke-test` and
// `smoke-brief/` into `<RepoRoot>/plans/<today>-kit-smoke-brief` (adding -2,
// -3, ... on a name collision), replaces the `__TODAY__` and `__PLAN__`
// tokens, and runs the plugin's
// `plugins/agrippa/scripts/validate_plan_workspace.pl` from this Agrippa
// checkout against each with the perl that `dev/tool-paths.mjs` finds, which
// on Windows is the one Git for Windows bundles. Both runs must PASS. It then
// marks the workspace's stage M1 `Open` and deletes the M1 packet's
// `Return only` line, and the same linter must FAIL with both errors. In the
// medium plan it removes the `## State` heading, points the covering tests at
// a missing file, and turns the manual row into a command, and the linter
// must FAIL with all three errors; the command error says either that the
// command is not in `.agrippa/validation-commands.md` or that the project has
// no catalog. Both folders are deleted afterwards either way; a `plans/`
// folder the script had to create is deleted too while it is still empty.
//
// The linter runs from the project root without -RepoRoot, the way the
// `agrippa-lint` wrapper runs it, so it finds the root through git. RepoRoot
// must therefore be the top-level folder of a git repository. The project needs
// no copy of the linter.
//
// It runs the linter with -SkipLocalChecks, because the generic fixture cannot
// satisfy a project's own invariants in
// `tools/validate_plan_workspace.local.pl`; prove those by linting one real
// plan workspace instead.
//
// The fixture references only the project's `.agrippa/project-rules.md`, whose
// first line is the consumer-census snippet `# Project rules`. If an adapted
// `project-rules.md` has a different first line, the pass run fails on check
// 25; fix the fixture's census snippet, not the linter.
//
// Usage: node dev/fixtures/run-smoke-test.mjs -RepoRoot <repository>
// (`--repo-root <repository>` and a bare path work too).
//
// Exit 0 when both runs behave as expected, 1 otherwise, 2 on a usage error.
// Read-only apart from the temporary workspace. Uses only Node's built-in
// modules.

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readdirSync, readFileSync, rmSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { findTool } from '../tool-paths.mjs';

const usage = 'usage: node dev/fixtures/run-smoke-test.mjs -RepoRoot <repository>';

function parseArguments(argv) {
    let repoRoot = '';
    for (let i = 0; i < argv.length; i++) {
        const argument = argv[i];
        const flag = /^--?([A-Za-z][\w-]*)(?:[=:](.*))?$/s.exec(argument);
        if (!flag) {
            if (!repoRoot) {
                repoRoot = argument;
                continue;
            }
            return { error: `unexpected argument '${argument}'` };
        }
        const name = flag[1].toLowerCase();
        if (name !== 'reporoot' && name !== 'repo-root') {
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
        repoRoot = value;
    }
    if (!repoRoot) {
        return { error: '-RepoRoot is required' };
    }
    return { repoRoot };
}

const parsed = parseArguments(process.argv.slice(2));
if (parsed.error) {
    process.stderr.write(`run-smoke-test: ${parsed.error}\n${usage}\n`);
    process.exit(2);
}

// This script lives in dev/fixtures/ of the Agrippa repository.
const scriptRoot = dirname(fileURLToPath(import.meta.url));
const fixture = join(scriptRoot, 'smoke-workspace');
const briefFixture = join(scriptRoot, 'smoke-brief');
const linter = join(scriptRoot, '..', '..', 'plugins', 'agrippa', 'scripts', 'validate_plan_workspace.pl');
const failures = [];

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

if (!isDirectory(parsed.repoRoot)) {
    console.log(`FAIL: -RepoRoot is not a folder: ${parsed.repoRoot}`);
    process.exit(1);
}
const root = resolve(parsed.repoRoot);
if (!isFile(linter)) {
    console.log(`FAIL: the plugin linter is missing at ${linter}.`);
    process.exit(1);
}
const perl = findTool('perl');
if (perl === null) {
    console.log('FAIL: perl is not available; the plugin linter runs on Perl, which Git for Windows provides on Windows and macOS and Linux ship.');
    process.exit(1);
}
if (!existsSync(join(root, '.git'))) {
    console.log(`FAIL: ${root} is not the top-level folder of a git repository, so the linter cannot find it without -RepoRoot.`);
    process.exit(1);
}

const plansDir = join(root, 'plans');
let createdPlansDir = false;
if (!isDirectory(plansDir)) {
    mkdirSync(plansDir);
    createdPlansDir = true;
}

const now = new Date();
const today = [
    String(now.getFullYear()),
    String(now.getMonth() + 1).padStart(2, '0'),
    String(now.getDate()).padStart(2, '0'),
].join('-');
function freeName(base) {
    let name = base;
    let suffix = 1;
    while (existsSync(join(plansDir, name))) {
        suffix++;
        name = `${base}-${suffix}`;
    }
    return name;
}
const name = freeName(`${today}-kit-smoke-test`);
const workspace = join(plansDir, name);
const planRelative = `plans/${name}`;
const briefName = freeName(`${today}-kit-smoke-brief`);
const briefFolder = join(plansDir, briefName);
const briefRelative = `plans/${briefName}`;

function runLinter(planPath) {
    // The linter runs with the project root as the current directory and no
    // -RepoRoot, so it finds the root through git as the wrapper does. It
    // reports errors through stderr and the summary through stdout; both are
    // collapsed to single-spaced text so a message is matched the same way
    // however the lines are presented.
    const result = spawnSync(perl, [linter, '-PlanPath', planPath, '-SkipLocalChecks'], {
        cwd: root,
        encoding: 'utf8',
    });
    return {
        exitCode: result.status === null ? 1 : result.status,
        text: `${result.stdout || ''} ${result.stderr || ''}`.replace(/\s+/g, ' '),
    };
}

function replaceFirstOccurrence(path, oldText, newText) {
    const text = readFileSync(path, 'utf8');
    const index = text.indexOf(oldText);
    if (index < 0) {
        return false;
    }
    writeFileSync(path, text.slice(0, index) + newText + text.slice(index + oldText.length), 'utf8');
    return true;
}

function copyFixture(source, target, targetRelative) {
    mkdirSync(target);
    for (const entry of readdirSync(source, { withFileTypes: true })) {
        if (!entry.isFile()) {
            continue;
        }
        const text = readFileSync(join(source, entry.name), 'utf8')
            .split('__TODAY__').join(today)
            .split('__PLAN__').join(targetRelative);
        writeFileSync(join(target, entry.name), text, 'utf8');
    }
}

let fatal = null;
try {
    copyFixture(fixture, workspace, planRelative);
    copyFixture(briefFixture, briefFolder, briefRelative);

    const pass = runLinter(planRelative);
    if (pass.exitCode !== 0 || !/PASS:/i.test(pass.text)) {
        failures.push(`Valid fixture did not pass:\n${pass.text}`);
    }

    const broken = replaceFirstOccurrence(join(workspace, 'PLAN.md'), '| Design state | Frozen |', '| Design state | Open |')
        && replaceFirstOccurrence(join(workspace, 'PACKETS.md'), 'Return only:', 'Returns:');
    if (!broken) {
        throw new Error('The fixture no longer contains the text the broken run replaces.');
    }

    const fail = runLinter(planRelative);
    if (fail.exitCode === 0) {
        failures.push('Broken fixture passed; the linter accepted an Open stage and a packet without Return only.');
    }
    if (!/\[Check 5\] M1/i.test(fail.text)) {
        failures.push(`Broken fixture did not report the Open stage (check 5):\n${fail.text}`);
    }
    if (!/M1 packet is missing 'Return only'/i.test(fail.text)) {
        failures.push(`Broken fixture did not report the missing packet label:\n${fail.text}`);
    }

    const briefPass = runLinter(briefRelative);
    if (briefPass.exitCode !== 0 || !/PASS:/i.test(briefPass.text)) {
        failures.push(`Valid medium plan did not pass:\n${briefPass.text}`);
    }

    const briefPath = join(briefFolder, 'BRIEF.md');
    const briefBroken = replaceFirstOccurrence(briefPath, '## State', 'State')
        && replaceFirstOccurrence(briefPath, 'Covering tests: `.agrippa/project-rules.md`', 'Covering tests: `.agrippa/missing-test.md`')
        && replaceFirstOccurrence(briefPath, '| manual | sandboxed | manual |', '| lint | sandboxed | deterministic |');
    if (!briefBroken) {
        throw new Error('The medium-plan fixture no longer contains the text the broken run replaces.');
    }

    const briefFail = runLinter(briefRelative);
    if (briefFail.exitCode === 0) {
        failures.push('Broken medium plan passed; the linter accepted a missing section, a missing covering test, and an uncatalogued command.');
    }
    if (!/\[Brief\] BRIEF\.md is missing the section '## State'/i.test(briefFail.text)) {
        failures.push(`Broken medium plan did not report the missing State section:\n${briefFail.text}`);
    }
    if (!/\[Check 26\] BRIEF\.md covering test does not exist: \.agrippa\/missing-test\.md/i.test(briefFail.text)) {
        failures.push(`Broken medium plan did not report the missing covering test:\n${briefFail.text}`);
    }
    if (!/\[Brief\] (?:V2 command is not in|\.agrippa\/validation-commands\.md is missing)/i.test(briefFail.text)) {
        failures.push(`Broken medium plan did not report the uncatalogued command:\n${briefFail.text}`);
    }
} catch (error) {
    fatal = error;
} finally {
    for (const folder of [workspace, briefFolder]) {
        if (existsSync(folder)) {
            rmSync(folder, { recursive: true, force: true });
        }
    }
    // Remove a plans/ folder this script created, but only while it is empty,
    // so a plan another session wrote meanwhile survives.
    if (createdPlansDir && existsSync(plansDir) && readdirSync(plansDir).length === 0) {
        rmSync(plansDir, { recursive: true, force: true });
    }
}

if (fatal) {
    console.log(fatal.message);
    process.exit(1);
}
if (failures.length > 0) {
    for (const message of failures) {
        console.log(message);
    }
    console.log(`FAIL: smoke test, ${failures.length} problem(s).`);
    process.exit(1);
}
console.log(`PASS: valid fixtures passed and broken fixtures failed with the expected errors (${planRelative} and ${briefRelative}, removed).`);
process.exit(0);
