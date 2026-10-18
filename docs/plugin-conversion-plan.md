# Plan: turn Agrippa into a Claude Code plugin marketplace

Written 2026-10-18. Status: Phases 0, 1, 2, 3, and 4 done on 2026-10-18.
Phase 5 has not started. Phase 1's second check, that `claude --plugin-dir
plugins/agrippa` lists the agents and skills, waits until the four agents and
four kit skills move into `agents/` and `skills/` in a later phase. The `plan`
and `handoff` skills are already in `skills/`.

## Goal

Today each project gets the methodology by copying `planning-methodology-kit/`
into it and filling the templates in place. Every improvement then has to be
upgraded into every project by hand.

After this change, Agrippa is a plugin marketplace with one plugin,
`agrippa`. The plugin holds everything that is the same in every project.
Each project keeps only its own facts and declares the plugin in its committed
`.claude/settings.json`. To improve the methodology, you change Agrippa, tag a
release, and move each project to the new tag.

## Starting point

These facts were checked on 2026-10-18.

- The GitHub repository is `https://github.com/pxd5295/Agrippa`. It is
  public and empty. The local clone has no remote configured yet.
- The kit has 17 template files that contain 141 `[PROJECT: ...]` install-time
  slots. These include all four agents and three of the four skills:
  `design-first` has 19 slots, `systematic-debugging` has 17, and
  `verify-before-done` has 11.
- Most of those slots repeat facts that the project-side documents already
  hold. For example, the "Architecture owners" table in
  `templates/PROJECT-CONTRACTS.md` already lists the base classes, variant
  subclasses, configuration layer, funnels, and performance-owned subsystem
  that `design-first` asks for again.
- The linter finds the repository root as the folder above its own location
  (`validate-plan-workspace.ps1:35`). It loads the local check file from its
  own folder (`validate-plan-workspace.ps1:542`).
- The smoke fixture and every plan's validation matrix name the linter as
  `tools/validate_plan_workspace.ps1`. Linter check 13 requires every path in a
  matrix command to exist in the repository.
- nuro-battler has the G3 kit installed. It has its own copies of the four
  agents and four kit skills, the `/handoff` command, the shared linter, its
  local linter file, the spawn logger, and its own edit-lint hook
  (`tools/lint_gd_file.ps1`). It also has two project skills,
  `brain-audit` and `brain-visualize`, which are unrelated to the kit.

## What Claude Code plugins can and cannot do

These facts come from the Claude Code plugin documentation, read on
2026-10-18. Phase 0 re-checks the ones this plan depends on.

- A plugin can ship agents, skills, commands, hooks, MCP servers, output
  styles, and a `bin/` folder whose files go on the Bash tool's PATH while the
  plugin is enabled.
- A plugin cannot ship an always-loaded `CLAUDE.md`. A `SessionStart` hook can
  add text to the session as context instead. Each hook's output is capped at
  10,000 characters. Above that cap, Claude receives only a 2,000-character
  preview and a file path.
- Plugin skills, agents, and commands are namespaced, for example
  `/agrippa:design-first` and the agent `agrippa:validator`.
- `${CLAUDE_PLUGIN_ROOT}` is substituted in hook commands and in skill, agent,
  and command text. It is not set in the environment of shell commands that
  Claude runs. Its value changes with every plugin version.
- A project enables a plugin with `extraKnownMarketplaces` and
  `enabledPlugins` in its committed `.claude/settings.json`. This takes effect
  once the user trusts the folder. The marketplace entry accepts a `ref`, such
  as a tag, which pins the version the project gets.
- Auto-update is off by default for marketplaces that Anthropic does not
  publish.

## Target layout

