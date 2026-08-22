# Planning and implementation workflow

Load this guide only for plan creation or plan implementation. Root `AGENTS.md`
owns triggers and hard safety rules. This file owns planning, evidence,
acceptance, and project contracts. `docs/planning/ROUTING.md` owns topology,
tier selection, packets, waves, launch, and review.

## Quick contract

Claude both plans and implements. Planning starts immediately on the user's
current session — there is no special mode, prefix, or model handshake. Project
config never pins a model or effort for ordinary non-planning work; the user's
current selection remains untouched. Plan-only work stops after workspace
creation and the exact implementation launch prompt. Per-stage tiers apply only
to subagents the lead spawns.

## Planning lifecycle

### 1. Start planning

Planning is triggered by ordinary language such as `Make a plan`, `Plan:`, or
`Create an implementation plan`. Begin at once on the current session.
Substantive planning benefits from a strong model and high reasoning; if the
session is on a weaker model and the change is complex, recommend once that the
user raise the model, then proceed regardless. Never block on a switch.

### 2. Inspect narrowly

Read relevant code, tests, current configuration, dirty-worktree state, and the
smallest applicable `docs/agent_memory/` set. Use targeted `rg` to map
interfaces and consumers. Do not spawn planning subagents by default; the
read-only `repo-scout` is allowed only when a broad census or long-context
extraction would otherwise dominate, and its fact-pack value is recorded.

For every symbol a plan deletes or changes, run the consumer census during
planning. Record every call site in the frozen contract with `file:line` and a
matching snippet. Pre-authorize the exact bounded ownership expansion needed
for those consumers. Do not defer discovery to implementation.

### 3. Conduct the interview

Ask one to three material questions per round with `AskUserQuestion`,
recommending the first option and its tradeoff. Normally use one round; use more
only when answers expose a material decision. Cover only behavior, scope,
compatibility, architecture, migration, persistence, performance, failure
handling, acceptance, or execution choices that change the plan. Record answers
and rationale in `SPEC.md`.

### 4. Resolve design before handoff

Every stage declares one design state:

- `Frozen`: `PACKETS.md` gives exact sourced contracts, signatures, layouts,
  constants, enumerated edit sites, and consumer census.
- `Bounded-choice`: options are enumerated, one default is named, and one exact
  observation changes that default.
- `Open`: implementation method remains undecided.

Only `Frozen` and `Bounded-choice` may ship. `Open` means the planner must
inspect or interview further; it is never a reason to raise the implementation
tier. A bounded choice contains no bare path or contract ID and cannot hide
open exploration.

When the objective routing table yields Opus, attempt to split the stage into a
planner-frozen contract and cheaper implementation stages. Record the split
attempt. Keep Opus only when the plan gives a concrete, disputable reason the
split would break interface, ownership, or validation safety.

### 5. Classify planning risk

Record the risk class in `STATUS.md`. High-risk work — coupled ownership,
shared contracts, material risk, unresolved design, nondeterministic
acceptance, or difficult integration — keeps the plan detailed and the
implementation tier conservative. A demonstrably low-risk plan (one bounded
ownership area, deterministic acceptance and validation) reduces scope and may
route more stages to Haiku or Sonnet. Uncertainty stays conservative.

### 6. Create a unique workspace

Create `plans/YYYY-MM-DD-short-name/` from the templates. Never overwrite a
workspace; append `-2`, `-3`, and so on.

Use `A#` for acceptance, `V#` for validation, and `C#` for frozen contracts.
`PLAN.md` references contracts and never restates their bodies. Packet-quoted
acceptance text matches `SPEC.md` after whitespace normalization.

Run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1 -PlanPath plans/YYYY-MM-DD-name
```

The linter checks shape, never truth. A wrong constant in a frozen contract can
pass every static check.

Soft targets: root instructions 10,000 characters; lifecycle and routing guides
9,000; a packet 800 tokens; routine hot context 3,500-5,000 tokens excluding
evidence.

Document a justified exception in `EVIDENCE.md`; never delete material safety
or acceptance detail merely to meet a target.

## Plan construction

Build waves from actual interfaces and whole-file ownership. Wave 0 lands
shared contracts or stubs before consumers. Later records include dependencies,
wave, design state, contracts, assigned tier and routing inputs, risks,
whole-file ownership/anchors, interface and scope bounds, expansion,
acceptance/validation IDs, output bounds, worktree, and blocks.

The ownership matrix maps each path and wave to one stage. `file:symbol`
ownership is temporal in a shared checkout; concurrent same-file writers need
worktrees and a merge owner.

Centralize commands in the Validation matrix from
`docs/agent_memory/validation-commands.md`, including style, environment stance,
and determinism. Run the workspace linter before implementation.

Recommended Execution records wave order, cheap-tier share, safety, launch, and
one atomic allocation row per stage with assigned tier, actual tier, route,
escalation trigger, and next stage. Objective routing and packet rules live only
in `docs/planning/ROUTING.md`.

## Implementation launch

When the user names a plan, use that workspace. When omitted, use only the plan
established in the current task; never guess among historical workspaces.

Before expensive reads, inspect only hot `STATUS.md`, Recommended Execution, and
Stage Model Allocation. Otherwise load `SPEC.md`, the assigned plan record,
packet/contracts, hot status, and relevant architecture; read cold evidence
only for a concrete decision or prior result.

Follow `docs/planning/ROUTING.md` for dispatch, waves, validator, allocation
continuity, escalation, and review. Treat each allocation row as atomic.

## Validation and evidence

Run the smallest relevant checks during a milestone and the immediate
shared-contract gate; run the complete applicable suite once after integration.
The validation catalog (`docs/agent_memory/validation-commands.md`) owns exact
executables, working directories, syntax, environment stance, inventory,
determinism, and retry rules. Copy commands verbatim into the plan instead of
substituting remembered examples.

Keep `STATUS.md` small: phase, planner, owner, assigned/actual tier, remaining
work, blockers, next action, and gates. Append commands, outcomes, routing,
retries, escalations, unrelated failures, and budget exceptions to `EVIDENCE.md`;
distinguish environment limits from regressions. Performance records a
baseline; a risk-flagged native/concurrency/perf change needs its documented
equivalence or baseline gate before completion.

Completion requires every Acceptance ID and required Validation ID to pass, or
an exact remaining gap to be reported. A green linter is never evidence that a
contract is correct.

## Prompt-scenario contract

Durable behaviors this workflow must preserve:

| Scenario | Required behavior |
|---|---|
| Ordinary non-planning request | Preserve the user's model/effort; no switch prompt |
| New planning request | Start immediately; recommend a stronger model only if complex, then proceed |
| Low-risk plan after interview | Reduce scope; route more stages to cheaper tiers |
| High-risk plan after interview | Keep detail and a conservative implementation tier |
| Normal implementation launch | Follow the stage table; spawn routed subagents |
| Same tier at boundary | Report progress and continue automatically |

## Project ownership and worktrees

`docs/agent_memory/project-contracts.md` is authoritative for this
repository's ownership areas, shared/public interfaces, high-risk change
classes, and required compatibility gates. Treat its ownership areas as
separate unless a milestone explicitly combines them after freezing the shared
contract. Use worktrees for substantial overlap, experiments, or branches; the
integration owner compares frozen contracts before merge.
