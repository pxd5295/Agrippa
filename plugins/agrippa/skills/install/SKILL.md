---
name: install
description: Install the Agrippa planning methodology in a repository that has none. Writes the project-side documents from the plugin's templates with facts discovered in the repository, and enables the plugin in the committed .claude/settings.json. Run it only when the user explicitly asks, by typing /agrippa:install or by asking to install Agrippa in this repository; never load it on your own initiative.
argument-hint: "[release tag to pin, default v<plugin version>]"
---

# Install the Agrippa methodology

This skill installs the methodology in the repository at the current git
top-level folder. Installing authorizes planning and configuration changes
only. Never change application code, and preserve every unrelated user
change, including uncommitted ones.

The plugin already provides the core rules, the agents, the skills, the plan
templates, the plan-workspace and decision-record rules, the linter, and the
spawn logger. The project keeps only its own facts, plus two short pointer
READMEs for people who browse it without the plugin. So this skill writes
project documents and settings, and never copies a plugin file into the
repository.

The kit files this skill uses are in the plugin:

| File | Use |
|---|---|
| `${CLAUDE_PLUGIN_ROOT}/README.md` | The layout table, "Enabling the plugin in a project", the placeholder convention, and the install-marker scan |
| `${CLAUDE_PLUGIN_ROOT}/ADOPTION-CHECKLIST.md` | Every item is done or reported at the end |
| `${CLAUDE_PLUGIN_ROOT}/templates/` | The project-side documents |
| `${CLAUDE_PLUGIN_ROOT}/templates/hooks/README.md` | The spawn-logger opt-in, the edit-lint hook rules, and the permission allowlist |
| `${CLAUDE_PLUGIN_ROOT}/skills/plan/reference/agent-workflow.md` | Its "Validation matrix values" section, which defines the Sandbox and Determinism values the command catalog records |
| `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` | The plugin version, which names the release tag to pin |

## 1. Check that this is a new install

Run `git rev-parse --show-toplevel` and work from that folder. If it is not a
git repository, stop and say so.

Stop and recommend `/agrippa:upgrade` instead if the repository already has
planning rules: an `AGENTS.md` or `CLAUDE.md` with a planning trigger, dated
`plans/YYYY-MM-DD-*` workspaces, copies of the plugin's agents or skills under
`.claude/`, or any marker in the generation table of
`${CLAUDE_PLUGIN_ROOT}/UPGRADING.md`. An upgrade protects dated plans and maps
old rules before it edits anything; an install does not.

A `.claude/settings.json` that already declares the `agrippa` marketplace or
enables `agrippa@agrippa` is not by itself a reason to stop. That is how the
plugin is often enabled for this very session, and step 6 handles the entry.

## 2. Read the kit

Read the README, the adoption checklist, and every file under `templates/`
completely before changing anything. The installed documents must match these
templates. Adapt only the install-time slots that the README's placeholder
convention describes, or what conflicts with an existing stricter rule in the
repository. An example from the source repository outside a slot sits in an
`Install note` comment: use it only as a shape, and never install it, because
it holds another project's facts.

## 3. Discover the repository, read-only

Change nothing in this step. Record:

- every existing `AGENTS.md` and `CLAUDE.md`, at any depth;
- `.claude/settings.json` and `.claude/settings.local.json` (hooks,
  permissions, `env`, marketplaces, enabled plugins), and any agents, skills,
  or commands under `.claude/`;
- the languages, build systems, test runners, and lint and typecheck tools,
  with the exact command for each. Run each command once to prove it works,
  and note what it needs: working directory, prerequisites, network, GPU,
  display, or services;
- the natural ownership areas;
- shared interfaces (public APIs, schemas, protocols, persisted formats, saved
  configuration, ABIs, layouts) and their consumers;
- base classes, hooks, configuration layers, registration funnels, and
  hot-path subsystems, for the "Architecture owners" table;
- any MCP server that observes the running application, for `live-app.md`;
- the tests that are red at `HEAD`;
- the dirty worktree, from `git status`.

