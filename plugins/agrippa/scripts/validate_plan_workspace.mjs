// Validates a planning workspace's dispatch shape.
//
// This linter checks shape, never truth. A wrong constant, incomplete design
// choice, or incorrect contract can satisfy every static check. Human planning
// and review remain responsible for semantic correctness.
//
// This is the portable version. It recognizes any dotted file extension and any
// URI-style scheme prefix, and it encodes no project's toolchain. Do not edit
// this file per project. Project-specific command invariants (one required test
// binary, an invocation shape per test kind, a prelude that must come first, a
// narrower command-path extension list) go in the optional
// `tools/validate_plan_workspace.local.mjs` in the project, which this script
// imports at the "Project-specific extension point". A plugin upgrade replaces
// this file and never touches the local one.
//
// It ships in the agrippa plugin and runs from there, never from a copy in the
// project. Inside Claude Code, the plugin's `bin/agrippa-lint` wrapper runs it
// from the Bash tool:
//
//     agrippa-lint -PlanPath plans/YYYY-MM-DD-name
//
// Elsewhere, run it from a checkout of Agrippa at the project's pinned tag:
//
//     node plugins/agrippa/scripts/validate_plan_workspace.mjs -PlanPath <plan> -RepoRoot <repository>
//
// Arguments: -PlanPath <folder> (the plan workspace, absolute or relative to
// the repository root; a bare path argument means the same), -RepoRoot <folder>
// (the repository the plan belongs to; when omitted, the git top-level folder
// of the current directory), and -SkipLocalChecks (ignore the project's local
// checks; the kit smoke test uses this because its generic fixture cannot
// satisfy a project's own invariants). The `--plan-path` spellings work too.
//
// Errors go to stderr one per line, warnings to stderr prefixed `WARNING:`,
// and one PASS or FAIL summary line to stdout. Exit 0 on PASS, 1 on FAIL, 2 on
// a usage error. Uses only Node's built-in modules.
//
// It is coupled to the plan templates in `skills/plan/templates/`: a change to
// the template shape must be reflected here, and the reverse. Keep it
// read-only.

import { readFileSync, statSync } from 'node:fs';
import { isAbsolute, join, resolve, sep } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { spawnSync } from 'node:child_process';

// Extensions that count as repository source or test paths when they appear
// inside a validation command (check 13). Other paths, such as an output file a
// command writes or a path a command proves is absent, are not checked for
// existence. Ownership, census, and contract-source fields use any dotted
// extension regardless of this list. The local extension file may replace it.
const defaultCommandPathExtensions = [
    'py', 'ps1', 'psm1', 'sh', 'bash', 'js', 'mjs', 'cjs', 'ts', 'tsx', 'jsx',
    'go', 'rs', 'java', 'kt', 'cs', 'c', 'cc', 'cpp', 'h', 'hpp', 'rb', 'php',
    'swift', 'lua', 'sql', 'gd', 'tscn', 'toml', 'yaml', 'yml', 'md',
];

// Every dispatch packet carries these labels. dev/validate-kit.mjs reads this
// list from the source and requires each label in the PACKETS.md template.
const requiredPacketLabels = [
    'Plan', 'Stage', 'Goal', 'Dependencies', 'Owner / assigned tier',
    'Design state', 'Contract IDs', 'Owned files', 'Forbidden scope',
    'Allowed interfaces', 'Pre-authorized ownership expansion',
    'Acceptance', 'Validation', 'Validation output',
    'Relevant references', 'Dirty/user-owned warnings',
    'Stop/escalate when', 'Return only',
];

// A stage's Assigned tier is a model tier (lead/haiku/sonnet/opus, optionally
// with an effort suffix) or a named role from the plugin's agents
// (repo-scout/plan-reviewer/validator).
const tierPattern = /^(lead|haiku|sonnet|opus|repo-scout|plan-reviewer|validator)\b/i;

const allowedDeterminism = ['deterministic', 'noisy-retry', 'skips-headless', 'manual'];

const localChecksName = 'tools/validate_plan_workspace.local.mjs';
const legacyLocalChecksName = 'tools/validate_plan_workspace.local.ps1';

// Paths compare case-insensitively where the default file system does.
const caseInsensitivePaths = process.platform === 'win32' || process.platform === 'darwin';

function usage() {
    return 'usage: agrippa-lint -PlanPath <plan folder> [-RepoRoot <repository>] [-SkipLocalChecks]';
}

