# Upgrading an older planning methodology

The upgrade prompt in `README.md` starts here. First decide which generation
of this methodology the repository has, then apply the rule mapping for that
generation. A repository can mix generations (for example a current
`AGENTS.md` with old agent profiles); treat every marker found as something to
map.

This is the only kit file that names older toolchains, because a session has
to recognize their markers to remove them. Nothing here is installed.

## Recognize the generation

| Generation | Markers (any one is enough) |
|---|---|
| None | No `AGENTS.md` planning trigger, no `plans/` workspaces with `SPEC.md`/`PLAN.md`, no planning templates. Use the new-project prompt instead. |
| Other methodology | Planning docs that do not follow this lineage (ADR-only processes, RFC folders, issue templates, a different agent framework). Treat each rule as an existing rule to map; do not delete it unmapped. |
| G1: dual toolchain (Codex lead, Claude scout) | `.codex/config.toml`; `.codex/agents/*.toml` profiles named `sol-*`, `terra-*`, `luna-*` (worker, reviewer, scout, validator); `docs/codex-planning-methodology-kit/`; an `AGENTS.md` section "Planning trigger and Sol-High entry" that stops with "Select Sol with High reasoning beneath the composer"; a Sol-Medium plan-writing handoff; the `Implement plan use workers` shortcut; launch stops for allocation confirmation; `default_mode_request_user_input = true`; `max_threads`; "one thread remains reserved for the lead"; only `.claude/agents/repo-scout.md` on the Claude side. |
| G2: first Claude-only kit | `AGENTS.md` with "Planning artifacts", "Implementation launch and shortcut", "Dependency-wave execution", and "Validation and review" sections but no "Engineering standards" or "Definition of done"; exactly three agents (`repo-scout` and `validator` on `haiku`, `plan-reviewer` without Blocking/Optional classes); validation matrix column `Environment`; no `Covering tests:` in contracts; three-writer gate citing "material wall-clock benefit"; no "Fork or fresh subagent" section; no single-stage workspace shape or planning size gate; no design-reference planning; a kit `validate-kit.ps1` with a forbidden-terms list. |
| G3: current | Everything in this kit: Engineering standards with a definition of done and a design-reviewer size floor, four agents including `design-reviewer`, the `design-first`, `systematic-debugging`, `verify-before-done`, and `receiving-review` skills, `/handoff`, `docs/decisions/`, per-directory `CLAUDE.md` files, `Covering tests:` with linter check 26, the cost-multiplier gate, fork-or-fresh routing, the planner read ladder, and design-reference planning. A G3 repository can still drift from the kit; compare section by section and treat each difference as a mapping row. |

## Rule mapping

Record one row per old rule in `docs/planning/MIGRATION.md`. Dispositions are
Retain (keep as is), Merge (keep the stricter of old and new), Replace (the new
rule supersedes it), and Deprecate (remove with no successor).

### From G1 (dual toolchain)

