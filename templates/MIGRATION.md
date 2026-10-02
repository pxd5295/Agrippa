# Planning Workflow Migration

## Scope and date

- Date: [YYYY-MM-DD]
- Kit source/version: [path and git revision of the kit used]
- Generation detected: [None / Other / G1 / G2 / G3 with drift; list the
  markers found, see the kit's `UPGRADING.md`]
- Existing plans covered: Future workspaces only; historical plans unchanged

## Existing workflow inventory

- Root/nested agent instructions: [paths, e.g. `AGENTS.md`, `CLAUDE.md`,
  per-directory `CLAUDE.md` files]
- Named Claude agents, skills, commands, and hooks: [paths]
- Any other toolchain's agent configuration or worker profiles: [paths]
- Lifecycle/routing docs, templates, shortcuts, and validators: [paths]
- Historical plan roots: [paths]
- Project contracts, decision records, and validation catalogs: [paths]
- Dirty user-owned files: [paths or None]

## Rule mapping

| Existing source/rule | Disposition | New authoritative location | Rationale |
|---|---|---|---|
| `[path: rule]` | Retain / Merge / Replace / Deprecate | `[path/section]` | [Reason; stricter rule preserved] |

## Methodology migration

- Engineering standards, definition of done, and design-reviewer size floor:
  [result]
- Design states and frozen `C#` contracts: [result]
- Changed/deleted-symbol consumer census and covering tests: [result]
- `A#`/`V#`/`C#` traceability and PACKETS: [result]
- Objective tier-routing table, split-first rule, and fork-or-fresh rule:
  [result]
- Whole-file ownership, two/three-writer gates, and cost multiplier: [result]
- Planning size gate and single-stage shape: [result]
- Minimal launch reads, planner read ladder, and Stage Model Allocation
  continuity: [result]
- Targeted/full validation, focused review, and review disposition: [result]
- Decision records and per-directory `CLAUDE.md` files: [result]

## Configuration, agent, skill, and hook changes

- [Removed project-wide model/effort pins and old toolchain config, retained
  unrelated configuration, installed `.claude/agents/*.md`, skills, commands,
  and hooks, and any local substitutions.]

## Project-specific adaptations

- Ownership/shared interfaces/high-risk classes: [summary]
- Validation catalog and full-suite inventory: [summary]
- Local linter checks (`tools/validate_plan_workspace.local.ps1`), or why none:
  [summary]
- Install-time placeholders and install notes: [all resolved, or each
  remaining one and why]
- `AskUserQuestion` and `engineering:*` skill availability and fallback:
  [summary]

## Historical preservation audit

- Audit command/check: [the hash manifest taken before any edit and compared
  after, or `git status --short plans/` when dated workspaces are tracked; a
  gitignored `plans/` makes `git status` prove nothing]
- Result: [No historical dated plan changed, or exact exception]

## Deprecated, awaiting confirmation

- [Old files the mapping deprecates that have not been deleted yet, or None]

## Validation and residual risks

| Check | Result | Notes |
|---|---|---|
| Kit self-check (`validate-kit.ps1`) | [Pass/Fail] | [details] |
| Smoke test (`fixtures/run-smoke-test.ps1 -RepoRoot .`) | [Pass/Fail] | [details] |
| Install-marker scan (kit README) | [0 hits / list] | [details] |
| Local linter checks against one real workspace | [Pass/Fail/None installed] | [details] |
| Validation catalog commands run once | [Pass/Fail] | [details] |
| Scoped formatting | [Pass/Fail] | [details] |
| Live planning smoke test | [Pending/Pass] | [details] |
| Live implementation smoke test | [Pending/Pass] | [details] |
