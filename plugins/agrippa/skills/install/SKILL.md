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
| `${CLAUDE_PLUGIN_ROOT}/templates/hooks/README.md` | The spawn-logger opt-in, the low-usage mode opt-in, the edit-lint hook rules, and the permission allowlist |
| `${CLAUDE_PLUGIN_ROOT}/skills/plan/reference/agent-workflow.md` | Its "List the open decisions, then interview" section, the procedure step 4 follows, and its "Validation matrix values" section, which defines the Sandbox and Determinism values the command catalog records |
| `${CLAUDE_PLUGIN_ROOT}/.claude-plugin/plugin.json` | The plugin version, which names the release tag to pin |

## 1. Check Perl, and that this is a new install

Run `perl --version` through the Bash tool first. The plugin's hooks are
POSIX sh scripts and run wherever the Bash tool does, so the core rules and
the spawn logger need nothing more. The shared linter and `agrippa-lint` run
on Perl, and nothing else checks for it, so a missing Perl fails only when a
plan's linter row runs: `agrippa-lint` prints one line saying perl is not on
PATH and exits 2. Claude Code itself does not need Perl, so a machine can
lack it. On Windows it comes with Git for Windows, which the Bash tool needs
anyway; macOS and Linux ship it. The README's "Requirements and fallbacks"
section records the requirement.

If the command fails, say so in plain words, then ask with `AskUserQuestion`
which of two options to take, and recommend the first:

1. **Install Perl now, then run the install again.** On Windows, perl is part
   of a standard Git for Windows install, not of MinGit, so install or
   repair Git for Windows with `winget install Git.Git`, where the installer
   shows an elevation prompt the user must accept. On macOS it ships with
   the system; if it is missing, `brew install perl`. On Linux install the
   distribution's `perl` package. Run the command only after the user's yes,
   and never download and run an installer yourself; without a package
   manager, print the command for the user to run. Then stop. Say that a
   running process keeps the PATH it started with, so this session's
   `agrippa-lint` cannot see the new `perl`, and that the user must open a
   new session and run `/agrippa:install` again from the start there.
2. **Install the documents anyway.** Continue through every step with Perl
   missing, and write the project documents and settings as usual. Never
   write a copy of a hook script or the linter into the project; the plugin's
   own scripts run from its cached copy, and `/agrippa:upgrade` cannot
   maintain a copy. In step 7, report every item that runs the linter as not
   run. In step 8, report every "Offline validation" item that runs the
   linter as not done with the reason "Perl is not installed". Say that
   `agrippa-lint` stays inactive until Perl is installed and a new session is
   opened, and that no project file changes when it is.

A no to both is a stop: write nothing.

Then run `git rev-parse --show-toplevel` and work from that folder. If it is
not a git repository, stop and say so.

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

## 4. Interview: list the open decisions, then ask

The install interview follows the same procedure as the planning interview
("List the open decisions, then interview" in the `plan` skill's
`agent-workflow.md`). It ends when no decision is left for the user to make,
never after a set number of rounds, and every decision is recorded.

1. **List the open decisions.** Write one entry per install-time slot in the
   templates, from what step 3 found. Mark each entry `inspection` when the
   code or configuration can answer it, or `user` when only a person who
   works in the repository can. The table below says which slots are usually
   which.
2. **Resolve every inspection entry by reading.** Never put one to the user.
   An entry that reading cannot settle moves to the user group with the
   evidence so far.
3. **Draft before asking.** Draft the ownership areas, the shared interfaces,
   the risk classes, and the architecture-owner rows from the inspection
   entries, in memory, not yet written. A user question about one of these
   shows the draft row with its evidence and asks the user to accept it or
   name the correction, because confirming a draft is easier than answering a
   blank.
4. **Ask in rounds.** Put the user entries to the user with `AskUserQuestion`,
   in the rounds below. It takes at most four questions per call and two to
   four options per question, so a round that needs more is split across
   calls. The recommended option is first and is marked `(Recommended)`, with
   its tradeoff in one sentence in its description. Where the template slot
   offers `None`, one option is "None for this project", so a deleted section
   is a recorded answer and never a guess. Rounds continue while user entries
   remain, including entries that an answer exposes. Without
   `AskUserQuestion`, ask the same focused questions in chat and record the
   answers the same way.