| Old rule or artifact | Disposition | New authoritative location |
|---|---|---|
| Sol-High entry gate and switch-and-resume prompt before planning | Deprecate | `AGENTS.md` "Planning trigger": planning starts on the current model; recommend a stronger model once for complex work, never block |
| Sol-Medium plan-writing handoff with its five conditions | Replace | `AGENTS.md` planning size gate and the single-stage shape in `docs/agent-workflow.md` |
| `.codex/config.toml` (`max_threads`, `max_depth`, features) | Deprecate | No toolchain config is installed. Writer limits live in `docs/planning/ROUTING.md` "Waves and parallelism" |
| `default_mode_request_user_input` | Replace | `AskUserQuestion` in the planning interview |
| `.codex/agents/*-worker.toml` implementation profiles | Replace | Inline `general-purpose` spawns with a verbatim packet and a routed `model` (`docs/planning/ROUTING.md` "Roster") |
| `terra-scout` | Replace | `.claude/agents/repo-scout.md` (`sonnet`) |
| `*-reviewer` profiles | Replace | `.claude/agents/plan-reviewer.md` (`sonnet`, Opus for high risk) plus `.claude/agents/design-reviewer.md` |
| `terra-validator` | Replace | `.claude/agents/validator.md` (`sonnet`, `haiku` per packet) |
| Luna / Terra / Sol tiers with Low/Medium/High effort | Replace | `haiku` / `sonnet` / `opus`, with effort raised inside a tier before the model. Luna maps to `haiku`, Terra to `sonnet`, Sol to `opus`; the old "Terra High or Sol needs a split attempt" rule becomes the Opus split-first rule |
| `Implement plan use workers` override and per-launch allocation confirmation | Deprecate | `Implement plan` spawns routed subagents by default; the request itself authorizes the spawns |
| "One thread remains reserved for the lead" in the three-writer gate | Replace | Three writers need every listed gate plus a stated, accepted token-cost multiplier |
| Project-wide pin of the lead's model or reasoning effort | Deprecate | `AGENTS.md` "Request boundaries and model freedom" |
| `docs/codex-planning-methodology-kit/` | Deprecate | This kit; delete the old copy only after the user confirms |

Then apply every G2 row below, because G1 also lacks all of them.

### From G2 (first Claude-only kit)

| Old rule or artifact | Disposition | New authoritative location |
|---|---|---|
| No engineering rules for unplanned changes | Replace | `AGENTS.md` "Engineering standards" and "Definition of done", `.claude/skills/design-first/` |
| Three agents | Merge | Add `.claude/agents/design-reviewer.md`; move `repo-scout` and `validator` from `haiku` to `sonnet` (a census and a suite are long-context work); add Blocking/Optional classes and the no-padding rule to `plan-reviewer` |
| Every request gets a full workspace | Replace | Planning size gate in `AGENTS.md`; single-stage shape in `docs/agent-workflow.md` |
| Three-writer gate citing material wall-clock benefit | Replace | Stated, accepted token-cost multiplier (STORM: cost linear per writer, wall-clock flat); `Cost multiplier` bullet in the `PLAN.md` template |
| Contracts without a test map | Replace | `Covering tests:` in every contract, copied into the packet; linter check 26 (TDAD) |
| No fork rule | Replace | `docs/planning/ROUTING.md` "Fork or fresh subagent" |
| Validation column `Environment` | Replace | Column `Sandbox` with `sandboxed` / `outside-sandbox`. The linter accepts either name, so old workspaces still lint |
| Planner reads not bounded | Replace | Planner read ladder in the root `CLAUDE.md` |
| No decision records | Replace | `docs/decisions/` with its README; required before a shared-interface change |
| No folder-level rules | Replace | Per-directory `CLAUDE.md` files from `templates/directory-CLAUDE.md` |
| No review procedure | Replace | `.claude/skills/receiving-review/` |
| No debugging or done-evidence procedure | Replace | `.claude/skills/systematic-debugging/`, `.claude/skills/verify-before-done/` |
| No session handoff | Replace | `.claude/commands/handoff.md` |
| No design-reference planning | Replace | "Plans that start from a design reference" in `docs/agent-workflow.md`; `Design reference` sections in the `SPEC.md` template |
| Linter with hardcoded source extensions, or with project toolchain checks edited into it | Replace | `tools/validate_plan_workspace.ps1` from this kit, unedited; the project's own checks move to `tools/validate_plan_workspace.local.ps1` |

### Always

- Keep stricter project safety, validation, and review rules (Merge, never
  Replace with something weaker).
- Keep unrelated configuration, hooks, permissions, and agents.
- Never edit, move, rename, or bulk-convert a dated plan workspace. Old
  workspaces may fail the new linter; that is expected and is recorded, not
  fixed.
- Remove an old file only after the user confirms. Report it as "deprecated,
  awaiting confirmation" until then.
