# Plan workspace files

Load this file when creating a workspace or resuming one. It is a reference
file of the `agrippa:plan` skill. It says what each workspace file owns, what
to read when, and how a workspace is linted. `agent-workflow.md` owns how a
plan is built, and `ROUTING.md` owns dispatch.

## Layout

Each substantial planning request gets a new workspace; never overwrite an
existing one. On a name collision append `-2`, `-3`, and so on.

```text
plans/YYYY-MM-DD-short-change-name/
  SPEC.md       # stable requirements, design rationale, and Acceptance IDs
  PLAN.md       # waves, exclusive ownership, and Validation ID matrix
  PACKETS.md    # frozen contracts and verbatim dispatch packets
  STATUS.md     # hot current-state handoff
  EVIDENCE.md   # cold append-only detail
  design/       # only with a design reference: frozen artboard and render
```

`plans/handoff-YYYY-MM-DD-<slug>.md` files are short session handoffs written
by the `/agrippa:handoff` skill; they link into workspaces and never replace
them.

New workspaces start from this skill's templates. Historical and active plan
workspaces keep their original schema and provenance; never convert one to a
newer template.

The repository's `plans/README.md` is a short pointer to the plugin for people
who browse the repository without it. It holds no rules, and none are added
there.

## Artifact contract

- `SPEC.md` is authoritative for numbered **Acceptance IDs** (`A1`, `A2`,
  ...); never renumber a referenced criterion. It also records interview
  decisions, the design rationale (owner extended, generalization,
  alternatives rejected, decision-record link), and any design reference with
  its visual inventory and deviations.
- `PLAN.md` has one **Validation ID** matrix (`V1`, `V2`, ...) with exact
  commands/checks and acceptance mappings. Milestone records reference those
  IDs and `PACKETS.md` Contract IDs while retaining dependencies, exclusive
  ownership, forbidden scope, design state, assigned tier, wave, and
  parallel-safety conditions.
- `PACKETS.md` defines sourced frozen contracts (`C1`, `C2`, ...) with consumer
  censuses and covering tests, and one copy-pasteable packet per stage.
  `PLAN.md` references the IDs and does not duplicate contract bodies.
- `STATUS.md` contains only current state, recent deltas, blockers/risks, next
  action, and concise gate summaries. Delete obsolete launch fields after
  launch rather than accumulating history.
- `EVIDENCE.md` is append-only and holds detailed command output, manual
  checks, routing outcomes, escalations, justified exceptions, and one
  `area map` entry when the plan consulted `.agrippa/area-map.md`
  (the rows used, the rows found stale, and whether they saved a read or
  misled).

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

Before handoff, run this through the Bash tool, because the plugin puts
`agrippa-lint` on the Bash tool's PATH only:

```bash
agrippa-lint -PlanPath plans/YYYY-MM-DD-name
```

Outside Claude Code, run the linter with Perl from a checkout of Agrippa at
the repository's pinned tag, with `-RepoRoot` set to the repository:

```bash
perl <Agrippa>/plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/YYYY-MM-DD-name -RepoRoot <repository>
```

Dated plans whose matrix names `tools/validate_plan_workspace.ps1` keep that
row; they are records.

The linter checks traceability, dispatch shape, routing, ownership, runnable
command syntax, covering-test paths, and contract freshness. It checks shape,
never truth: a wrong constant in a syntactically frozen contract can still
pass. A workspace's freshness checks start failing once its contract sources
change after the plan lands; that is expected for a finished plan.
