# Planning and implementation routing

Read this guide when assigning or dispatching stages from a plan. Lifecycle,
interview, risk, evidence, and acceptance rules remain in
`docs/agent-workflow.md`. A planner freezes design before using this routing
table; implementation never receives an `Open` stage.

Claude both plans and implements. The lead is the main session on the user's
selected model; it implements small work directly and delegates bounded or
parallel stages to subagents at a routed tier. There is no external
implementer and no model-switch handshake.

## Design states

| State | Required record | Handoff |
|---|---|---|
| `Frozen` | Contract IDs with exact signatures, layouts, constants, edit sites, sources, and consumer census | Allowed |
| `Bounded-choice` | Enumerated options, one default, and the exact observation that changes the default | Allowed |
| `Open` | Implementation method remains undecided | Forbidden |

`Bounded-choice` permits no design exploration, bare path, or contract ID.

When the table would assign Opus, first split the work into a planner-frozen
contract and cheaper implementation stages. Record the attempt for the stage.
An Opus allocation is valid only when the plan explains why the split would
destroy ownership, validation, or interface safety.

## Model-tier routing table

Read the first matching row from top to bottom. Long-context need is first
because Haiku is weakest with large files or output.

| Inputs | Tier | Reason |
|---|---|---|
| Read a long file, broad diff, consumer census, or large command output; design `Frozen`; no risk flag | `sonnet` | Cheap capable long-context floor |
| No long-context recall; exact line-anchored edit sites; mechanical `Frozen` change; bounded output | `haiku` | Exact transcription |
| No long-context recall; short mechanical `Frozen` change; deterministic check | `haiku` | Small mechanical judgment |
| `Frozen` behavioral work in one ownership area; deterministic validation | `sonnet` | Standard behavioral transcription |
| `Bounded-choice`, or bounded behavioral work needing local judgment | `sonnet` | Standard bounded implementation |
| Native, persistence, security, concurrency, performance, or other shared-layout/schema risk with bounded ownership | `opus` | Risk-aware bounded work |
| Difficult cross-area integration, or a failed bounded repair at a lower tier | `opus` (high effort) | Escalation ceiling |

Tier inputs are: long-context need, files touched, ownership areas,
shared-interface touch, risk flags, design state, and validation determinism.
Do not pick from a model menu; apply the first matching cell and record the
inputs in the stage.

Reasoning effort is the finer lever inside a tier. Escalate effort
(`low → medium → high`) before escalating the model for hard-but-bounded work.
The Agent tool sets `model` per spawn; a deterministic multi-stage
orchestration tool (where available) sets both `model` and `effort` per stage
and is preferred when a stage needs explicit effort control.

Haiku is short-context by contract. A Haiku packet names a line-anchored edit
site for every owned file and bounded validation output. A file above roughly
800 lines without anchors routes to Sonnet. Behavioral ambiguity never routes
to Haiku.

## Roster

Named agents live in `.claude/agents/`. The roster is deliberately lean: the
lead orchestrates and implements, and implementation workers are inline
subagent spawns rather than dedicated files. Only recurring read-only or
command-runner roles are named.

| File | Role | Tools | Default tier |
|---|---|---|---|
| `repo-scout.md` | Consumer census and contract fact-pack for planning | Glob, Grep, Read | `haiku` |
| `plan-reviewer.md` | Independent read-only review of a stage or wave diff | Glob, Grep, Read, Bash | `sonnet` (Opus for high-risk) |
| `validator.md` | Runs the validation matrix verbatim; owns no repo files | Bash, Read | `haiku`/`sonnet` |

Implementation workers have no dedicated file. The lead spawns a
`general-purpose` subagent with the verbatim stage packet and the routed
`model`. Ownership and forbidden scope are enforced by the packet, not by tool
restriction. A built-in review skill (if the local toolchain provides one) is
the lead's self-review path; `plan-reviewer` is the independent path for
multi-writer or high-risk waves.

## Dispatch-ready packets