5. **End on an empty list.** The interview ends when the user group is empty,
   or when the user says to proceed on the recommendations. An entry still
   unresolved at that point takes the recommended option with
   `Resolved by: default`. It is never dropped.
6. **Record every entry**, including the ones inspection settled, as a row of
   the "Interview decisions" table in `.agrippa/INSTALL.md`, with
   `Resolved by` set to `inspection`, `user`, or `default`. A row resolved by
   inspection says what was read. A fact the user supplied and the code cannot
   confirm is marked `(per maintainer, YYYY-MM-DD)` where it lands in the
   project documents, so a later reader can tell it from a `file:line` fact.

**Round 0, the scope of the interview.** One question, first: "Take the
recommended answer for every optional feature, and ask me only about the
project" `(Recommended)`, or "Ask me about each optional feature too". With
the first answer, round 5 asks only about the permission allowlist and the
other five features take their recommended answers with
`Resolved by: default`.

**Round 1, contracts.** Show the drafts and ask to accept or correct:

- the ownership areas, where a folder could belong to more than one area or
  the tests do not line up with the source tree;
- which interfaces are frozen shared interfaces (an API, schema, protocol,
  file format, persisted record, saved configuration, or layout) whose change
  needs a decision record and a consumer census;
- which high-risk change classes apply, and the trigger and gate for each;
- any "Architecture owners" row the code did not settle, for example which
  layer is the performance owner or which subsystem is gated.

**Round 2, the debugging map.** These hold experience, not structure, and
reading code rarely settles them:

- the layers of the main runtime path, in order, with the check at each
  boundary that says which side is wrong;
- the naming convention for temporary probe files;
- the working counterparts a failing path is usually compared against;
- the kinds of difference that have mattered before, for example ordering or
  lifecycle state.

**Round 3, how the tests behave.** For `validation-commands.md`:

- which targets are flaky and get `noisy-retry`, and which are red at `HEAD`
  on purpose, with the date checked;
- messages that mean something specific here, messages that are expected in
  a headless or CI run, and the failure surfaces besides a failing test;
- the invocation mistakes a validator must not make;
- which commands write outside the workspace and so are `outside-sandbox`,
  as "Validation matrix values" in the `plan` skill's `agent-workflow.md`
  defines the two values;
- which measurement is the authoritative evidence for a performance claim.

**Round 4, environment and workflow.**

- whether operating-system screen capture is allowed on this project's
  machines, and how the rendered UI is captured in-app otherwise, for "UI
  capture"; or that the project has no UI;
- where git worktrees live, and the setup gap that breaks a fresh one, for
  "Worktree and integration contracts";
- whether `plans/` is tracked or gitignored. A gitignored `plans/` is why the
  upgrade skill hashes dated workspaces instead of trusting `git status`;
- when step 3 found an MCP server that observes the running application,
  confirm it is the live-app bridge and that the authoring-tool list is
  complete, for `.agrippa/live-app.md`.

**Round 5, the optional features.** Two multi-select questions in one call,
because a question holds at most four options. An unticked box is a no.