```text
Agrippa/
  .claude-plugin/marketplace.json        marketplace "agrippa", one plugin
  plugins/agrippa/                       the shipped plugin
    .claude-plugin/plugin.json
    agents/                              repo-scout, plan-reviewer, design-reviewer, validator
    skills/
      design-first/                      the four existing skills, made project-neutral
      systematic-debugging/
      verify-before-done/
      receiving-review/
      plan/                              planning entry point; reference/agent-workflow.md,
                                         reference/ROUTING.md, templates/*.md
      handoff/                           replaces commands/handoff.md
      install/                           install procedure and project-side templates
      upgrade/                           upgrade procedure, UPGRADING.md, MIGRATION template
    hooks/hooks.json                     SessionStart rules injection; optional spawn logger
    bin/agrippa-lint                     wrapper that runs the linter on PATH
    scripts/                             validate_plan_workspace.ps1, inject_core_rules.ps1,
                                         core-rules.md, log_subagent_spawns.ps1, hook_payload.ps1
  dev/                                   not shipped
    validate-kit.ps1
    fixtures/
  docs/                                  design notes, research, this plan
  history/                               unchanged
```

`planning-methodology-kit/` is moved with `git mv` so file history follows.

### What lives where

| In the plugin (shared by every project) | In each project (its own facts) |
|---|---|
| The core always-loaded rules, injected at session start | A short `AGENTS.md` and `CLAUDE.md` with project rules only |
| The four agents | `docs/agent_memory/project-contracts.md` |
| The four skills, plus `plan`, `handoff`, `install`, `upgrade` | `docs/agent_memory/validation-commands.md` |
| `agent-workflow.md` and `ROUTING.md`, as `plan` skill reference files | `docs/agent_memory/live-app.md`, only when a live-app bridge exists |
| The plan templates | Per-directory `CLAUDE.md` files |
| The shared linter and its `agrippa-lint` wrapper | `tools/validate_plan_workspace.local.ps1`, when needed |
| The spawn logger | The edit-lint hook, `docs/decisions/`, and `plans/` |

## Decisions

### Inject the core rules with a SessionStart hook

The generic parts of the `AGENTS.md` and `CLAUDE.md` templates become
`scripts/core-rules.md`. These parts are request boundaries, Engineering
standards, the definition of done, the planning trigger and size gate,
implementation launch, the roster, the skills list, the planner read ladder,
and validation reach. A `SessionStart` hook prints that file as
`additionalContext`. A `SubagentStart` hook prints it for every subagent,
which does not receive `SessionStart` context (added in Phase 2). The
project's own `AGENTS.md` keeps only the project contracts section and any
project rules.

The reason is that these rules change with the methodology, so they must
update with the plugin. The alternative, keeping them in each project's
`AGENTS.md`, would bring back the per-project upgrade this plan exists to
remove.

The file must stay under 10,000 characters, and the self-check enforces that.
The current `AGENTS.md` template already has a 10,000-character soft target,
and the project contracts section moves out. The Engineering standards
currently name project classes inline, for example `WorldBase`. Those mentions
become references to the "Architecture owners" table in `project-contracts.md`.

### Project facts move out of skills and agents into project documents

Every `[PROJECT: ...]` slot in an agent or skill is replaced with an
instruction to read the named section of a project document. The slots map to
three documents:

- **`project-contracts.md`** takes architecture and placement facts. The
  "Architecture owners" table gains rows for hook lists per base class,
  schema-driven lists and their version constants, the hot path with its
  multiplier and budget, gated subsystems with their gate targets, and the
  languages that have a language server.
- **`validation-commands.md`** takes command and evidence facts. New sections
  cover the once-per-session setup step, the verdict line format, the error
  grep, run caps, shared log paths, the build command, the authoritative
  performance measurement, invocation traps, caches that must not be deleted,
  and recurring environment limits.
- **`live-app.md`** is new and optional. It names the live-app MCP server, its
  read-only and authoring tools, and the rules from the current optional
  live-app blocks.

When this is done, no file in the plugin contains `[PROJECT:`. The self-check
enforces that.

### Agents and live-app MCP tools

The agents' `tools:` lines are complete allowlists. A project with a live-app
bridge, such as nuro-battler's Godot editor bridge, currently adds that
server's read-only tools to the line. A shared plugin agent cannot list one
project's MCP tools.

