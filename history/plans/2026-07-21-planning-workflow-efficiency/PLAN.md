# Planning Workflow Efficiency Implementation Plan

## Dependency graph

```text
Wave 1: M1 instruction and planner-routing contract
                    |
Wave 2: M2 compact artifacts + M3 bounded agent context
                    |
Wave 3: M4 checker and scenario gates
                    |
Wave 4: Integration and focused review
```

## Milestone 1: Establish the lean instruction and planner-routing contract

### Dependencies

- None

### Owned files or modules

- `AGENTS.md`
- `.codex/config.toml`
- `docs/agent-workflow.md`

### Interfaces allowed to change

- Planning triggers and High-to-Medium downgrade handshake.
- Execution topology terminology and `use workers` shortcut ordering.
- Durable instruction routing between root guidance and the detailed guide.

### Do not modify

- `.codex/agents/**`
- `docs/planning/templates/**`
- Existing `plans/*` workspaces.

### Implementation

- Reduce root instructions to triggers, authorization boundaries, critical
  safety/quality contracts, shortcuts, and instructions to load the detailed
  guide only for planning or planned implementation.
- Deduplicate and compact the detailed guide while retaining the full planning,
  execution, validation, and review methodology.
- Remove all top-level active lead model and reasoning-effort defaults from
  project config; retain agent limits and the default-mode question feature so
  non-planning work follows the user's selected allocation.
- Add a Sol-High start gate for every ordinary-language planning request and a
  conservative
  post-interview downgrade checklist. Continue on High automatically unless
  every low-risk gate passes: one bounded ownership area; no shared/public,
  native, persistence, security, migration, or performance-sensitive contract;
  deterministic acceptance and validation; no unresolved design choice; and
  no difficult dirty-worktree integration.
- Resolve explicit routing overrides before any launch-model handshake and
  define sequential workers as a supported multi-agent topology.

### Acceptance criteria

- `A1-A4`, `A7`, and `A8`.

### Validation

```powershell
python -c "import pathlib,tomllib; files=list(pathlib.Path('.codex').rglob('*.toml')); [tomllib.loads(p.read_text(encoding='utf-8')) for p in files]; print(f'Parsed {len(files)} TOML files')"
rg -n "Sol High|downgrade|use workers|two.*writers|docs/agent-workflow" AGENTS.md docs/agent-workflow.md
rg -n "^model\s*=|^model_reasoning_effort\s*=|^plan_mode_reasoning_effort\s*=" .codex/config.toml
```

The final `rg` must return no match; worker profile allocations remain explicit
in `.codex/agents/`.

### Parallelizable with

- None; it establishes the contract consumed by later milestones.

### Blocks

- Milestones 2-4

## Milestone 2: Compact future plan artifacts and separate cold evidence

### Dependencies

- Milestone 1 instruction contract

### Owned files or modules

- `docs/planning/templates/SPEC.md`
- `docs/planning/templates/PLAN.md`
- `docs/planning/templates/STATUS.md`
- `docs/planning/templates/EVIDENCE.md` (new)
- `plans/README.md`

### Interfaces allowed to change

- Future plan workspace schema.
- Acceptance/validation ID conventions, soft budgets, and evidence retention.

### Do not modify

- Existing dated plan workspaces.
- Root instructions, agent profiles, or project runtime files.

### Implementation

- Make `SPEC.md` authoritative for numbered acceptance criteria and `PLAN.md`
  authoritative for a single validation matrix.
- Replace repetitive milestone subsections with a compact but ownership-safe
  schema that references acceptance and validation IDs.
- Keep `STATUS.md` to current state, recent deltas, blockers, next action, and
  gate results; remove obsolete launch details after launch completes.
- Add append-only `EVIDENCE.md` for detailed command outcomes, manual checks,
  routing outcomes, escalations, and justified budget exceptions.
- Document soft budgets and selective-read rules.

### Acceptance criteria

- `A5`, `A10`, and the artifact portion of `A12`.

### Validation

```powershell
rg -n "Acceptance ID|Validation ID|EVIDENCE|soft budget|Current state" docs/planning/templates plans/README.md
git diff --check -- docs/planning/templates plans/README.md
```

### Parallelizable with

- Milestone 3; ownership does not overlap after Milestone 1 fixes the contract.

### Blocks

- Milestone 4
- Integration

## Milestone 3: Bound worker and reviewer context

### Dependencies

- Milestone 1 instruction contract

### Owned files or modules

