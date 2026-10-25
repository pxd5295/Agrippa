# Upgrading an older planning methodology

The `/agrippa:upgrade` skill starts here. First decide which generation of
this methodology the repository has, then apply the rule mapping for that
generation. A repository can mix generations (for example a current
`AGENTS.md` with old agent profiles); treat every marker found as something to
map.

This is the only kit file that names older toolchains, because a session has
to recognize their markers to remove them. Nothing here is installed.

## Recognize the generation

| Generation | Markers (any one is enough) |
|---|---|
| None | No `AGENTS.md` planning trigger, no `plans/` workspaces with `SPEC.md`/`PLAN.md`, no planning templates. Use `/agrippa:install` instead. |
| Other methodology | Planning docs that do not follow this lineage (ADR-only processes, RFC folders, issue templates, a different agent framework). Treat each rule as an existing rule to map; do not delete it unmapped. |
| G1: dual toolchain (Codex lead, Claude scout) | `.codex/config.toml`; `.codex/agents/*.toml` profiles named `sol-*`, `terra-*`, `luna-*` (worker, reviewer, scout, validator); `docs/codex-planning-methodology-kit/`; an `AGENTS.md` section "Planning trigger and Sol-High entry" that stops with "Select Sol with High reasoning beneath the composer"; a Sol-Medium plan-writing handoff; the `Implement plan use workers` shortcut; launch stops for allocation confirmation; `default_mode_request_user_input = true`; `max_threads`; "one thread remains reserved for the lead"; only `.claude/agents/repo-scout.md` on the Claude side. |
| G2: first Claude-only kit | `AGENTS.md` with "Planning artifacts", "Implementation launch and shortcut", "Dependency-wave execution", and "Validation and review" sections but no "Engineering standards" or "Definition of done"; exactly three agents (`repo-scout` and `validator` on `haiku`, `plan-reviewer` without Blocking/Optional classes); validation matrix column `Environment`; no `Covering tests:` in contracts; three-writer gate citing "material wall-clock benefit"; no "Fork or fresh subagent" section; no single-stage workspace shape or planning size gate; no design-reference planning; a kit `validate-kit.ps1` with a forbidden-terms list. |
| G3: copied-in kit | The methodology copied into the repository: an `AGENTS.md` that holds the Engineering standards, definition of done, and planning trigger itself; four agents in `.claude/agents/` including `design-reviewer.md`; the `design-first`, `systematic-debugging`, `verify-before-done`, and `receiving-review` skills in `.claude/skills/`; `.claude/commands/handoff.md`; `docs/agent-workflow.md`; `docs/planning/ROUTING.md`; `docs/planning/templates/`; `tools/validate_plan_workspace.ps1`; `tools/log_subagent_spawns.ps1` and `tools/hook_payload.ps1`; a plan validation matrix row that runs `tools/validate_plan_workspace.ps1`. |
| G4: plugin (current) | The committed `.claude/settings.json` declares the `agrippa` marketplace in `extraKnownMarketplaces`, pinned with `ref`, and enables `agrippa@agrippa`. The repository keeps no copy of the plugin's agents, skills, linter, or spawn logger. `AGENTS.md` holds only project contracts and project rules, and the project's facts are in `.agrippa/project-contracts.md` and `validation-commands.md` (under `docs/agent_memory/` up to v0.2.0). A plan's matrix runs `agrippa-lint`. |

A G4 repository moves to a newer release by changing the marketplace `ref` to
the new tag. It can still drift from the templates; compare its project
documents with them section by section and treat each difference as a mapping
row. A repository installed at v0.1.0 also has three files whose rules now
ship in the plugin; apply "From G4 v0.1.0" below. A repository installed at
v0.1.0 or v0.1.1 also has generic rule text inside its project documents;
apply "From G4 v0.1.1" below. From v0.1.2 the plugin's hooks run on Node.js
instead of Windows PowerShell, so every machine that uses the plugin needs
`node` on PATH; a project file does not change for this. From v0.2.0 the
linter runs on Node.js too and loads `tools/validate_plan_workspace.local.mjs`
instead of the PowerShell local file; a repository that has
`tools/validate_plan_workspace.local.ps1` applies "From G4 v0.1.2" below.
PowerShell is no longer required anywhere. Up to v0.2.0 the project documents
and the decision records lived under `docs/`; a repository that has
`docs/agent_memory/` or `docs/decisions/` applies "From G4 v0.2.0" below. Up
to v0.3.0 an upgrade wrote its record to `docs/planning/MIGRATION.md`; a
repository that has that file applies "From G4 v0.3.0" below.