// Accepts the PowerShell spellings every plan's matrix row uses (-PlanPath,
// -RepoRoot, -SkipLocalChecks), their --long-option forms, and a bare path.
function parseArguments(argv) {
    const names = {
        planpath: 'planPath',
        'plan-path': 'planPath',
        reporoot: 'repoRoot',
        'repo-root': 'repoRoot',
        skiplocalchecks: 'skipLocalChecks',
        'skip-local-checks': 'skipLocalChecks',
    };
    const options = { planPath: '', repoRoot: '', skipLocalChecks: false };
    for (let i = 0; i < argv.length; i++) {
        const argument = argv[i];
        const flag = /^--?([A-Za-z][\w-]*)(?:[=:](.*))?$/s.exec(argument);
        if (!flag) {
            if (!options.planPath) {
                options.planPath = argument;
                continue;
            }
            return { error: `unexpected argument '${argument}'` };
        }
        const key = names[flag[1].toLowerCase()];
        if (!key) {
            return { error: `unknown option '${argument}'` };
        }
        if (key === 'skipLocalChecks') {
            options.skipLocalChecks = true;
            continue;
        }
        let value = flag[2];
        if (value === undefined) {
            i++;
            value = argv[i];
            if (value === undefined) {
                return { error: `${argument} needs a value` };
            }
        }
        options[key] = value;
    }
    if (!options.planPath) {
        return { error: '-PlanPath is required' };
    }
    return { options };
}

