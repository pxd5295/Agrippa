# Kit design notes

These are the choices behind the kit that the files themselves do not
explain. They were first recorded in nuro-battler between 2026-09-13 and
2026-10-01 and moved here when the kit became its own repository.

## Placeholders

- Install-time slots are written `[PROJECT: ...]`. Plain `[...]` stays in the
  installed templates and is filled per plan.
- An installed repository must contain no `[PROJECT:` outside the kit folder.
  The README's install-marker scan enforces this.

## Generations

`UPGRADING.md` recognizes three generations:

- **G1**: the dual toolchain, with `.codex/` TOML profiles for three worker
  tiers and a gate that switched the session to a high-effort planner.
- **G2**: the first Claude-only kit, with three agents and no Engineering
  standards.
- **G3**: the current kit.

Only `UPGRADING.md` and `validate-kit.ps1` may name the old vocabulary, because
they need it to recognize and search for an old install.

## The linter

- The kit linter is the linter every project runs. It is never edited per
  project.
- Since Phase 4 of `docs/plugin-conversion-plan.md` (2026-10-18), the linter
  lives at `plugins/agrippa/scripts/validate_plan_workspace.ps1` and runs from
  the plugin. A project no longer gets a copy at
  `tools/validate_plan_workspace.ps1`. Inside Claude Code, the plugin's
  `bin/agrippa-lint` wrapper runs it under `powershell` or `pwsh` and passes
  every argument through. Outside Claude Code, for example in a terminal or
  CI, you run it from a checkout of Agrippa at the project's pinned tag.
- A plan's matrix row is `agrippa-lint -PlanPath plans/YYYY-MM-DD-name`. That
  command names no version-specific path, so check 13 has nothing to fail on.
  The plugin cache path changes with every version, and
  `${CLAUDE_PLUGIN_ROOT}` is not set in shell commands, so a full path could
  not work. Phase 0 showed that `bin/` is on the Bash tool's PATH only, so the
  plan templates, the `plan` skill, the core rules, and the `validator` agent
  all say this row runs through the Bash tool.
- The repository root used to be the folder above the linter's own location.
  It is now `-RepoRoot`, or else the git top-level folder of the current
  directory. The default is resolved in the script body, because Windows
  PowerShell 5.1 leaves `$PSScriptRoot` empty in parameter defaults. Outside a
  git repository and without `-RepoRoot`, the linter fails with one `[Files]`
  error rather than guess.
- The wrapper converts the linter's path with `cygpath -w` when it exists,
  because Windows PowerShell needs a Windows path and Git Bash passes POSIX
  ones. Git records the wrapper as executable (`git add --chmod=+x`), and
  `.gitattributes` keeps it LF, which its `#!/bin/sh` line needs.
  `validate-kit.ps1` checks all three.
- Project checks go in an optional `tools/validate_plan_workspace.local.ps1`,
  which the linter now loads from `<RepoRoot>/tools/` rather than from its own
  folder, and dot-sources. It defines `Test-LocalValidationRow` (run once
  per validation-matrix row) and `Test-LocalValidationMatrix` (run once per
  matrix). The template carries nuro-battler's Godot checks as the example.
- `-SkipLocalChecks` exists for the smoke test, whose generic fixture cannot
  satisfy project rules.
- With nuro-battler's local file installed, the kit linter reproduced the old
  repository linter's error and check counts on the ten newest plans. It also
  caught a gap the old linter missed: the old linter's hard-coded extension
  list ignored `.js` and `.mjs`, so one plan owned files its ownership matrix
  never listed.
- Accepted loss in that switch: check 20 now matches `layout` rather than
  `sensor`.
- A fresh worktree checkout resets file modification times, so check 24
  (freshness) counts differ between a worktree and the main checkout.
- `validate-kit.ps1 -InstalledRepo` used to compare a project's copy of the
  linter with the kit's. Since Phase 5 of the plugin plan it fails on any
  copy instead, because the project runs `agrippa-lint` from the plugin and a
  copy could only drift. It also fails on a copy of a plugin agent or skill,
  which would sit beside the plugin's `agrippa:` version and drift from it. It
  leaves `tools/hook_payload.ps1` alone while another script in the folder
  uses it, because nuro-battler's edit-lint hook dot-sources that helper.
  Comparisons that remain, such as the two copies of `LICENSE`, normalize
  line endings, because git converts them on checkout. A byte-for-byte hash
  failed on CRLF versus LF on 2026-10-18.