- Plugin features: the area map, by loading `agrippa:survey` after the
  documents are written (recommended when the repository has more than a
  handful of folders; the map is optional and read only during planning);
  the spawn logger (recommended; it is silent, gitignored, and shows which
  spawns inherited the lead's model); low-usage mode, for token limits that
  the normal methodology would exhaust (Recommend no. Say in one sentence
  what it trades: fewer review passes, cheaper tiers, one writer per wave,
  and shallower planning reads, as "Low-usage mode" in
  `templates/hooks/README.md` describes. A collaborator with different limits
  can override the committed value in their own `.claude/settings.local.json`);
  and an edit-lint hook (recommend no unless the project already runs a
  per-file linter; the hook is the project's own script, written to the rules
  in `templates/hooks/README.md`).
- Committed settings additions: the `engineering` plugin, whose
  `architecture` and `system-design` skills write decision records (Recommend
  no. Say in one sentence what a yes does: it adds
  `"engineering@claude-plugins-official": true` to the committed
  `enabledPlugins`, so every collaborator who trusts the folder gets the whole
  plugin, its other skills and its MCP servers included, each of which asks
  for its own authorization. Say that without it the `design-first` skill
  gives the shape to write a decision record by hand, and that a person who
  wants the plugin only for themselves runs
  `/plugin install engineering@claude-plugins-official` instead, which leaves
  the committed file alone); and the permission allowlist from
  `templates/hooks/README.md` (recommended; it names only read-only git
  commands, `agrippa-lint`, and the project's own test and build executables).
  Never add a permission rule, and never set a permission mode, without a yes
  to this question; the scope answer in round 0 never stands in for it.

**Which slots are usually which.** The inspection column is answered from
the code in step 2 of the procedure; the user column is asked in the round
named.

| Template section | Usually resolved by |
|---|---|
| `AGENTS.md` ownership bullets; `project-contracts.md` "Ownership areas", "Contract documents", "Shared and public interfaces", "Architecture owners" | inspection, confirmed in round 1 where the evidence is ambiguous |
| `project-contracts.md` "High-risk change classes" | inspection for the rows the code shows (a native build, a schema version, a deployment script); round 1 for the trigger and gate wording |
| `project-contracts.md` "Debugging map" | user, round 2 |
| `project-contracts.md` "Worktree and integration contracts", "Environment boundaries" | inspection for tool versions and generated files; round 4 for worktrees and setup gaps |
| `validation-commands.md` "Command catalog", "Full-suite inventory", "Build", "Run caps", "Session setup", "Runtime writes and caches", "Shared log paths" | inspection: each command was run once in step 3 |
| `validation-commands.md` "Known messages", "Failure surfaces", "Invocation traps", "Performance evidence", known red targets, `noisy-retry` targets | user, round 3 |
| `validation-commands.md` "Sandbox stance" | inspection from what each command wrote when run; round 3 to confirm |
| `validation-commands.md` "UI capture", "Environment limits" | user, round 4, for the capture policy; inspection for the limits a run showed |
| `live-app.md` | inspection by calling the bridge's tools once; round 4 to confirm the authoring-tool list |
| Per-directory `CLAUDE.md` rules and traps | round 2 answers that name one folder; otherwise not written |

## 5. Write the project documents

Write every layout-table row whose destination is a repository path, except
`.agrippa/MIGRATION.md`, which is for upgrades only.

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
- Write `plans/README.md` and `.agrippa/decisions/README.md` from their templates
  unchanged. They only say what each folder holds and where the rules are;
  never add rules to them.
- Write `.agrippa/INSTALL.md` from `templates/INSTALL.md`: the plugin version
  and pinned `ref`, every interview entry from step 4 as a row of its
  "Interview decisions" table, and each optional feature's answer. Its
  "Validation results" table is filled in step 7. It is a record, so nothing
  in it is edited after the install.
- Write a per-directory `CLAUDE.md` only for an ownership area with real rules
  to state.
- Write `.agrippa/live-app.md` only when the project has an MCP
  server that observes the running application, and list every one of its
  authoring tools there.
- Write `.agrippa/area-map.md` only when the user said yes in step
  4, and only by loading `agrippa:survey` and following it from its discovery
  step; never fill `templates/AREA-MAP.md` by hand. Skip it otherwise; the
  planner and `agrippa:repo-scout` treat a missing map as "no map".
- Write `tools/validate_plan_workspace.local.pl`, from
  `templates/validate-plan-workspace.local.pl`, only when the repository has
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
5. If the user chose low-usage mode, add `"AGRIPPA_LOW_USAGE": "1"` to the
   `env` block. Write nothing for a no; an absent variable is normal mode.
6. If the user chose an edit-lint hook and it is proved, add its `PostToolUse`
   entry to `hooks`.
7. If the user chose the `engineering` plugin, add
   `"engineering@claude-plugins-official": true` under `enabledPlugins`. The
   official marketplace is known to Claude Code already, so it needs no
   `extraKnownMarketplaces` entry. Write nothing for a no.
8. If the user said yes to the permission allowlist, add those rules to
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

Run each check below and paste the exact command and its result. If step 1
found no Perl and the user chose to install the documents anyway, report the
"Local linter checks" item and the two development checks at the end as not
run, with the reason "Perl is not installed", instead of running them.

- **Install-marker scan.** Run the scan the README describes under
  "Install-marker scan" over every file of the repository. It must find
  nothing.
- **Project documents.** `.agrippa/project-contracts.md` and
  `.agrippa/validation-commands.md` exist, and each fact in them was
  checked against the code or is marked `per maintainer` with the date.
  `.agrippa/INSTALL.md` exists, and its "Interview decisions" table has a row
  for every install-time slot the templates asked for, each with
  `Resolved by` set.
- **Settings.** `.claude/settings.json` parses as JSON, declares
  `extraKnownMarketplaces.agrippa`, and enables `agrippa@agrippa`. A `github`
  or `git` source must carry a `ref`. A local `directory` source the user
  chose to keep has none; report it as unpinned and say it must become the
  pinned GitHub entry before collaborators use the repository. If the user
  chose the `engineering` plugin, `enabledPlugins` also has
  `"engineering@claude-plugins-official": true`.
- **No local copies.** `.claude/agents/`, `.claude/skills/`, and
  `.claude/commands/` hold nothing named after a plugin agent or skill, and
  `tools/` has no `validate_plan_workspace.ps1`, `log_subagent_spawns.ps1`, or
  `hook_payload.ps1`. `plans/README.md` and `.agrippa/decisions/README.md` match
  their pointer templates.
- **Validation commands.** Each command in `validation-commands.md` was run
  once before this step, and its result is recorded. Run any command that
  step 5 added to the catalog and step 3 did not run.
- **Local linter checks.** If `tools/validate_plan_workspace.local.pl` was
  written, write one small real plan workspace for a trivial change, lint it
  through the Bash tool with `agrippa-lint -PlanPath plans/<name>`, and delete
  the workspace afterwards. `agrippa-lint` is on the Bash tool's PATH only.

Record each check's result in the "Validation results" table of
`.agrippa/INSTALL.md`, with the two development checks below as `Not run`
when they were not.

Then ask the user whether to commit the installed files and
`.claude/settings.json` in one commit. The settings take effect for
collaborators only once the file is committed and they trust the folder.

Finally, give the user the two development checks, which run from a checkout
of the Agrippa repository at the pinned tag and need Node.js, which the plugin
itself does not. If the user names such a checkout, or one exists next to
this repository with `dev/validate-kit.mjs` in it, and Node.js is available,
run them yourself and paste the results, unless the user said they will run
them. Both are read-only for this repository; the smoke test removes the
workspace it writes. Otherwise print them for the user, with both paths
filled in:

```text
node <Agrippa>/dev/validate-kit.mjs -InstalledRepo <this repository>
node <Agrippa>/dev/fixtures/run-smoke-test.mjs -RepoRoot <this repository>
```

Both must print `PASS`. `-InstalledRepo` also fails until
`.claude/settings.json` is committed.

## 8. Report

Report the files written, each project-specific adaptation with the evidence
behind it, the interview decisions table from `.agrippa/INSTALL.md` with how
many entries inspection, the user, and the defaults settled, every settings
change, and every item in the adoption checklist as done or not done with the
reason. Items that describe the plugin's own
behavior, such as "Planning behavior" and "Routing, execution, and quality",
cannot be verified at install time. Report each of them as provided by the
plugin and not yet verified, pending the live "Make a plan" check.

Say that the plugin loads in a new session once the folder is trusted, and
the `engineering` plugin with it if the user chose it, and
name the one live check left for the user: a real "Make a plan" request.
Shape checks do not prove that the contracts are true. Do not call the install
complete while any checklist item is unreported.