## Rule mapping

Record one row per old rule in `.agrippa/MIGRATION.md`. Dispositions are
Retain (keep as is), Merge (keep the stricter of old and new), Replace (the new
rule supersedes it), and Deprecate (remove with no successor).

"Core rules" below means the plugin's `scripts/core-rules.md`, which a hook
adds to every session and subagent. "The `plan` skill" means the plugin's
`agrippa:plan` skill and its reference files `agent-workflow.md` and
`ROUTING.md`.

### From G1 (dual toolchain)

| Old rule or artifact | Disposition | New authoritative location |
|---|---|---|
| Sol-High entry gate and switch-and-resume prompt before planning | Deprecate | Core rules "Planning trigger": planning starts on the current model; recommend a stronger model once for complex work, never block |
| Sol-Medium plan-writing handoff with its five conditions | Replace | The planning size gate in the core rules and the single-stage shape in `agent-workflow.md` |
| `.codex/config.toml` (`max_threads`, `max_depth`, features) | Deprecate | No toolchain config is installed. Writer limits live in `ROUTING.md` "Waves and parallelism" |
| `default_mode_request_user_input` | Replace | `AskUserQuestion` in the planning interview |
| `.codex/agents/*-worker.toml` implementation profiles | Replace | Inline `general-purpose` spawns with a verbatim packet and a routed `model` (`ROUTING.md` "Roster") |
| `terra-scout` | Replace | The plugin agent `agrippa:repo-scout` (`sonnet`) |
| `*-reviewer` profiles | Replace | The plugin agents `agrippa:plan-reviewer` (`sonnet`, Opus for high risk) and `agrippa:design-reviewer` |
| `terra-validator` | Replace | The plugin agent `agrippa:validator` (`sonnet`, `haiku` per packet) |
| Luna / Terra / Sol tiers with Low/Medium/High effort | Replace | `haiku` / `sonnet` / `opus`, with effort raised inside a tier before the model. Luna maps to `haiku`, Terra to `sonnet`, Sol to `opus`; the old "Terra High or Sol needs a split attempt" rule becomes the Opus split-first rule |
| `Implement plan use workers` override and per-launch allocation confirmation | Deprecate | `Implement plan` spawns routed subagents by default; the request itself authorizes the spawns |
| "One thread remains reserved for the lead" in the three-writer gate | Replace | Three writers need every listed gate plus a stated, accepted token-cost multiplier |
| Project-wide pin of the lead's model or reasoning effort | Deprecate | Core rules "Request boundaries" |
| `docs/codex-planning-methodology-kit/` | Deprecate | The plugin; delete the old copy only after the user confirms |
| `.claude/agents/repo-scout.md` | Replace | Apply its "From G3" row |

Then apply every G2 row below, because G1 also lacks all of them.

### From G2 (first Claude-only kit)

| Old rule or artifact | Disposition | New authoritative location |
|---|---|---|
| No engineering rules for unplanned changes | Replace | Core rules "Engineering standards" and "Definition of done", the plugin skill `agrippa:design-first` |
| Three agents | Replace | The four plugin agents. `agrippa:design-reviewer` is new, `repo-scout` and `validator` run on `sonnet` (a census and a suite are long-context work), and `plan-reviewer` has Blocking/Optional classes and the no-padding rule. Apply the "From G3" rows to the old copies |
| Every request gets a full workspace | Replace | The planning size gate in the core rules; the single-stage shape in `agent-workflow.md` |
| Three-writer gate citing material wall-clock benefit | Replace | Stated, accepted token-cost multiplier (STORM: cost linear per writer, wall-clock flat); `Cost multiplier` bullet in the `PLAN.md` template |
| Contracts without a test map | Replace | `Covering tests:` in every contract, copied into the packet; linter check 26 (TDAD) |
| No fork rule | Replace | `ROUTING.md` "Fork or fresh subagent" |
| Validation column `Environment` | Replace | Column `Sandbox` with `sandboxed` / `outside-sandbox`. The linter accepts either name, so old workspaces still lint |
| Planner reads not bounded | Replace | Core rules "Planner read ladder" |
| No decision records | Replace | `.agrippa/decisions/` with its pointer README; required before a shared-interface change, in the shape the `agrippa:design-first` skill gives |
| No folder-level rules | Replace | Per-directory `CLAUDE.md` files from `templates/directory-CLAUDE.md` |
| No review procedure | Replace | The plugin skill `agrippa:receiving-review` |
| No debugging or done-evidence procedure | Replace | The plugin skills `agrippa:systematic-debugging` and `agrippa:verify-before-done` |
| No session handoff | Replace | The plugin skill `/agrippa:handoff` |
| No design-reference planning | Replace | "Plans that start from a design reference" in `agent-workflow.md`; `Design reference` sections in the `SPEC.md` template |
| Linter with hardcoded source extensions, or with project toolchain checks edited into it | Replace | `agrippa-lint`, the plugin's linter, unedited; the project's own checks move to `tools/validate_plan_workspace.local.mjs` |