Every future workspace includes `PACKETS.md`. The planner writes one verbatim,
copy-pasteable packet per stage; the lead dispatches it without re-synthesizing
the plan. `PLAN.md` references contract IDs and never repeats their bodies.

Each frozen contract has:

- `C#` and a descriptive name;
- `Contract source: file:line (read YYYY-MM-DD)`;
- exact signature, layout, constants, and line-anchored edit sites;
- `Consumer census:` containing every call site for a symbol being changed or
  deleted, captured with `rg` during planning;
- the bounded pre-authorized ownership expansion that covers those consumers.

Each stage packet contains plan/stage, goal/dependencies, owner/tier, owned
files, allowed interfaces, forbidden scope, exact acceptance and validation
text (commands, style, determinism), contract/design state, expansion,
references, dirty warnings, stop/escalate conditions, and the compact result
schema.

Workers do not read the complete workspace. They may open one packet-linked
section for a concrete ambiguity. Results contain changed files, implemented
behavior, validation outcomes, and unresolved dependencies or risks.

## Contract landing and ownership

Wave 0 lands any interface or stub that multiple consumers need, using one
writer, or provides an exact patch in `PACKETS.md`. Later waves consume that
stable contract.

Within a shared checkout, one stage owns a whole file for the duration of a
wave. `file:symbol` ownership is temporal only: concurrent whole-file saves can
silently overwrite the other writer's changes. Concurrent work inside one file
requires worktrees and a named merge owner.

For a deletion or changed symbol, the frozen contract includes the plan-time
consumer census. The packet pre-authorizes the exact bounded ownership
expansion so a worker can update those enumerated consumers without stopping.
An unlisted consumer or interface change is an escalation.

## Waves and parallelism

Two concurrent writers are the default ceiling. Three are permitted only when:

- every stage in the wave is `Frozen`;
- owned paths are pairwise disjoint and pass the workspace linter;
- validation is independent and produces bounded output;
- contracts are stable and already landed; and
- the wall-clock benefit is material.

Otherwise dispatch sequentially. Concurrent writers to overlapping files, or
isolated experiments and separate branches, run in git worktrees — the Agent
tool's `isolation: "worktree"` or an equivalent worktree-isolation option in
the local toolchain. The plan names the merge owner and integration gate.

For each wave, verify dependencies and ownership, dispatch packets, review the
combined diff, run the shared-contract gate, repair introduced failures, and
update hot status plus cold evidence.

An allocation row is atomic. Finish its acceptance and assigned validation
unless blocked, escalated, awaiting approval or user input, or explicitly
deferred. At each boundary report completed/total stages, remaining stages,
next goal, assigned and actual tier, and required user action. When the
allocation is unchanged, say `No tier change; continuing automatically` and
continue in the same turn.

## Launch

Claude implements in the same session that planned, or in a later session named
against the plan workspace. Before expensive reads, inspect only hot
`STATUS.md`, Recommended Execution, and Stage Model Allocation. Then load
`SPEC.md`, the assigned plan record, packet and contracts, hot status, and
relevant architecture; read cold `EVIDENCE.md` only for a concrete decision or
prior result.

## Validation and validator

Plans copy runnable commands from `docs/agent_memory/validation-commands.md`.
Every validation row names style, environment stance, and determinism. Run the
smallest stage checks and immediate shared-contract gates, then the full
applicable suite once at integration.

The `validator` agent receives an inline stage packet with `Owned files: None`.
It may write runtime caches required by the project's build or test tooling but
must not change the repository diff. Any produced diff is an integration error.

## Review topology

Use one focused independent review (the `plan-reviewer` agent) for multi-writer
execution, native ABI, persistence or migration, security/trust boundaries, or
unresolved integration risk. Otherwise the lead performs a focused self-review.

Review correctness, cross-component assumptions, security, races, validation,
tests, and specification regressions; ignore style unless it hides a defect.
Escalate the reviewer to Opus when the diff carries native, persistence, or
security risk.
