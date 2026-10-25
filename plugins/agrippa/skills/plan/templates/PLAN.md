# Implementation Plan

> Derive this plan from `SPEC.md`, inspected code, and `PACKETS.md`. This file
> references frozen Contract IDs but never restates their bodies.

## Dependency graph

```text
Wave 0: [contract/stub landing, if required]
Wave 1: [M1] + [M2]
              |
Wave 2: [Integration]
```

## Validation matrix

Copy runnable commands from `.agrippa/validation-commands.md`. Each
**Validation ID** is stable and maps to one or more acceptance IDs.

| Validation ID | Acceptance IDs | Exact command or check | Style | Sandbox | Determinism | When |
|---|---|---|---|---|---|---|
| V1 | A1 | `[exact prerequisite command from the catalog, if the toolchain needs one]` | [prerequisite / build] | [sandboxed / outside-sandbox] | deterministic | Before first test |
| V2 | A1 | `[exact command or manual pass condition]` | [unit / integration / build / lint / benchmark / manual] | [sandboxed / outside-sandbox] | [deterministic / noisy-retry / skips-headless / manual] | M1 |
| V3 | A1-A2 | `[full applicable suite]` | [style] | [stance] | [determinism] | Integration |

Delete V1 when the catalog names no prerequisite. Style and Sandbox values come
from `.agrippa/validation-commands.md`.

The workspace linter row is `agrippa-lint -PlanPath plans/YYYY-MM-DD-name`
(`lint`, `sandboxed`, `deterministic`). It runs through the Bash tool, because
the agrippa plugin puts its `bin/` folder on the Bash tool's PATH only.

With a design reference, add the fidelity row for the fidelity criterion: an
in-app capture of the rendered UI, compared side by side with the frozen render
at the same width, plus a walk of every visual inventory row; `manual`,
`skips-headless`. Its When column names the first stage that puts the UI on
screen and Integration.

## Ownership matrix

Paths are whole-file ownership in a shared checkout. Concurrent
`file:symbol` ownership requires a worktree and named merge owner.

| Path | Wave | Owning stage | Worktree / merge owner |
|---|---|---|---|
| `path/to/file.ext` | 1 | M1 | None |
| `path/to/other.ext` | 1 | M2 | None |

## Milestones

### M1: [Outcome-oriented title]

| Field | Record |
|---|---|
| Wave | 1 |
| Dependencies | [Wave 0 / None] |
| Design state | Frozen |
| Contract IDs | C1 |
| Assigned tier | [tier from the `agrippa:plan` skill's `ROUTING.md`: lead / haiku / sonnet / opus] |
| Routing inputs | [long-context; file count; ownership areas; shared interface; risk flags; determinism] |
| Risk flags | [None / native / persistence / security / concurrency / perf / shared-layout] |
| Owned files/modules | `path/to/file.ext` |
| Line-anchored edit sites | `path/to/file.ext:10-30` |
| Allowed interfaces | [Named interface or `None`] |
| Forbidden scope | [Paths/modules/interfaces owned elsewhere] |
| Pre-authorized ownership expansion | [Exact bounded consumer paths or `None`] |
| Work | [Concrete transcription of the frozen contract.] |
| Acceptance IDs | A1 |
| Validation IDs | V2 |
| Validation output | Bounded |
| Parallel safety | [Sequential, or stable upstream contracts, disjoint files/interfaces, independent checks, and accepted cost multiplier.] |
| Worktree | [No, or path/branch and merge owner] |
| Blocks | [M2 or `None`] |

#### Split attempt

[For an Opus stage: describe the attempted planner-frozen split and why a
cheaper bounded stage is unsafe. For lower tiers: `Not required by tier`.]

For `Bounded-choice`, add a record that enumerates `Options`, `Default`, and the
exact `Change observation`; it must not contain a bare path or Contract ID.

Add one record per substantive milestone. An `Open` stage is invalid.

### Integration: Full acceptance and focused review

| Field | Record |
|---|---|
| Wave | 2 |
| Dependencies | All implementation milestones |
| Design state | Frozen |
| Contract IDs | C1 |
| Assigned tier | [lead / worker / validator tier] |
| Routing inputs | integration |
| Risk flags | [combined flags or None] |
| Owned files/modules | Cross-cutting fixes only |
| Line-anchored edit sites | [exact sites or `Not applicable to lead integration`] |
| Allowed interfaces | None without a recorded contract update |
| Forbidden scope | Unrelated systems and user-owned changes |
| Pre-authorized ownership expansion | [Exact bound or None] |
| Work | Reconcile interfaces, run the full applicable suite, and perform the risk-required focused review. |
| Acceptance IDs | A1-A[n] |
| Validation IDs | V3 |
| Validation output | Bounded |
| Parallel safety | Sequential integration |
| Worktree | No |
| Blocks | Completion |

#### Split attempt

[Required when assigned Opus; otherwise `Not required by tier`.]

## Recommended Execution

- **Shape:** [lead + sequential/parallel subagents / worktrees + integration].
- **Wave order:** [Wave 0, then dependency waves; default two writers, three
  only when all stages are Frozen and linter-proven disjoint/independent].
- **Cheap-tier share:** [N of T implementation stages on haiku/sonnet].
- **Cost multiplier:** [expected token cost relative to sequential for each
  wave with more than one writer, or `Sequential`].
- **Safety:** [ownership, dependency, worktree, and validation rationale].
- **Launch:** [first packet, required allocation/action, and exact resume prompt
  if confirmation is required].

### Stage Model Allocation

| Stage/wave | Assigned tier | Actual tier | Routing | Escalation trigger | After stage |
|---|---|---|---|---|---|
| M1 | [tier] | Pending | [subagent or active lead] | [Concrete trigger] | [Next stage] |
| Integration | [tier] | Pending | [route] | [Concrete trigger] | Complete |

Rows are atomic. Report progress, remaining stages, assigned/actual tier,
next routing, and required user action at every boundary.