- `.codex/agents/luna-worker.toml`
- `.codex/agents/terra-worker.toml`
- `.codex/agents/terra-high-worker.toml`
- `.codex/agents/sol-worker.toml`
- `.codex/agents/luna-reviewer.toml`
- `.codex/agents/terra-reviewer.toml`
- `.codex/agents/sol-reviewer.toml`

### Interfaces allowed to change

- Worker/reviewer context contract and result schema.

### Do not modify

- Root instructions, plan templates, historical plans, or Godot project files.

### Implementation

- Require one inline stage packet containing goal, ownership, allowed
  interfaces, forbidden scope, acceptance IDs, validation IDs/commands,
  relevant architecture references, dirty-file warnings, and output schema.
- Remove instructions to reread the complete plan workspace; agents may open
  only packet-linked sections when a concrete ambiguity requires it.
- Keep summaries compact and structured for lead integration.
- Permit Luna only when the lead explicitly records high confidence that the
  work is mechanical and exactly validated; otherwise use Terra Medium or
  stronger.
- Keep reviewers read-only and focused on assigned risks plus the integrated
  diff and acceptance map.

### Acceptance criteria

- `A6`, `A9`, and `A11`.

### Validation

```powershell
python -c "import pathlib,tomllib; files=list(pathlib.Path('.codex/agents').glob('*.toml')); [tomllib.loads(p.read_text(encoding='utf-8')) for p in files]; print(f'Parsed {len(files)} agent profiles')"
rg -n "SPEC.md, PLAN.md, and STATUS.md|assigned plan workspace" .codex/agents
```

The final `rg` must return no full-workspace read instruction; narrowly scoped
references are allowed.

### Parallelizable with

- Milestone 2.

### Blocks

- Milestone 4
- Integration

## Milestone 4: Add workflow invariants and prompt-scenario gates

### Dependencies

- Milestones 1-3

### Owned files or modules

- `tools/validate_planning_workflow.ps1` (new)
- Workflow validation examples in `docs/agent-workflow.md` only if a checker
  contract clarification is required.

### Interfaces allowed to change

- Static workflow validation command and warning format.

### Do not modify

- Godot/runtime/test code or historical plan workspaces.

### Implementation

- Validate project TOML, required model/agent limits, template presence and
  headings, worker packet language, shortcut-before-launch behavior, and
  future-only migration markers.
- Report root/guide/template sizes as soft warnings rather than failures.
- Encode prompt-scenario assertions for ordinary-language planning High entry,
  unrestricted non-planning allocation, post-interview downgrade, ordinary
  active-model launch, and `use workers` bypassing the superseded switch.
- Keep the checker deterministic, offline, and concise enough for Luna or Terra
  to run without interpreting long documents.

### Acceptance criteria

- `A2`, `A3`, `A7`, `A8`, and `A12`.

### Validation

- Validation IDs: `V1`, `V2`, `V3`, `V4`, and `V5`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_planning_workflow.ps1
```

### Parallelizable with

- None; it validates the integrated contract.

### Blocks

- Integration and final review

## Integration and final review

### Dependencies

- Milestones 1-4

### Owned files or modules

- `plans/2026-07-21-planning-workflow-efficiency/STATUS.md`
- `plans/2026-07-21-planning-workflow-efficiency/EVIDENCE.md`
- Cross-cutting fixes proven necessary by validation; record ownership
  expansion before editing.

### Interfaces allowed to change

- No new workflow behavior without updating `SPEC.md` and the affected gate.

### Do not modify

- Historical plans, game/runtime code, or unrelated user-owned files.

### Implementation

- Reconcile instruction, template, profile, and checker terminology.
- Run the full workflow checker once, TOML parsing, prompt scenarios, scoped
  whitespace checks, and historical-plan diff audit.
- Use one focused reviewer because Wave 2 has two writers and the workflow is a
  cross-cutting Codex interface; fix valid findings and rerun affected gates.
- Record only summarized current state in `STATUS.md` and detailed results in
  `EVIDENCE.md`.

### Acceptance criteria

- `A1-A12` and `V1-V7` pass, or an exact unresolved gap is reported.

### Validation

- Validation IDs: `V1`, `V2`, `V3`, `V4`, `V5`, `V6`, and `V7`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_planning_workflow.ps1
python -c "import pathlib,tomllib; files=list(pathlib.Path('.codex').rglob('*.toml')); [tomllib.loads(p.read_text(encoding='utf-8')) for p in files]; print(f'Parsed {len(files)} TOML files')"
git diff --check -- AGENTS.md .codex docs/agent-workflow.md docs/planning/templates plans/README.md tools/validate_planning_workflow.ps1
git diff --name-only -- plans | Where-Object { $_ -match '^plans/\d{4}-\d{2}-\d{2}-[^/]+/' -and $_ -notlike 'plans/2026-07-21-planning-workflow-efficiency/*' }
```

