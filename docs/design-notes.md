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

Only `UPGRADING.md` and `validate-kit.mjs` may name the old vocabulary, because
they need it to recognize and search for an old install.

## The linter

- The kit linter is the linter every project runs. It is never edited per
  project.
- Since Phase 4 of `docs/plugin-conversion-plan.md` (2026-10-18), the linter
  runs from the plugin. It is `plugins/agrippa/scripts/validate_plan_workspace.pl`,
  a Perl script since 0.4.0 (a Node script from 0.2.0, and a PowerShell
  script before that; see "Linter runs on Node" and "Node leaves the plugin"
  below). A project no longer gets a copy at
  `tools/validate_plan_workspace.ps1`. Inside Claude Code, the plugin's
  `bin/agrippa-lint` wrapper runs it and passes every argument through.
  Outside Claude Code, for example in a terminal or CI, you run it with
  `perl` from a checkout of Agrippa at the project's pinned tag.
- A plan's matrix row is `agrippa-lint -PlanPath plans/YYYY-MM-DD-name`. That
  command names no version-specific path, so check 13 has nothing to fail on.
  The plugin cache path changes with every version, and
  `${CLAUDE_PLUGIN_ROOT}` is not set in shell commands, so a full path could
  not work. Phase 0 showed that `bin/` is on the Bash tool's PATH only, so the
  plan templates, the `plan` skill, the core rules, and the `validator` agent
  all say this row runs through the Bash tool.
- The repository root used to be the folder above the linter's own location.
  It is now `-RepoRoot`, or else the git top-level folder of the current
  directory, from `git rev-parse --show-toplevel`. Outside a git repository
  and without `-RepoRoot`, the linter fails with one `[Files]` error rather
  than guess.
- The wrapper is an extensionless POSIX `sh` script with a `#!/bin/sh` line
  (since 0.4.0; a Node script from 0.2.0). Git Bash runs it through that
  line, and it `exec`s `perl` on the linter beside it after checking that
  `perl` exists, so a missing Perl fails with one plain line and exit 2
  instead of a shebang error. Git records the wrapper as executable
  (`git add --chmod=+x`), and `.gitattributes` keeps it LF, which the shebang
  line needs. `validate-kit.mjs` checks all three.
- Project checks go in an optional `tools/validate_plan_workspace.local.pl`,
  which the linter loads from `<RepoRoot>/tools/` rather than from its own
  folder, with `do`. The file returns one hash whose optional keys are
  `check_validation_row` (run once per validation-matrix row),
  `check_validation_matrix` (run once per matrix), and
  `command_path_extensions`; see "Node leaves the plugin" below for the
  contract and its history. The template carries nuro-battler's
  Godot checks as the example.
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
- `validate-kit.mjs -InstalledRepo` used to compare a project's copy of the
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

`fixtures/run-smoke-test.mjs` is the one end-to-end proof: the valid fixture
must pass and a mutated copy must fail. `validate-kit.mjs` runs it against a
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
  asks, and `dev/validate-kit.mjs` fails on the flag in any plugin skill.

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
  `validate-kit.mjs` fails when `core-rules.md` reaches 10,000 characters. The
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
  drift; `validate-kit.mjs` fails if a pointer template grows a section.
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
  `validate-kit.mjs -InstalledRepo` recognizes a full copy by a section heading
  that every earlier version had and the pointer never has.

## Generic rules moved out of the project documents (2026-10-24)

Up to v0.1.1 the templates for `project-contracts.md`,
`validation-commands.md`, `live-app.md`, and `AGENTS.md` mixed the project's
facts with rule text that was identical in every install: the noisy-retry and
pre-existing-failure rules, the Sandbox and Determinism definitions, the
"Full-suite inventory" and "Plan-matrix contract" rules, the consumer-census
and decision-record paragraphs, the risk-flag rule, the live-app bridge rules,
and a list of the core-rule sections in the `AGENTS.md` opening. Each install
copied them, and each copy drifted from the plugin as the plugin changed. This
continues the 2026-10-19 move of the pointer READMEs.

- **Where the rules went.** Each rule went to the one skill or agent that
  uses it. The matrix values, the inventory and verbatim-copy rules, and the
  local-linter rule are a "Validation matrix values" section of the `plan`
  skill's `agent-workflow.md`, because the lead writes the matrix from there.
  The retry and pre-existing-failure rules are in `verify-before-done`, which
  is the procedure for reading a run, and the `validator` restates the retry
  rule because it runs rows without loading skills. The risk-flag rule is in
  `ROUTING.md` under the tier table. The bridge rules were already in all four
  agents; `verify-before-done` gained a "Live-app bridge" section for the lead,
  which also uses the bridge and had read the rules only from the project's
  copy.
- **The installer still needs the definitions.** The Sandbox and Determinism
  values are not pure deletions: the install skill fills those two catalog
  columns and nowhere else defined them, so its kit-files table now names
  `agent-workflow.md` and step 5 says where the values are.