Phase 0 showed that plugin agents support `disallowedTools`. So the agents
drop their `tools:` line and list every editing tool under `disallowedTools`
instead. A project's MCP tools then become available to them. A bridge's
authoring tools would also become available, so `live-app.md` must list them,
and each agent must be told never to call them. The self-check cannot
enforce that rule, so reviewers have to watch for it.

### The linter runs from the plugin through a PATH wrapper

The linter gains a `-RepoRoot` parameter. When it is omitted, the script uses
the git top-level folder of the current directory, resolved in the script body
because Windows PowerShell 5.1 leaves `$PSScriptRoot` empty in parameter
defaults. The local check file is loaded from
`<RepoRoot>/tools/validate_plan_workspace.local.ps1`.

`bin/agrippa-lint` is a small shell wrapper that runs the linter under
`powershell` or `pwsh`. A plan's matrix row becomes
`agrippa-lint -PlanPath plans/YYYY-MM-DD-name`. That command holds no
version-specific path, and check 13 does not fail on it. Phase 0 showed that
`bin/` is on the PATH for the Bash tool only. So the validator and the plan
templates must say that this row runs through the Bash tool.

The reason is that matrix commands run in the shell, where
`${CLAUDE_PLUGIN_ROOT}` is not set and the plugin's cache path changes with
every version. Outside Claude Code, for example in a terminal or CI, you run
the linter from a checkout of Agrippa at the project's pinned tag.

Existing dated plans keep their `tools/validate_plan_workspace.ps1` rows. They
are historical records and are never edited.

### Hooks

The spawn logger moves into the plugin's `hooks.json`. It is opt-in: it does
nothing unless the project sets `AGRIPPA_SPAWN_LOG=1` in the `env` block of
its `.claude/settings.json`. It writes to `subagent-spawns.log` at the
repository root. The reason is that a plugin hook runs in every project that
enables the plugin, and a project that has not ignored the log file would get
an untracked file.

The edit-lint hook stays per project, because it wraps the project's own
linter. The README section on how to write one moves into the `install`
skill's reference files.

### Versioning

Agrippa tags releases with semantic versions, starting at `v1.0.0`. Each
project pins its marketplace entry to a tag with `ref`. Upgrading a project
means changing that one value and running `/reload-plugins` or starting a new
session. `plugin.json` carries the same version, and the self-check fails if
the two disagree.

The reason is that nuro-battler should not receive an untested methodology
change in the middle of a plan. Following `main` with auto-update stays
possible for a project that wants it.

### Install and upgrade become skills

`/agrippa:install` replaces the new-project setup prompt. It writes the
project-side documents from templates in its skill folder and adds the
marketplace and plugin entries to `.claude/settings.json`.

`/agrippa:upgrade` replaces the upgrade prompt. `UPGRADING.md` gains a
generation G4 for the plugin. It also gains a "From G3" section that maps each
copied-in file to either deletion (the plugin now provides it) or a move of
its project facts into a project document.

The safeguards in the current prompts carry over unchanged:

- the SHA-256 manifest of dated plan workspaces
- the rule mapping shown before any edit
- the `AskUserQuestion` confirmation of every deletion
- the rule against editing dated plans

## Phases

Each phase ends with `dev/validate-kit.ps1` printing `PASS`, except Phase 0,
which changes no files. The earliest phase is the riskiest one.

### Phase 0: confirm the plugin features this plan depends on

Build a throwaway plugin in the scratchpad and load it with
`claude --plugin-dir`. Record each answer in `docs/design-notes.md`.

1. A `SessionStart` hook's `additionalContext` reaches the session on startup,
   on resume, and after compaction.
2. `${CLAUDE_PLUGIN_ROOT}` is substituted in a skill body and in its
   `allowed-tools` line, for both the Bash and PowerShell tools.
