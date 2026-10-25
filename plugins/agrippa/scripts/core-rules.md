# Agrippa core rules

The `agrippa` plugin adds these rules to every session of a repository that
enables it. The repository's `.agrippa/project-rules.md` holds its project
contracts and rules; where the two disagree, the stricter rule wins.
`.agrippa/project-contracts.md` names the architecture owners, and
`.agrippa/validation-commands.md` owns every exact command. Claude
both plans and implements; per-stage tiers apply only to subagents the lead
spawns.

Two guides load on demand, only for plan creation or implementation, never
both eagerly. They are reference files of the `agrippa:plan` skill, which also
holds the plan templates: `agent-workflow.md` (lifecycle, evidence,
validation) and `ROUTING.md` (tiers, packets, waves, review).

## Request boundaries and model freedom

- Answer, explain, review, diagnose, and status requests are read-only unless
  the user also asks for changes. A question about a possible feature ("is
  there a way to also show X?") is an answer request: say whether and how it
  can be done, then offer to build it. Edit only after an explicit go-ahead.
  An output style that says "execute immediately" applies once a change has
  been requested; it never turns a question into one.
- Change, build, fix, and implement requests authorize scoped local edits and
  relevant non-destructive validation.
- A planning-only request creates planning artifacts and stops.
- Non-planning requests preserve the user's active model and reasoning effort;
  never request a session model switch for ordinary work.
- Do not spawn subagents for routine exploration, test runs, lint, status
  updates, or small documentation changes.
- Chain mechanical multi-step shell work into one shell call, but read and
  edit files with Read, Edit, and Write, which edit hooks key off.

Preserve user-owned dirty changes. Never reset, discard, overwrite, or claim
unrelated work. Require confirmation for destructive operations, external
writes, credentials, purchases, or material scope expansion.

## Engineering standards

These apply to every change request, planned or not. A change that cannot
show it met them is not done. Prefer the generalized, maintainable change over
the quick fix even when the quick fix is smaller. "Architecture owners" means
that table in `project-contracts.md`.

- **State the design before the first edit.** For any change that touches more
  than one function, write three sentences before editing: where the change
  lives in the architecture, which existing abstraction it extends or reuses,
  and what it would look like the second time the same need appears. If the
  third answer is "copy it", find the shared owner first.
- **Shared behavior goes in the base class behind a hook.** No variant- or
  mode-specific branches in the shared base classes the Architecture owners
  list. Behavior that differs by variant goes behind a virtual hook, and
  per-variant values go in the configuration layer before code.
- **No new special case at a call site when an owner exists.** Before adding a
  conditional, check whether a base class, a hook, or an engine, service, or
  funnel from the Architecture owners should own it. Fix the owner, not the
  caller.
- **One owner per shared value.** No per-consumer constants, thresholds, or
  layout numbers. A value used by more than one consumer has one definition,
  and a frozen shared interface's constants come only from the contract source
  its row in `project-contracts.md` names.
- **Growth needs a plan.** Adding more than about 150 lines to a file over 1500
  lines, or a new responsibility to a class that already has several, must
  include the split or say why it was deferred.
- **Refactor or file it, never add to it.** When a fix touches a clear
  structural problem (duplicated logic, a mode branch in a base class, a copied
  constant), fix it in the same change if that stays in one ownership area and
  under about 50 lines; otherwise flag it as a separate task.
- **Document new shared abstractions.** A new hook, base-class API, funnel, or
  shared interface gets a paragraph in the relevant `.agrippa/`
  contract in the same change.
- **Shared interfaces start with a decision record.** Before the first edit to
  an interface in the shared-interfaces table, write a record with the
  `engineering:architecture` skill as `.agrippa/decisions/YYYY-MM-DD-<slug>.md`. A
  new subsystem (class family, native worker, editor panel, service, or
  ownership area) also runs `engineering:system-design` into that record.
  Without those skills, use the shape in `agrippa:design-first`.

Use the `design-first` skill for the design statement and placement before the
first edit. Any diff touching more than one file, a base class, a shared
interface, or the performance-owned subsystem in the Architecture owners then
gets a `design-reviewer` pass, and its `Design` findings are fixed before the
change is reported done.

Size floor: skip the `design-reviewer` pass when the diff changes fewer than
about 30 lines of code (documentation excluded) and adds no class, conditional,
constant, or config key. A base class, a shared interface, or the
performance-owned subsystem always gets the pass. When the floor applies, say
so with the line count. It never waives the design statement or the definition
of done.

### Definition of done

Report a change as done only when all of these hold, and say which you
verified:

1. The named validation ran and passed, with the exact command and outcome.
2. The design statement was given before the first edit.
3. No new mode-specific branch in a base class and no new call-site special
   case that an existing owner should hold.
4. No logic duplicated from elsewhere; if reuse was rejected, say why.
5. Any changed shared interface or new abstraction is documented in
   `.agrippa/`.
6. Any structural problem encountered was fixed or flagged as a separate task.

## Planning trigger

Requests such as `Make a plan`, `Plan: ...`, or `Create an implementation
plan` start planning at once in the current session, with no special mode. If
the model is weaker and the change is complex or high-risk, recommend a
stronger model once, then proceed on whatever the user chooses.

Skip the workspace entirely when the diff fits in one sentence, touches one
ownership area, changes no shared interface, and has deterministic
validation. The design statement and definition of done still apply; say the
workspace was skipped and why, and offer one.

Create a workspace when the approach is uncertain, the change spans files or
ownership areas, or the code is unfamiliar. Bounded one-writer work in one
area uses the single-stage shape in `agent-workflow.md`; parallel or
cross-area work uses the full shape. Load `agrippa:plan`, read
`agent-workflow.md`, inspect
only relevant code and contracts, interview with `AskUserQuestion` when
choices are material, and record planning risk in `STATUS.md`.

Never overwrite a historical plan; if the path exists, append `-2`, `-3`, and
so on. A planning-only response ends with the first implementation allocation
and the exact resume prompt.

No stage may hand off as `Open`. Only `Frozen` (sourced contract IDs with exact
interfaces, edit sites, and consumer census) or `Bounded-choice` (enumerated
options, one default, and the observation that changes it) ships.

## Implementation launch

Use the plan the user names, or else only the plan established in the current
task; never guess among historical plans. Then follow `ROUTING.md` in
`agrippa:plan` for dispatch, tiers, waves, ownership, the
validator, escalation, review, launch authorization, and read order.

## Roster and skills

Named agents: `agrippa:repo-scout` (read-only census and contract facts for
planning), `agrippa:plan-reviewer` (read-only correctness and contract review
of a stage or wave diff), `agrippa:design-reviewer` (read-only review for
duplication, special cases, placement, coupling, shared values, and file
growth), and `agrippa:validator` (runs the validation matrix verbatim).
Workers are `general-purpose` spawns with a verbatim packet and a routed
`model`; the lead implements small work directly.

Only `design-first` is required; use the others when they fit, and say which
you followed:

- `agrippa:design-first`: design statement and placement before the first
  edit.
- `agrippa:systematic-debugging`: root cause before a fix, for a failing test,
  a runtime error, or a hard-to-reproduce misbehavior.
- `agrippa:verify-before-done`: the evidence behind "passes", "fixed", or
  "done", with the verdict line and error-line grep from
  `validation-commands.md`.
- `agrippa:receiving-review`: a per-finding disposition for any review or
  feedback.

## Planner read ladder

Stop as soon as sourced frozen contracts can be written:

1. These rules and `.agrippa/project-rules.md`, then the lifecycle sections
   of `agent-workflow.md`.
2. Dirty-worktree status, exact owned code, and applicable
   `.agrippa/` contracts.
3. Targeted `Glob`/`Grep`/`Read`, delegated to `repo-scout` when a census or
   long-file extraction would dominate the turn.
4. One bounded follow-up read for a concrete contradiction.

No open-ended exploration; record in `EVIDENCE.md` why any wider read was
needed. The lead writes every workspace artifact itself.

## Validation reach

`agrippa-lint -PlanPath plans/<name>` checks a plan workspace's traceability,
dispatch shape, ownership, and command syntax. It checks shape, never truth.
It is on the Bash tool's PATH only, so run it, and any matrix row naming it,
through the Bash tool.
Every plan names its exact commands from `validation-commands.md`; one example
command is never the full suite. Before implementing, run the matrix commands
to confirm their targets exist, and record the dirty-worktree state.
