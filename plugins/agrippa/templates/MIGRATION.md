# Planning Workflow Migration

This file records how this repository adopted or upgraded the Agrippa
planning methodology. It is a record: never edit its decisions afterwards.

## Scope and date

- Date: [PROJECT: YYYY-MM-DD]
- Plugin version: [PROJECT: the `agrippa` plugin version and the marketplace
  `ref` pinned in `.claude/settings.json`]
- Generation detected: [PROJECT: None / Other / G1 / G2 / G3 / G4 with drift;
  list the markers found, see the plugin's `UPGRADING.md`]
- Existing plans covered: Future workspaces only; historical plans unchanged

## Existing workflow inventory

- Root/nested agent instructions: [PROJECT: paths, e.g. `AGENTS.md`,
  `CLAUDE.md`, per-directory `CLAUDE.md` files]
- Named Claude agents, skills, commands, and hooks: [PROJECT: paths]
- Any other toolchain's agent configuration or worker profiles: [PROJECT: paths]
- Lifecycle/routing docs, templates, shortcuts, and validators: [PROJECT: paths]
- Historical plan roots: [PROJECT: paths]
- Project contracts, decision records, and validation catalogs: [PROJECT: paths]
- Dirty user-owned files: [PROJECT: paths or None]

## Rule mapping

| Existing source/rule | Disposition | New authoritative location | Rationale |
|---|---|---|---|
| `[PROJECT: path: rule]` | Retain / Merge / Replace / Deprecate | `[PROJECT: path/section]` | [PROJECT: Reason; stricter rule preserved] |

## Methodology migration

- Engineering standards, definition of done, and design-reviewer size floor:
  [PROJECT: result]
- Design states and frozen `C#` contracts: [PROJECT: result]
- Changed/deleted-symbol consumer census and covering tests: [PROJECT: result]
- `A#`/`V#`/`C#` traceability and PACKETS: [PROJECT: result]
- Objective tier-routing table, split-first rule, and fork-or-fresh rule:
  [PROJECT: result]
- Whole-file ownership, two/three-writer gates, and cost multiplier:
  [PROJECT: result]
- Planning size gate and single-stage shape: [PROJECT: result]
- Minimal launch reads, planner read ladder, and Stage Model Allocation
  continuity: [PROJECT: result]
- Targeted/full validation, focused review, and review disposition:
  [PROJECT: result]
- Decision records and per-directory `CLAUDE.md` files: [PROJECT: result]

## Configuration, agent, skill, and hook changes

- [PROJECT: Removed project-wide model/effort pins and old toolchain config,
  retained unrelated configuration, enabled the plugin in
  `.claude/settings.json`, deleted local copies of what the plugin provides
  after confirmation, moved their project facts into the project documents,
  and kept the project's own hooks and skills.]

## Project-specific adaptations

- Ownership/shared interfaces/high-risk classes: [PROJECT: summary]
- Validation catalog and full-suite inventory: [PROJECT: summary]
- Local linter checks (`tools/validate_plan_workspace.local.mjs`), or why none:
  [PROJECT: summary]
- Install-time placeholders and install notes: [PROJECT: all resolved, or each
  remaining one and why]
- `AskUserQuestion` and `engineering:*` skill availability and fallback:
  [PROJECT: summary]

## Historical preservation audit

- Audit command/check: [PROJECT: the hash manifest taken before any edit and
  compared after, or `git status --short plans/` when dated workspaces are
  tracked; a gitignored `plans/` makes `git status` prove nothing]
- Result: [PROJECT: No historical dated plan changed, or exact exception]

## Deprecated, awaiting confirmation

- [PROJECT: Old files the mapping deprecates that have not been deleted yet,
  or None]

## Validation and residual risks

| Check | Result | Notes |
|---|---|---|
| Installed-repository check (`dev/validate-kit.ps1 -InstalledRepo .` from an Agrippa checkout) | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Smoke test (`dev/fixtures/run-smoke-test.ps1 -RepoRoot .` from an Agrippa checkout) | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Install-marker scan (kit README) | [PROJECT: 0 hits / list] | [PROJECT: details] |
| Local linter checks against one real workspace | [PROJECT: Pass/Fail/None installed] | [PROJECT: details] |
| Validation catalog commands run once | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Scoped formatting | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Live planning smoke test | [PROJECT: Pending/Pass] | [PROJECT: details] |
| Live implementation smoke test | [PROJECT: Pending/Pass] | [PROJECT: details] |
