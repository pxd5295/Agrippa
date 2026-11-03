# Implementation Plan

> Derived from `SPEC.md`, the inspected kit files, and `PACKETS.md`. This file
> references frozen Contract IDs but never restates their bodies.

## Dependency graph

```text
Wave 1: [M1 medium-plan shape: template, linter, smoke fixture]
              |
Wave 2: [M2 routing rule and medium-level guidance]
              |
Wave 3: [M3 low-usage row, upgrade note, design note]
              |
Wave 4: [Integration]
```

Every stage has one writer, the lead, and every wave is sequential. Each
stage also owns `dev/validate-kit.mjs` for its own wave, so the self-check
passes at the end of every stage, as `CLAUDE.md` requires.

## Validation matrix

This repository has no `.agrippa/validation-commands.md`; its commands come
from `CLAUDE.md` ("After any change to the kit or to `dev/`" and "When a
change alters the linter") and `docs/goals.md` ("How a long run works").

| Validation ID | Acceptance IDs | Exact command or check | Style | Sandbox | Determinism | When |
|---|---|---|---|---|---|---|
| V1 | A1, A2, A3, A4, A5, A6, A7, A8, A9 | `node dev/validate-kit.mjs` | lint | outside-sandbox | deterministic | M1, M2, M3, Integration |
| V2 | A6 | Parity: run the linter from `HEAD` and the changed linter on every plan folder under `plans/` in nuro-battler, with that repository as the root, and compare stdout, stderr, and exit code byte for byte; every folder must match | manual | outside-sandbox | deterministic | M1, Integration |
| V3 | A6 | `perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-10-01-inspector-redesign -RepoRoot ../evolution-game/nuro-battler` | lint | sandboxed | deterministic | M1, Integration |
| V4 | A9 | `node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler` | lint | outside-sandbox | deterministic | Integration |
| V5 | A9 | Live routing: a fresh Code session in the sandbox repository receives one small and one medium change request, and each first reply states a level with a reason in one line | manual | outside-sandbox | manual | Integration |
| V6 | A1, A2, A3, A4, A5, A6, A7, A8, A9 | `perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-11-01-plan-levels -RepoRoot .` | lint | sandboxed | deterministic | Before implementation, Integration |

V3 lints a recent nuro-battler workspace with its project rules loaded, as
`CLAUDE.md` requires for a linter change. Its result is compared with the
parity run (V2), not expected to pass: finished plans fail check 24 once
their sources change. V6 is this plan's own lint, run from this checkout
because the plugin is not installed here.

## Ownership matrix

Paths are whole-file ownership in a shared checkout. One writer per wave.

| Path | Wave | Owning stage | Worktree / merge owner |
|---|---|---|---|
| `plugins/agrippa/scripts/validate_plan_workspace.pl` | 1 | M1 | None |
| `plugins/agrippa/skills/plan/templates/BRIEF.md` | 1 | M1 | None |
| `dev/fixtures/smoke-brief/BRIEF.md` | 1 | M1 | None |
| `dev/fixtures/run-smoke-test.mjs` | 1 | M1 | None |
| `dev/validate-kit.mjs` | 1 | M1 | None |
| `plugins/agrippa/scripts/core-rules.md` | 2 | M2 | None |
| `plugins/agrippa/skills/plan/reference/agent-workflow.md` | 2 | M2 | None |
| `plugins/agrippa/skills/plan/reference/workspace-files.md` | 2 | M2 | None |
| `plugins/agrippa/skills/plan/SKILL.md` | 2 | M2 | None |
| `plugins/agrippa/skills/plan/templates/STATUS.md` | 2 | M2 | None |
| `plugins/agrippa/skills/design-first/SKILL.md` | 2 | M2 | None |
| `plugins/agrippa/README.md` | 2 | M2 | None |
| `plugins/agrippa/ADOPTION-CHECKLIST.md` | 2 | M2 | None |
| `dev/validate-kit.mjs` | 2 | M2 | None |
| `plugins/agrippa/skills/plan/reference/low-usage.md` | 3 | M3 | None |
| `plugins/agrippa/templates/hooks/README.md` | 3 | M3 | None |
| `plugins/agrippa/skills/plan/SKILL.md` | 3 | M3 | None |
| `plugins/agrippa/README.md` | 3 | M3 | None |
| `plugins/agrippa/UPGRADING.md` | 3 | M3 | None |
| `docs/design-notes.md` | 3 | M3 | None |
| `dev/validate-kit.mjs` | 3 | M3 | None |
| `docs/worklog.md` | 4 | Integration | None |

## Milestones

### M1: The medium plan's shape, linted

| Field | Record |
|---|---|
| Wave | 1 |
| Dependencies | None |
| Design state | Frozen |
| Contract IDs | C1, C3 |
| Assigned tier | lead |
| Routing inputs | no long-context; 5 files; 1 ownership area (the plan skill and its linter) plus the dev tools that test it; no shared interface change for full workspaces; no risk flag; deterministic |
| Risk flags | None |
| Owned files/modules | `plugins/agrippa/scripts/validate_plan_workspace.pl`, `plugins/agrippa/skills/plan/templates/BRIEF.md`, `dev/fixtures/smoke-brief/BRIEF.md`, `dev/fixtures/run-smoke-test.mjs`, `dev/validate-kit.mjs` |
| Line-anchored edit sites | `plugins/agrippa/scripts/validate_plan_workspace.pl:552-937`, `dev/fixtures/run-smoke-test.mjs:171-205`, `dev/validate-kit.mjs:244-287`, `dev/validate-kit.mjs:1231-1244` |
| Allowed interfaces | `agrippa-lint` arguments and output format, unchanged |
| Forbidden scope | The full-workspace checks and their messages; the local-checks interface; the core rules and guides (M2 and M3) |
| Pre-authorized ownership expansion | None |
| Work | Write the `BRIEF.md` template and the medium branch of the linter per C1 and C3, with a smoke fixture and self-check coverage; prove parity on nuro-battler. |
| Acceptance IDs | A3, A6 |
| Validation IDs | V1, V2, V3 |
| Validation output | Bounded |
| Parallel safety | Sequential |
| Worktree | No |
| Blocks | M2 |

#### Split attempt

Not required by tier.

### M2: The routing rule and the medium level in the guides

| Field | Record |
|---|---|
| Wave | 2 |
| Dependencies | M1 |
| Design state | Frozen |
| Contract IDs | C2, C3 |
| Assigned tier | lead |
| Routing inputs | no long-context; 9 files; 1 ownership area (the methodology text); the core rules are injected into every session; no risk flag; deterministic |
| Risk flags | None |
| Owned files/modules | `plugins/agrippa/scripts/core-rules.md`, `plugins/agrippa/skills/plan/reference/agent-workflow.md`, `plugins/agrippa/skills/plan/reference/workspace-files.md`, `plugins/agrippa/skills/plan/SKILL.md`, `plugins/agrippa/skills/plan/templates/STATUS.md`, `plugins/agrippa/skills/design-first/SKILL.md`, `plugins/agrippa/README.md`, `plugins/agrippa/ADOPTION-CHECKLIST.md`, `dev/validate-kit.mjs` |
| Line-anchored edit sites | `plugins/agrippa/scripts/core-rules.md:106-132`, `plugins/agrippa/skills/plan/reference/agent-workflow.md:169-187`, `plugins/agrippa/skills/plan/SKILL.md:1-50`, `plugins/agrippa/skills/design-first/SKILL.md:123-127`, `dev/validate-kit.mjs:447-472` |
| Allowed interfaces | None |
| Forbidden scope | The linter (M1); the low-usage guide and the upgrade guide (M3); the full workspace shape |
| Pre-authorized ownership expansion | None |
| Work | Rewrite "Planning trigger" per C2 without growing it, describe the medium level and the implementation-location rule per C3, add the medium section of `design-first`, and add the level line to the `STATUS.md` template. |
| Acceptance IDs | A1, A2, A3, A4, A5 |
| Validation IDs | V1 |
| Validation output | Bounded |
| Parallel safety | Sequential |
| Worktree | No |
| Blocks | M3 |

#### Split attempt

Not required by tier.

### M3: Six low-usage rules and the upgrade note

| Field | Record |
|---|---|
| Wave | 3 |
| Dependencies | M2 |
| Design state | Frozen |
| Contract IDs | C4, C5 |
| Assigned tier | lead |
| Routing inputs | no long-context; 7 files; 1 ownership area; no shared interface; no risk flag; deterministic |
| Risk flags | None |
| Owned files/modules | `plugins/agrippa/skills/plan/reference/low-usage.md`, `plugins/agrippa/templates/hooks/README.md`, `plugins/agrippa/skills/plan/SKILL.md`, `plugins/agrippa/README.md`, `plugins/agrippa/UPGRADING.md`, `docs/design-notes.md`, `dev/validate-kit.mjs` |
| Line-anchored edit sites | `plugins/agrippa/skills/plan/reference/low-usage.md:7`, `plugins/agrippa/skills/plan/reference/low-usage.md:24`, `plugins/agrippa/templates/hooks/README.md:55-66`, `plugins/agrippa/UPGRADING.md:280`, `dev/validate-kit.mjs:905-928` |
| Allowed interfaces | None |
| Forbidden scope | The other six low-usage rules; the hook's low-usage line, which names no count; the linter |
| Pre-authorized ownership expansion | None |
| Work | Delete the "One-writer planning" row and every "seven" that counts it per C4, add the upgrade note per C5, and add the dated design note. |
| Acceptance IDs | A7, A8 |
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
| Wave | 4 |
| Dependencies | M1, M2, M3 |
| Design state | Frozen |
| Contract IDs | C1, C2, C3, C4, C5 |
| Assigned tier | lead |
| Routing inputs | integration |
| Risk flags | None |
| Owned files/modules | Cross-cutting fixes only, and `docs/worklog.md` |
| Line-anchored edit sites | Not applicable to lead integration |
| Allowed interfaces | None without a recorded contract update |
| Forbidden scope | Unrelated systems, user-owned changes, nuro-battler, `history/plans/`, the version and tags |
| Pre-authorized ownership expansion | None |
| Work | Run the full applicable suite (V1, V2, V3, V4, V5, V6), run a `design-reviewer` pass over the diff, then update `STATUS.md` and the worklog. |
| Acceptance IDs | A1, A2, A3, A4, A5, A6, A7, A8, A9 |
| Validation IDs | V1, V2, V3, V4, V5, V6 |
| Validation output | Bounded |
| Parallel safety | Sequential integration |
| Worktree | No |
| Blocks | Completion |

#### Split attempt

Not required by tier.

## Recommended Execution

- **Shape:** full shape with one writer: the lead implements every stage
  directly and sequentially.
- **Wave order:** Wave 1 (M1), Wave 2 (M2), Wave 3 (M3), Wave 4
  (Integration). M1 comes first because the linter and the template define
  the shape the guides then describe.
- **Cheap-tier share:** 0 of 3 implementation stages on haiku or sonnet; the
  lead holds the interview context and every stage edits files the injected
  rules or the linter depend on.
- **Cost multiplier:** Sequential.
- **Safety:** one writer, so no ownership overlap within a wave; the parity
  run guards the linter; nuro-battler is read-only; the self-check runs after
  each stage.
- **Launch:** M1 in this session, by the lead.

### Stage Model Allocation

| Stage/wave | Assigned tier | Actual tier | Routing | Escalation trigger | After stage |
|---|---|---|---|---|---|
| M1 | lead | Pending | active lead | A parity difference on any nuro-battler plan | M2 |
| M2 | lead | Pending | active lead | The core rules exceed the cap with low-usage mode on | M3 |
| M3 | lead | Pending | active lead | None | Integration |
| Integration | lead | Pending | active lead | A `Design` finding from the reviewer, or a sandbox reply that states no level | Complete |
