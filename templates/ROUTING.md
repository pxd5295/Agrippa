# Planning and implementation routing

Read this guide when assigning or dispatching stages from a plan. Lifecycle,
interview, risk, evidence, acceptance, and validation rules remain in
`docs/agent-workflow.md`, which also defines the design states. Only `Frozen`
and `Bounded-choice` stages reach this table.

When the table would assign Opus, first split the work into a planner-frozen
contract and cheaper implementation stages, and record the attempt. An Opus
allocation is valid only when the plan explains why the split would destroy
ownership, validation, or interface safety.

## Model-tier routing table

Read the first matching row from top to bottom. Long-context need is first
because Haiku is weakest with large files or output.

| Inputs | Tier | Reason |
|---|---|---|
| Read a long file, broad diff, consumer census, or large command output; design `Frozen`; no risk flag | `sonnet` | Cheap capable long-context floor |
| No long-context recall; mechanical `Frozen` change with line-anchored edit sites; bounded output and deterministic check | `haiku` | Exact transcription |
| `Frozen` behavioral work in one ownership area; deterministic validation | `sonnet` | Standard behavioral transcription |
| `Bounded-choice`, or bounded behavioral work needing local judgment | `sonnet` | Standard bounded implementation |
| Native, persistence, security, concurrency, performance, or [PROJECT: shared-layout] risk with bounded ownership | `opus` | Risk-aware bounded work |
| Difficult cross-area integration, or a failed bounded repair at a lower tier | `opus` (high effort) | Escalation ceiling |

Tier inputs are: long-context need, files touched, ownership areas,
shared-interface touch, risk flags, design state, and validation determinism.
Do not pick from a model menu; apply the first matching cell and record the
inputs in the stage. Dispatch shape is a separate choice, below.

Reasoning effort is the finer lever inside a tier: escalate `low → medium →
high` before escalating the model. The Agent tool sets `model` per spawn; the
Workflow tool sets `model` and `effort` per stage and is preferred for explicit
effort or deterministic multi-stage orchestration.

Haiku is short-context by contract. A Haiku packet names a line-anchored edit
site for every owned file and bounded validation output. A file above roughly
800 lines without anchors routes to Sonnet. Behavioral ambiguity never routes
to Haiku.

## Fork or fresh subagent

Tier selection picks the model; this picks how the worker starts. A fresh
subagent reloads the root instructions and its own system prompt and cannot
reuse the lead's prompt cache. A fork inherits both, but also inherits the
lead's model, so a forked stage cannot be tier-routed.

- Default: spawn fresh at the routed tier when the packet is complete and the
  stage needs nothing the lead learned this session.
- When the stage depends on context the lead just established — a repair after
  a failed validation, a follow-on edit in a file the lead has already read, an
  ambiguity resolved in conversation — first close the gap by completing the
  packet, which keeps the tier saving.
- Fork only when that gap cannot be closed in the packet, and record that the
  stage forfeits its routed tier.

Never fork to avoid writing a packet; the packet remains the ownership and
acceptance record.

## Roster

Named agents live in `.claude/agents/`; only recurring read-only or
command-runner roles are named.

| File | Role | Tools | Default tier |
|---|---|---|---|
| `repo-scout.md` | Consumer census and contract fact-pack for planning | Glob, Grep, Read, LSP | `sonnet` |
| `plan-reviewer.md` | Independent read-only review of a stage or wave diff against contracts and acceptance | Glob, Grep, Read, Bash, LSP | `sonnet` (Opus for high-risk) |
| `design-reviewer.md` | Read-only review of any non-trivial diff against the Engineering standards | Glob, Grep, Read, Bash, LSP | `sonnet` |
| `validator.md` | Runs the validation matrix verbatim; owns no repo files | Bash, Read | `sonnet` (`haiku` per packet) |

A `tools:` line is a complete allowlist. MCP tools are not implied by it; an
agent that should observe a running application through an MCP server lists
each of that server's tools by full name. [PROJECT: name any MCP tools the
agents above carry, or delete this sentence.]

