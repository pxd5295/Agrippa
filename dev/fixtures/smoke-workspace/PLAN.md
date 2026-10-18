# Implementation Plan

> Kit smoke-test fixture. This file references frozen Contract IDs but never
> restates their bodies.

## Dependency graph

```text
Wave 1: [M1]
          |
Wave 2: [Integration]
```

## Validation matrix

| Validation ID | Acceptance IDs | Exact command or check | Style | Sandbox | Determinism | When |
|---|---|---|---|---|---|---|
| V1 | A1 | `git grep -n "Make a plan" -- AGENTS.md` | lint | sandboxed | deterministic | M1 |
| V2 | A1-A2 | `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1 -PlanPath __PLAN__` | lint | sandboxed | deterministic | Integration |

## Ownership matrix

| Path | Wave | Owning stage | Worktree / merge owner |
|---|---|---|---|
| `AGENTS.md` | 1 | M1 | None |

## Milestones

### M1: Confirm the planning trigger

| Field | Record |
|---|---|
| Wave | 1 |
| Dependencies | None |
| Design state | Frozen |
| Contract IDs | C1 |
| Assigned tier | sonnet |
| Routing inputs | no long-context; 1 file; 1 ownership area; no shared interface; no risk flag; deterministic |
| Risk flags | None |
| Owned files/modules | `AGENTS.md` |
| Line-anchored edit sites | `AGENTS.md:1` |
| Allowed interfaces | None |
| Forbidden scope | Every other path |
| Pre-authorized ownership expansion | None |
| Work | Read-only check; no edit is made. |
| Acceptance IDs | A1 |
| Validation IDs | V1 |
| Validation output | Bounded |
| Parallel safety | Sequential |
| Worktree | No |
| Blocks | Integration |

#### Split attempt

Not required by tier.

### Integration: Full acceptance and focused review

| Field | Record |
|---|---|
| Wave | 2 |
| Dependencies | M1 |
| Design state | Frozen |
| Contract IDs | C1 |
| Assigned tier | lead |
| Routing inputs | integration |
| Risk flags | None |
| Owned files/modules | Cross-cutting fixes only |
| Line-anchored edit sites | Not applicable to lead integration |
| Allowed interfaces | None without a recorded contract update |
| Forbidden scope | Unrelated systems and user-owned changes |
| Pre-authorized ownership expansion | None |
| Work | Run the full applicable suite, which here is the workspace linter. |
| Acceptance IDs | A1-A2 |
| Validation IDs | V2 |
| Validation output | Bounded |
| Parallel safety | Sequential integration |
| Worktree | No |
| Blocks | Completion |

#### Split attempt

Not required by tier.

## Recommended Execution

- **Shape:** single-stage; the lead runs it directly.
- **Wave order:** Wave 1, then Integration.
- **Cheap-tier share:** 1 of 1 implementation stages on sonnet.
- **Cost multiplier:** Sequential.
- **Safety:** read-only; no file is edited.
- **Launch:** not applicable; the runner script deletes this workspace.

### Stage Model Allocation

| Stage/wave | Assigned tier | Actual tier | Routing | Escalation trigger | After stage |
|---|---|---|---|---|---|
| M1 | sonnet | Pending | active lead | None | Integration |
| Integration | lead | Pending | active lead | None | Complete |
