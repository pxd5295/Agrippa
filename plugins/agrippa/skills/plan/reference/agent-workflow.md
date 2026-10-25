# Planning and implementation workflow

Load this guide only for plan creation or plan implementation. It is a
reference file of the `agrippa:plan` skill. The Agrippa core rules own
triggers and hard safety rules, and the project's `.agrippa/project-rules.md`
owns the project contracts and project rules. This file owns planning, evidence, acceptance,
and project contracts. `ROUTING.md`, the skill's other reference file, owns
topology, tier selection, packets, waves, launch, and review.

## Planning lifecycle

The core rules own the trigger and the gate that decides whether a workspace
is warranted at all. This lifecycle starts once it is.

### 1. Inspect narrowly

Read relevant code, tests, current configuration, dirty-worktree state, and the
smallest applicable `.agrippa/` set. Use targeted `rg` to map
interfaces and consumers. Do not spawn planning subagents by default; the
read-only `repo-scout` is allowed only when a broad census or long-context
extraction would otherwise dominate, and its fact-pack value is recorded.

If `.agrippa/area-map.md` exists, open it first for the folders the
change touches. Its rows name the entry points and covering tests to read and
the contract that governs each folder, and its "Traps" list records what has
gone wrong there before. Check its `Built at` commit with
`git diff --name-only <commit> -- <folder>`: a row whose folder changed since
is verified in the code before it is cited, and the map is never a
`Contract source:`. Append one `area map` entry to `EVIDENCE.md` per plan
that consulted it, saying which rows were used, which were stale, and whether
they replaced a wider read or misled. Those entries decide whether the map is
kept, refreshed with `/agrippa:survey`, or dropped, and whether any larger
knowledge layer is worth building.

For every symbol a plan deletes or changes, run the consumer census during
planning. Record every call site in the frozen contract with `file:line` and a
matching snippet. Pre-authorize the exact bounded ownership expansion needed
for those consumers. Do not defer discovery to implementation.

Capture the covering tests in the same pass: every test file or target that
references an owned file, recorded in the contract as `Covering tests:` and
copied into the packet's validation block. Do not substitute general test-first
instructions for the list; with a targeted test map regressions fell 70%, and
procedure text without one made them worse (TDAD, arXiv 2603.17973).

### 2. List the open decisions, then interview

The interview ends when no known decision is left for the user to make. It
does not end after a set number of rounds, and it never ends on a
self-reported confidence score; `docs/design-notes.md` in the methodology
repository records why.

1. After the narrow inspection, write down every uncertainty whose answer
   would change the plan. Each entry names what it affects (behavior, scope,
   compatibility, architecture, migration, persistence, performance, failure
   handling, acceptance, execution choices, or appearance, including each
   deviation from a design reference, below) and whether reading code can
   resolve it or only the user can. An uncertainty that changes nothing in
   the plan is not an entry; decide it and move on.
2. Resolve every code-resolvable entry by reading further. Never put one to
   the user. An entry that reading cannot settle moves to the user-only group.
3. Put the user-only entries to the user with `AskUserQuestion`, one to three
   per round, recommending the first option and stating its tradeoff. Rounds
   continue while user-only entries remain, including entries that an answer
   exposes.
4. The interview ends when the user-only group is empty, or when the user
   says to proceed on the recommendations. An entry still unresolved at that
   point becomes a `Bounded-choice` (step 3, below) with the recommendation as
   its default. It is never dropped.

Record every entry, including the ones inspection settled, as a row of the
`Planning interview decisions` table in `SPEC.md`, with `Resolved by` set to
`inspection`, `user`, or `default`. A row resolved by inspection says what
was read.

### 3. Resolve design before handoff

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

`SPEC.md` also records the design rationale for the chosen approach: the owner
it extends, how the next similar need is served without copying, the
alternatives rejected and why, and a link to the decision record in
`.agrippa/decisions/` when a shared interface changes.

### Plans that start from a design reference

This applies when the request names a mockup, a design canvas artboard, or any
other visual design as the target. The design is the source of truth for how
the result looks. A plan that lists only its parts and behaviors will be built
correctly and still look different, so the plan carries the look itself.

1. **Freeze the design.** Copy the chosen artboard's source into
   `plans/<slug>/design/`; for a published design canvas, read the artboard
   file with the Artifact tool's `read` action and its `path`. Add a rendered
   image at the target panel width when one can be produced. Record the URL,
   the artboard name and the read date under `Design reference` in `SPEC.md`.
   Plan from the frozen file, never from memory of drawing it or from a
   summary, even in the session that drew it.
2. **Write the visual inventory.** `SPEC.md`'s `Visual inventory` lists every
   visible element of the artboard with concrete values from its source: the
   container or card for each region, all text including secondary notes and
   units, font family, size and weight, colors mapped to the project's style
   tokens (the style-token document in the "Contract documents" table of
   `.agrippa/project-contracts.md`, or raw values when it lists
   none), bar and row heights, spacing, legend style, and every state it draws (open,
   closed, hover, empty). Each row names the contract that builds it (`C#`) or
   a deviation (`D#`). A row with neither is `Open` design and does not hand
   off.