Their default tiers obey the table above: a consumer census and a full test
suite are both long-context, large-output work, so neither `repo-scout` nor
`validator` routes to Haiku. The lead may pass `haiku` per invocation for a
bounded, small-output validation packet; the per-invocation parameter overrides
the frontmatter.

Implementation workers have no dedicated file: the lead spawns a
`general-purpose` subagent with the verbatim packet and routed `model`.
Ownership and forbidden scope are enforced by the packet, not by tool
restriction.

## Dispatch-ready packets

The planner writes one verbatim, copy-pasteable packet per stage in
`PACKETS.md`; the lead dispatches it without re-synthesizing the plan.
`PLAN.md` references contract IDs and never repeats their bodies.

Each frozen contract has:

- `C#` and a descriptive name;
- `Contract source: file:line (read YYYY-MM-DD)`;
- exact signature, layout, constants, and line-anchored edit sites;
- `Consumer census:` containing every call site for a symbol being changed or
  deleted, captured with `rg` during planning;
- the bounded pre-authorized ownership expansion that covers those consumers;
- `Covering tests:` every test file or target that references an owned file,
  captured with `rg` during planning, or `None`.

Each stage packet contains plan/stage, goal/dependencies, owner/tier, owned
files, allowed interfaces, forbidden scope, exact acceptance and validation
text (commands, style, determinism, covering tests), contract/design state,
expansion, references, dirty warnings, stop/escalate conditions, and the
compact result schema.

In a plan with a design reference, every packet for a stage that changes
anything visible lists the frozen design file in `design/` and the visual
inventory rows it builds as primary references. The worker builds to those
values. When an existing part or style token looks different from them, the
worker escalates instead of substituting it.

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
- the plan states the expected token-cost multiplier and accepts it.

Otherwise dispatch sequentially. Concurrent writers to overlapping files,
isolated experiments, and separate branches run in git worktrees
(`isolation: "worktree"`). The plan names the merge owner and integration gate.
File ownership and worktree isolation for concurrent agents are Claude Code's
own documented rules (agent teams: "Avoid file conflicts"; worktrees).

Concurrency buys throughput, not elapsed time: the one published measurement
(STORM, arXiv 2605.20563) found cost scaling linearly per writer while
wall-clock stayed flat. A plan never claims a time saving from parallel writers.

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
against the plan workspace. `docs/agent-workflow.md` owns the launch read order.

`Implement plan` proceeds with the lead plus routed subagents by default. A
plan-implementation request is an explicit user request to spawn the routed
subagents named in the plan; no per-spawn confirmation is needed. There is no
manual model-switch mode to override; this routing table already selects a tier
per stage. A worktree that the plan requires cannot be skipped.

## Validator

The `validator` agent receives an inline stage packet with `Owned files: None`.
It may write runtime caches required by the project's build or test tooling
([PROJECT: name them, for example class cache, import cache, logs]) but must
not change the repository diff. Any produced diff is an integration error.

## Review topology

Use one focused independent review (the `plan-reviewer` agent) for multi-writer
execution, native ABI, persistence or migration, security/trust boundaries, or
unresolved integration risk. Otherwise the lead performs a focused self-review,
optionally via `/code-review`. Do not spawn duplicate generic reviewers.
Escalate the reviewer to Opus when the diff carries native, persistence, or
security risk.

The `design-reviewer` pass is separate and is owned by the Engineering
standards in `AGENTS.md`, which name the diffs that need it and the size floor
that exempts small ones, plan or not. Its `Design` findings are fixed before
the change is reported done.

`.claude/agents/plan-reviewer.md` owns the review subject list. A finding that
cannot be bound to correctness, a contract ID, or an acceptance ID is optional,
and the lead does not act on it to close a review. This applies to self-review
findings too. The recommended `receiving-review` skill gives a per-finding
procedure for acting on a review.
