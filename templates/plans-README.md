# Change plans

Each substantial planning request gets a new workspace; never overwrite an
existing one. On a name collision append `-2`, `-3`, and so on.

```text
plans/YYYY-MM-DD-short-change-name/
  SPEC.md       # stable requirements and Acceptance IDs
  PLAN.md       # waves, exclusive ownership, and Validation ID matrix
  PACKETS.md    # frozen contracts and verbatim dispatch packets
  STATUS.md     # hot current-state handoff
  EVIDENCE.md   # cold append-only detail
```

Use `docs/planning/templates/` for future workspaces only. Historical and
active plan workspaces retain their original schema and provenance.

## Artifact contract

- `SPEC.md` is authoritative for numbered **Acceptance IDs** (`A1`, `A2`,
  ...); never renumber a referenced criterion.
- `PLAN.md` has one **Validation ID** matrix (`V1`, `V2`, ...) with exact
  commands/checks and acceptance mappings. Milestone records reference those
  IDs and `PACKETS.md` Contract IDs while retaining dependencies, exclusive
  ownership, forbidden scope, design state, assigned tier, wave, and
  parallel-safety conditions.
- `PACKETS.md` defines sourced frozen contracts (`C1`, `C2`, ...) with consumer
  censuses and one copy-pasteable packet per stage. `PLAN.md` references the
  IDs and does not duplicate contract bodies.
- `STATUS.md` contains only current state, recent deltas, blockers/risks, next
  action, and concise gate summaries. Delete obsolete launch fields after
  launch rather than accumulating history.
- `EVIDENCE.md` is append-only and holds detailed command output, manual
  checks, routing outcomes, escalations, and justified exceptions.

## Selective reads and soft budgets

Start planned implementation with `STATUS.md` plus the assigned `PLAN.md`
records and `SPEC.md` acceptance IDs. Read `EVIDENCE.md` only for a concrete
decision, failure, gate detail, routing outcome, escalation, or budget
exception. Workers receive the lead's compact stage packet rather than a full
workspace reread.

Soft budgets warn, never fail, when the plan records a justified exception in
`EVIDENCE.md`: routine hot workspace content (`SPEC.md`, `PLAN.md`,
`STATUS.md`) targets about 3,500-5,000 tokens excluding cold evidence; a stage
packet targets at most about 800 tokens. Keep necessary traceability over an
arbitrary size limit.

## Workspace validation

Before handoff, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1 -PlanPath plans/YYYY-MM-DD-name
```

The linter checks traceability, dispatch shape, routing, ownership, runnable
command syntax, and freshness metadata. It checks shape, never truth: a wrong
constant in a syntactically frozen contract can still pass.