- Proof of the move, 2026-10-18. nuro-battler still had the G3 copy of the
  linter. The plugin linter, run from this repository as
  `powershell -NoProfile -ExecutionPolicy Bypass -File plugins/agrippa/scripts/validate_plan_workspace.ps1 -RepoRoot <nuro-battler> -PlanPath plans/<name>`,
  reproduced nuro-battler's installed linter exactly on its two newest plans.
  `2026-10-01-inspector-fidelity` gave 18 errors and 711 checks with both, and
  `2026-10-01-inspector-redesign` gave 19 errors and 877 checks with both.
  Every error message was identical. Without the local checks the first plan
  had 647 checks, so the local file loaded from `<RepoRoot>/tools/`.
  `agrippa-lint` run from nuro-battler's root with no `-RepoRoot` gave the
  same 18 errors and 711 checks.

## Proof

`fixtures/run-smoke-test.ps1` is the one end-to-end proof: the valid fixture
must pass and a mutated copy must fail. `validate-kit.ps1` runs it against a
simulated project: a temporary git repository that holds only the
`AGENTS.md` template and has no `tools/` folder. So the smoke test proves the
plugin's linter needs no copy in the project and finds the root through git.
The fixture cites only `AGENTS.md`, because the guides it used to cite now
ship in the plugin.

## Plugin feature checks (2026-10-18)

Phase 0 of `docs/plugin-conversion-plan.md` tested the Claude Code features the
plugin conversion depends on. The tests used a throwaway plugin loaded from a
local directory marketplace, in a desktop-app session on Claude Code 2.1.299
on Windows 11.

- **SessionStart context.** A plugin `SessionStart` hook's `additionalContext`
  reached the session at startup. The hook ran again after `/compact`, with
  `source` set to `compact`, and its new text was in the compacted session.
  A second, fresh session gave the same result.
  The startup text survived only as a mention in the compaction summary, so
  the injected rules depend on the hook running again after compaction, and
  it does. A resumed session was not tested.
- **Path substitution.** `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` were
  substituted in skill text, with forward slashes. Hook scripts also receive
  `CLAUDE_PLUGIN_ROOT` as an environment variable. A plugin from a local
  directory marketplace loads in place rather than from a cache copy.
- **`bin/` on PATH.** A file in the plugin's `bin/` folder ran by bare name
  from the Bash tool. It did not run from the PowerShell tool, whether named
  with no extension, `.ps1`, or `.cmd`. So a matrix row that calls a `bin/`
  command must run through the Bash tool.
- **Plugin agents.** An agent spawned as `agprobe:echo-agent` with a `model`
  override ran on that model. The `PreToolUse` hook received
  `subagent_type: agprobe:echo-agent` and `model: sonnet`. The
  `SubagentStart` hook received `agent_type: agprobe:echo-agent`.
- **`disallowedTools`.** A plugin agent with no `tools:` line and
  `disallowedTools: Write, Edit, NotebookEdit` had none of those three tools.
  It kept every other tool, including the user's MCP tools. That is how a
  shared agent can stay read-only and still use a project's live-app bridge.
- **Skill `allowed-tools`.** A skill's `allowed-tools` line did not
  pre-approve its command. In a fresh session in Ask permissions mode, a
  skill's PowerShell command still asked for permission, even though it
  matched the skill's `PowerShell(...)` rule exactly. Bash could not be tested
  this way, because this environment ran every Bash command without a prompt,
  with or without a skill. The first run's "no prompt" results came from that
  automatic Bash approval and from the session being in auto mode. The plan
  does not depend on `allowed-tools`, because a project can allow
  `Bash(agrippa-lint:*)` in its settings.
- **Hook changes need a new session.** A hook matcher changed while a session
  was running did not take effect in that session.
- **Skills after compaction.** A skill invoked again after compaction was not
  delivered again. Claude Code pointed to the copy of the skill kept in the
  compacted context.
- **GitHub access.** `pxd5295/Agrippa` is public, so installing and updating
  the plugin needs no GitHub credentials.
- **`disable-model-invocation` hides a plugin skill.** Found on 2026-10-18
  during the Phase 6 install proof, in a desktop-app session on Claude Code
  2.1.299 on Windows 11, with the plugin loaded from a local directory
  marketplace. The three plugin skills with `disable-model-invocation: true`
  (`install`, `upgrade`, and `handoff`) were missing from that session, while
  the other five skills and the four agents loaded. `Skill("agrippa:install")`
  returned "Unknown skill", and when the user typed `/agrippa:install` the app
  said no command by that name exists. So in this app the flag removes the
  skill entirely, not only its model invocation. These skills have no flag.
  Each description says instead that it runs only when the user explicitly
  asks, and `dev/validate-kit.ps1` fails on the flag in any plugin skill.