3. A `bin/` file runs by bare name from the Bash tool on Windows (Git Bash).
   Also check whether it runs from the PowerShell tool.
4. A plugin agent can be spawned as `agrippa:validator` with a `model`
   override, and the spawn logger sees that name.
5. Whether plugin agents support `disallowedTools`. This settles the
   live-app question above.
6. Whether a private GitHub repository needs a token for background
   auto-update. Answered 2026-10-18: the repository is public, so this does
   not apply.

Done when every question has a recorded answer. Any answer that contradicts
this plan stops the work so the affected decision can be revised.

Result, 2026-10-18: the answers are recorded in `docs/design-notes.md` under
"Plugin feature checks".

- Questions 1, 2, 4, 5, and 6 confirmed the plan, although a resumed session
  was not tested.
- Question 3 narrowed the linter decision, because `bin/` works only from the
  Bash tool.
- The `allowed-tools` part of question 2 came out negative: a skill's
  `allowed-tools` line did not pre-approve its PowerShell command. Nothing in
  the plan depends on it.
- Question 5 settled the agents decision in favor of `disallowedTools`.

During development, a changed hook takes effect only in a new session.

### Phase 1: restructure the repository

1. Move the kit to `plugins/agrippa/` and the development files to `dev/`.
2. Add `marketplace.json` and `plugin.json`.
3. Update the layout table, the root `README.md`, and this repository's
   `CLAUDE.md`, whose rules name `planning-methodology-kit/` and the
   `-InstalledRepo` check.

Done when `claude plugin validate plugins/agrippa --strict` passes and
`claude --plugin-dir plugins/agrippa` lists the agents and skills.

### Phase 2: split out the core rules

1. Write `scripts/core-rules.md` and the injection hook.
2. Shrink the `AGENTS.md` and `CLAUDE.md` templates to project content.
3. Move the required-clause checks in `validate-kit.ps1` from those templates
   to `core-rules.md`, and add the 10,000-character limit.

Done when a fresh session in a test folder with the plugin enabled can state
the Engineering standards without reading any file.

Result, 2026-10-18: done. `core-rules.md` is 9,645 characters.

- The hook runs on `SubagentStart` as well as `SessionStart`, because
  subagents do not receive `SessionStart` context. `docs/design-notes.md`
  records why, under "Core rules injection".
- A fresh desktop session in a scratch folder enabled the plugin from this
  repository as a local directory marketplace. Without reading any file, it
  listed all eight Engineering standards and the size floor.
- A `general-purpose` subagent spawned from that session quoted the first
  standard and the size floor. It said the rules arrived as `SubagentStart`
  context.
- The session's transcript shows no file read. Its only tool call was the
  subagent spawn.
- The smoke fixture's acceptance text still says the root `AGENTS.md` names
  the planning trigger. The linter checks shape only, so it still passes.
  Phase 4 rewrites the fixture.
- `UPGRADING.md` still maps old rules to sections of `AGENTS.md`. Phase 6
  rewrites it for G4.

### Phase 3: make the skills and agents project-neutral

1. Extend the `PROJECT-CONTRACTS.md` and `VALIDATION-COMMANDS.md` templates
   with the new rows and sections.
2. Add the `LIVE-APP.md` template.
3. Rewrite every slot in the agents and skills as a read of the matching
   section.
4. Add the "no `[PROJECT:` in the plugin" check.

Done when that check passes. A review must also confirm that each removed
slot's example from nuro-battler has a home in a project document.

Result, 2026-10-18: done. The four agents and three skills had 67 slots, and
none remain.

- Each slot is now a read of a named section of `project-contracts.md`,
  `validation-commands.md`, or the new optional `live-app.md`. Each slot's
  example moved into that section of the project-side template. A script
  confirmed that every backticked name in the old examples appears in one of
  the three templates.
- The agents have no `tools:` line. `disallowedTools` removes `Write`, `Edit`,
  and `NotebookEdit` from all four. `repo-scout` also loses `Bash` and
  `PowerShell`, because it had no shell before. `docs/design-notes.md`
  records why, under "Agent tools after Phase 3".