Then apply every G3 row below to each copied-in file the repository has.

### From G3 (copied-in kit)

Every file a G3 install copied in is either deleted, because the plugin now
provides it, or has its project facts moved into a project document first.
G3 filled the copied agents and skills at install time, so they are the data
source for the project documents: move each fact into the named section
before deleting the file, and rediscover nothing. Delete a file only after the
user confirms it.

| G3 file or setting | Disposition | What happens |
|---|---|---|
| `AGENTS.md` sections "Request boundaries", "Engineering standards", "Definition of done", "Planning trigger", "Implementation launch", and "Validation reach" | Replace | The core rules hold them. Keep only "Project contracts" and any project rules, in the shape of `templates/AGENTS.md`. A project rule that is stricter than a core rule stays, under "Project rules" |
| Class names inlined in the Engineering standards (base classes, funnels, the performance-owned subsystem) | Move | "Architecture owners" in `project-contracts.md` |
| Root `CLAUDE.md` roster, skills list, and planner read ladder | Replace | The core rules hold them. Keep the `@AGENTS.md` import and the project skills, in the shape of `templates/CLAUDE.md` |
| `.claude/agents/repo-scout.md` | Delete | The plugin agent `agrippa:repo-scout`. First move its other contract documents into "Contract documents" and its language servers into the "Language servers" row of "Architecture owners" in `project-contracts.md`, and its live-app lookups and serialized file types into "Read-only tools" and "Serialized files" in `live-app.md` |
| `.claude/agents/plan-reviewer.md` | Delete | The plugin agent `agrippa:plan-reviewer`. First move its project paragraph into "Project summary", "Shared and public interfaces", and the "Gated subsystems" and "Language servers" rows of "Architecture owners" in `project-contracts.md`, and into "Build" in `validation-commands.md`. Move its live-app tools into "Server" and "Read-only tools" in `live-app.md` |
| `.claude/agents/design-reviewer.md` | Delete | The plugin agent `agrippa:design-reviewer`. First move its variant axis, shared engines, reimplementation case, and language servers into the matching rows of "Architecture owners", its contract sources into "Shared and public interfaces", and its highest-risk dispatch layer into the Native/ABI row of "High-risk change classes", all in `project-contracts.md`. Move its live-app tools and style document into "Read-only tools", "Run tools", "Authoring tools", and "Layout checks" in `live-app.md` |
| `.claude/agents/validator.md` | Delete | The plugin agent `agrippa:validator`. First move its permitted cache writes and invocation traps into "Runtime writes and caches" and "Invocation traps" in `validation-commands.md`, and its live-app tools and bridge test runner into "Server", "Read-only tools", "Run tools", and "Test runner" in `live-app.md` |
| MCP tool names added to an agent's `tools:` line | Move | `.agrippa/live-app.md`, which lists the bridge's read-only, run, and authoring tools. The plugin agents have no `tools:` line |
| `.claude/skills/design-first/` | Delete | The plugin skill `agrippa:design-first`. First move its ownership areas, shared interfaces, and owners (base classes, variants, configuration layer, funnels, engines, hook lists, schema-driven lists, hot path, gated subsystems, new subsystem kinds) into "Ownership areas", "Shared and public interfaces", and the rows of "Architecture owners" in `project-contracts.md`. Move its once-per-session setup and build step into "Session setup" and "Build" in `validation-commands.md` |
| `.claude/skills/systematic-debugging/` | Delete | The plugin skill `agrippa:systematic-debugging`. First move its layers, probe naming, working counterparts, and known differences into "Debugging map", and its companion files and worktree location into "Worktree and integration contracts", in `project-contracts.md`. Move its failure surfaces, error marker, known messages, run caps, shared log path, rebuild steps, and performance evidence into the matching sections of `validation-commands.md` |
| `.claude/skills/verify-before-done/` | Delete | The plugin skill `agrippa:verify-before-done`. First move its session setup, verdict line, error marker, run cap, linter scope, build, performance evidence, and environment limits into the matching sections of `validation-commands.md`, and its gate targets into the "Gated subsystems" row of "Architecture owners" in `project-contracts.md` |
| `.claude/skills/receiving-review/` | Delete | The plugin skill `agrippa:receiving-review`. It held no project facts |
| `.claude/commands/handoff.md` | Delete | The plugin skill `/agrippa:handoff`. Move a changed transcript-path rule into the project's `CLAUDE.md` |
| `docs/agent-workflow.md` | Delete | `agent-workflow.md` in the `plan` skill. Move any project facts added to it into `project-contracts.md` or `validation-commands.md` |
| `docs/planning/ROUTING.md` | Delete | `ROUTING.md` in the `plan` skill. Move any project facts added to it into `project-contracts.md` |
| `docs/planning/templates/*.md` | Delete | The templates in the `plan` skill, which the plugin's linter parses |
| `tools/validate_plan_workspace.ps1` | Delete | `agrippa-lint`, the plugin's linter. Port `tools/validate_plan_workspace.local.ps1` to `tools/validate_plan_workspace.local.mjs` as "From G4 v0.1.2" says; the plugin's linter loads the `.mjs` |
| `tools/log_subagent_spawns.ps1` | Delete | The plugin's spawn logger, which runs when the `env` block of `.claude/settings.json` sets `AGRIPPA_SPAWN_LOG=1` |
| `tools/hook_payload.ps1` | Delete | Nothing; the plugin's spawn logger does not need it. Keep the project's copy only when another project script, such as the edit-lint hook, dot-sources it |
| `.claude/settings.json` hook entries that run `tools/log_subagent_spawns.ps1` | Delete | The plugin's `hooks/hooks.json`. Add `AGRIPPA_SPAWN_LOG=1` to the `env` block instead, or every spawn is logged twice |
| `.claude/settings.json` permission for `tools/validate_plan_workspace.ps1` | Replace | `Bash(agrippa-lint:*)` |
| No plugin declaration in `.claude/settings.json` | Replace | `extraKnownMarketplaces.agrippa` pinned with `ref`, and `enabledPlugins` `agrippa@agrippa`, as the README section "Enabling the plugin in a project" shows |
| The edit-lint hook script and its wiring | Retain | It is the project's own and wraps the project's linter |
| Project skills and commands that are not the kit's | Retain | They are the project's own |
| Matrix rows that run `tools/validate_plan_workspace.ps1` in dated plan workspaces | Retain | Dated plans are records and are never edited. New plans run `agrippa-lint` |
| Generic rules written into `docs/agent_memory/validation-commands.md`: the noisy-retry rule, the pre-existing-failure rule, the Sandbox value definitions, the allowed Determinism values, the "copy commands verbatim" and "run the matrix once before implementing" rules, and the local-linter rule | Delete | The `plan` skill's `agent-workflow.md` ("Validation matrix values") and the plugin skill `agrippa:verify-before-done` ("Retries"). G3 reworded these and mixed them with project facts, so read each bullet and keep only the project fact in it |
| Project facts under a `## Plan-matrix contract` heading in `validation-commands.md` | Move | Into a section that stays, such as "Full-suite inventory", "Performance evidence", or "Invocation traps"; then delete the heading, which the current template does not have |
| Live-app bridge rules in `AGENTS.md` or `validation-commands.md` (confirm the session, no-persist run, both logs, stale frames, headless matrix rows, bridge down means not done) | Delete | The plugin agents and `agrippa:verify-before-done` ("Live-app bridge"). `AGENTS.md` keeps one or two sentences naming the server and pointing to `live-app.md`, in the shape of `templates/AGENTS.md`; the Godot facts go to `live-app.md` |

