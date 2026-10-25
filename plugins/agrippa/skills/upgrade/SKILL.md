---
name: upgrade
description: Upgrade a repository's planning methodology to the Agrippa plugin, from an earlier copied-in Agrippa kit, an older generation, a drifted install, or a different planning process. Maps every old rule before editing, never touches dated plan workspaces, and confirms every deletion. Run it only when the user explicitly asks, by typing /agrippa:upgrade or by asking to upgrade this repository to Agrippa; never load it on your own initiative.
argument-hint: "[release tag to pin, default v<plugin version>]"
---

# Upgrade to the Agrippa plugin

This skill upgrades the methodology in the repository at the current git
top-level folder. Upgrading authorizes planning and configuration changes
only. Never change application code, and preserve every unrelated user
change, including uncommitted ones.

Four safeguards hold for the whole upgrade:

- A SHA-256 manifest of every dated plan workspace is recorded before the
  first edit and compared after the last one.
- The rule mapping is shown to the user before any edit.
- Every deletion is confirmed by the user with `AskUserQuestion`.
- A dated plan workspace is never edited, moved, renamed, or converted.

The kit files this skill uses are in the plugin:

| File | Use |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/UPGRADING.md` | The generation markers and the rule mapping for each generation, including "From G3", "From G4 v0.1.0", "From G4 v0.1.1", "From G4 v0.1.2", and "From G4 v0.2.0" |
| `${CLAUDE_PLUGIN_ROOT}/README.md` | The layout table, "Enabling the plugin in a project", the placeholder convention, and the install-marker scan |
| `${CLAUDE_PLUGIN_ROOT}/ADOPTION-CHECKLIST.md` | Every item is done or reported at the end |
| `${CLAUDE_PLUGIN_ROOT}/templates/` | The project-side documents, including `MIGRATION.md` |
| `${CLAUDE_PLUGIN_ROOT}/templates/hooks/README.md` | The spawn-logger opt-in, the edit-lint hook rules, and the permission allowlist |
| `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` | The plugin version, which names the release tag to pin |

## 1. Read the kit

Run `git rev-parse --show-toplevel` and work from that folder. Read
`UPGRADING.md`, the README, the adoption checklist, and every file under
`templates/` completely before changing anything. The result must match these
templates. Adapt only the install-time slots that the README's placeholder
convention describes, or what an existing stricter rule overrides.

## 2. Inventory the current methodology, read-only

Change nothing in this step. Record:

- every `AGENTS.md` and `CLAUDE.md`, at any depth;
- everything under `.claude/`: agents, skills, commands, and the hooks,
  permissions, `env`, marketplaces, and enabled plugins in `settings.json` and
  `settings.local.json`;
- any other toolchain's configuration or agent profiles, using the markers
  table in `UPGRADING.md`;
- planning guides, routing documents, templates, shortcuts, and validators,
  and the scripts under `tools/` that hooks run;
- `.agrippa/`, the folders under `docs/` that "From G4 v0.2.0" in
  `UPGRADING.md` names for a plugin before 0.3.0, or the equivalent contract
  documents;
- decision records;
- every dated plan workspace root, usually `plans/YYYY-MM-DD-*`;
- the validation commands actually in use, each run once;
- the dirty worktree, from `git status`.

Identify the generation with the markers table in `UPGRADING.md`, and list
every marker found. A repository can mix generations, so treat every marker as
something to map.

Before the first edit, record the SHA-256 manifest of every file under the
dated plan workspaces. They are often gitignored, so `git status` cannot prove
they were left alone. Write the manifest outside the repository, for example
in your scratchpad or the system temp folder, and run this from the repository
root with each workspace root found above in place of `plans`:

```powershell
Get-ChildItem -LiteralPath plans -Directory | Where-Object { $_.Name -match '^\d{4}-\d{2}-\d{2}-' } | Get-ChildItem -Recurse -File | Sort-Object FullName | ForEach-Object { (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash + '  ' + $_.FullName } | Set-Content -Encoding utf8 <manifest-before.txt>
```

Say in chat how many files the manifest lists and where it is.

## 3. Write the rule mapping, show it, and ask

Before any edit, write the rule mapping: one row per existing rule or artifact,
with its disposition (Retain, Merge, Replace, or Deprecate), its new location,
and the reason. Start from the mapping tables in `UPGRADING.md` for each
generation found. For a copied-in Agrippa kit, the "From G3" table says which
copied files are deleted and which project facts move into which project
document. Keep the stricter rule whenever old and new disagree.

Show the whole mapping to the user. Then ask with `AskUserQuestion`:

- about every material conflict between an old rule and a new one;
- about every file you propose to delete. Each file is its own option or its
  own question, so the user can keep any one of them. Never offer a single
  "delete all" choice;
- about removing project-wide model or reasoning-effort pins and old toolchain
  configuration;
- about the optional spawn logger, the edit-lint hook, and the permission
  allowlist, as `/agrippa:install` does. Never add a permission rule, and
  never set a permission mode, without a yes to this question.

`AskUserQuestion` takes at most four questions per call, so split a longer
list across calls. Without `AskUserQuestion`, ask the same questions in chat.
Wait for every answer before step 4.

## 4. Apply the mapping

- Write or update every layout-table row whose destination is a repository
  path, including `docs/planning/MIGRATION.md` filled from its template.
- Follow the README's placeholder convention, including its rule "When a
  subject does not apply", and never install an `Install note` example
  comment. Carry over the project facts the old methodology already recorded
  (ownership areas, shared interfaces, commands, known traps) rather than
  rediscovering them. A copied-in agent or
  skill that was filled at install time is a data source: move each of its
  project facts into the document section "From G3" names before deleting it.
- Move the project documents and the decision records into `.agrippa/` with
  `git mv`, as "From G4 v0.2.0" in `UPGRADING.md` says, write
  `.agrippa/CLAUDE.md` from `templates/agrippa-CLAUDE.md`, and replace every
  reference to the old paths outside dated plan workspaces and decision
  records. `git grep` finds the references; command-line `rg` skips the hidden
  folder unless given `--hidden`.
- Replace a full copy of `plans/README.md` or `.agrippa/decisions/README.md` with
  the short pointer from its template, and delete `docs/planning/CLAUDE.md`
  once the user confirms, as "From G4 v0.1.0" in `UPGRADING.md` says. Move
  any project rule added to those files into `AGENTS.md` first.
- Move project-specific checks that an old linter enforced into
  `tools/validate_plan_workspace.local.mjs`, written from
  `templates/validate-plan-workspace.local.mjs`. A
  `tools/validate_plan_workspace.local.ps1` from a plugin before 0.2.0 is
  ported with the "From G4 v0.1.2" table in `UPGRADING.md`: write the `.mjs`
  with the same rules and messages, then delete the `.ps1` once the user
  confirms. The shared linter runs from the plugin; never hand-merge it.
- Change `.claude/settings.json` exactly as step 6 of the install skill,
  `${CLAUDE_PLUGIN_ROOT}/skills/install/SKILL.md`, describes: merge into the
  existing file, add `extraKnownMarketplaces.agrippa` with its `ref` pinned to
  the release tag, enable `agrippa@agrippa`, show the current and complete
  proposed content, and write nothing until the user says yes. In the same
  change, remove the hook entries and permissions that run a deleted local
  copy, if the user confirmed those deletions, and replace a permission for
  the local linter with `Bash(agrippa-lint:*)`.
- Delete only the files the user confirmed in step 3. List every other
  deprecated file under "Deprecated, awaiting confirmation" in `MIGRATION.md`.
- Keep a helper script that a project script still uses, even when "From G3"
  lists it as a deletion. For example, an edit-lint hook may dot-source
  `tools/hook_payload.ps1`.
- Never edit, move, rename, or convert a dated plan workspace. Old workspaces
  failing the new linter is expected; record it and do not fix them.

## 5. Validate

Run each check below, paste the exact command and its result, and record all
of it in `docs/planning/MIGRATION.md`.

- **Dated-plan manifest.** Recompute the manifest with the same command into a
  second file, and compare the two files. They must be identical.
- **Install-marker scan.** Run the scan the README describes under
  "Install-marker scan" over every file of the repository outside dated plan
  workspaces. It must find nothing.
- **Old-toolchain markers.** A search of `AGENTS.md`, `CLAUDE.md`, `docs/`,
  `.agrippa/`, and `.claude/` for the markers `UPGRADING.md` lists for the
  generations found, and for the old project-document paths, must find
  nothing outside `MIGRATION.md`, dated plan workspaces, and decision
  records. Use `git grep`, which searches the hidden folders.
- **Local linter checks.** If `tools/validate_plan_workspace.local.mjs`
  exists, lint one recent existing workspace through the Bash tool with
  `agrippa-lint -PlanPath plans/<name>`. It must report no `[Local]` error and
  no error from the local checks themselves. Freshness errors on plans that
  have landed are expected.
- **Validation commands.** Each command in `validation-commands.md` was run
  once, and its result is recorded.

Then ask the user whether to commit the upgrade in one commit.

Finally, give the user the two development checks, which run from a checkout
of the Agrippa repository at the pinned tag. If the user names such a checkout,
or one exists next to this repository with `dev/validate-kit.mjs` in it, run
them yourself and paste the results. Otherwise print them for the user, with
both paths filled in:

```text
node <Agrippa>/dev/validate-kit.mjs -InstalledRepo <this repository>
node <Agrippa>/dev/fixtures/run-smoke-test.mjs -RepoRoot <this repository>
```

Both must print `PASS`. `-InstalledRepo` also fails until
`.claude/settings.json` is committed.

## 6. Report

Report the generation found and its markers, the mapping, the files changed and
deleted, each adaptation and its evidence, every settings change, every item in
the adoption checklist as done or not done with the reason, anything
deprecated but not yet deleted, and the live checks left for the user. Say
that old workspaces failing the new linter is expected.
