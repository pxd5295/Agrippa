# Working on Agrippa

This repository develops the planning methodology kit, which is also the
`agrippa` plugin, in `plugins/agrippa/`. Its development-only files, the
self-check and the smoke-test fixture, are in `dev/`. It is not itself an
installed copy: there is no root `AGENTS.md`, and the templates are the
product, not instructions for this session.

- Everything under `plugins/agrippa/` must stay project-neutral.
  Project facts appear only as `[PROJECT: ...]` slots with an example; plain
  `[...]` is filled per plan. See the kit README's placeholder convention.
- Old-toolchain vocabulary (the G1 dual-toolchain terms) may appear only in
  `plugins/agrippa/UPGRADING.md` and `dev/validate-kit.ps1`.
  `history/` is exempt because it is not shipped.
- Never edit files under `history/plans/`. They are dated records.
- All PowerShell (now only under `dev/`) must stay Windows PowerShell
  5.1-clean: no `&&`/`||`, no ternary or null-coalescing operators, and no
  `$PSScriptRoot` in a parameter default (5.1 leaves it empty there).
- The plugin ships no PowerShell. Its hook scripts and the plan linter are
  Node ES modules (`.mjs`) that use only Node's built-in modules, so the same
  command runs on every OS and the plugin needs no `npm install`. The
  `bin/agrippa-lint` wrapper is an extensionless Node script, so it is written
  as CommonJS and imports the linter dynamically.
- After any change to the kit or to `dev/`, run `dev/validate-kit.ps1` and
  report its last line. A new template file must also be added to the kit
  README's layout table, or the self-check fails.
- When a change alters the linter, also prove it on a real installed
  repository with `dev/validate-kit.ps1 -InstalledRepo <path>`, and lint one
  of that repository's recent plan workspaces. The smoke fixture alone does
  not cover project rules.
- `docs/design-notes.md` and `docs/research-2026-08.md` record why rules
  exist. Update them when a rule's reason changes.