Then apply the "From G4 v0.1.0" rows below, because a G3 install has full
copies of those files too, the "From G4 v0.1.1" rows after them, "From G4
v0.1.2" when the repository has a PowerShell local-checks file, and "From G4
v0.2.0", because every install before v0.3.0 wrote its documents under
`docs/`.

### From G4 v0.1.0

Up to v0.1.0, an install copied three generic files into the project in full.
Their rules now ship in the plugin: the plan-workspace rules in the `plan`
skill's `workspace-files.md`, and the decision-record rules in the
`design-first` skill's `decision-records.md`. A full copy left in the project
drifts from the plugin, so it is replaced or deleted. `dev/validate-kit.mjs
-InstalledRepo` reports each one.

| v0.1.0 file | Disposition | What happens |
|---|---|---|
| `plans/README.md` with the sections "Artifact contract" and "Selective reads and soft budgets" | Replace | Overwrite it with `templates/plans-README.md`, a short pointer with no rules. Move any project rule added to it into "Project rules" in `AGENTS.md` first |
| `docs/decisions/README.md` with the sections "When a record is required" and "Shape" | Replace | Overwrite it with `templates/decisions-README.md`, a short pointer with no rules. Move any project rule added to it into "Project rules" in `AGENTS.md` first |
| `docs/planning/CLAUDE.md` | Delete | The guides and templates it pointed to are in the `plan` skill, which also says a project keeps no copy of them. Nothing of the kit's stays in `docs/planning/`; the upgrade record is `.agrippa/MIGRATION.md`, which says itself that it is a record |