- **Install guidance became install notes.** Sentences that told the installer
  what to do ("delete a row that provably does not apply", "list every
  target") are `Install note` blocks or comments now, which the install deletes,
  rather than prose the project keeps.
- **Two rules stay in the project's `AGENTS.md`.** The generated-files rule
  and the one-sentence bridge pointer with its authoring go-ahead stay, because
  they must be loaded for every edit, including small ones that skip
  `design-first`, and the core rules have no room (9,895 of 10,000
  characters).
- **Detection.** The project headings could not mark a leftover this time,
  because "Sandbox stance" keeps a project slot and nuro-battler uses the
  "Plan-matrix contract" heading for its own facts. So `validate-kit.mjs
  -InstalledRepo` matches the template sentences themselves, with every space
  allowed to be any whitespace because an install may rewrap lines. It catches
  the template's wording only; nuro-battler's G3 copies are reworded, and the
  "From G3" rows in `UPGRADING.md` tell the upgrade skill to remove them by
  meaning.
- **Not moved.** `UPGRADING.md` and `ADOPTION-CHECKLIST.md` stay at the plugin
  root. Both the install and the upgrade skill read both files, so neither has
  a single skill that could own it, and the root is where someone browsing the
  repository expects `UPGRADING.md`.

## Hooks run on Node (2026-10-24)

The three hook scripts were PowerShell, and `hooks/hooks.json` ran them as
`powershell -File ...`. No `powershell` command exists on macOS or Linux,
where PowerShell 7 is installed as `pwsh`, so on those systems every hook
failed and the core rules never loaded. They are now
`scripts/inject_core_rules.mjs` and `scripts/log_subagent_spawns.mjs`, and
`hooks.json` runs them with `node`. This replaces the script names in "Core
rules injection" and the PowerShell start-up cost in "Plugin skills and the
spawn logger after Phase 4". Superseded on 2026-10-25: since 0.4.0 the hooks
are POSIX sh scripts; see "Node leaves the plugin" below.

- **Why Node rather than `pwsh`.** One hook command has to work on every OS,
  and `node` is named the same everywhere. With PowerShell, the program is
  `powershell` on a stock Windows machine and `pwsh` elsewhere, so the hook
  would need a wrapper, and the wrapper would need a shell of its own. Node is
  also installed more often than `pwsh`, especially on Windows. Neither is
  guaranteed.
- **No dependencies.** The scripts are ES modules that import only Node's
  built-in modules, so the plugin needs no `package.json` or `npm install`.
- **The UTF-8 workaround is gone.** Node writes strings to stdout as UTF-8,
  so the byte-level write that Windows PowerShell 5.1 needed is not needed.
- **`hook_payload.ps1` left the plugin.** It existed so two PowerShell hook
  scripts could share the payload reader. Only the spawn logger reads a
  payload, so the reader is now a function inside it. A project's own copy of
  `tools/hook_payload.ps1` still serves the project's edit-lint hook, and
  `validate-kit.mjs -InstalledRepo` still checks it the same way.
- **The event is a positional argument.** `inject_core_rules.mjs SessionStart`
  replaces `-HookEvent SessionStart`, because Node has no built-in parameter
  binding and one value does not need a flag.
- **The linter followed the same day.** Porting it changed the
  `tools/validate_plan_workspace.local.ps1` contract that installed projects
  rely on, so it shipped as its own breaking release, 0.2.0; see "Linter runs
  on Node" below. The smoke test and the kit self-check stayed PowerShell in
  that release, because they are Agrippa's development tools and not part of
  the plugin; they followed the same day, see "Development tools run on
  Node" below.

## Linter runs on Node (2026-10-24, release 0.2.0)

`scripts/validate_plan_workspace.ps1` became
`scripts/validate_plan_workspace.mjs`, and `bin/agrippa-lint` became a Node
script. The plugin now needs Node and nothing else. The reason is the one the
hooks section gives: `node` has one name on every OS, and the `sh` wrapper
only existed to find `powershell` or `pwsh` and convert a path for it.
Superseded on 2026-10-25: since 0.4.0 the linter is a Perl script and the
wrapper is `sh` again; see "Node leaves the plugin" below, which keeps the
parity method and the transliteration traps recorded here.

- **Same command, same output.** `agrippa-lint -PlanPath plans/<name>` is
  unchanged, so no plan's matrix row and no `Bash(agrippa-lint:*)` permission
  changes. The linter still accepts `-PlanPath`, `-RepoRoot`, and
  `-SkipLocalChecks` (and `--plan-path` forms), prints one error per stderr
  line, warnings prefixed `WARNING:`, and the same PASS or FAIL summary line
  on stdout with the same exit codes. Every message keeps its text and its
  `[Check N]` label, so the smoke test's expectations did not change.
- **Parity proof.** Before the `.ps1` was deleted, a scratch harness ran both
  linters on the two `history/plans/` workspaces, the ten newest nuro-battler
  plans with `-SkipLocalChecks`, three of them again with nuro-battler's local
  file ported to `.mjs`, and the smoke fixture in a valid and a broken copy.
  Every run gave the same error set, check count, and exit code, including
  the recorded baselines: `2026-10-01-inspector-fidelity` 18 errors / 711
  checks with local checks and 647 checks without, and
  `2026-10-01-inspector-redesign` 19 / 877.
- **Where a transliteration goes wrong.** PowerShell's `-match`, `-eq`, `-in`,
  and hashtable keys ignore case, while `[regex]::Matches`, `.Contains()`, and
  `Select-Object -Unique` do not; the port gives the `i` flag to every former
  `-match`, lowercases every former `-eq` string comparison, and keeps the
  former `[regex]::Matches` patterns case-sensitive. `Get-Content` line counts
  (checks 21, 24, 25) do not count a trailing newline as a line, so the port
  drops a final empty element after splitting. Check 24 compares local
  calendar dates, not timestamps. `Compare-Object` on unique lists is set
  equality.
- **One deliberate change.** Windows PowerShell 5.1 read a file without a
  byte-order mark in the system code page; Node reads UTF-8. A check 4 or
  check 25 comparison that involves non-ASCII text can now differ from the
  old result, and the new result is the right one. No plan in the parity set
  was affected.
- **The local-checks contract.** `tools/validate_plan_workspace.local.mjs`
  is an ES module with optional named exports `checkValidationRow({ row,
  command, sandbox, check, repoRoot, planRoot })`, `checkValidationMatrix({
  rows, check, repoRoot, planRoot })`, and `commandPathExtensions`. The
  linter passes `check` in rather than exposing a global, so the file depends
  on nothing but its arguments. A project that still has only the `.ps1` gets
  a `[Local]` error and a failing run, never a silent skip, because the point
  of the file is that its rules always run. `UPGRADING.md` "From G4 v0.1.2"
  holds the construct-by-construct port.
- **The wrapper is CommonJS.** It has no extension, and Node loads an
  extensionless file as CommonJS below 22.7, so it uses `require` and a
  dynamic `import()` of the linter and calls its exported `main`. Git Bash
  honours its `#!/usr/bin/env node` line when the plugin's `bin/` folder is on
  PATH in POSIX form, which is how Claude Code adds it; a `C:/...` entry on
  bash's PATH is not searched, which is a bash fact, not a wrapper fault.
- **The self-check reads the linter's source.** `validate-kit.mjs` still
  pulls the required packet labels and the stage field names out of the
  linter rather than keeping a second list, now from the
  `requiredPacketLabels` constant and the `getField(stage, '...')` calls.
- **Direct run outside Claude Code.** `node
  plugins/agrippa/scripts/validate_plan_workspace.mjs -PlanPath <plan>
  -RepoRoot <repository>`. The script detects whether it is the entry point
  and only then runs `main`, so the wrapper can import it without side
  effects.

## Development tools run on Node (2026-10-24)

`dev/validate-kit.ps1` became `dev/validate-kit.mjs` and
`dev/fixtures/run-smoke-test.ps1` became `dev/fixtures/run-smoke-test.mjs`.
They were the last PowerShell in the repository, so Agrippa now needs
PowerShell nowhere: not to use the plugin, and not to develop it. The install
and upgrade skills print the two commands as `node <Agrippa>/dev/...`, and
`CLAUDE.md` lost its PowerShell 5.1 rule.

- **Why.** The plugin's own reason applies to the tools that test it: `node`
  has one name on every OS, while the development commands needed `powershell`
  on Windows and `pwsh` elsewhere. A contributor on macOS or Linux could run
  the plugin but not its self-check. The self-check also runs the hooks, the
  linter, and the smoke test with the same Node that runs it, so the chain
  has one runtime from end to end.
- **Same parameters, checks, and lines.** `-InstalledRepo <path>` and
  `-RepoRoot <path>` keep their spellings, with `--installed-repo` and
  `--repo-root` as alternatives. Every check keeps its message, and the
  PASS and FAIL summary lines keep their format, so a note that quotes a
  self-check result still reads the same.
- **Parity proof.** Both self-checks ran on one tree that held both the
  `.ps1` and the `.mjs` files, intact and then broken in nine places (a
  README layout row removed, trailing whitespace in `NOTICE`, a `[PROJECT:`
  slot and a project copy path in an agent, a marketplace version mismatch,
  a plain placeholder in a template, a packet label removed, stray files at
  the plugin root and in `agents/`, a changed hook matcher, and a
  `disable-model-invocation` flag). The error sets were identical apart from
  the planned differences: the clauses that now name the `.mjs` commands, the
  swapped exempt file, and the script's own name inside one message. The
  check counts differed by exactly two, the PowerShell parse checks on the
  two `.ps1` files, which no longer exist. The `-InstalledRepo` audit of
  nuro-battler gave the same 22 findings from 67 checks with both.
- **The PowerShell parser check is gone.** It parsed every `.ps1` under the
  checked folders, and none remain. `node --check` still covers every `.mjs`
  and the wrapper, including the two development scripts themselves.
- **Where a transliteration goes wrong.** The same traps as the linter port:
  PowerShell's `-match`, `-eq`, `-like`, `-contains`, and `-in` ignore case,
  so every former `-match` clause has the `i` flag and every former
  `-contains` compares lower-cased names, while the former `[regex]::Match`
  calls and `.Contains()` stay case-sensitive. `[regex]::Escape` also escapes
  spaces, which is what the generic-rules table relied on to turn each space
  into `\s+`; the port does that replacement directly. Settings keys
  (`enabledPlugins`, `agrippa@agrippa`) are now read case-sensitively, which
  is how Claude Code reads them.
- **The two scripts stay out of the plugin.** They live in `dev/` and are
  listed nowhere in the README layout table, as before. The self-check
  requires both by name, exempts itself from the old-vocabulary scan by its
  new name, and runs the smoke test with `process.execPath` rather than
  looking `node` up on PATH.

## The knowledge layer grows on demand: the area map (2026-10-24)

A proposal to deepen the plugin's knowledge layer at install time, with a
`CLAUDE.md` in every subfolder and a generated wiki or code graph, and to
retire `AGENTS.md` in their favour, became one on-demand document instead:
`docs/agent_memory/area-map.md`, written by the new `/agrippa:survey` skill
from `templates/AREA-MAP.md`. One row per folder gives its ownership area,
entry points as `file:symbol`, covering tests, and governing contract; a
"Not mapped" list names generated and vendored folders; a "Traps" list holds
only incidents that are recorded somewhere. The `Built at` line names the
commit the rows describe.

- **Why not a `CLAUDE.md` per folder.** Claude Code loads every `CLAUDE.md`
  on the path from the root to the edited file, so generated folder files are
  always-loaded context. The only independent study of instruction files
  (`docs/research-2026-08.md`, "Still open") found more than 20% extra cost
  and no gain, and the kit's standing answer is to keep the always-loaded
  pair lean. The install rule stays: one per-directory `CLAUDE.md` per area
  with real rules, and the survey never writes one.
- **Why `AGENTS.md` stays.** It holds decisions a survey cannot derive from
  code: the ownership boundaries, which interfaces are frozen, and the
  project rules stricter than the core. Derived facts go in the map, where
  they are read only when a plan touches the folder.
- **An index, not a contract.** Every earlier drift problem in these notes
  came from a second copy of a fact. The map is therefore excluded from the
  "Contract documents" table, is never a `Contract source:`, and every row a
  reader uses is verified in the code first. `repo-scout` has no Bash, so it
  cannot compare `Built at` with `HEAD`; the planner runs
  `git diff --name-only <commit> -- <folder>` and the scout confirms each
  entry point and covering test by `file:line` before it enters the fact
  pack. The `agent-memory-CLAUDE.md` template says the same in the project.
- **Measured before it grows.** Every plan that consults the map appends an
  `area map` entry to `EVIDENCE.md` (rows used, rows stale, saved a read or
  misled), and the scout ends its fact pack with an `Area map:` line for the
  planner to record. The research note asked for exactly this kind of data.
  A graph or wiki waits until those entries show a gain.
- **A setup skill, outside the core rules.** `survey` is listed with
  `install` and `upgrade` in `validate-kit.mjs`, not with the four working
  skills, so the core-rules roster check does not require it and the rules
  stay at 9,895 of 10,000 characters. The planner learns of the map from the
  `plan` skill's `agent-workflow.md`, which already loads for every plan.
- **Checks.** `validate-kit.mjs` requires the template and the skill, their
  README layout rows, the clauses above in the skill, template, scout,
  workflow guide, and evidence template, and, with `-InstalledRepo`, a
  `Built at` commit and no install marker in a project's map.

## Project documents move to `.agrippa/` (2026-10-24, release 0.3.0)

Up to 0.2.0 an install wrote the project documents to `docs/agent_memory/`
and the decision records to `docs/decisions/`. They now live in `.agrippa/`
at the repository root, the documents directly under it and the records in
`.agrippa/decisions/`, and `templates/agent-memory-CLAUDE.md` became
`templates/agrippa-CLAUDE.md`. Plan workspaces stay in `plans/`, where people
work in them every day.

- **Why leave `docs/`.** `docs/` is a generic name that a repository often
  already uses for its own material, so the kit was claiming two subfolders
  of someone else's folder. A hidden folder named after the plugin follows
  the convention that `.claude/` and `.github/` set, and collides with
  nothing.
- **Why both folders.** `docs/decisions/` had the same problem, and moving
  one without the other would have left the kit with two conventions.
  The upgrade record, written to `docs/planning/MIGRATION.md` up to 0.3.0,
  followed in the next release as `.agrippa/MIGRATION.md`, with "From G4
  v0.3.0" in `UPGRADING.md` as its one-row move, so that the kit claims
  nothing under `docs/`.
- **The folder `CLAUDE.md` still loads.** The earlier note that the folder's
  `CLAUDE.md` stays whole depends on Claude Code attaching a folder's
  `CLAUDE.md` when a session reads a file in that folder. A probe in the
  sandbox on 2026-10-24 confirmed that this also happens for a hidden folder:
  a fresh session that read `.agrippa/note.md` received `.agrippa/CLAUDE.md`,
  exactly as it did for a visible control folder. A `CLAUDE.md` created
  during a session is not picked up until the next session, which is why the
  probe needed a fresh one.
- **Hidden folders and search.** Command-line `rg` skips hidden folders
  unless given `--hidden`. `git grep` and Claude Code's Read, Glob, and Grep
  tools search them, which was checked by finding a string in
  `.claude-plugin/plugin.json` with the Grep tool. The folder `CLAUDE.md`,
  the README's install-marker scan, and the upgrade skill's marker search all
  say so, so a search that finds nothing is not taken as proof that a fact is
  unrecorded.
- **Upgrade path.** "From G4 v0.2.0" in `UPGRADING.md` is two `git mv`
  commands plus a reference sweep. Dated plan workspaces and existing
  decision records keep the old paths, because they are records.
  `validate-kit.mjs -InstalledRepo` fails while either old folder exists, and
  the kit-side vocabulary check rejects the old paths in every shipped file
  except `UPGRADING.md`, so they cannot drift back in.
- **Release.** This changes an installed repository's layout, so the release
  that ships it is 0.3.0, and each installed repository runs
  `/agrippa:upgrade` when it moves its tag.

## The install and upgrade skills check for Node (2026-10-24)

Both skills now run `node --version` before anything else. Until this change
nothing in the plugin checked for Node, even though every hook, the shared
linter, and `bin/agrippa-lint` run on it. Superseded on 2026-10-25: since
0.4.0 the check is `perl --version` through the Bash tool, and only the
linter depends on it; see "Node leaves the plugin" below.

- **Why the failure was silent.** Claude Code's native installer and the
  desktop app do not need Node, so a machine can lack it. The hook commands
  in `hooks/hooks.json` then exit with "command not found", which Claude
  Code treats as a non-blocking hook error: it prints a short notice and the
  session continues with no core rules in context. The install skill's own
  steps are Markdown, git, and file writes, so an install on such a machine
  went through to step 7, where `agrippa-lint` finally failed on its
  `#!/usr/bin/env node` line. The project documents and settings looked
  right, and every later session ran without the rules, the spawn logger, or
  the linter.
- **Why two options and not a conversion.** The idea of translating the
  scripts to PowerShell or Bash at install time was considered and rejected.
  The hooks run from the plugin's cached copy, which the skill cannot edit,
  so the plugin's own `node` commands would keep failing beside any
  project-side copy. A translation would also recreate the `powershell`
  versus `pwsh` problem that "Hooks run on Node" records, would have none of
  the parity proof the 0.2.0 linter port had, would drift from the shared
  linter with every release, and would be invisible to `/agrippa:upgrade`.
  The project rule that the linter is never copied into a repository exists
  for the same reason. So the prompt offers to install Node through the
  machine's package manager, which is the recommended option, or to install
  the documents anyway and report every Node-dependent checklist item as not
  done with the reason "Node.js is not installed". The degraded state is
  visible in the report and recovers completely the moment Node is
  installed, with no project file to clean up.
- **Why the install option stops.** A running process keeps the environment
  it started with, and the Bash tool, the hooks, and `agrippa-lint` all
  inherit PATH from the Claude Code process. So a Node installed during the
  session is invisible to it, and the skill tells the user to open a new
  session and run the skill again from the start rather than continue with
  checks that would still fail.
- **Only package managers.** The skill installs with `winget`, `brew`, or
  the distribution's package manager or a version manager, after the user's
  yes, and never downloads and runs an installer itself. Without a package
  manager it prints the command for the user.
- **Checked by the self-check.** `validate-kit.mjs` requires both skills to
  contain the `node --version` check, the reason text, and the sentence that
  forbids a shell-language copy, and the adoption checklist opens with the
  Node item so the report cannot skip it.

## The interview ends on a list, not a count or a score (2026-10-25)

Step 2 of the planning lifecycle used to say "one to three questions per
round, normally one round, more only when an answer exposes a material
decision". The number of questions and rounds was the planner's judgment with
no stated exit condition. The proposal that prompted this change was a
confidence threshold: the planner rates how well it understands the scope as
a percentage and keeps asking until the rating passes a fixed value. The
intent, keep asking until the planner is confident, is kept. The percentage
is not, for three reasons.

- **A self-reported percentage is not a measurement.** A model's verbalized
  confidence is poorly calibrated: it runs high, clusters on round values,
  and moves with the prompt's wording more than with the evidence. Two runs
  on the same code report different numbers, so a threshold against it is
  not a real gate.
- **An exit condition the planner writes itself becomes the answer.** If
  reporting the threshold value ends the interview, the planner reports it
  after a round or two whether or not anything changed, and nothing can
  check it. A question tied to a named decision can be checked by reading
  the plan; a percentage cannot.
- **Confidence about full scope is confidence about what was not thought
  of.** The scope problems that sink plans are the consumer never found, the
  covering test never noticed, the interface not known to be shared. Those
  come out of code inspection, and the user usually cannot answer them. A
  planner that missed one reports high confidence, because nothing it can
  see is missing. A confidence loop over the interview would push it to ask
  more when the fix was to read more.

So the exit condition is a list. After the narrow inspection the planner
writes down every uncertainty whose answer would change the plan, marks each
as resolvable by reading or only by the user, resolves the first group by
reading, and asks the user only the second group. Rounds continue while
user-only entries remain. The interview ends when that group is empty or
when the user says to proceed on the recommendations; anything still open
then becomes a `Bounded-choice` with the recommendation as its default, so
the user's escape never drops a decision. Every entry, including the ones
reading settled, is a row of `SPEC.md`'s `Planning interview decisions`
table with a `Resolved by` value, which is what makes the condition
checkable after the fact. The design states were already this gate per
stage, with `Open` meaning "not confident enough to hand off"; this change
adds the step that forces the list to be written before the planner decides
whether to ask.

The option of recording a percentage alongside the list, allowed only to
force another round and never to permit handoff, was considered and not
adopted. The self-check requires the workflow guide to carry the sentence
that rules the score out and the user's escape phrase, and the SPEC template
to carry the `Resolved by` column. The linter does not read the table.

## Low-usage mode: one switch, seven rules (2026-10-25)

A project whose token limits the normal methodology would exhaust can set
`AGRIPPA_LOW_USAGE=1` in the `env` block of `.claude/settings.json`. The
`SessionStart` and `SubagentStart` hook then appends one line to the core
rules, and the `plan` skill gains a reference file, `low-usage.md`, that the
planner reads only when that line is present. The mode replaces seven rules
with cheaper ones and nothing else. The study behind it compared four
designs.

- **Not three profiles.** The first proposal was low, medium, and high, with
  the kit today as medium. A pass over every file found 27 levers, and 26 of
  them had a distinct low value and 18 a distinct high value: 44 cells of
  alternative behavior to keep in step with the normal text, each one a place
  for the rules to drift. The high column was mostly "same as medium", which
  gave the second reason: spending more never breaks a rule, so a user with
  large limits can ask for an Opus reviewer or a full suite after each wave
  in the moment. Spending less does break rules, and the core rules say the
  stricter rule wins when a project's `AGENTS.md` disagrees, so a project has
  no sanctioned way to loosen one. A low switch needs to exist; a high one
  does not.
- **Not per-rule toggles.** The cost levers are correlated: someone with
  small limits wants all of them, and someone without wants none. Toggles
  would create combinations nobody intends, one install question per toggle
  on top of the seven the install already asks, and one injected line per
  toggle against a hook context cap with 146 characters of headroom. Toggles
  suit options that are independent of one another, which is what the kit
  already uses them for: the spawn logger, the edit-lint hook, and the
  permission allowlist. If a project ever needs to keep one rule at normal,
  an exclusion list is a subtraction from a list that already exists and does
  not reopen the maintenance problem; it waits for a project that asks.
- **Why these seven.** Each one fires on every change, spawns a model, or
  multiplies cost per writer: the design-reviewer size floor (30 to about
  80 changed lines), no reviewer self-escalation to Opus, the risk row of the
  tier table routed to Sonnet at high effort with Opus as the ceiling, every
  spawn starting at low effort, one writer per wave, the skip-workspace gate
  widened to any one-writer one-area change with the single-stage shape
  whenever one sequential writer suffices, and planning reads stopped at the
  third rung of the read ladder with `repo-scout` taking any census over
  about 20 call sites or file over about 800 lines. Nineteen other low cells
  from the study were left out because they save little (`EVIDENCE.md`
  detail, soft budgets), are rare (fidelity capture cadence), or trade
  correctness for tokens (trusting the known-red list without a run at
  `HEAD`, cutting validation cadence). Validation cadence stays because a
  regression found only at Integration costs a repair wave, which is more
  than the targeted checks save.
- **The interview is not in it.** The first draft capped the interview at
  one round. The same day, "The interview ends on a list, not a count or a
  score" replaced the round count with an exit condition, so a cap would
  have put the count back. The user's escape, "proceed on the
  recommendations", already carries the rest as `Bounded-choice`, and a mode
  that did that silently would make per-decision trades the user never saw.
  Instead the read-depth rule is bounded: a decision that reading could
  settle but the three rungs did not is carried as a `Bounded-choice` whose
  change observation is the skipped read, performed by the stage that owns
  the code, and recorded as `Resolved by: default` with the deferred read in
  the rationale. So the `Resolved by` column measures what the mode cost
  without a new value.
- **Floors.** The mode never moves the design statement, the definition of
  done, the consumer census and covering tests, `Frozen` or `Bounded-choice`
  only, the decision record, the linter, the `verify-before-done` gate, the
  noisy-retry rule, the full suite at Integration, Haiku's limits, the
  always-review conditions for a base class, a shared interface, or the
  performance-owned subsystem, or the lead's own model and effort. A low
  profile that dropped one would produce wrong plans rather than cheaper
  ones.
- **The mechanism follows the spawn logger.** A boolean in the `env` block,
  read by a plugin hook, with nothing appended when it is unset, so a normal
  session is unchanged by the mode existing. The script exports the line it
  appends and `validate-kit.mjs` reads it from there, runs the hook with the
  variable unset and set to `1`, and checks both outputs against the cap.
  Two parentheticals in the core rules were shortened by 68 characters to
  make room: the rules were at 9,854 of 10,000 and the line is 150. The guide
  lists only the replacements and names the file that owns each normal rule,
  so the normal column cannot drift from the text it describes. Claude Code
  resolves `env` per variable across settings files with the local file
  first, which is how a collaborator with different limits overrides the
  committed value in `.claude/settings.local.json`, and the `env` block
  reaches hook processes (settings and env-vars pages, read 2026-10-25). A
  committed value reaches a collaborator only once they trust the folder.
- **Measured before it grows.** `STATUS.md` records `Low-usage mode: on`, and
  `EVIDENCE.md` gets an entry for each decision the mode changed. As with the
  area map, those entries decide whether a rule stays in the mode. The spawn
  log, when on, shows whether the tier and effort rules were followed.

## License: Mozilla Public License 2.0 (2026-10-25)

The kit moved from Apache 2.0 to the Mozilla Public License 2.0. The change
started from a reading of the Corridor Key Licence 2.0, a Creative Commons
BY-NC-SA base with additional terms that forbid resale and paid hosting,
require public forks to be free, and charge large organisations per seat.
Each of its conditions was put to the owner in turn, and the choices were:

- Agrippa stays open source in the OSI sense, so no ban on selling it, on
  paid hosted use, or on charging for forks, and no revenue threshold or
  commercial agreement. Those are the three Corridor terms that make a license
  source-available rather than open.
- Agrippa may be the core of a larger proprietary system, but a kit file that
  someone changes and passes on must stay open with its source available.
  That is file-level copyleft triggered by distribution, which is the MPL 2.0
  model (sections 3.1 to 3.3). Apache 2.0 has no such duty, and the GPL
  family would pull the surrounding system in. Internal changes that never
  leave the organisation carry no duty.
- Contributions come in under the same license with no extra grant to the
  owner, so everyone holds the same rights to them (MPL section 2.1 does
  this on its own). Forks must keep the copyright notice but may rename the
  project (section 3.4, and no trademark grant in 2.3).
- Combining with GPL-family code stays allowed, so Exhibit B is not used.

The MPL text is verbatim, because its section 10.3 requires a modified
license to be renamed. The one addition Agrippa needs sits in `NOTICE`, where
the copyright holder grants an additional permission: the documents the
install and upgrade skills write from the templates, the plan workspace files,
and the plans and code made with the methodology are the user's under any
terms. Without it, a filled-in `AGENTS.md` in a closed repository would be a
modified copy of a covered file. `NOTICE` also carries the Exhibit A notice
for the whole kit folder in place of a header in each file, which Exhibit A
allows and which keeps template text clean when it is copied into a project.
`validate-kit.mjs` already required both files in both places and identical,
so no check changed.

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

The templates now state each of these rules beside the line it governs; see
"The lint traps move into the templates (2026-10-25)" below.

## Node leaves the plugin: hooks on sh, linter on Perl (2026-10-25, release 0.4.0)

Every user of the plugin had to install Node.js, because the two hook scripts,
the linter, and the `bin/agrippa-lint` wrapper were Node scripts. Claude Code
itself does not need Node, so a machine could lack it, and then the
`SessionStart` hook failed with a non-blocking notice and every session ran
without the core rules. From 0.4.0 the hooks and the wrapper are POSIX `sh`
scripts and the linter is a Perl script, so the plugin needs nothing a machine
that runs Claude Code's Bash tool does not already have.

- **What Claude Code provides, from its documentation.** Shell-form hook
  commands run through `sh -c` on macOS and Linux and through Git Bash on
  Windows; without Git for Windows they run in PowerShell, where a Bash
  script fails, but the plugin already cannot work there because
  `agrippa-lint` is reachable only through the Bash tool, which needs Git
  Bash too. `SessionStart` accepts plain stdout as context, but
  `SubagentStart` needs the JSON `hookSpecificOutput.additionalContext` form,
  so the rules hook keeps emitting JSON for both events. Git for Windows
  bundles `sh` (bash 5), GNU sed, awk, tr, and Perl 5.38 in `usr/bin`.
- **Why `sh` for the hooks.** `sh` is present wherever the hooks run, with no
  second runtime, so the core rules load on a machine with nothing else
  installed. The scripts are POSIX only (no arrays, `[[`, or `${var,,}`)
  because macOS `/bin/sh` may be bash 3.2 in POSIX mode or dash. The rules
  hook escapes `core-rules.md` into a JSON string with a `sed` pipeline
  (backslash, double quote, tab, carriage return) and an `awk` join that
  inserts `\n` and restores the file's final newline; the self-check now
  requires the rules file to hold no other control character, so those cases
  are complete. The spawn logger reads its fields with `sed` at object-key
  position (the key preceded by `{` or `,`), which an escaped quote inside
  another string cannot produce; it unescapes `\\`, `\/`, and `\"` for a
  Windows `cwd` and treats a `\u` escape as missing. It is observational,
  so textual matching is enough. Both scripts prepend `/usr/bin` to PATH:
  Git's `bin/sh.exe` launcher, which Claude Code uses, adds it already, but
  the bare `usr/bin/sh.exe` started from a Windows process does not, and
  then `sed` and `tr` are not found.
- **Why Perl for the linter.** Its 26 checks use lookbehind, lazy
  quantifiers, and capture groups, which POSIX `sh`, BSD awk (no capture
  groups), and bash 3.2's extended regular expressions cannot express without
  redesigning the checks. Perl takes the patterns almost unchanged and is
  present wherever git is on Windows and with the OS elsewhere. Python is
  absent on Windows (the `python3` on PATH is a Store stub), PowerShell is
  absent elsewhere, and compiled binaries would need a build pipeline,
  per-platform artifacts in git, and a redesigned extension point. Perl's
  one risk is macOS, where Apple has called its scripting runtimes legacy
  since 2019 but still ships Perl 5.34; the install and upgrade skills check
  `perl --version` through the Bash tool for the same reason they checked
  `node`, and only the linter depends on it now.
- **The wrapper.** `bin/agrippa-lint` is `#!/bin/sh`, checks `command -v
  perl`, prints one plain line and exits 2 when it is missing (the linter's
  usage-error code, so the matrix row fails loudly instead of with a shebang
  error), and `exec`s `perl` on the linter beside it, located from `$0`,
  which Git Bash sets to the full path it found on PATH.
- **Paths under Git Bash.** `git rev-parse --show-toplevel` and the
  substituted `${CLAUDE_PLUGIN_ROOT}` are `C:/...` paths, while MSYS Perl's
  `Cwd::abs_path` returns `/c/...`, and `$^O` is `msys`, not `MSWin32`. The
  linter resolves the repository root and the plan root through `abs_path`
  so the two spellings compare equal, treats `^[A-Za-z]:[\\/]` as absolute
  as well as what `File::Spec` accepts (MSYS `File::Spec` does accept
  `C:/x`), builds every path with `/`, and compares paths without regard to
  case when `$^O` is `MSWin32`, `msys`, `cygwin`, or `darwin`. The local
  file is loaded by its resolved path, because `do "C:/..."` would search
  `@INC`.
- **Encoding.** Files are read `:raw` and decoded with `Encode::decode`,
  which substitutes U+FFFD for a bad byte silently as Node's `'utf8'` read
  did; a `<:encoding(UTF-8)` layer would print a warning per bad byte from
  checks 21, 24, and 25. `STDOUT` and `STDERR` carry the UTF-8 layer with
  autoflush on, because the layer buffers `STDERR` and the summary line could
  otherwise reach a shared pipe before the errors it counts. Every string
  inside the program is a character string; `fs_*` helpers encode a path
  back to bytes at each file-system call, so a non-ASCII path works.
- **Regex port rules.** Every pattern carries `/a`, so `\d`, `\w`, and `\b`
  stay ASCII as in JavaScript; `\s` under `/a` no longer matches non-ASCII
  whitespace such as U+00A0, which JavaScript's did, and no plan in the
  parity set contained any. JavaScript's `.` never matches `\r` and `$`
  under `/m` matches before `\r\n`; Perl's `.` matches `\r` and `$` only
  before `\n`, so every `.` outside `/s` became `[^\r\n]` and `(.+)$` became
  `([^\r\n]+)\r?$`, or a CRLF workspace would gain a trailing `\r` in the
  `Contract IDs:` and `Owned files:` captures. `(?![\s\S])` is `\z`.
  `matchAll` is a `while (/.../g)` loop collecting `$&` and `@{^CAPTURE}`.
  `Map`, `Set`, and `unique()` keep insertion order in JavaScript, and that
  order fixes the sequence of the check 9, 10, and 11 messages, so the Perl
  keeps a parallel order array beside each hash. `split(/\r?\n/)` is `split
  /\r?\n/, $text, -1` followed by dropping one trailing empty element,
  because Perl otherwise discards trailing empty fields and the line counts
  in checks 21, 24, and 25 would change. `escapeRegex` is `\Q...\E`.
- **The list-context trap.** A regex match passed straight as the first
  argument of `$check->(...)` is evaluated in list context and yields an
  empty list when it fails, which shifts the message into the condition slot
  and makes the check pass. The broken smoke fixture caught it: the Perl
  port reported one error where Node reported three. Every such call now
  wraps the match in `scalar()`, and `$check` treats a one-argument call as
  the failure it can only be, so a project's local file cannot make the same
  mistake silently. `UPGRADING.md` "From G4 v0.3.1" records it.
- **The local-checks contract, version 0.4.0.**
  `tools/validate_plan_workspace.local.pl` is loaded with `do` and returns one
  hash reference with the optional keys `command_path_extensions` (an array
  reference), `check_validation_row` (a sub taking one hash reference with
  `row`, `command`, `sandbox`, `check`, `repo_root`, `plan_root`), and
  `check_validation_matrix` (the same with `rows`). `do` reports failure
  through `$@`, `$!`, or an `undef` return rather than an exception, so the
  three are tested separately and then `ref eq 'HASH'`; each failure is a
  `[Local]` error, never a silent skip. A leftover `.local.mjs` or
  `.local.ps1` produces a `[Local]` error naming the upgrade skill. The
  template is the Godot worked example ported from the `.mjs` template, and
  it returns its hash with `return { ... };` so `perl -c` does not warn about
  a hash in void context. `UPGRADING.md` "From G4 v0.3.1" holds the
  construct-by-construct port.
- **Parity proof.** A scratch harness ran the 0.3.1 Node linter and the Perl
  linter on the two `history/plans/` workspaces and all 74 dated nuro-battler
  plan workspaces with `-SkipLocalChecks`, and on four of them with local
  checks in a shared clone that held both the `.mjs` and the `.pl` form of
  the Godot template. Every run gave byte-identical ordered output (stdout,
  then stderr) and the same exit code after `\` was normalised to `/` in the
  Node output, including the recorded baselines: `2026-10-01-inspector-fidelity`
  18 errors and 647 checks without local checks and 711 with, and
  `2026-10-01-inspector-redesign` 877 with. The smoke fixture matched valid,
  broken, and converted to CRLF, and so did every usage-error path. The one
  cosmetic difference is the "not inside a git repository" message, which
  prints the current directory as `/c/...` under MSYS Perl where Node printed
  `C:\...`.
- **Deliberate changes.** Messages print repository paths with `/` on
  Windows where Node printed `\`, so the same text appears on every OS.
  `[Local]` messages name the Perl keys. The spawn log ends lines with LF on
  Windows where Node wrote CRLF. MSYS `sed` and `awk` drop a carriage return
  before a line feed, which the rules hook never meets because
  `.gitattributes` keeps the rules file LF and the self-check forbids a
  carriage return in it.
- **The development tools stay on Node.** `dev/validate-kit.mjs` and the
  smoke test are for this repository's maintainer, so they do not affect the
  plugin's requirement. They find `sh` and `perl` through `dev/tool-paths.mjs`,
  which on Windows prefers Git's `bin/sh.exe` launcher and `usr/bin/perl.exe`
  derived from `git --exec-path`, because a developer runs them from
  PowerShell, where Git's `usr/bin` is not on PATH; `sh` is probed with
  `sh -c 'exit 0'` because dash rejects `--version`. The self-check runs the
  hooks with `sh`, compiles every `.sh` with `sh -n` and every `.pl` with
  `perl -c`, checks that each `.pl` uses only a core-module allowlist and no
  Perl above 5.30, that no JavaScript file ships under `plugins/agrippa/`,
  and that the old script names and `node --version` appear nowhere in the
  plugin but `UPGRADING.md`.
- **What this machine could not verify.** Everything ran on Windows under
  Git Bash. The scripts target POSIX `sh` and Perl 5.30 with core modules so
  they should behave the same on macOS (bash 3.2 as `sh`, Perl 5.34) and
  Linux, but nothing here executed them there. A GitHub Actions workflow that
  runs `node dev/validate-kit.mjs` on Ubuntu, macOS, and Windows would prove
  it at each push and is the recommended follow-up.

## The install interview follows the planning interview (2026-10-25)

Step 4 of the install skill was a list of nine question topics: three vague
project-fact questions ("ownership boundaries that are ambiguous") and six
yes/no opt-ins, each its own question, with a recommendation stated for only
two of them. The planning interview, by contrast, has a procedure the kit
already tests: list the open decisions, settle by reading what reading can
settle, ask only the rest with a recommended option each, end on an empty list
or the user's go-ahead, and record every entry with how it was resolved. The
install step now follows that procedure, for these reasons.

- **The templates need answers the code cannot give.** The debugging map
  (runtime layers, probe convention, working counterparts, differences that
  mattered before), the known messages and invocation traps, which targets are
  flaky or red on purpose, the authoritative performance measurement, the
  screen-capture policy, and where worktrees live are experience, not
  structure. The old interview never asked for them, so an install either
  guessed them or deleted the section. Each is now a question in a named
  round, with "None for this project" as an option where the slot offers
  `None`, so a deleted section is a recorded answer.
- **A confirmed draft beats a blank.** Ownership areas, shared interfaces,
  risk classes, and owner rows are drafted from inspection first and the user
  is asked to accept or correct the draft row with its evidence. Reviewing a
  proposal is a far easier question than "what are your ownership boundaries".
- **Every answer is recorded with its provenance.** A new project document,
  `.agrippa/INSTALL.md` from `templates/INSTALL.md`, holds an "Interview
  decisions" table in the shape of a plan's `SPEC.md` table, with `Resolved
  by` set to `inspection`, `user`, or `default`, plus the optional features
  chosen and the install-time check results. A fact the user supplied and the
  code cannot confirm is marked `(per maintainer, YYYY-MM-DD)` where it lands
  in the documents, so a later reader can tell it from a `file:line` fact. The
  upgrade record `MIGRATION.md` is upgrade-shaped (rule mapping, preservation
  audit), so installs get their own short record rather than a half-empty
  copy of it; `.agrippa/CLAUDE.md` names whichever the repository has.
- **The opt-ins cost one call.** `AskUserQuestion` supports multi-select but
  holds at most four options per question, so the six optional features are
  two multi-select questions in one call: plugin features (area map, spawn
  logger, low-usage mode, edit-lint hook) and committed-settings additions
  (`engineering` plugin, permission allowlist). Every feature now has a
  stated recommendation. A round-0 question lets the user take every
  recommended default and answer only the project questions; the permission
  allowlist is the one feature that round never answers, because the rule
  that no permission is added without a yes to that specific question stays.
- **The upgrade skill shares the procedure.** Later the same day, step 3 of
  the upgrade skill got the same six-step procedure, with the install skill's
  rounds asked by reference rather than copied, so the two question lists
  cannot drift apart. The upgrade's open-decisions list adds its own entries
  (each material conflict, each proposed deletion, the pins and old toolchain
  configuration to remove) and its own round for them, between the install
  skill's round 0 and round 1. Its inspection step reads the old documents as
  the data source: a slot the old methodology already answered is carried
  over with the old path as evidence and is never asked again, which is why
  an upgrade from a filled-in methodology asks few project questions. Two
  entries have no default, because "proceed on the recommendations" must not
  turn into an unconfirmed edit: a deletion the user has not confirmed stays
  under "Deprecated, awaiting confirmation", and the permission allowlist
  keeps its own yes. Round 5 is asked for the four features an upgrade
  offered before; the `engineering` plugin stays out for the reason the next
  note gives, and the area map stays a `/agrippa:survey` run the user asks
  for. `MIGRATION.md` records every entry in an "Interview decisions" table
  of the same shape as `INSTALL.md`'s, so both records answer "why is this
  here" the same way. The self-check requires the procedure's clauses in both
  skills and the table in both templates.
- **What is not proved.** Nothing yet proves either interview end to end; the
  self-check requires the procedure's clauses and the record templates'
  sections, and the live proof is still an install or upgrade run in a fresh
  session.

## The install skill offers the engineering plugin (2026-10-25)

The decision-record rule names the `engineering:architecture` and
`engineering:system-design` skills, and the README listed their plugin as an
optional requirement that the user had to go and install. `/agrippa:install`
now asks about it in its interview, as one more opt-in beside the spawn
logger and low-usage mode.

- **Why the committed file, and why no is recommended.** The install skill
  cannot run `/plugin install`, a terminal command, but it already writes the
  committed `.claude/settings.json`, and the `engineering` plugin lives in
  Anthropic's official marketplace, which Claude Code knows without an
  `extraKnownMarketplaces` entry. So a yes is one line,
  `"engineering@claude-plugins-official": true` under `enabledPlugins`. That
  line reaches every collaborator who trusts the folder, and the plugin is
  much larger than the two skills Agrippa uses: its MCP servers (Slack,
  Linear, GitHub, Datadog, PagerDuty, and more) each ask for authorization.
  The question therefore recommends no, says what a yes does to
  collaborators, and names `/plugin install engineering@claude-plugins-official`
  for a person who wants the skills for themselves only. The self-check
  requires the install skill to name the entry and to recommend no.
- **Not in the upgrade skill.** An upgrade touches a repository whose
  collaborators already share settings, and adding a plugin to them is a
  team decision outside a methodology upgrade. The README tells a person how
  to enable it by hand either way.

## The lint traps move into the templates (2026-10-25)

The trap list under the license note cost one nuro-battler plan three lint
rounds. Each trap was a rule the linter enforced but no template stated, and
in two cases the template itself taught the trap: the packet's `Owned files:`
was a bulleted list, which the linter reads only as far as the first bullet,
and the Integration record wrote its acceptance IDs as a range, which the
linter reads as its two ends. The fix is template wording only. No check
changed, so the linter output and the local-checks contract are as they were.

- **Where the wording goes.** `PACKETS.md` opens with a short list of the
  line formats the linter parses (contract source, census, owned files,
  acceptance and validation lines, one packet per stage), and its sample
  packet writes `Owned files:` on one line. `PLAN.md` says to write every ID
  out with commas, explains check 13 and the "full applicable suite" phrase
  under the validation matrix, and shows the `Bounded choice` row. `SPEC.md`
  warns about capital A, C, or V followed by digits in prose.
- **Why some wording sits outside the stage records.** The linter reads a
  stage's whole section, from its heading to the next stage heading or the end
  of the file, when it looks for the bounded-choice labels and for "full
  applicable suite". Guidance placed inside a stage record would satisfy those
  checks for a plan that never wrote the real row or phrase. The bounded-choice
  example therefore sits under "Milestones" before the first stage, and the
  suite phrase is explained under the validation matrix. No guidance names a
  concrete ID beyond the ones the templates define, because the linter would
  read a copied example as a reference.
- **How it was proven.** A scratch harness applied each recommended form to a
  copy of the smoke fixture in a throwaway repository and linted it with the
  plugin linter (PASS for all eight), then applied 17 trap variants on top and
  confirmed each failed with the message the templates name. The self-check
  gained 15 clauses that keep the wording and the bounded-choice placement in
  the templates and forbid an ID range in `PLAN.md`.
- **What is not proven.** Whether first-time planners now reach `PASS` in
  fewer rounds can only be counted on new plans in installed repositories.

## The project rules leave the root `AGENTS.md` (2026-10-25, release 0.4.2)

Up to 0.4.1 an install wrote the project contracts and project rules to the
repository's root `AGENTS.md` and had the root `CLAUDE.md` import it with
`@AGENTS.md`. The content now installs as `.agrippa/project-rules.md`, from
`templates/PROJECT-RULES.md`, and the root `CLAUDE.md` imports that file. The
kit writes nothing to `AGENTS.md` any more.

- **Why.** `AGENTS.md` is the file most other coding agents read from a
  repository root, so a repository often has one before Agrippa arrives, and
  the install was merging the kit's sections into a file the kit did not own.
  This is the same reason the project documents left `docs/` in 0.3.0: a name
  that is someone else's convention is not the kit's to fill. The merge rule
  handled the collision, but every upgrade then had to find the kit's sections
  inside a file the project also edits.
- **What was decided against, twice.** Earlier on 2026-10-25 a rename of the
  file to `AGRIPPA.md` was asked for and withdrawn, because the file holds the
  project's own decisions, not the plugin's rules, and a plugin-named file
  would send someone wanting to change a methodology rule to the wrong place.
  The new name keeps that distinction: `project-rules.md` says whose rules
  they are, and the folder says which kit installed the file. The other
  option, keeping the root file and mirroring it into `.agrippa/`, was
  rejected because every drift problem in these notes came from a second copy
  of a fact.
- **What is given up.** Codex, Cursor, Copilot, and Gemini CLI read a root
  `AGENTS.md` on their own and will no longer see the ownership areas and
  shared interfaces unless the repository copies them there itself. The
  methodology targets Claude Code (`docs/goals.md`, "Non-goals"), so this is
  accepted, and `UPGRADING.md` says the copy is the repository's to make.
- **Loading.** The rules reach a session only through the `@` import, where
  `AGENTS.md` at least reached other tools without one. A probe in the
  sandbox on 2026-10-25 confirmed that Claude Code follows an import whose
  path starts with a hidden folder: a fresh session whose root `CLAUDE.md`
  carried a temporary `@.agrippa/probe-rules.md` line had that file's
  codeword in context before its first tool call. So the installed
  repository check now fails when the root `CLAUDE.md` lacks the
  `@.agrippa/project-rules.md` line, not only when the file is missing. The
  folder's `CLAUDE.md` explains that `project-rules.md` is the one
  always-loaded file in `.agrippa/` and the rest load on demand, because the
  folder otherwise looks like a set of on-demand documents.
- **Detection.** The kit's opening sentence, "whose core rules the `agrippa`
  plugin adds to every session", marks a root `AGENTS.md` that has not been
  moved. A project's own `AGENTS.md` never contains it, so the check cannot
  misfire on a file the project wrote. The generic-rules check for v0.1.1
  wording looks in both the old and the new file.
- **The fixture.** The smoke fixture used to cite `AGENTS.md:1` with the
  census snippet `# Agent Workflow`, a heading left from the copied-in kit. It
  now cites `.agrippa/project-rules.md:1` with `# Project rules`, and the
  self-check pins the template's first line so the two cannot drift. The
  simulated project is a git repository holding only that file, which also
  proves the linter's path checks accept a hidden folder.
- **Release.** This changes an installed repository's layout. The plan was
  to ship it as 0.5.0; on 2026-10-27 the owner chose to release it as 0.4.2
  instead, with "From G4 v0.4.1" in `UPGRADING.md` as the move. A repository
  pinned to a tag moves only when its `ref` changes, so the upgrade step
  still runs when it does.
  The upgrade keeps whatever the project itself wrote in `AGENTS.md` and
  deletes the file only when the kit's sections were all it held, after the
  user confirms.