3. **Record and ask about every deviation.** Anything the plan will build
   differently goes in `Deviations from the design`, saying what the user will
   see instead and why. Typical causes are a repo rule (such as a card never
   containing a card), data that does not exist, an existing part that looks
   different, or a missing style token. Reuse under the Engineering standards
   never silently overrides the design: choosing an existing part that looks
   different from the mockup is a deviation. Put every deviation to the user in
   the interview, described as the visible change, and record the answer in its
   row.
4. **Accept and check fidelity.** `SPEC.md` carries one acceptance criterion
   that the built UI matches the frozen design except for the listed
   deviations. Its validation row captures the rendered UI in-app, the way
   "UI capture" in `.agrippa/validation-commands.md` says, compares
   it side by side with the frozen render at the same width, and walks every
   inventory row. Run it after the first stage that puts the UI on screen and
   again at Integration. The lead runs this check itself. In-app capture is
   allowed; operating-system screen capture is allowed only when that section
   says so. If the capture path is down, report the check as not done; a
   headless pass never replaces it.

### 4. Classify planning risk

Record the risk class in `STATUS.md`. High-risk work — coupled ownership,
shared contracts, material risk, unresolved design, nondeterministic
acceptance, or difficult integration — keeps the plan detailed and the
implementation tier conservative. A demonstrably low-risk plan (one bounded
ownership area, deterministic acceptance and validation) reduces scope and may
route more stages to Haiku or Sonnet. Uncertainty stays conservative.

### 5. Create a unique workspace

Create `plans/YYYY-MM-DD-short-name/` from the `agrippa:plan` skill's
templates. Never overwrite a
workspace; append `-2`, `-3`, and so on. A workspace contains:

- `SPEC.md`: requirements, interview decisions, design rationale,
  constraints, and acceptance IDs;
- `PLAN.md`: dependency waves, exclusive ownership, validation IDs, and
  execution recommendation;
- `PACKETS.md`: sourced frozen contracts and verbatim dispatch packets;
- `STATUS.md`: small current-state handoff;
- `EVIDENCE.md`: cold append-only command and routing evidence;
- `design/`: only for a plan with a design reference, the frozen artboard
  source and its render.

Use `A#` for acceptance, `V#` for validation, and `C#` for frozen contracts.
`PLAN.md` references contracts and never restates their bodies. Packet-quoted
acceptance text matches `SPEC.md` after whitespace normalization.

### Workspace shape

Two shapes are allowed; the trigger gate in the core rules chooses between them,
and the linter applies unchanged to both.

The **single-stage shape** is the default for bounded work in one ownership area
with one writer. It contains the same linted files, one implementation stage
plus the required `Integration` stage, one wave, and no parallelism. The lead
implements it directly, so its packet exists for the ownership and
acceptance/validation record rather than for dispatch. Do not invent waves,
extra writers, or a worktree for work that needs none.

The **full shape** adds dependency waves, multiple owners, packets written for
dispatch, and worktrees where ownership overlaps. Use it when the work spans
ownership areas, needs concurrent writers, or changes a shared interface with
consumers in more than one area.

A single-stage plan still needs its `Integration` stage, ownership matrix, and
validation matrix. Reducing scope never means dropping the acceptance trace.

Run the linter through the Bash tool, because the plugin's `bin/` folder is
on the Bash tool's PATH only:

```bash
agrippa-lint -PlanPath plans/YYYY-MM-DD-name
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
`.agrippa/validation-commands.md`, including style, sandbox stance,
and determinism. Run the workspace linter before implementation.

Recommended Execution records wave order, cheap-tier share, the expected cost
multiplier for any wave with more than one writer, safety, launch, and one
atomic allocation row per stage with assigned tier, actual tier, route,
escalation trigger, and next stage. Objective routing and packet rules live only
in `ROUTING.md`.

## Planning on Claude Fable 5.1

Three documented Fable 5.1 behaviors work against the artifact rules above.
Each has a published fix; apply it in the system prompt or the first user turn
of the planning session.

**Mark quoted contract text as quoted.** Fable 5.1 is more likely than Fable 5
to reproduce passages of a source without marking them as quotations. A stage
ships as `Frozen` only on sourced contract IDs, so a `SPEC.md` that blends
`.agrippa/` wording into the planner's own prose is unsourced in fact
while passing every shape check the workspace linter runs. Quote contract text
explicitly and cite the contract ID beside it; reword everything else.

**Edit plan artifacts in place.** Fable 5.1 is more likely to rewrite a whole
text file than make a targeted edit. Across the turns that iterate `SPEC.md`,
`PLAN.md`, and `PACKETS.md`, a rewrite can drop a frozen constant or a
consumer-census row without that loss appearing as a deletion. Anthropic's fix:

> The number of tokens used to edit files is best minimized, all else being
> equal. Therefore, when it will not affect the end result, try to surgically
> edit a file rather than rewrite the entire thing.

**Plan at `high` effort.** A full workspace is a long multi-section
deliverable. At `xhigh` and `max`, Fable 5.1 may draft most of it in thinking
and write it out again as the reply, doubling the turn and risking a
`max_tokens` cutoff mid-artifact. Start at `high` and move up only where a
measured quality gain justifies it.

Two lesser effects need no rule, only awareness. Fable 5.1 may issue one tool
call per turn where Fable 5 batched several, which inflates the step-3 read
ladder the same way unchained shell steps inflate a shell turn. Its prose is
denser in places, with longer sentences and fewer paragraph breaks, which costs
more in a `PACKETS.md` packet that reaches an implementation subagent verbatim
than it does in chat.

Source: [Prompting Claude Fable
5.1](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1).

## Implementation launch

Before expensive reads, inspect only hot `STATUS.md`, Recommended Execution, and
Stage Model Allocation. Otherwise load `SPEC.md`, the assigned plan record,
packet/contracts, hot status, and relevant architecture; read cold evidence
only for a concrete decision or prior result.

Follow `ROUTING.md` for dispatch, waves, validator, allocation
continuity, escalation, and review. Treat each allocation row as atomic.

## Validation and evidence

Run the smallest relevant checks during a milestone and the immediate
shared-contract gate; run the complete applicable suite once after integration.
Expand earlier only when evidence exposes unexpected coupling. The validation
catalog, `.agrippa/validation-commands.md`, owns exact syntax,
prerequisites, the inventory, and each command's matrix values; the retry and
pre-existing-failure rules are in the `agrippa:verify-before-done` skill. Read
the catalog's "Invocation traps" section before the first run, because it
names the invocation rules that most often go wrong.

### Validation matrix values

Every matrix row records Style, Sandbox, Determinism, and When, with the
Style, Sandbox, and Determinism values copied from the catalog's row for that
command. Allowed Determinism values are `deterministic`, `noisy-retry`,
`skips-headless`, and `manual`. The Sandbox value is one of:

- `sandboxed`: the command reads and writes only inside the workspace and
  needs no network, GPU, display, or external service;
- `outside-sandbox`: the command writes caches or user data outside the
  workspace, or needs network, credentials, a GPU, a display, or a service.

A plan cites only a target registered in the catalog's "Full-suite inventory";
one representative test is never the whole suite. Before implementing a plan,
run its matrix commands once to confirm that every named target exists and
executes; a speculative matrix is the main way the process fails quietly.
Every matrix row is a headless command. A row that needs the live app or a GPU
says so in its packet, and that mark is the only case for running the app
through the project's live-app bridge.

The project's durable command invariants (one required binary, an invocation
shape per target kind, a prerequisite that must come first, a required working
directory) are checks in `tools/validate_plan_workspace.local.pl`, which
`agrippa-lint` loads from the repository. The shared linter is never edited
for them, and it checks shape and freshness, never semantic truth.

Keep `STATUS.md` small: phase, planner, owner, assigned/actual tier, remaining
work, blockers, next action, and gates. Append commands, outcomes, routing,
retries, escalations, unrelated failures, and budget exceptions to `EVIDENCE.md`;
distinguish environment limits from regressions. Performance records a
baseline, and a change to a subsystem in the "Gated subsystems" row of the
Architecture owners table in `.agrippa/project-contracts.md` passes
the gate that row names.

Completion requires every Acceptance ID and required Validation ID to pass, or
an exact remaining gap to be reported. A green linter is never evidence that a
contract is correct.

## Prompt-scenario contract

Durable behaviors this workflow must preserve:

| Scenario | Required behavior |
|---|---|
| Ordinary non-planning request | Preserve the user's model/effort; no switch prompt |
| Question about a possible feature | Answer and offer; edit only after an explicit go-ahead |
| New planning request | Start immediately; recommend a stronger model only if complex, then proceed |
| Planning request for a one-sentence diff | Skip the workspace; implement directly and say why |
| Stage depends on the lead's live context | Complete the packet, or fork and record the forfeited tier |
| User says to proceed on the recommendations mid-interview | End the interview; each unresolved entry becomes a `Bounded-choice` with the recommendation as its default |
| Low-risk plan after interview | Reduce scope; route more stages to cheaper tiers |
| High-risk plan after interview | Keep detail and a conservative implementation tier |
| Plan from a mockup or design canvas | Freeze the artboard, inventory it, ask about each deviation, check fidelity side by side |
| Normal implementation launch | Follow the stage table; spawn routed subagents |
| Same tier at boundary | Report progress and continue automatically |

## Project ownership and worktrees

`.agrippa/project-contracts.md` names the ownership areas, the shared
interfaces, and the high-risk change classes with their required gates. Use
worktrees for substantial overlap, experiments, or branches; the integration
owner compares contracts before merge.