The final command must return no historical plan path.

### Parallelizable with

- One read-only focused reviewer after integration is available.

### Blocks

- Completion

## Recommended Execution

- **Execution shape:** Sol lead plus shared-checkout subagents in dependency
  waves; at most two writers run concurrently.
- **Model/reasoning tier:** Standard for implementation. Planning is a
  user-selected Sol-High exception; escalate implementation to Sol High only on
  the triggers below.
- **Stage routing recommendation:** Active Sol Medium lead for the shared
  instruction contract and integration; two Terra Medium workers in Wave 2;
  one focused Terra Medium reviewer after integration.
- **Routing preflight:** Codex desktop uses the model/reasoning control beneath
  the composer. If `use workers` is explicitly requested, resolve it before the
  launch handshake. Named worker fallbacks are listed in the stage table.
- **Lead allocation:** Sol Medium owns shared terminology, integration, dirty
  worktree preservation, and final acceptance.
- **Worker allocation:** At most two concurrent `terra_worker` agents in Wave
  2, one for artifacts and one for profiles. No explorer or test-runner agent.
- **Review allocation:** One read-only `terra_reviewer` focused on instruction
  conflicts, routing regressions, missing invariants, and accidental full
  context reads.
- **Wave order:** M1 -> M2 + M3 -> M4 -> integration/review.
- **Why this scales correctly:** Only M2 and M3 have stable, disjoint ownership;
  M1 establishes their contract and M4 validates their combined result.
- **Why this model tier fits:** Sol High has already resolved design choices.
  The implementation is bounded documentation/config/tooling work with
  deterministic checks, so Standard is the lowest reliable tier.
- **Worktrees:** Not needed; the two parallel writers have disjoint files and a
  shared-checkout integration gate.
- **Usage controls:** Thin hot context, compact worker packets, no full-plan
  rereads, two-writer cap, targeted stage checks, one final full gate, and one
  distinct reviewer.
- **Continuation protocol:** Finish each stage and its assigned gates. Continue
  automatically across unchanged allocations; pause only for a real switch,
  blocker, approval, or escalation.
- **Launch stage:** Milestone 1, lean instruction and planner-routing contract.
- **Launch allocation:** Sol Medium, active lead.
- **Launch verification:** User confirmation required because runtime metadata
  does not verify the current allocation.
- **Launch action:** Select Sol with Medium reasoning beneath the composer.
- **Launch prompt:** `Switched to Sol Medium. Implement plans/2026-07-21-planning-workflow-efficiency/PLAN.md starting Milestone 1.`

### Stage Model Allocation

| Stage/wave | Work | Routing | Model | Reasoning | Why lowest reliable | Escalation trigger | Fallback | After stage |
|---|---|---|---|---|---|---|---|---|
| Planning | Confirm High, inspect, interview, classify risk, specify | Active lead | Sol | High | User requires conservative trusted planning from ordinary requests | Material system remains unmapped | Continue Sol High and document uncertainty | Switch to Sol Medium |
| M1 | Instruction split, defaults, planner and shortcut contract | Active lead | Sol | Medium | Design is resolved but cross-file terminology needs lead context | Any authorization, launch, or safety rule becomes contradictory | Sol High active lead | Spawn Wave 2 |
| M2 + M3 | Compact artifacts and bounded agent profiles | Two parallel workers | Terra | Medium | Disjoint, specified files with deterministic validation | Contract ambiguity, unsafe context omission, or two bounded repairs fail | `terra_high_worker` sequentially | Return to lead |
| M4 | Deterministic checker and prompt scenarios | Active lead | Sol | Medium | Cross-artifact assertions need integration context | A scenario cannot be expressed without changing agreed behavior | Sol High active lead | Integration |
| Integration/review | Full gates, focused review, fixes, evidence | Lead + one reviewer | Sol lead / Terra reviewer | Medium | Integrated judgment plus independent bounded challenge | Conflicting instructions or an acceptance gate remains unresolved | Sol High lead or `sol_reviewer` | Complete |

Luna remains permitted by the general workflow only when the orchestrator is
highly confident a task is mechanical and exactly validated; no planned stage
here is weak enough to justify Luna by default.