- Each agent reads `live-app.md` only when it exists, may call only the tools
  it lists as read-only or run tools, and never calls an authoring tool.
- `dev/validate-kit.ps1` now fails on a `[PROJECT:` slot under
  `templates/agents/` or `templates/skills/`, on a `tools:` line in an agent,
  on a `disallowedTools` line that keeps an editing tool, and on an agent that
  does not point to the "Authoring tools" section of `live-app.md`.
- `claude plugin validate --strict` passed on a scratch copy with the agents
  and skills moved into `agents/` and `skills/`, so the new frontmatter is
  valid where the plugin will load it.
- The README's layout table, placeholder convention, and requirements, the
  adoption checklist, and the ROUTING roster now describe `disallowedTools`
  and `live-app.md`. The ROUTING roster's MCP slot is gone too.

### Phase 4: the linter, wrapper, and hooks

1. Add `-RepoRoot` to the linter and write `bin/agrippa-lint`.
2. Switch the smoke fixture's matrix row to `agrippa-lint`.
3. Move the spawn logger into `hooks.json` behind its opt-in.
4. Write the `plan` and `handoff` skills.
5. Update `docs/design-notes.md`, where the linter section describes the
   install location.

Done when the smoke test passes against a simulated project that has no
`tools/validate_plan_workspace.ps1`.

Result, 2026-10-18: done. `dev/validate-kit.ps1` builds the simulated project
as a temporary git repository with only `AGENTS.md`, and the smoke test passes
against it.

- The linter moved to `scripts/validate_plan_workspace.ps1`, as the target
  layout says. It takes `-RepoRoot`, defaults to the git top-level folder of
  the current directory, and loads the local file from
  `<RepoRoot>/tools/validate_plan_workspace.local.ps1`.
- `bin/agrippa-lint` is committed as executable. Run by bare name from Git
  Bash, it linted nuro-battler and a materialized smoke fixture.
- On nuro-battler's two newest plans, the plugin linter with `-RepoRoot`
  reproduced the installed linter's errors, check counts, and messages
  exactly. `docs/design-notes.md` records the commands and counts under "The
  linter".
- The spawn logger and its payload helper moved to `scripts/` and are wired in
  `hooks/hooks.json`. They do nothing unless `AGRIPPA_SPAWN_LOG=1`.
  `validate-kit.ps1` runs the logger with and without the variable. A live
  session with the plugin enabled was not used to test the `env` block;
  Phase 8 checks that with nuro-battler's spawn log.
- `skills/plan/` holds `SKILL.md`, `reference/agent-workflow.md`,
  `reference/ROUTING.md`, and `templates/*.md`. The guides' seven
  `[PROJECT: ...]` slots became reads of project documents, and the
  `VALIDATION-COMMANDS.md` template gained a "UI capture" section for two of
  them. `skills/handoff/SKILL.md` replaces `commands/handoff.md`.
- The core rules now point to the `agrippa:plan` skill for the guides and to
  `agrippa-lint` for the linter. They are 9,829 characters.
- `validate-kit.ps1 -InstalledRepo ../evolution-game/nuro-battler` now fails,
  as expected: nuro-battler's copy of the linter predates `-RepoRoot`. Phase 5
  changes what `-InstalledRepo` checks, and Phase 8 removes the copy.
- `UPGRADING.md` still maps old rules to `docs/agent-workflow.md`,
  `docs/planning/ROUTING.md`, `.claude/commands/handoff.md`, and
  `tools/validate_plan_workspace.ps1`, where G3 installed them. Phase 6
  rewrites it.

### Phase 5: rewrite the self-check

`dev/validate-kit.ps1` checks the following:

- the plugin layout
- that the `plugin.json` and `marketplace.json` versions agree
- frontmatter and namespacing
- no `[PROJECT:` in the plugin
- the size of `core-rules.md`
- encoding and script parsing, as today
- the older-toolchain vocabulary check, with its exemption list updated for
  the new paths
