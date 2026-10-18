# Claude Code entry

@AGENTS.md

`AGENTS.md` above is the canonical workflow for this repository. This repo is
Claude-only: Claude both authors plans and implements them, in the same session
or a later one. There is no second toolchain, no model-switch handshake, and no
allocation target the lead "assigns" to anyone else — per-stage tiers apply only
to subagents the lead spawns.

Read `docs/agent-workflow.md` on demand for the planning lifecycle and
`docs/planning/ROUTING.md` for tier selection and dispatch. Do not load both
eagerly for unrelated work.

## Subagents

The only named agents are in `.claude/agents/`:

- `repo-scout.md` — read-only consumer census and contract fact-pack for
  planning. Collects facts; never decides design or writes plan artifacts.
- `plan-reviewer.md` — read-only independent review of a stage or wave diff
  for correctness and contract conformance.
- `design-reviewer.md` — read-only review of a diff for duplication, special
  cases, placement, coupling, shared-value ownership, and file growth; runs
  on any non-trivial diff, plan or not.
- `validator.md` — runs the validation matrix verbatim; owns no repo files.

Implementation workers are inline `general-purpose` subagent spawns with a
verbatim packet and a routed `model` (`haiku`/`sonnet`/`opus`); the roster is
deliberately lean. The lead implements small work directly and reserves
subagents for bounded, parallel, or long-context stages.

## Skills

Repo-specific procedures live in `.claude/skills/`. Only `design-first` is
required by `AGENTS.md`; the others are recommended, not mandatory. Reach
for them when the situation matches, and say which one you followed:

- `design-first` — the design statement and placement decision before the
  first edit. Required by the Engineering standards.
- `systematic-debugging` — root cause before a fix: reproduce on one named
  target, one hypothesis at a time, fix at the owner, stop after three failed
  attempts. Use for a failing test, a runtime error, [PROJECT: the project's
  hard-to-debug classes, for example "a native or GPU misbehavior, or a hitch
  in a performance capture"].
- `verify-before-done` — the evidence behind "passes", "fixed", or "done":
  a fresh run, the verdict line, [PROJECT: the toolchain's error-line grep,
  for example a `SCRIPT ERROR` grep], and pre-existing red proven at `HEAD`.
  Use before reporting a change done, before a commit, and when a subagent
  reports success.
- `receiving-review` — per-finding disposition for design-reviewer,
  plan-reviewer, `/code-review`, or user feedback: verify against the tree,
  then fix, push back with a citation, file separately, or decline in a line.

[PROJECT: list any further project-specific skills here, one bullet each,
with what they are for and when to use them. Delete this line if none.]

## Planner read ladder

Use this order and stop as soon as sourced frozen contracts can be written:

1. `AGENTS.md`, then the planning lifecycle sections of `docs/agent-workflow.md`.
2. Dirty-worktree status, exact owned code, and only applicable
   `docs/agent_memory/` contracts.
3. Targeted `Glob`/`Grep`/`Read`, delegated to `repo-scout` when a consumer
   census or long-file extraction would otherwise dominate the planning turn.
4. One bounded follow-up read for a concrete contradiction.

Do not perform open-ended repository exploration. Record in `EVIDENCE.md` why
any read beyond the named ownership areas plus applicable architecture memory
was necessary. The lead writes every `SPEC.md`, `PLAN.md`, `PACKETS.md`,
`STATUS.md`, and `EVIDENCE.md` artifact itself.

## Validation reach

`tools/validate_plan_workspace.ps1` checks a specific plan workspace's
traceability, dispatch shape, ownership, and command syntax. It checks shape,
never truth: a frozen constant or design choice can be wrong and still pass.

Before implementing a plan, run the commands in its validation matrix to confirm
the named targets, tests, and benchmarks exist and are executable, and record
the dirty-worktree state at planning time. A speculative matrix is the main way
this process fails quietly.