You may delegate read-only discovery of large areas to subagents and keep only
their conclusions.

## 4. Ask about material choices

Use `AskUserQuestion` only for choices the repository cannot answer, and
recommend an option for each. It takes at most four questions per call, so
split a longer list across calls. Without `AskUserQuestion`, ask the same
focused questions in chat. The usual questions are:

- ownership boundaries that are ambiguous;
- which interfaces count as frozen;
- the risk classes that apply;
- whether to survey the folders into `docs/agent_memory/area-map.md` once the
  documents are written. The map is optional and read only during planning;
  recommend it for a repository with more than a handful of folders;
- whether to turn on the plugin's spawn logger;
- whether to write an edit-lint hook;
- whether to add the permission allowlist from `templates/hooks/README.md`.
  Never add a permission rule, and never set a permission mode, without a yes
  to this question.

## 5. Write the project documents

Write every layout-table row whose destination is a repository path, except
`docs/planning/MIGRATION.md`, which is for upgrades only.

- Follow the README's placeholder convention. Resolve every install-time slot
  from what step 3 found, using the template's example only as a shape.
- When a subject does not exist here, follow the README rule "When a subject
  does not apply": delete the slot with its sentence, bullet, table row, or
  optional block; write `None` only where the slot offers it; keep section
  headings, with one sentence under a heading whose content all went.
- Fill the Sandbox and Determinism columns of the command catalog in
  `validation-commands.md` with the values "Validation matrix values" in the
  `plan` skill's `agent-workflow.md` defines, from what step 3 found about
  each command. The project documents hold the repository's facts only; the
  rules for using them already ship in the plugin's skills, so never copy a
  rule into them.
- Delete every `Install note` line or comment, including the example comments,
  once its file is filled.
- Merge into an existing `AGENTS.md` or `CLAUDE.md`; never drop the
  repository's own rules. Keep the stricter rule when the two disagree.
- Write `plans/README.md` and `docs/decisions/README.md` from their templates
  unchanged. They only say what each folder holds and where the rules are;
  never add rules to them.
- Write a per-directory `CLAUDE.md` only for an ownership area with real rules
  to state.
- Write `docs/agent_memory/live-app.md` only when the project has an MCP
  server that observes the running application, and list every one of its
  authoring tools there.
- Write `docs/agent_memory/area-map.md` only when the user said yes in step
  4, and only by loading `agrippa:survey` and following it from its discovery
  step; never fill `templates/AREA-MAP.md` by hand. Skip it otherwise; the
  planner and `agrippa:repo-scout` treat a missing map as "no map".
- Write `tools/validate_plan_workspace.local.mjs`, from
  `templates/validate-plan-workspace.local.mjs`, only when the repository has
  command invariants worth enforcing in every plan. Never copy or edit the
  shared linter.
- If the user chose an edit-lint hook, write its script under `tools/`
  following every rule in `templates/hooks/README.md`. Prove it by making one
  deliberate lint error and reverting it, or leave it unwired and say so.
- Never copy the plugin's agents, skills, linter, or spawn logger into
  `.claude/` or `tools/`.

## 6. Change `.claude/settings.json`, after showing every change

Build the new content of the committed `.claude/settings.json` by merging into
the existing file. Never replace or reorder its other entries, and never touch
`.claude/settings.local.json`.

1. If an `agrippa` marketplace entry already exists, for example a local
   directory that enabled the plugin for this session, show it and ask whether
   to keep it or replace it with the pinned GitHub entry. If the user keeps
   it, skip item 2.
2. Add or replace `extraKnownMarketplaces.agrippa` with the source from the
   README section "Enabling the plugin in a project". Set its `ref` to the
   release tag: the skill argument if one was given, otherwise `v` followed by
   the `version` in `plugin.json`. Check that the tag exists with
   `git ls-remote --tags https://github.com/pxd5295/Agrippa <tag>`. If it does
   not, ask the user which ref to pin, and never leave the entry unpinned
   without their yes.