- the simulated-project smoke test

`-InstalledRepo` changes meaning. It stops comparing a copied linter. It
checks that the project declares the marketplace and plugin, has the
required project documents, and has no leftover local copies of plugin
agents, kit skills, the shared linter, or the spawn logger.

Done when it prints `PASS` here and fails, with a clear message, against
nuro-battler before migration.

### Phase 6: the install and upgrade skills

1. Port the two setup prompts into `skills/install/` and `skills/upgrade/`.
2. Add G4 and "From G3" to `UPGRADING.md`.

Done when `/agrippa:install` run in a scratch repository produces a project
that passes `validate-kit.ps1 -InstalledRepo`.

### Phase 7: publish

1. Add the GitHub remote.
2. Push `main` and tag `v1.0.0`.

Pushing and tagging happen only with your go-ahead at the time.

### Phase 8: migrate nuro-battler

Do this on a branch in nuro-battler, using `/agrippa:upgrade`.

1. Move the project facts from its filled agents and skills into its project
   documents. Those files are the data source, so nothing is rediscovered.
2. Delete its copies of the four agents, the four kit skills, `/handoff`, the
   shared linter, and the spawn-logger scripts.
3. Keep `brain-audit`, `brain-visualize`, `lint_gd_file.ps1`, and the local
   linter file.
4. Add the marketplace entry pinned to `v1.0.0`, `enabledPlugins`, and
   `AGRIPPA_SPAWN_LOG=1`.
5. Replace the linter permission with `Bash(agrippa-lint:*)`.

Validation:

- `validate-kit.ps1 -InstalledRepo ../evolution-game/nuro-battler` prints
  `PASS`.
- `agrippa-lint` on its ten newest plans reproduces the current linter's error
  and check counts, apart from the known freshness differences between a
  worktree and the main checkout.
- The dated-plan manifest is unchanged.
- One live "Make a plan" request completes, and the spawn log shows
  `agrippa:` agents with routed models.

### Phase 9: record the change

1. Update `docs/design-notes.md` with why the methodology became a plugin, why
   the rules are injected, and why the linter uses a PATH wrapper.
2. Update the root `README.md` table of installed repositories.

## How an improvement reaches every project

1. Change the plugin in Agrippa and run `dev/validate-kit.ps1`.
2. Test it in a project without committing anything there, using
   `claude --plugin-dir <Agrippa>/plugins/agrippa`.
3. Commit, tag the next version, and push.
4. In each project, change the marketplace `ref` to the new tag and commit
   that one line.

A rule that first appears in a project still has to be ported to Agrippa by
hand. A small skill that records a proposed change as an issue in the Agrippa
repository would help with that. It is out of scope for this plan.

## Risks

- **The core rules may not fit under 10,000 characters.** If they do not, the
  overflow becomes a skill that `core-rules.md` tells Claude to load. Rules
  that must always apply stay in the injected text.
- **Project facts may arrive later than before.** A fact that used to be
  inlined in a skill now costs Claude one extra read. The skill text must name
  the exact document and section, so the read is direct.
- **PowerShell must be installed for the hooks and the linter.** A project on
  macOS or Linux needs `pwsh`. This is already a kit requirement.
- **Untrusted folders get nothing.** A collaborator who has not trusted the
  folder does not load the plugin and sees no message about it.
- **Linting needs a checkout outside Claude Code.** A terminal or CI run needs
  its own checkout of Agrippa at the pinned tag.

## Open questions for you

1. Resolved 2026-10-18: the GitHub repository is public, so installing and
   updating the plugin needs no GitHub credentials.
2. Should projects pin release tags, as recommended, or follow `main` with
   auto-update?
3. Should the copy-into-the-repository install stay supported alongside the
   plugin? The recommendation is to drop it. Keeping both means two install
   paths for the self-check to prove.