### From G4 v0.1.1

Up to v0.1.1, the templates for `project-contracts.md`,
`validation-commands.md`, `live-app.md`, and `AGENTS.md` carried generic rule
text beside the project's facts, so every install copied it. Those rules now
ship in the plugin: the matrix values and catalog rules in the `plan` skill's
`agent-workflow.md`, the retry and bridge rules in `agrippa:verify-before-done`
and the agents, and the risk-flag rule in `ROUTING.md`. A copy left in a
project drifts from the plugin, so each is deleted; the section headings and
the project's facts stay. `dev/validate-kit.mjs -InstalledRepo` reports each
copy it recognizes by its template wording.

| v0.1.1 text | Disposition | What happens |
|---|---|---|
| `validation-commands.md`: the "Retry rule" and "Existing-failure rule" bullets under "Runtime and invocation rules" | Replace | Delete both. Keep the project's list of red targets as a "Known red targets at `HEAD`" bullet, with the date checked |
| `validation-commands.md`: the two Sandbox value definitions under "Sandbox stance" | Delete | Keep the heading and the project's sentence naming its `outside-sandbox` targets |
| `validation-commands.md`: the "Allowed plan-matrix determinism values" paragraph after the command catalog | Delete | Nothing replaces it |
| `validation-commands.md`: the opening paragraph of "Full-suite inventory" | Delete | Keep the heading and the table |
| `validation-commands.md`: the whole "Plan-matrix contract" section | Delete | If the project added facts under it, move them to a section that stays first |
| `project-contracts.md`: the opening paragraphs of "Ownership areas", "Architecture owners", and "Shared and public interfaces", the "cite them by path" sentence under "Contract documents", the paragraph after the "High-risk change classes" table, and the last two bullets of "Environment boundaries" | Delete | Keep every heading, table, and project bullet. Any project fact inside one of those paragraphs moves into the table or a bullet under the same heading |
| `live-app.md`: the opening paragraph about which tools the agents may call, the "Which agents run the app" paragraph, the second and third sentences of the "Authoring tools" introduction, the citation sentences under "Serialized files", and the whole "Rules" section | Delete | Keep the headings, the tables, and the project's facts |
| `AGENTS.md`: the opening paragraph's list of core-rule sections, and the live-app paragraph's bridge rules | Replace | The shape of `templates/AGENTS.md`: one sentence saying the plugin adds the core rules, and one or two sentences naming the server and pointing to `live-app.md`. The generated-files paragraph stays |

### From G4 v0.1.2

Up to v0.1.2 the linter was a PowerShell script, and a project's command
invariants were PowerShell functions in
`tools/validate_plan_workspace.local.ps1`, which the linter dot-sourced. From
v0.2.0 the linter is a Node script and imports
`tools/validate_plan_workspace.local.mjs` instead. A project with no local file
changes nothing. A project with the `.ps1` ports it; until then `agrippa-lint`
fails with a `[Local]` error naming the file, so the project's rules never
silently stop running. The command, its arguments, the `Bash(agrippa-lint:*)`
permission, and every plan's matrix row stay the same. One result can change:
Node reads plan and source files as UTF-8, where Windows PowerShell 5.1 read a
file without a byte-order mark in the system code page, so a check 4 or check
25 comparison that involves non-ASCII text is now right where it was wrong.