3. Add `"agrippa@agrippa": true` under `enabledPlugins`.
4. If the user chose the spawn logger, add `"AGRIPPA_SPAWN_LOG": "1"` to the
   `env` block and `subagent-spawns.log` to `.gitignore`.
5. If the user chose an edit-lint hook and it is proved, add its `PostToolUse`
   entry to `hooks`.
6. If the user said yes to the permission allowlist, add those rules to
   `permissions.allow`, including `Bash(agrippa-lint:*)` and the exact test and
   build executables from `validation-commands.md`.

Before writing, show the user the file's current content and the complete
proposed content, or a diff of the two, and list every added key in plain
words. List permission rules apart from the other changes. Then ask with
`AskUserQuestion` whether to write it, and write nothing until the answer is
yes. Write valid JSON with two-space indentation and no byte-order mark.

When nothing changes, for example because the user kept the existing entry
and declined every option, show the current file, say that it stays as it
is, and ask nothing.

## 7. Validate

Run each check below and paste the exact command and its result.

- **Install-marker scan.** Run the scan the README describes under
  "Install-marker scan" over every file of the repository. It must find
  nothing.
- **Project documents.** `docs/agent_memory/project-contracts.md` and
  `docs/agent_memory/validation-commands.md` exist, and each fact in them was
  checked against the code.
- **Settings.** `.claude/settings.json` parses as JSON, declares
  `extraKnownMarketplaces.agrippa`, and enables `agrippa@agrippa`. A `github`
  or `git` source must carry a `ref`. A local `directory` source the user
  chose to keep has none; report it as unpinned and say it must become the
  pinned GitHub entry before collaborators use the repository.
- **No local copies.** `.claude/agents/`, `.claude/skills/`, and
  `.claude/commands/` hold nothing named after a plugin agent or skill, and
  `tools/` has no `validate_plan_workspace.ps1`, `log_subagent_spawns.ps1`, or
  `hook_payload.ps1`. `plans/README.md` and `docs/decisions/README.md` match
  their pointer templates.
- **Validation commands.** Each command in `validation-commands.md` was run
  once before this step, and its result is recorded. Run any command that
  step 5 added to the catalog and step 3 did not run.
- **Local linter checks.** If `tools/validate_plan_workspace.local.mjs` was
  written, write one small real plan workspace for a trivial change, lint it
  through the Bash tool with `agrippa-lint -PlanPath plans/<name>`, and delete
  the workspace afterwards. `agrippa-lint` is on the Bash tool's PATH only.

Then ask the user whether to commit the installed files and
`.claude/settings.json` in one commit. The settings take effect for
collaborators only once the file is committed and they trust the folder.

Finally, give the user the two development checks, which run from a checkout
of the Agrippa repository at the pinned tag. If the user names such a checkout,
or one exists next to this repository with `dev/validate-kit.mjs` in it, run
them yourself and paste the results, unless the user said they will run them.
Both are read-only for this repository; the smoke test removes the workspace
it writes. Otherwise print them for the user, with both paths filled in:

```text
node <Agrippa>/dev/validate-kit.mjs -InstalledRepo <this repository>
node <Agrippa>/dev/fixtures/run-smoke-test.mjs -RepoRoot <this repository>
```

Both must print `PASS`. `-InstalledRepo` also fails until
`.claude/settings.json` is committed.

## 8. Report

Report the files written, each project-specific adaptation with the evidence
behind it, every settings change, and every item in the adoption checklist as
done or not done with the reason. Items that describe the plugin's own
behavior, such as "Planning behavior" and "Routing, execution, and quality",
cannot be verified at install time. Report each of them as provided by the
plugin and not yet verified, pending the live "Make a plan" check.

Say that the plugin loads in a new session once the folder is trusted, and
name the one live check left for the user: a real "Make a plan" request.
Shape checks do not prove that the contracts are true. Do not call the install
complete while any checklist item is unreported.