## Agent tools after Phase 3 (2026-10-18)

The agents used to carry complete `tools:` allowlists, and a project with a
live-app bridge added that server's read-only tools to the list. A shared
plugin agent cannot name one project's MCP tools, so the agents now have no
`tools:` line, and `disallowedTools` removes the editing tools instead.

- **Editing tools.** All four agents lose `Write`, `Edit`, and
  `NotebookEdit`. Those are the editing tools Phase 0 proved
  `disallowedTools` removes.
- **Shells.** `repo-scout` also loses `Bash` and `PowerShell`. It had no shell
  in its allowlist, and a census needs none, so taking the shells away keeps
  it a pure reader. The other three agents had `Bash` and keep the shells.
  Their text limits the shell to reading state or running the packet's
  commands. They now also get `PowerShell`, which their allowlists did not
  include, because a project's validation catalog may be written for it.
- **Authoring tools.** Every tool a project's MCP servers offer now reaches
  the agents, including a live-app bridge's authoring tools. So
  `docs/agent_memory/live-app.md` lists the bridge's read-only, run, and
  authoring tools, and each agent may call only the first two kinds. A bridge
  tool the file does not list counts as authoring. No check can enforce this,
  so reviewers watch for it.

## Core rules injection (2026-10-18)

Phase 2 of `docs/plugin-conversion-plan.md` moved the generic always-loaded
rules out of the `AGENTS.md` and `CLAUDE.md` templates into
`plugins/agrippa/scripts/core-rules.md`. `scripts/inject_core_rules.ps1`
prints that file as `additionalContext`.

- **Two hooks, one script.** The plan named only a `SessionStart` hook. A
  subagent does not receive `SessionStart` context; it starts with its own
  prompt, the task, and the `CLAUDE.md` files. Before the split, subagents saw
  the rules because the root `CLAUDE.md` imports `AGENTS.md`. Without a second
  hook, `design-reviewer` and implementation workers would lose the
  Engineering standards they are told to apply. A `SubagentStart` hook adds
  the same text to every subagent before its first prompt.
- **The 10,000-character cap.** Claude Code caps each context string at
  10,000 characters and shows only a preview above that. The cap applies to
  the `additionalContext` string, not to the JSON around it, so
  `validate-kit.ps1` fails when `core-rules.md` reaches 10,000 characters. The
  first version is 9,645 characters, so new rules need an equal cut or the
  overflow skill the plan's risks section describes.
- **Project names became table references.** The Engineering standards used
  to name project classes inline. They now point to the "Architecture owners"
  table in `docs/agent_memory/project-contracts.md`, so the same text works in
  every project.
- **The decision-record rule moved too.** "A shared-interface change starts
  with a decision record" is methodology, so it is in the core rules. The
  project's `AGENTS.md` names which interfaces are shared.
- **UTF-8 output.** Windows PowerShell 5.1 encodes piped stdout in the console
  code page, so the script writes UTF-8 bytes to the standard output stream
  directly.
- **Proof.** On 2026-10-18 a fresh desktop session (Claude Code 2.1.299,
  Windows 11) enabled the plugin from this repository as a local directory
  marketplace. It listed all eight Engineering standards without reading any
  file. A `general-purpose` subagent it spawned quoted the rules and said they
  arrived as `SubagentStart` context.

## Plugin skills and the spawn logger after Phase 4 (2026-10-18)

- **The guides are `plan` skill reference files.** `agent-workflow.md` and
  `ROUTING.md` change with the methodology, so they moved into
  `skills/plan/reference/`, and the plan templates into
  `skills/plan/templates/`. They had seven `[PROJECT: ...]` slots. Each became
  a read of a project document: the style-token document in "Contract
  documents" and the risk classes in `project-contracts.md`; "Invocation
  traps", "Runtime writes and caches", and a new "UI capture" section in
  `validation-commands.md`; and the "Gated subsystems" owner row.
