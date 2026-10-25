// Project-specific checks for the agrippa plugin's plan-workspace linter.
// Optional.
//
// Install as `tools/validate_plan_workspace.local.mjs` only when this repository
// has command invariants worth enforcing in every plan's validation matrix; with
// no such invariant, do not install it. The linter, which runs from the plugin
// as `agrippa-lint`, imports this file from `<repository root>/tools/` when it
// exists. A plugin upgrade replaces the linter and never this file.
//
// Every export is optional:
//
// - `commandPathExtensions`: an array of lower-case extensions that replaces the
//   list check 13 verifies (which source or test paths inside a validation
//   command must exist).
// - `checkValidationRow({ row, command, sandbox, check, repoRoot, planRoot })`:
//   called once per validation-matrix row. `row` is the row keyed by the
//   table's header text (`row['Validation ID']`, `row['Exact command or
//   check']`); `command` and `sandbox` are that row's command and Sandbox (or
//   older Environment) cells; `check(condition, message)` records one check and
//   its failure message.
// - `checkValidationMatrix({ rows, check, repoRoot, planRoot })`: called once
//   with every row, in matrix order, for ordering invariants.
//
// Typical invariants: one required launcher or wrapper binary instead of a bare
// name on PATH, an invocation shape per test kind, a required working directory
// for one runner, a required Sandbox value, and a prerequisite command that must
// come before the first test. Label failures "[Check 14]" to "[Check 17]" so
// they sort with the linter's own checks.
//
// The function bodies below are the worked example from the Godot repository the
// kit was extracted from. Replace them with this repository's rules; keep the
// export names and parameters.

// Optional: narrow or extend the command-path extensions check 13 verifies.
// export const commandPathExtensions = ['gd', 'tscn', 'py', 'ps1', 'toml', 'md'];

// A row is an engine row when it launches the console binary or runs a
// resource script or scene headless. Both functions use this one definition.
const engineRowPattern = /Godot_[^\s`]*_console\.exe|--headless\s+[^`]*res:\/\/[^\s`]+\.(?:gd|tscn)/i;

function commandOf(row) {
    const command = row['Exact command or check'];
    return command === undefined || command === null ? '' : String(command);
}

export function checkValidationRow({ row, command, sandbox, check }) {
    const id = row['Validation ID'];

    // Every engine row uses one exact console binary and runs outside the
    // sandbox, because the engine writes caches outside the workspace.
    if (engineRowPattern.test(command)) {
        check(command.includes('[PROJECT: exact console binary path]'), `[Check 14] ${id} must use the real console binary.`);
        check(!/(?:^|[;&]\s*|`)\s*godot\s/i.test(command), `[Check 14] ${id} uses a bare launcher name.`);
        check(sandbox.toLowerCase() === 'outside-sandbox', `[Check 14] ${id} must declare outside-sandbox.`);
    }

    // A script target takes -s and no frame cap; a scene target takes a
    // numeric frame cap.
    if (/res:\/\/[^\s`]+\.gd/i.test(command)) {
        check(/(?:^|\s)-s(?:\s|$)/.test(command), `[Check 15] ${id} targets a script without -s.`);
        check(!/--quit-after/.test(command), `[Check 15] ${id} script invocation must not use --quit-after.`);
    }
    if (/res:\/\/[^\s`]+\.tscn/i.test(command)) {
        check(/--quit-after\s+\d+/.test(command), `[Check 15] ${id} scene invocation requires a numeric --quit-after.`);
    }
}

export function checkValidationMatrix({ rows, check }) {
    // The class-cache prelude must be the first engine row.
    const engineRows = rows.filter((row) => engineRowPattern.test(commandOf(row)));
    if (engineRows.length > 0) {
        check(/--headless\s+--editor\s+--path\s+\.\s+--quit-after\s+\d+/.test(commandOf(engineRows[0])), '[Check 16] The class-cache prelude must precede the first engine test.');
    }
}
