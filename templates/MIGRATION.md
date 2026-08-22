# Planning Workflow Migration

## Scope and date

- Date: [YYYY-MM-DD]
- Kit source/version: [path and revision]
- Existing plans covered: Future workspaces only; historical plans unchanged

## Existing workflow inventory

- Root/nested agent instructions: [paths, e.g. `AGENTS.md`, `CLAUDE.md`]
- Named Claude agents and any other toolchain's worker/agent configuration:
  [paths]
- Lifecycle/routing docs, templates, shortcuts, and validators: [paths]
- Historical plan roots: [paths]
- Project contracts and validation catalogs: [paths]
- Dirty user-owned files: [paths or None]

## Rule mapping

| Existing source/rule | Disposition | New authoritative location | Rationale |
|---|---|---|---|
| `[path: rule]` | Retain / Merge / Replace / Deprecate | `[path/section]` | [Reason; stricter rule preserved] |

## Methodology migration

- Design states and frozen C# contracts: [result]
- Changed/deleted-symbol consumer census: [result]
- A#/V#/C# traceability and PACKETS: [result]
- Objective tier-routing table and split-first rule: [result]
- Whole-file ownership and two/three-writer gates: [result]
- Minimal launch reads and Stage Model Allocation continuity: [result]
- Targeted/full validation and focused review: [result]

## Configuration and agent changes

- [Removed project-wide model/effort pins, retained unrelated configuration,
  installed `.claude/agents/*.md` files, local substitutions for any roles
  the target project does not need.]

## Project-specific adaptations

- Ownership/shared interfaces/high-risk classes: [summary]
- Validation catalog and full-suite inventory: [summary]
- Workspace-linter extension points filled in for this repository: [summary]
- `AskUserQuestion` (or equivalent structured-question) availability and
  fallback: [summary]

## Historical preservation audit

- Audit command/check: [exact read-only command]
- Result: [No historical dated plan changed, or exact exception]

## Validation and residual risks

| Check | Result | Notes |
|---|---|---|
| Kit self-check (`validate-kit.ps1`, if run against a local copy) | [Pass/Fail] | [details] |
| Representative workspace pass fixture | [Pass/Fail] | [details] |
| Workspace failure fixture | [Pass/Fail] | [details] |
| Scoped formatting | [Pass/Fail] | [details] |
| Live planning smoke test | [Pending/Pass] | [details] |
| Live implementation smoke test | [Pending/Pass] | [details] |