| v0.1.2 file or construct | Disposition | What happens |
|---|---|---|
| `tools/validate_plan_workspace.local.ps1` | Replace | `tools/validate_plan_workspace.local.mjs`, written from `templates/validate-plan-workspace.local.mjs` with the same rules, and proved by linting one recent plan workspace. Delete the `.ps1` after the user confirms |
| `function Test-LocalValidationRow { param([object]$Row, [string]$Command, [string]$Sandbox) ... }` | Replace | `export function checkValidationRow({ row, command, sandbox, check }) { ... }` |
| `function Test-LocalValidationMatrix { param([object[]]$Rows) ... }` | Replace | `export function checkValidationMatrix({ rows, check }) { ... }` |
| `Add-Check ($condition) "message"` | Replace | `check(condition, 'message')` |
| `$Row.'Validation ID'`, `$_.'Exact command or check'` | Replace | `row['Validation ID']`, `row['Exact command or check']`, keyed by the header text as the plan template writes it |
| `$Command -match '(?i)pattern'`, `-notmatch` | Replace | `/pattern/i.test(command)`, `!/pattern/i.test(command)`. PowerShell `-match` ignores case even without `(?i)`, so give every ported pattern the `i` flag, and compare `-eq` strings with `.toLowerCase()` |
| `$Command -match [regex]::Escape('literal')` | Replace | `command.toLowerCase().includes('literal'.toLowerCase())` |
| `$CommandPathExtensions = @('gd', 'tscn')` | Replace | `export const commandPathExtensions = ['gd', 'tscn'];` |
| A script-scope variable both functions share | Retain | A module-level `const` |

### From G4 v0.2.0

Up to v0.2.0, an install wrote the project documents to `docs/agent_memory/`
and the decision records to `docs/decisions/`. `docs/` is a generic folder
that a repository often already uses for its own material, so from v0.3.0
both live in `.agrippa/`, a hidden folder at the repository root named after
the plugin: the documents directly under it, and the records in
`.agrippa/decisions/`. Claude Code loads `.agrippa/CLAUDE.md` when a session
reads a file in the folder, exactly as it did for the old one. Nothing else
changes: the file names, their sections, the plugin's agents and skills, and
`agrippa-lint` stay the same. `dev/validate-kit.mjs -InstalledRepo` fails
while either old folder exists. Command-line `rg` skips hidden folders unless
given `--hidden`; `git grep` and Claude Code's own search tools search them.

| v0.2.0 path or reference | Disposition | What happens |
|---|---|---|
| `docs/agent_memory/` and every file in it | Move | `git mv docs/agent_memory .agrippa`. The file names stay the same |
| `docs/decisions/` and every record in it | Move | `git mv docs/decisions .agrippa/decisions`, after the first move so that the folder exists |
| `docs/agent_memory/CLAUDE.md` | Replace | Now `.agrippa/CLAUDE.md`. Rewrite it from `templates/agrippa-CLAUDE.md`, keeping the project's own bullets under "The files" |
| References to the old paths in `AGENTS.md`, every `CLAUDE.md`, the project documents themselves, `plans/README.md`, `tools/validate_plan_workspace.local.mjs`, an edit-lint hook script, and `.claude/settings.json` permissions | Replace | The `.agrippa/` path. Find them with `git grep -n -e docs/agent_memory -e docs/decisions` |
| References inside dated plan workspaces and decision records | Retain | They are records and are never edited; a reader follows the moved path |

### From G4 v0.3.0

Up to v0.3.0, an upgrade wrote its record to `docs/planning/MIGRATION.md`,
the last kit file under `docs/`. It is now `.agrippa/MIGRATION.md`, beside
the project documents, so the kit claims nothing under `docs/`. The file is a
record and its content does not change.

| v0.3.0 path | Disposition | What happens |
|---|---|---|
| `docs/planning/MIGRATION.md` | Move | `git mv docs/planning/MIGRATION.md .agrippa/MIGRATION.md`. A new upgrade appends its own section to the moved file rather than starting a second record |
| An empty `docs/planning/` left behind | Delete | Remove the folder only if nothing of the project's own is in it |

### Always

- Keep stricter project safety, validation, and review rules (Merge, never
  Replace with something weaker).
- Keep unrelated configuration, hooks, permissions, and agents.
- Never edit, move, rename, or bulk-convert a dated plan workspace. Old
  workspaces may fail the new linter; that is expected and is recorded, not
  fixed.
- Remove an old file only after the user confirms. Report it as "deprecated,
  awaiting confirmation" until then.
