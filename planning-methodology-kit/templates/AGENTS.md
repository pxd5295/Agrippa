# Agent Workflow

This is the canonical workflow for this repository. Claude owns planning and
implementation end to end. This file is loaded on every session, so it is
limited to triggers, hard safety rules, shortcuts, and project contracts. The
methodology itself lives in two guides that load on demand:

- `docs/agent-workflow.md` — planning lifecycle, workspace artifacts,
  interview, risk, evidence, acceptance, validation, and model-specific
  planning fixes.
- `docs/planning/ROUTING.md` — topology, tier selection, packets, waves,
  ownership, launch, and review.

Read a guide only for plan creation or plan implementation. Do not load both
eagerly, and do not load either for unrelated work.

## Request boundaries and model freedom

- Answer, explain, review, diagnose, and status requests are read-only unless
  the user also asks for changes. A question about a possible feature ("is
  there a way to also show X?", "could the tooltip include Y?") is an answer
  request: say whether and how it can be done, then offer to build it. Edit
  only after an explicit go-ahead. An output style that says "execute
  immediately" applies once a change has been requested; it never turns a
  question into one.
- Change, build, fix, and implement requests authorize scoped local edits and
  relevant non-destructive validation.
- A planning-only request creates planning artifacts and stops; it does not
  authorize implementation.
- Non-planning requests preserve the user's active model and reasoning effort;
  do not request a session model switch for ordinary work. Per-stage tier
  choices apply only to subagents the lead spawns, never to the user's session.
- Do not spawn subagents for routine exploration, test execution, lint, status
  updates, or small documentation changes.
- Chain mechanical multi-step shell work into a single shell call — build then
  grep the log, search then count — rather than one call per step. This is
  turn economy only: read and edit files with Read, Edit, and Write, which any
  edit hooks and the per-directory `CLAUDE.md` files key off.

Preserve user-owned dirty changes. Never reset, discard, overwrite, or claim
ownership of unrelated work. Require confirmation for destructive operations,
external writes, credentials, purchases, or material scope expansion.

## Engineering standards

These rules apply to every change request, whether or not it goes through a
plan workspace. They are written to be checkable: a change that cannot show it
met them is not done. Prefer the generalized, maintainable change over the
quick fix even when the quick fix is smaller.

- **State the design before the first edit.** For any change that touches more
  than one function, write three sentences in the reply before editing: where
  the change lives in the architecture, which existing abstraction it extends
  or reuses, and what the change would look like the second time the same need
  appears. If the answer to the third is "copy it", the design is wrong; find
  the shared owner first.
- **Shared behavior goes in the base class behind a hook.** No variant- or
  mode-specific branches in shared base classes
  ([PROJECT: name them, for example `WorldBase` and `AnimalBase`]). Behavior
  that differs by variant goes behind a virtual hook, and per-variant
  differences go in the configuration layer before they go in code.
- **No new special case at a call site when an owner exists.** Before adding a
  conditional, check whether the base class, a hook, an existing engine or
  service, or an existing funnel ([PROJECT: name the registration funnels and
  config loaders]) should own it. Fix the owner, not the caller.
- **One owner per shared value.** No per-consumer constants, thresholds, or
  layout numbers. A value used by more than one consumer has one definition,
  and the constants of a frozen shared interface come only from the contract
  document that owns them ([PROJECT: for example
  `docs/agent_memory/sensor-contract.md`]).
- **Growth needs a plan.** Adding more than about 150 lines to a file already
  over 1500 lines, or a new responsibility to a class that already has several,
  must include the split or say in the reply why one was deferred.
- **Refactor or file it, never add to it.** When a fix touches a clear
  structural problem (duplicated logic, a mode branch in a base class, a copied
  constant), fix it in the same change if that stays in one ownership area and
  under roughly 50 lines; otherwise flag it as a separate task in the reply.
- **Document new shared abstractions.** A new hook, base-class API, funnel, or
  shared interface gets a paragraph in the relevant `docs/agent_memory/`
  contract in the same change.

The `design-first` skill (`.claude/skills/design-first/SKILL.md`) is the
procedure for the design statement and placement decision; use it before the
first edit. Any diff touching more than one file, a base class, a shared
interface, or [PROJECT: the performance-owned or native subsystem, if any]
then gets a `design-reviewer` pass (`.claude/agents/design-reviewer.md`) in
addition to any plan review, and its `Design` findings are fixed before the
change is reported done.

Size floor: skip the `design-reviewer` pass when the diff changes fewer than
about 30 lines of code (documentation excluded) and adds no class, no
conditional, and no constant or config key. A base class, a shared interface,
or [PROJECT: the same subsystem named above] always gets the pass regardless
of size. When the floor applies, say so in the reply with the line count. The
floor never waives the design statement or the definition of done.

### Definition of done

Report a change as done only when all of the following hold, and say which
ones you verified:

1. The named validation ran and passed, with the exact command and outcome.
2. The design statement above was given before the first edit.
3. No new mode-specific branch in a base class and no new call-site special
   case that an existing owner should hold.
4. No logic duplicated from elsewhere in the tree; if reuse was rejected, say
   why in one sentence.
5. Any changed shared interface or new abstraction is documented in
   `docs/agent_memory/`.
6. Any structural problem encountered was either fixed or flagged as a
   separate task.

## Planning trigger

Treat ordinary-language requests such as `Make a plan`, `Plan: ...`, or
`Create an implementation plan` as planning requests. There is no special mode,
prefix, or model handshake — planning starts immediately on the user's current
session.

Substantive planning benefits from a strong model and high reasoning. If the
session is on a weaker model and the change is complex or high-risk, say so once
and recommend the user raise the model in the app's model selector; then
proceed on whatever they choose. Never block planning on a switch.

Planning is not free, so size the response to the change. Skip the workspace
entirely when the diff fits in one sentence, touches one ownership area, changes
no shared interface, and has deterministic validation. Implementing directly
still requires the design statement from Engineering standards before the first
edit, and the change still has to meet the definition of done. Name the
validation you ran, and say plainly that the workspace was skipped and why;
offer to create one if the user wants the record.

Create a workspace when the approach is uncertain, the change spans multiple
files or ownership areas, or the code is unfamiliar. Bounded work that clears
that bar but still needs one writer in one ownership area uses the single-stage
shape in `docs/agent-workflow.md`; parallel or cross-area work uses the full
shape.

When a workspace is warranted:

1. Read `docs/agent-workflow.md`.
2. Inspect only the relevant code and `docs/agent_memory/` contracts.
3. Conduct the focused planning interview with `AskUserQuestion` when the
   choices are material.
4. Classify planning risk after the interview and record it in `STATUS.md`.

Never overwrite or repurpose a historical plan; if a workspace path exists,
append `-2`, `-3`, and so on. A planning-only response ends with the first
implementation allocation and the exact resume prompt, then stops.

No stage may hand off as `Open`. Only `Frozen` (sourced contract IDs with exact
interfaces, edit sites, and consumer census) or `Bounded-choice` (enumerated
options, one default, and the exact observation that changes it) ships to
implementation.

## Implementation launch

When a user names a plan, use that workspace. When omitted, use only the plan
established in the current task; never guess among historical plans. Claude
implements in the same session that planned, or a later one.

Then follow `docs/planning/ROUTING.md` for dispatch, tiers, waves, ownership,
the validator, allocation continuity, escalation, and review. It also owns the
launch authorization and read order; do not re-derive either here.

## Project contracts

`docs/agent_memory/project-contracts.md` owns this repository's ownership
areas, shared interfaces, high-risk change classes, and compatibility gates.
`docs/agent_memory/validation-commands.md` owns every exact command. Treat
these as separate ownership areas unless a milestone combines them:

[PROJECT: one bullet per ownership area, for example
- simulation and editor code in `scripts/` and root scene files;
- native runtime code in `native/`;
- tests and benchmarks in `tests/`;
- stable contracts in `docs/agent_memory/`.]

[PROJECT: one sentence naming the shared interfaces, for example "Sensor
order, network shape, GPU layout, serialization, scene/node contracts, and
saved configuration are shared interfaces."] Establish them before parallel
consumers. A change to any of them starts with an architecture decision record
written with the `engineering:architecture` skill before the first edit and
saved as `docs/decisions/YYYY-MM-DD-<slug>.md`; a plan workspace links it from
the design rationale in `SPEC.md`. A new subsystem (a new base class or class
family, native worker or extension class, editor panel, service, or ownership
area) also runs `engineering:system-design` first; its output goes in the same
decision record. Without those skills, write the record by hand in the shape
`docs/decisions/README.md` gives.

[PROJECT: optional. Delete this paragraph if nothing applies. Generated or
tool-serialized files (engine scene and resource files, lockfiles, generated
code, schema snapshots) are data, not source text. Do not hand-edit them to
add, remove, or re-parent entries, renumber ids, or change references; that
belongs in the tool that owns them, and when the tool is unavailable, stop and
say so. Substituting a value on an existing line is fine when it changes no id
and no reference. Sidecar files (for example `.uid` or `.meta`) move, rename,
and delete in the same change as the file they name.]

[PROJECT: optional. Delete this paragraph if the project has no MCP server
that observes the running application. Name the server, what it is preferred
for (what the UI actually renders, the live object tree, editor-side load
errors, anything needing a GPU or a real display), and that every row in a
plan's validation matrix stays a headless command. Name any bridge test runner
whose discovery conventions do not match this repository's tests, so it is
never used for the suite. If the bridge is unreachable, say so and name the
headless command run instead; never report a visual or GPU-dependent check as
done when the bridge was down and nothing replaced it. If the bridge can also
author (create nodes, edit scenes, save resources), say that its edits write
real files, that it is the sanctioned path for tool-serialized files rather
than an exception to the rule above, and that such edits need the user's
go-ahead and belong in a change the user can see.]

[PROJECT: optional. Name any subsystem whose state, geometry, or dispatch
changes must pass a dedicated equivalence or compatibility gate before
completion, for example "`NuroMovementWorker` is the sole movement backend;
any state, geometry, or dispatch change must pass the native serial-versus-pool
tick equivalence gate."]

Every active plan must name its exact relevant commands from
`docs/agent_memory/validation-commands.md`; one example command is never the
full suite.
