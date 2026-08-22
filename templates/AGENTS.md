# Agent Workflow

This is the canonical workflow for this repository. Claude owns planning and
implementation end to end. Use `docs/agent-workflow.md` for the planning
lifecycle and planned implementation, and `docs/planning/ROUTING.md` for tier
selection, packets, waves, and review. Keep this root file limited to triggers,
hard safety rules, shortcuts, and project contracts so unrelated tasks and
subagents do not pay for the full methodology.

## Request boundaries and model freedom

- Answer, explain, review, diagnose, and status requests are read-only unless
  the user also asks for changes.
- Change, build, fix, and implement requests authorize scoped local edits and
  relevant non-destructive validation.
- A planning-only request creates planning artifacts and stops; it does not
  authorize implementation.
- Non-planning requests preserve the user's active model and reasoning effort.
  Do not ask to change models. Per-stage tier choices apply only to subagents
  the lead spawns, never to the user's session.

Preserve user-owned dirty changes. Never reset, discard, overwrite, or claim
ownership of unrelated work. Require confirmation for destructive operations,
external writes, credentials, purchases, or material scope expansion.

## Planning trigger

Treat ordinary-language requests such as `Make a plan`, `Plan: ...`, or
`Create an implementation plan` as planning requests. There is no special mode,
prefix, or model handshake — planning starts immediately on the user's current
session.

Substantive planning benefits from a strong model and high reasoning. If the
session is on a weaker model and the change is complex or high-risk, say so once
and recommend the user raise the model in the app's model selector; then
proceed on whatever they choose. Never block planning on a switch.

Then:

1. Read `docs/agent-workflow.md`.
2. Inspect only the relevant code and `docs/agent_memory/` contracts.
3. Conduct the focused planning interview with `AskUserQuestion` when the
   choices are material.
4. Classify planning risk after the interview and record it in `STATUS.md`.

## Planning artifacts

Create a new workspace at `plans/YYYY-MM-DD-<short-name>/` from
`docs/planning/templates/`. Future workspaces contain:

- `SPEC.md`: requirements, interview decisions, constraints, and acceptance
  IDs;
- `PLAN.md`: dependency waves, exclusive ownership, validation IDs, and
  execution recommendation;
- `PACKETS.md`: sourced frozen contracts and verbatim dispatch packets;
- `STATUS.md`: small current-state handoff;
- `EVIDENCE.md`: cold append-only command and routing evidence.

Never overwrite or repurpose a historical plan. If a path exists, append `-2`,
`-3`, and so on. A planning-only response ends with the first implementation
allocation and the exact resume prompt, then stops.

Every stage declares `Frozen`, `Bounded-choice`, or `Open`. `Frozen` names
sourced contract IDs with exact interfaces and edit sites. `Bounded-choice`
enumerates options, a default, and the exact observation that changes it.
`Open` is planning-incomplete and may not hand off. For every changed or
deleted symbol, record an `rg` consumer census and a bounded pre-authorized
ownership expansion in its frozen contract.

## Implementation launch and shortcut

When a user names a plan, use that workspace. When omitted, use only the plan
established in the current task; never guess among historical plans.

Claude implements in the same session that planned, or a later one. Before
expensive reads, inspect only `STATUS.md` current state and `PLAN.md`
Recommended Execution plus Stage Model Allocation. After that, read the
assigned specification, plan record, hot status, and only relevant architecture
notes. Do not load cold evidence unless a specific decision or result needs it.

`Implement plan` proceeds with the lead plus routed subagents by default. There
is no manual model-switch mode to override; the routing table already selects a
tier per stage. A worktree that the plan requires cannot be skipped.

## Dependency-wave execution

- Establish shared interfaces before their consumers.
- Give one writer exclusive ownership of each file and shared interface within
  a wave.
- Use two concurrent writers by default. Three are allowed only when every
  stage is `Frozen`, owned paths are machine-checked as disjoint, validation is
  independent, and the wall-clock benefit is material.
- Parallel writers require stable upstream contracts, disjoint ownership,
  independent validation, compact context packets, and material wall-clock
  benefit. Otherwise use sequential subagents or one active lead.
- Treat `file:symbol` ownership as sequential in a shared checkout. Concurrent
  writes inside one file require worktrees (`isolation: "worktree"`) and a
  named merge owner.
- Use worktrees for substantial overlapping writers, isolated experiments, or
  separate branches.
- Do not spawn subagents for routine exploration, test execution, lint, status
  updates, or small documentation changes.

Dispatch the verbatim inline stage packet prewritten in `PACKETS.md`; the lead
does not re-synthesize it. It contains design state, contract IDs, goal,
ownership, interfaces, acceptance text, exact validation, consumer-bound
expansion, references, dirty-file warnings, dependencies, stop conditions, and
the compact result schema. Workers must not reread the full plan workspace or
redesign adjacent systems.

Use Haiku only when the task is mechanical, bounded, exactly validated, and
line-anchored, and needs no long-context recall; route work that must read long
files or large command output to Sonnet. Behavioral code defaults to Sonnet.
Escalate reasoning effort, then to Opus, when interface ambiguity,
safety/concurrency risk, or a failed bounded repair proves the tier
insufficient.

When the objective tier table yields Opus, first attempt to split the stage
into a planner-frozen contract plus cheaper implementation stages and record
the attempt. Keep Opus only when that split is concretely unsafe. Apply the
table in `docs/planning/ROUTING.md`, starting with long-context need.

Treat each allocation row as atomic. Finish its acceptance and validation
before stopping unless blocked, an escalation triggers, user input/approval is
required, or the user asks to defer. At every boundary update `STATUS.md` and
report completed/total stages, remaining stages, next goal, next tier, and
required user action. If the tier is unchanged, say `No tier change; continuing
automatically` and continue in the same turn.

## Validation and review

Run the smallest relevant checks during a milestone, plus any immediate gate
for a changed shared contract. Run the complete applicable suite once after
integration. Expand earlier only when evidence exposes unexpected coupling.
Record concise current results in `STATUS.md` and detailed outputs in
`EVIDENCE.md`; distinguish unrelated existing failures.

Use one focused independent reviewer (`plan-reviewer`) for multi-writer
execution, native ABI, persistence/migration, security/trust boundaries, or
unresolved integration risk. Otherwise use a focused lead self-review,
optionally via `/code-review`. Do not spawn duplicate generic reviewers.
Completion requires every acceptance ID and required validation ID to pass or an
exact remaining gap to be reported.

## Project contracts

Read `docs/agent_memory/project-contracts.md` when planning or implementing.
It defines this repository's ownership areas, shared/public interfaces,
high-risk change classes, and required compatibility gates — the
project-specific facts that a portable methodology cannot know in advance.
Treat its ownership areas as separate unless a milestone explicitly combines
them after freezing the shared contract.

Read `docs/agent_memory/validation-commands.md` for exact commands, working
directories, environment stance, determinism, retry rules, and the full-suite
inventory. Every active plan names its exact applicable commands; an example
command is never the complete suite by implication.
