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
| G4: plugin (current) | The committed `.claude/settings.json` declares the `agrippa` marketplace in `extraKnownMarketplaces`, pinned with `ref`, and enables `agrippa@agrippa`. The repository keeps no copy of the plugin's agents, skills, linter, or spawn logger. `AGENTS.md` holds only project contracts and project rules, and the project's facts are in `docs/agent_memory/project-contracts.md` and `validation-commands.md`. A plan's matrix runs `agrippa-lint`. |

A G4 repository moves to a newer release by changing the marketplace `ref` to
the new tag. It can still drift from the templates; compare its project
documents with them section by section and treat each difference as a mapping
row.

## Rule mapping

Record one row per old rule in `docs/planning/MIGRATION.md`. Dispositions are
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
| No decision records | Replace | `docs/decisions/` with its README; required before a shared-interface change |
| No folder-level rules | Replace | Per-directory `CLAUDE.md` files from `templates/directory-CLAUDE.md` |
| No review procedure | Replace | The plugin skill `agrippa:receiving-review` |
| No debugging or done-evidence procedure | Replace | The plugin skills `agrippa:systematic-debugging` and `agrippa:verify-before-done` |
| No session handoff | Replace | The plugin skill `/agrippa:handoff` |
| No design-reference planning | Replace | "Plans that start from a design reference" in `agent-workflow.md`; `Design reference` sections in the `SPEC.md` template |
| Linter with hardcoded source extensions, or with project toolchain checks edited into it | Replace | `agrippa-lint`, the plugin's linter, unedited; the project's own checks move to `tools/validate_plan_workspace.local.ps1` |

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
| MCP tool names added to an agent's `tools:` line | Move | `docs/agent_memory/live-app.md`, which lists the bridge's read-only, run, and authoring tools. The plugin agents have no `tools:` line |
| `.claude/skills/design-first/` | Delete | The plugin skill `agrippa:design-first`. First move its ownership areas, shared interfaces, and owners (base classes, variants, configuration layer, funnels, engines, hook lists, schema-driven lists, hot path, gated subsystems, new subsystem kinds) into "Ownership areas", "Shared and public interfaces", and the rows of "Architecture owners" in `project-contracts.md`. Move its once-per-session setup and build step into "Session setup" and "Build" in `validation-commands.md` |
| `.claude/skills/systematic-debugging/` | Delete | The plugin skill `agrippa:systematic-debugging`. First move its layers, probe naming, working counterparts, and known differences into "Debugging map", and its companion files and worktree location into "Worktree and integration contracts", in `project-contracts.md`. Move its failure surfaces, error marker, known messages, run caps, shared log path, rebuild steps, and performance evidence into the matching sections of `validation-commands.md` |
| `.claude/skills/verify-before-done/` | Delete | The plugin skill `agrippa:verify-before-done`. First move its session setup, verdict line, error marker, run cap, linter scope, build, performance evidence, and environment limits into the matching sections of `validation-commands.md`, and its gate targets into the "Gated subsystems" row of "Architecture owners" in `project-contracts.md` |
| `.claude/skills/receiving-review/` | Delete | The plugin skill `agrippa:receiving-review`. It held no project facts |
| `.claude/commands/handoff.md` | Delete | The plugin skill `/agrippa:handoff`. Move a changed transcript-path rule into the project's `CLAUDE.md` |
| `docs/agent-workflow.md` | Delete | `agent-workflow.md` in the `plan` skill. Move any project facts added to it into `project-contracts.md` or `validation-commands.md` |
| `docs/planning/ROUTING.md` | Delete | `ROUTING.md` in the `plan` skill. Move any project facts added to it into `project-contracts.md` |
| `docs/planning/templates/*.md` | Delete | The templates in the `plan` skill, which the plugin's linter parses |
| `docs/planning/CLAUDE.md` | Replace | Rewrite it from `templates/planning-CLAUDE.md`, which says the guides and templates are in the plugin |
| `tools/validate_plan_workspace.ps1` | Delete | `agrippa-lint`, the plugin's linter. Keep `tools/validate_plan_workspace.local.ps1`; the plugin's linter loads it |
| `tools/log_subagent_spawns.ps1` | Delete | The plugin's spawn logger, which runs when the `env` block of `.claude/settings.json` sets `AGRIPPA_SPAWN_LOG=1` |
| `tools/hook_payload.ps1` | Delete | The plugin's copy serves its spawn logger. Keep the project's copy only when another project script, such as the edit-lint hook, dot-sources it |
| `.claude/settings.json` hook entries that run `tools/log_subagent_spawns.ps1` | Delete | The plugin's `hooks/hooks.json`. Add `AGRIPPA_SPAWN_LOG=1` to the `env` block instead, or every spawn is logged twice |
| `.claude/settings.json` permission for `tools/validate_plan_workspace.ps1` | Replace | `Bash(agrippa-lint:*)` |
| No plugin declaration in `.claude/settings.json` | Replace | `extraKnownMarketplaces.agrippa` pinned with `ref`, and `enabledPlugins` `agrippa@agrippa`, as the README section "Enabling the plugin in a project" shows |
| The edit-lint hook script and its wiring | Retain | It is the project's own and wraps the project's linter |
| Project skills and commands that are not the kit's | Retain | They are the project's own |
| Matrix rows that run `tools/validate_plan_workspace.ps1` in dated plan workspaces | Retain | Dated plans are records and are never edited. New plans run `agrippa-lint` |

### Always

- Keep stricter project safety, validation, and review rules (Merge, never
  Replace with something weaker).
- Keep unrelated configuration, hooks, permissions, and agents.
- Never edit, move, rename, or bulk-convert a dated plan workspace. Old
  workspaces may fail the new linter; that is expected and is recorded, not
  fixed.
- Remove an old file only after the user confirms. Report it as "deprecated,
  awaiting confirmation" until then.