function escapeRegex(text) {
    return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeText(text) {
    return String(text === undefined || text === null ? '' : text).replace(/\s+/g, ' ').trim();
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

// Reads a text file as UTF-8 and drops a byte-order mark.
function readText(path) {
    return readFileSync(path, 'utf8').replace(/^﻿/, '');
}

// Splits text into lines the way a line-by-line reader counts them: a
// trailing newline does not add an empty last line, and an empty file has no
// lines.
function readLines(path) {
    const lines = readText(path).split(/\r?\n/);
    if (lines.length > 0 && lines[lines.length - 1] === '') {
        lines.pop();
    }
    return lines;
}

function unique(values) {
    return [...new Set(values)];
}

function sameSet(left, right) {
    const a = unique(left).sort();
    const b = unique(right).sort();
    return a.length === b.length && a.every((value, index) => value === b[index]);
}

function matchAll(text, pattern) {
    return [...text.matchAll(pattern)];
}

function samePath(left, right) {
    return caseInsensitivePaths ? left.toLowerCase() === right.toLowerCase() : left === right;
}

// Local calendar date of a file's last write, as yyyy-mm-dd.
function localDate(date) {
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    return `${date.getFullYear()}-${month}-${day}`;
}

// Returns a table cell by header name, ignoring the header's case, or ''.
function cell(row, name) {
    if (Object.prototype.hasOwnProperty.call(row, name)) {
        return String(row[name] === undefined || row[name] === null ? '' : row[name]);
    }
    const wanted = name.toLowerCase();
    for (const key of Object.keys(row)) {
        if (key.toLowerCase() === wanted) {
            return String(row[key] === undefined || row[key] === null ? '' : row[key]);
        }
    }
    return '';
}

// Splits one Markdown table row into cells: a pipe splits cells unless it is
// escaped or inside backticks.
function splitMarkdownRow(line) {
    const body = line.trim().replace(/^\|+/, '').replace(/\|+$/, '');
    const cells = [];
    let current = '';
    let inCode = false;
    let escaped = false;
    for (const char of body) {
        if (escaped) {
            current += char;
            escaped = false;
            continue;
        }
        if (char === '\\') {
            current += char;
            escaped = true;
            continue;
        }
        if (char === '`') {
            inCode = !inCode;
            current += char;
            continue;
        }
        if (char === '|' && !inCode) {
            cells.push(current.trim());
            current = '';
            continue;
        }
        current += char;
    }
    cells.push(current.trim());
    return cells;
}

// Returns the rows of the first table whose header line matches, as objects
// keyed by header text. A row with the wrong cell count is reported and skipped.
function getTable(text, headerPattern, errors) {
    const lines = text.split(/\r?\n/);
    const headerIndex = lines.findIndex((line) => headerPattern.test(line));
    if (headerIndex < 0) {
        return [];
    }
    const headers = splitMarkdownRow(lines[headerIndex]);
    const rows = [];
    for (let i = headerIndex + 2; i < lines.length; i++) {
        if (!/^\s*\|/.test(lines[i])) {
            break;
        }
        const cells = splitMarkdownRow(lines[i]);
        if (cells.length !== headers.length) {
            errors.push(`[Table] Row has ${cells.length} cells; expected ${headers.length}: ${lines[i]}`);
            continue;
        }
        const row = {};
        headers.forEach((header, index) => {
            row[header] = cells[index];
        });
        rows.push(row);
    }
    return rows;
}

// Milestone and Integration sections of PLAN.md with their two-column field
// tables. Field names are matched without regard to case.
function getStageSections(text) {
    const pattern = /^#{2,3}\s+((?:M\d+\s*:|Milestone\s+\d+|Integration)[^\r\n]*)\r?\n(.*?)(?=^#{2,3}\s+(?:M\d+\s*:|Milestone\s+\d+|Integration)|(?![\s\S]))/gms;
    const stages = [];
    for (const match of matchAll(text, pattern)) {
        const heading = match[1].trim();
        let id = 'Integration';
        const milestone = /^M(\d+)/i.exec(heading) || /^Milestone\s+(\d+)/i.exec(heading);
        if (milestone) {
            id = `M${milestone[1]}`;
        }
        const fields = new Map();
        for (const field of matchAll(match[2], /^\|\s*([^|]+?)\s*\|\s*([^|]+?)\s*\|\s*$/gm)) {
            const key = field[1].trim();
            if (!['field', '---'].includes(key.toLowerCase())) {
                fields.set(key.toLowerCase(), field[2].trim());
            }
        }
        stages.push({ id, heading, text: match[2], fields });
    }
    return stages;
}

function getPacketSections(text) {
    const pattern = /^###\s+Packet\s+(M\d+|Integration)\s*\r?\n(.*?)(?=^###\s+|(?![\s\S]))/gms;
    return matchAll(text, pattern).map((match) => ({ id: match[1], text: match[2] }));
}

function getField(stage, name) {
    const value = stage.fields.get(name.toLowerCase());
    return value === undefined ? '' : value;
}

// Generic path detector: any backtick-quoted token ending in a dotted extension,
// optionally followed by :line, :line-line, or :symbol. There is no
// project-specific extension allow-list, so this works for any language.
function getCodePaths(text) {
    const paths = [];
    for (const match of matchAll(text, /`([^`]+)`/g)) {
        const candidate = match[1].trim();
        if (/\.[A-Za-z0-9]{1,10}(?::[^/\s]+|:\d+(?:-\d+)?)?$/i.test(candidate)) {
            paths.push(candidate);
        }
    }
    return paths;
}

function getOwnedPathTokens(text) {
    const tokens = getCodePaths(text);
    const seen = new Set(tokens.map((token) => token.toLowerCase()));
    const pattern = /(?:^|[\s,`])((?:\.?[\w.-]+\/)*[\w.*-]+\.[A-Za-z0-9]{1,10}(?::[^,\s`]+)?)(?=$|[\s,`])/gi;
    for (const match of matchAll(text, pattern)) {
        if (!seen.has(match[1].toLowerCase())) {
            seen.add(match[1].toLowerCase());
            tokens.push(match[1]);
        }
    }
    return tokens;
}

// Strips a URI-style scheme prefix (for example an engine's virtual resource
// root), a :line or :line-line suffix, and a :symbol suffix, and returns the
// file path with this platform's separators.
function getRepoRelativeFile(ownedPath) {
    let path = ownedPath.replace(/^[A-Za-z][A-Za-z0-9+.-]*:\/\//, '');
    path = path.replace(/:\d+(?:-\d+)?$/, '');
    const symbol = /^(.+\.[A-Za-z0-9]{1,10}):[^/\\]+$/i.exec(path);
    if (symbol) {
        path = symbol[1];
    }
    return path.split('/').join(sep);
}

function toSlashes(path) {
    return path.split(sep).join('/');
}

// Resolves the repository root from -RepoRoot or from git. Returns the root or
// a message explaining why none was found.
function findRepoRoot(requested) {
    let root = requested;
    if (!root) {
        try {
            const git = spawnSync('git', ['rev-parse', '--show-toplevel'], { encoding: 'utf8', windowsHide: true });
            if (git.status === 0 && git.stdout) {
                root = git.stdout.split(/\r?\n/)[0].trim();
            }
        } catch {
            root = '';
        }
    }
    if (!root || !isDirectory(root)) {
        const shown = root || `the current directory (${process.cwd()}) is not inside a git repository`;
        return { error: `[Files] Could not find the repository root: ${shown}. Run from inside the repository or pass -RepoRoot.` };
    }
    return { root: resolve(root) };
}

// Loads the project's optional local checks. Returns the module's exports, an
// empty object when there is no local file, or null after reporting a problem.
async function loadLocalChecks(repoRoot, check) {
    const localPath = join(repoRoot, ...localChecksName.split('/'));
    if (isFile(localPath)) {
        try {
            return await import(pathToFileURL(localPath).href);
        } catch (error) {
            check(false, `[Local] ${localChecksName} failed to load: ${error.message}`);
            return null;
        }
    }
    if (isFile(join(repoRoot, ...legacyLocalChecksName.split('/')))) {
        check(false, `[Local] ${legacyLocalChecksName} is PowerShell; this linter loads ${localChecksName}. Run the agrippa upgrade skill to port it.`);
    }
    return null;
}

export async function main(argv) {
    const parsed = parseArguments(argv);
    if (parsed.error) {
        process.stderr.write(`agrippa-lint: ${parsed.error}\n${usage()}\n`);
        return 2;
    }
    const options = parsed.options;

    const errors = [];
    const warnings = [];
    let checks = 0;
    function check(condition, message) {
        checks++;
        if (!condition) {
            errors.push(message);
        }
    }
    function finish(summary) {
        for (const warning of warnings) {
            process.stderr.write(`WARNING: ${warning}\n`);
        }
        for (const message of errors) {
            process.stderr.write(`${message}\n`);
        }
        process.stdout.write(`${summary}\n`);
        return errors.length > 0 ? 1 : 0;
    }

    const found = findRepoRoot(options.repoRoot);
    if (found.error) {
        errors.push(found.error);
        return finish('FAIL: 1 shape error(s), 0 checks. Shape validation never proves contract truth.');
    }
    const repoRoot = found.root;

    let requestedPath = options.planPath;
    if (!isAbsolute(requestedPath)) {
        requestedPath = join(repoRoot, requestedPath);
    }
    check(isDirectory(requestedPath), `[Files] PlanPath is not a directory: ${options.planPath}`);
    if (!isDirectory(requestedPath)) {
        return finish(`FAIL: ${errors.length} error(s), ${checks} checks.`);
    }
    const planRoot = resolve(requestedPath);
    const rootPrefix = caseInsensitivePaths ? repoRoot.toLowerCase() : repoRoot;
    const planPrefix = caseInsensitivePaths ? planRoot.toLowerCase() : planRoot;
    check(planPrefix.startsWith(rootPrefix), '[Files] PlanPath must be inside the repository.');

    function readRequiredFile(name) {
        const path = join(planRoot, name);
        check(isFile(path), `[Files] Missing ${name}.`);
        return isFile(path) ? readText(path) : '';
    }
    const spec = readRequiredFile('SPEC.md');
    const plan = readRequiredFile('PLAN.md');
    const packets = readRequiredFile('PACKETS.md');
    const status = readRequiredFile('STATUS.md');
    const workspaceText = [spec, plan, packets, status].join('\n');

    // 1-4: ID traceability and exact acceptance quoting.
    const acceptanceIds = matchAll(spec, /^\s*-\s*\[[ xX]\]\s*\*\*(A\d+):\*\*/gm).map((match) => match[1]);
    const validationRows = getTable(plan, /^\s*\|\s*Validation ID\s*\|/i, errors);
    const validationIds = validationRows.map((row) => cell(row, 'Validation ID')).filter((id) => /^V\d+$/i.test(id));
    const contractIds = matchAll(packets, /^###\s+(C\d+):/gm).map((match) => match[1]);

    check(unique(acceptanceIds).length === acceptanceIds.length, '[Check 2] Duplicate Acceptance ID definition.');
    check(unique(validationIds).length === validationIds.length, '[Check 2] Duplicate Validation ID definition.');
    check(unique(contractIds).length === contractIds.length, '[Check 3] Duplicate Contract ID definition.');

    for (const acceptanceId of unique(acceptanceIds)) {
        const idPattern = new RegExp(`\\b${escapeRegex(acceptanceId)}\\b`, 'i');
        const mapped = validationRows.some((row) => idPattern.test(cell(row, 'Acceptance IDs')));
        check(mapped, `[Check 1] ${acceptanceId} is not mapped by any validation row.`);
    }

    for (const [prefix, ids, checkNumber] of [['A', acceptanceIds, 2], ['V', validationIds, 2], ['C', contractIds, 3]]) {
        const defined = unique(ids);
        const definedLower = new Set(defined.map((id) => id.toLowerCase()));
        const referenced = unique(matchAll(workspaceText, new RegExp(`\\b${prefix}\\d+\\b`, 'g')).map((match) => match[0]));
        for (const id of referenced) {
            check(definedLower.has(id.toLowerCase()), `[Check ${checkNumber}] Referenced ${id} is undefined.`);
        }
        for (const id of defined) {
            const occurrences = matchAll(workspaceText, new RegExp(`\\b${escapeRegex(id)}\\b`, 'g')).length;
            check(occurrences > 1, `[Check ${checkNumber}] Defined ${id} is orphaned.`);
        }
    }

    const normalizedSpec = normalizeText(spec);
    for (const quote of matchAll(packets, /^\s*-\s*(A\d+):\s*(.+)$/gm)) {
        const text = normalizeText(quote[2]);
        if (!text.startsWith('[')) {
            check(normalizedSpec.includes(text), `[Check 4] Packet text for ${quote[1]} is not a whitespace-normalized SPEC.md substring.`);
        }
    }

    // 5-12 and 19-23: stage design, routing, ownership, and validation assignment.
    const stages = getStageSections(plan);
    check(stages.length > 0, '[Stages] No milestone or integration records found.');
    const packetSections = getPacketSections(packets);
    const packetIds = packetSections.map((packet) => packet.id);
    check(unique(packetIds).length === packetIds.length, '[Packets] Duplicate stage packet.');
    const planRelativePath = toSlashes(planRoot.substring(repoRoot.length).replace(/^[\\/]+/, ''));

    const waveStages = new Map();
    for (const stage of stages) {
        const designState = getField(stage, 'Design state');
        const designStateLower = designState.toLowerCase();
        check(['frozen', 'bounded-choice'].includes(designStateLower), `[Check 5] ${stage.id} Design state must be Frozen or Bounded-choice; Open/missing cannot hand off.`);
        const contracts = getField(stage, 'Contract IDs');
        if (designStateLower === 'frozen') {
            check(/\bC\d+\b/i.test(contracts), `[Check 6] Frozen stage ${stage.id} must name at least one Contract ID.`);
        }
        if (designStateLower === 'bounded-choice') {
            const choice = getField(stage, 'Bounded choice') || stage.text;
            check(/Options\s*:/i.test(choice), `[Check 7] ${stage.id} bounded choice must enumerate Options.`);
            check(/Default\s*:/i.test(choice), `[Check 7] ${stage.id} bounded choice must name a Default.`);
            check(/Change observation\s*:/i.test(choice), `[Check 7] ${stage.id} bounded choice must name the exact Change observation.`);
            const choiceBlock = /Bounded choice\s*\|(.+?)(?:\r?\n\||(?![\s\S]))/is.exec(stage.text);
            if (choiceBlock && choiceBlock[1]) {
                check(!/\bC\d+\b|(?:^|\s)(?:[A-Za-z][A-Za-z0-9+.-]*:\/\/|[\w.-]+\/)[^\s,;]+/i.test(choiceBlock[1]), `[Check 7] ${stage.id} bounded-choice block contains a Contract ID or bare path.`);
            }
        }

        const profile = getField(stage, 'Assigned tier');
        const tier = tierPattern.exec(profile);
        const profileBase = tier ? tier[1].toLowerCase() : '';
        check(Boolean(profileBase), `[Check 19] ${stage.id} Assigned tier '${profile}' is not a known tier (lead/haiku/sonnet/opus) or role (repo-scout/plan-reviewer/validator).`);
        if (profileBase === 'opus') {
            const split = /^####\s+Split attempt\s*\r?\n(.+?)(?=^####|^#{2,3}\s|(?![\s\S]))/ims.exec(stage.text);
            const splitText = split ? normalizeText(split[1]) : '';
            check(Boolean(splitText) && !/^not attempted|not required/i.test(splitText), `[Check 8] ${stage.id} high-tier stage requires a substantive Split attempt.`);
        }

        check(Boolean(getField(stage, 'Forbidden scope')), `[Check 12] ${stage.id} must name Forbidden scope.`);
        check(Boolean(getField(stage, 'Pre-authorized ownership expansion')), `[Check 12] ${stage.id} must name a pre-authorized ownership-expansion bound.`);

        const validationRefs = getField(stage, 'Validation IDs');
        check(/\bV\d+\b/i.test(validationRefs), `[Check 22] ${stage.id} must name at least one Validation ID.`);

        const riskFlags = getField(stage, 'Risk flags');
        if (profileBase === 'haiku' && /native|persist|security|concurr|perf|layout|gpu/i.test(riskFlags)) {
            check(false, `[Check 20] ${stage.id} risk flags require sonnet or stronger, not haiku.`);
        }

        const owned = getField(stage, 'Owned files/modules');
        const ownsNothing = /^None$/i.test(owned);
        if (profileBase === 'validator') {
            check(ownsNothing, `[Check 23] validator stage ${stage.id} must declare Owned files/modules: None.`);
        }
        if (profileBase === 'haiku') {
            const anchorText = getField(stage, 'Line-anchored edit sites');
            for (const ownedPath of getCodePaths(owned)) {
                const fileOnly = getRepoRelativeFile(ownedPath);
                const slashPath = toSlashes(fileOnly);
                const hasAnchor = new RegExp(`${escapeRegex(slashPath)}:\\d+`, 'i').test(anchorText);
                check(hasAnchor, `[Check 21] Haiku stage ${stage.id} lacks a line anchor for ${slashPath}.`);
                const absoluteOwned = join(repoRoot, fileOnly);
                if (isFile(absoluteOwned)) {
                    const lineCount = readLines(absoluteOwned).length;
                    if (lineCount > 800) {
                        check(hasAnchor, `[Check 21] Haiku stage ${stage.id} owns ${lineCount}-line ${slashPath} without an anchor.`);
                    }
                }
            }
            check(/^Bounded$/i.test(getField(stage, 'Validation output')), `[Check 21] Haiku stage ${stage.id} must declare bounded validation output.`);
        }

        const wave = getField(stage, 'Wave');
        if (wave && stage.id !== 'Integration') {
            const waveKey = wave.toLowerCase();
            if (!waveStages.has(waveKey)) {
                waveStages.set(waveKey, { name: wave, stages: [] });
            }
            waveStages.get(waveKey).stages.push(stage);
        }

        const stagePackets = packetSections.filter((packet) => packet.id === stage.id);
        check(stagePackets.length === 1, `[Packets] ${stage.id} must have exactly one dispatch packet.`);
        if (stagePackets.length === 1) {
            const packetText = stagePackets[0].text;
            for (const label of requiredPacketLabels) {
                check(new RegExp(`^${escapeRegex(label)}\\s*:`, 'im').test(packetText), `[Packets] ${stage.id} packet is missing '${label}'.`);
            }
            check(new RegExp(`^Plan:\\s*${escapeRegex(planRelativePath)}\\s*$`, 'im').test(packetText), `[Packets] ${stage.id} packet Plan path does not match ${planRelativePath}.`);
            check(new RegExp(`^Stage:\\s*${escapeRegex(stage.id)}\\b`, 'im').test(packetText), `[Packets] ${stage.id} packet Stage field does not match.`);
            check(new RegExp(`^Owner / assigned tier:\\s*${escapeRegex(profile)}\\s*$`, 'im').test(packetText), `[Packets] ${stage.id} packet assigned tier does not match PLAN.md.`);
            check(new RegExp(`^Design state:\\s*${escapeRegex(designState)}\\s*$`, 'im').test(packetText), `[Packets] ${stage.id} packet design state does not match PLAN.md.`);

            const planContractIds = unique(matchAll(contracts, /\bC\d+\b/g).map((match) => match[0]));
            const packetContractLine = /^Contract IDs:\s*(.+)$/im.exec(packetText);
            const packetContractIds = packetContractLine ? unique(matchAll(packetContractLine[1], /\bC\d+\b/g).map((match) => match[0])) : [];
            check(sameSet(planContractIds, packetContractIds), `[Packets] ${stage.id} Contract IDs differ between PLAN.md and PACKETS.md.`);

            const stageAcceptanceIds = unique(matchAll(getField(stage, 'Acceptance IDs'), /\bA\d+\b/g).map((match) => match[0]));
            for (const acceptanceId of stageAcceptanceIds) {
                check(new RegExp(`^\\s*-\\s*${escapeRegex(acceptanceId)}:\\s*\\S`, 'im').test(packetText), `[Packets] ${stage.id} omits acceptance text for ${acceptanceId}.`);
            }
            const stageValidationIds = unique(matchAll(validationRefs, /\bV\d+\b/g).map((match) => match[0]));
            for (const validationId of stageValidationIds) {
                check(new RegExp(`^\\s*-\\s*${escapeRegex(validationId)}:\\s*\\S`, 'im').test(packetText), `[Packets] ${stage.id} omits validation text for ${validationId}.`);
            }

            const planOwnedPaths = unique(getOwnedPathTokens(owned).map((token) => getRepoRelativeFile(token).toLowerCase()));
            const packetOwnedLine = /^Owned files:\s*(.+)$/im.exec(packetText);
            const packetOwnedPaths = packetOwnedLine ? unique(getOwnedPathTokens(packetOwnedLine[1]).map((token) => getRepoRelativeFile(token).toLowerCase())) : [];
            if (ownsNothing) {
                check(/^Owned files:\s*None\s*$/im.test(packetText), `[Packets] ${stage.id} no-file ownership must match in its packet.`);
            } else {
                check(sameSet(planOwnedPaths, packetOwnedPaths), `[Packets] ${stage.id} owned files differ between PLAN.md and PACKETS.md.`);
            }
        }
    }

    const stageIds = stages.map((stage) => stage.id);
    for (const packetId of unique(packetIds)) {
        check(stageIds.includes(packetId), `[Packets] Packet ${packetId} has no matching PLAN.md stage.`);
    }

    for (const { name: wave, stages: members } of waveStages.values()) {
        const writers = members.filter((stage) => !/^None$/i.test(getField(stage, 'Owned files/modules')));
        check(writers.length <= 3, `[Check 10] Wave ${wave} declares ${writers.length} writers; maximum is 3.`);
        if (writers.length > 2) {
            for (const writer of writers) {
                check(getField(writer, 'Design state').toLowerCase() === 'frozen', `[Check 10] Every stage in three-writer Wave ${wave} must be Frozen.`);
            }
        }

        const ownersByPath = new Map();
        for (const writer of writers) {
            for (const ownedPath of getCodePaths(getField(writer, 'Owned files/modules'))) {
                const fileOnly = getRepoRelativeFile(ownedPath).toLowerCase();
                if (!ownersByPath.has(fileOnly)) {
                    ownersByPath.set(fileOnly, []);
                }
                ownersByPath.get(fileOnly).push({ stage: writer, raw: ownedPath });
            }
        }
        for (const [path, owners] of ownersByPath) {
            check(owners.length <= 1, `[Check 9] Wave ${wave} has overlapping ownership of ${path}.`);
            if (owners.length > 1 && owners.some((owner) => /\.[A-Za-z0-9]+:[^\d][^/\\]*$/i.test(owner.raw))) {
                for (const owner of owners) {
                    check(!/^No$|^None$|^$/i.test(getField(owner.stage, 'Worktree')), `[Check 11] Concurrent file:symbol ownership of ${path} requires a declared worktree.`);
                }
            }
        }
    }

    // The ownership matrix is authoritative and must exactly mirror stage ownership.
    const ownershipRows = getTable(plan, /^\s*\|\s*Path\s*\|\s*Wave\s*\|\s*Owning stage\s*\|/i, errors);
    check(ownershipRows.length > 0, '[Ownership matrix] Missing or empty Ownership matrix.');
    const expectedOwnership = [];
    for (const stage of stages) {
        const wave = getField(stage, 'Wave');
        for (const ownedPath of getCodePaths(getField(stage, 'Owned files/modules'))) {
            expectedOwnership.push({ path: getRepoRelativeFile(ownedPath).toLowerCase(), wave, stage: stage.id });
        }
    }
    const actualOwnership = [];
    for (const row of ownershipRows) {
        const matrixPaths = getCodePaths(cell(row, 'Path')).map((path) => getRepoRelativeFile(path).toLowerCase());
        check(matrixPaths.length === 1, `[Ownership matrix] Each row must name exactly one code path: ${cell(row, 'Path')}`);
        if (matrixPaths.length === 1) {
            actualOwnership.push({ path: matrixPaths[0], wave: cell(row, 'Wave'), stage: cell(row, 'Owning stage') });
        }
    }
    function sameMapping(left, right) {
        return left.path === right.path
            && left.wave.toLowerCase() === right.wave.toLowerCase()
            && left.stage.toLowerCase() === right.stage.toLowerCase();
    }
    for (const expected of expectedOwnership) {
        const matches = actualOwnership.filter((actual) => sameMapping(actual, expected));
        check(matches.length === 1, `[Ownership matrix] Missing or duplicate mapping for ${expected.path}, Wave ${expected.wave}, ${expected.stage}.`);
    }
    for (const actual of actualOwnership) {
        const matches = expectedOwnership.filter((expected) => sameMapping(expected, actual));
        check(matches.length === 1, `[Ownership matrix] Extraneous or mismatched mapping for ${actual.path}, Wave ${actual.wave}, ${actual.stage}.`);
    }

    const integration = stages.find((stage) => stage.id === 'Integration');
    check(Boolean(integration), '[Check 22] Exactly one Integration stage is required.');
    if (integration) {
        check(/full applicable suite/i.test(integration.text), '[Check 22] Integration must run the full applicable suite.');
        const integrationIds = getField(integration, 'Validation IDs');
        const hasIntegrationRow = validationRows.some((row) => /Integration/i.test(cell(row, 'When'))
            && new RegExp(`\\b${escapeRegex(cell(row, 'Validation ID'))}\\b`, 'i').test(integrationIds));
        check(hasIntegrationRow, '[Check 22] Integration Validation IDs must include a matrix row scheduled for Integration.');
    }

    // Project-specific extension point: load the optional local checks. The
    // module may export commandPathExtensions (replacing the default list),
    // checkValidationRow (called once per matrix row), and
    // checkValidationMatrix (called once with every row); both functions get
    // check() to report with. A missing file changes nothing. The file belongs
    // to the project, so it is read from the repository root, never from this
    // script's folder.
    let commandPathExtensions = defaultCommandPathExtensions;
    let local = null;
    if (!options.skipLocalChecks) {
        local = await loadLocalChecks(repoRoot, check);
    }
    if (local && Array.isArray(local.commandPathExtensions)) {
        commandPathExtensions = local.commandPathExtensions.map((extension) => String(extension).toLowerCase());
    }
    const localRowCheck = local && typeof local.checkValidationRow === 'function' ? local.checkValidationRow : null;
    const localMatrixCheck = local && typeof local.checkValidationMatrix === 'function' ? local.checkValidationMatrix : null;
    const localContext = { check, repoRoot, planRoot };

    // 13-18: validation commands are runnable and honestly classified.
    check(validationRows.length > 0, '[Validation] Validation matrix is missing or empty.');
    for (const row of validationRows) {
        const validationId = cell(row, 'Validation ID');
        const command = cell(row, 'Exact command or check');
        const style = cell(row, 'Style');
        // Current templates name this column Sandbox. Workspaces written from an
        // earlier kit named it Environment; accept either so older plans still lint.
        const sandbox = cell(row, 'Sandbox') || cell(row, 'Environment');
        const determinism = cell(row, 'Determinism');
        check(Boolean(style), `[Check 18] ${validationId} is missing Style.`);
        check(Boolean(sandbox), `[Check 18] ${validationId} is missing Sandbox.`);
        check(allowedDeterminism.includes(determinism.toLowerCase()), `[Check 18] ${validationId} has invalid Determinism '${determinism}'.`);

        // Check 13: every source or test path a command names must exist, relative
        // to the repository root or to the plan folder (for a file under design/
        // or another plan-local folder). A URL is not a repository path.
        const pathPattern = /(?<![\w.-])([A-Za-z][A-Za-z0-9+.-]*:\/\/)?((?:[\w.-]+\/)+[\w.-]+\.([A-Za-z0-9]{1,10}))(?![\w/-])/gi;
        for (const target of matchAll(command, pathPattern)) {
            if (/^https?:\/\/$/i.test(target[1] || '')) {
                continue;
            }
            if (!commandPathExtensions.includes(target[3].toLowerCase())) {
                continue;
            }
            const relative = target[2].split('/').join(sep);
            const exists = isFile(join(repoRoot, relative)) || isFile(join(planRoot, relative));
            check(exists, `[Check 13] ${validationId} names missing path ${relative}.`);
        }

        // Project-specific extension point, per row (checks 14-17).
        if (localRowCheck) {
            try {
                await localRowCheck({ row, command, sandbox, ...localContext });
            } catch (error) {
                check(false, `[Local] checkValidationRow failed on ${validationId}: ${error.message}`);
            }
        }
    }
    // Project-specific extension point, across rows (ordering invariants).
    if (localMatrixCheck) {
        try {
            await localMatrixCheck({ rows: validationRows, ...localContext });
        } catch (error) {
            check(false, `[Local] checkValidationMatrix failed: ${error.message}`);
        }
    }

    // 24-26: contract source freshness, consumer census, and covering-test resolution.
    for (const contract of matchAll(packets, /^###\s+(C\d+):[^\r\n]*\r?\n(.*?)(?=^###\s+|^##\s|(?![\s\S]))/gms)) {
        const contractId = contract[1];
        const body = contract[2];
        const source = /Contract source:\s*`?([^`\r\n:]+\.[A-Za-z0-9]+):(\d+)`?\s*\(read\s+(\d{4}-\d{2}-\d{2})\)/i.exec(body);
        if (source) {
            const sourceRelative = source[1];
            const sourceLine = Number(source[2]);
            const readDate = source[3];
            const sourcePath = join(repoRoot, sourceRelative.split('/').join(sep));
            check(isFile(sourcePath), `[Check 24] ${contractId} source file does not exist: ${sourceRelative}.`);
            if (isFile(sourcePath)) {
                const sourceLines = readLines(sourcePath);
                check(sourceLine >= 1 && sourceLine <= sourceLines.length, `[Check 24] ${contractId} source line ${sourceLine} is outside ${sourceRelative}.`);
                const modifiedDate = localDate(statSync(sourcePath).mtime);
                check(modifiedDate <= readDate, `[Check 24] ${contractId} is stale: ${sourceRelative} changed after ${readDate}.`);
            }
        } else {
            check(false, `[Check 24] ${contractId} lacks Contract source: file:line (read YYYY-MM-DD).`);
        }

        const census = /Consumer census:\s*(.+?)(?=Pre-authorized ownership expansion:|Covering tests:|(?![\s\S]))/is.exec(body);
        if (census) {
            for (const entry of matchAll(census[1], /`([^`:\r\n]+\.[A-Za-z0-9]+):(\d+)`(?:\s*:\s*`([^`\r\n]+)`)?/gm)) {
                const relative = entry[1];
                const lineNumber = Number(entry[2]);
                const snippet = normalizeText(entry[3]);
                const consumerPath = join(repoRoot, relative.split('/').join(sep));
                check(isFile(consumerPath), `[Check 25] ${contractId} consumer file does not exist: ${relative}.`);
                if (isFile(consumerPath)) {
                    const consumerLines = readLines(consumerPath);
                    check(lineNumber >= 1 && lineNumber <= consumerLines.length, `[Check 25] ${contractId} consumer line ${lineNumber} is outside ${relative}.`);
                    if (snippet && lineNumber >= 1 && lineNumber <= consumerLines.length) {
                        check(normalizeText(consumerLines[lineNumber - 1]).includes(snippet), `[Check 25] ${contractId} consumer snippet no longer matches ${relative}:${lineNumber}.`);
                    }
                }
            }
        } else {
            check(false, `[Check 25] ${contractId} lacks a Consumer census.`);
        }

        const covering = /Covering tests:\s*(.+?)(?=^-\s|(?![\s\S]))/ims.exec(body);
        if (covering) {
            for (const entry of matchAll(covering[1], /`([^`\r\n]+\.[A-Za-z0-9]+)(?::\d+)?`/g)) {
                const relative = entry[1];
                check(isFile(join(repoRoot, relative.split('/').join(sep))), `[Check 26] ${contractId} covering test does not exist: ${relative}.`);
            }
        } else {
            warnings.push(`[Check 26] ${contractId} lacks Covering tests; list the test scripts and scenes that reference the owned files, or None.`);
        }
    }

    if (errors.length > 0) {
        return finish(`FAIL: ${errors.length} shape error(s), ${checks} checks. Shape validation never proves contract truth.`);
    }
    return finish(`PASS: ${checks} workspace-shape checks. This result does not validate contract truth.`);
}

// Run when executed directly; the bin/agrippa-lint wrapper imports main instead.
const entryPath = process.argv[1] ? resolve(process.argv[1]) : '';
if (entryPath && samePath(entryPath, fileURLToPath(import.meta.url))) {
    main(process.argv.slice(2)).then(
        (code) => {
            process.exitCode = code;
        },
        (error) => {
            process.stderr.write(`agrippa-lint: ${error.stack || error}\n`);
            process.exitCode = 1;
        },
    );
}