- **`handoff` is a skill.** It replaces `commands/handoff.md` and keeps
  `$ARGUMENTS`. Phase 4 gave it `disable-model-invocation: true`, because the
  command only ever ran when the user typed it. Phase 6 removed the flag,
  because the desktop app then hides the skill entirely (see "Plugin feature
  checks"). Its description now says it runs only when the user explicitly
  asks.
- **The spawn logger is opt-in.** A plugin hook runs in every project that
  enables the plugin. Without `AGRIPPA_SPAWN_LOG=1` the script exits before
  reading its payload, so a project that has not opted in pays only for
  starting PowerShell on each spawn. The log goes to `CLAUDE_PROJECT_DIR`,
  with the payload's `cwd` as the fallback, because the script no longer sits
  inside the project. Whether the `env` block reaches a plugin hook was not
  tested in a live session; Phase 8 checks it with the spawn log.

## Generic project files moved into the plugin (2026-10-19)

Up to v0.1.0, `/agrippa:install` copied three templates with no
`[PROJECT: ...]` slot into every project in full: `plans/README.md`,
`docs/decisions/README.md`, and `docs/planning/CLAUDE.md`. They held only
methodology, so every project carried a copy that would drift from the
plugin.

- **Where the rules went.** The plan-workspace rules (artifact contract,
  handoff files, selective reads, soft budgets, linting outside Claude Code)
  are the `plan` skill's `reference/workspace-files.md`. The decision-record
  rules are the `design-first` skill's `reference/decision-records.md`,
  because a shared-interface change needs a record whether or not it has a
  plan workspace, and `design-first` is the skill that runs before that first
  edit. The core rules named `docs/decisions/README.md` for the record shape;
  they now name `agrippa:design-first`, which made them 4 characters shorter.
- **Pointer READMEs stay.** A project keeps a short `plans/README.md` and
  `docs/decisions/README.md` that say what the folder holds and link to the
  Agrippa repository, with no rules. Someone browsing the repository on
  GitHub, or a collaborator without the plugin, otherwise finds a folder of
  dated files with no explanation. `docs/decisions/` also has to exist before
  the first record is written. The pointers stay free of rules so they cannot
  drift; `validate-kit.ps1` fails if a pointer template grows a section.
- **`docs/planning/CLAUDE.md` is gone.** It only said that the guides and
  templates are in the plugin and that a local copy must not be kept. A
  freshly installed project has nothing else in `docs/planning/`, and an
  upgraded one has only `MIGRATION.md`, which now says itself that it is a
  record. The no-copy rule moved into the `plan` skill.
- **`docs/agent_memory/CLAUDE.md` stays whole.** Its editing rules are generic,
  but they work because Claude Code loads a folder's `CLAUDE.md` whenever a
  session touches a file in that folder. A skill has no such trigger, and the
  core rules have no room. Splitting the file would leave the project copy
  holding only its one slot while the rules lost the moment they are needed.
- **Upgrades.** `UPGRADING.md` "From G4 v0.1.0" replaces a full copy with
  the pointer and deletes `docs/planning/CLAUDE.md`.
  `validate-kit.ps1 -InstalledRepo` recognizes a full copy by a section heading
  that every earlier version had and the pointer never has.

## Linter rules that are easy to trip over

These cost three lint rounds (62 errors down to 0) on one nuro-battler plan.
The templates do not make them obvious, so they are candidates for either
template wording or friendlier linter messages.

- `Contract source:` must be `` `path:NNN` (read YYYY-MM-DD) `` with one line
  number. A range like `:19-29` fails check 24; put the range after the date.
- The census label must be literally `Consumer census:`. A parenthetical
  between the words and the colon fails check 25. Backticked
  `` `dir/file.ext:NNN` ``: `` `snippet` `` entries are verified against the
  real line, so paths need their directory and snippets must be substrings.
- Packet `- A#:` bullets must be the SPEC text verbatim, including backticks
  (check 4). Stage notes go on a separate `Acceptance notes:` line. There is
  one `- V#:` line per validation ID the stage lists.
- `Owned files:` in a packet is read from that one line only, so every file
  goes on that line in backticks.
- Check 13 rejects a matrix command that names a file that does not exist yet,
  so a new test file cannot be in the matrix. Add cases to a registered test
  instead.
- There must be exactly one `### Packet Integration`, with validator and
  reviewer packets inside it. It needs its own `- V#:` line for every ID its
  PLAN row lists (a range like "V1 to V9" fails), and PLAN's Integration row
  must contain the literal phrase "full applicable suite".
- A `Bounded-choice` stage needs a `| Bounded choice |` row containing the
  literal "Options:", "Default:" and "Change observation:", with no C-ids or
  paths in it.
- Any `V` followed by digits anywhere in a workspace (for example a product
  version name) is read as a validation ID and fails as undefined.
