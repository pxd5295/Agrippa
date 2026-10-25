# Working on Agrippa

This repository develops the planning methodology kit, which is also the
`agrippa` plugin, in `plugins/agrippa/`. Its development-only files, the
self-check and the smoke-test fixture, are in `dev/`. It is not itself an
installed copy: there is no root `AGENTS.md`, and the templates are the
product, not instructions for this session.

- Everything under `plugins/agrippa/` must stay project-neutral.
  Project facts appear only as `[PROJECT: ...]` slots with an example; plain
  `[...]` is filled per plan. See the kit README's placeholder convention.
- Old-toolchain vocabulary (the G1 dual-toolchain terms) and the names of the
  plugin's former Node scripts may appear only in
  `plugins/agrippa/UPGRADING.md` and `dev/validate-kit.mjs`; the linter may
  name the old local-checks file it detects. `history/` is exempt because it
  is not shipped.
- Never edit files under `history/plans/`. They are dated records.
- The repository has no PowerShell, and the plugin needs no Node. The
  plugin's hook scripts and the `bin/agrippa-lint` wrapper are POSIX `sh`
  scripts (sed, awk, and tr only, no bashisms, because macOS `/bin/sh` may be
  bash 3.2 or dash), and the plan linter and the local-checks template are
  Perl 5.30 or newer using only core modules, so they run on what Git for
  Windows, macOS, and Linux already provide. Write them as ASCII, escaping
  any non-ASCII character, and pass a regex match to `$check->(...)` wrapped
  in `scalar()`, because a bare match is an empty list in argument position
  when it fails. The development tools under `dev/` are Node ES modules
  (`.mjs`) that use only Node's built-in modules and find `sh` and `perl`
  through `dev/tool-paths.mjs`.
- After any change to the kit or to `dev/`, run `node dev/validate-kit.mjs`
  and report its last line. A new template file must also be added to the kit
  README's layout table, or the self-check fails.
- When a change alters the linter, also prove it on a real installed
  repository with `node dev/validate-kit.mjs -InstalledRepo <path>`, and lint one
  of that repository's recent plan workspaces. The smoke fixture alone does
  not cover project rules.
- `docs/design-notes.md` and `docs/research-2026-08.md` record why rules
  exist. Update them when a rule's reason changes.
