# Planning Methodology v2 Dogfood Plan

## Dependency graph

```text
Wave 1: M1 + M2 + M3
              |
Wave 2: Integration
```

## Validation matrix

| Validation ID | Acceptance IDs | Exact command or check | Style | Sandbox | Determinism | When |
|---|---|---|---|---|---|---|
| V1 | A1 | `rg -n "Godot_v4.7-stable_win64_console.exe|rendered frames|outside-sandbox|deterministic" docs/agent_memory/validation-commands.md README.md docs/agent_memory/animal-stat-system.md` | powershell | workspace-write | deterministic | M1 |
| V2 | A2 | `python -c "import pathlib,tomllib; files=list(pathlib.Path('.codex/agents').glob('*.toml')); [tomllib.loads(p.read_text(encoding='utf-8')) for p in files]; assert len(files)==12; print('12 profiles parsed')"` | python | workspace-write | deterministic | M2 |
| V3 | A3-A4 | `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1 -PlanPath plans/2026-07-25-planning-methodology-v2-dogfood` | powershell | workspace-write | deterministic | M3 |
| V4 | A1-A4 | `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_planning_workflow.ps1` | powershell | workspace-write | deterministic | Integration |
| V5 | A1-A4 | `powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1 -PlanPath plans/2026-07-25-planning-methodology-v2-dogfood` | powershell | workspace-write | deterministic | Integration |

## Ownership matrix

| Path | Wave | Owning stage | Worktree / merge owner |
|---|---|---|---|
| `docs/agent_memory/validation-commands.md` | 1 | M1 | None |
| `README.md` | 1 | M1 | None |
| `docs/agent_memory/animal-stat-system.md` | 1 | M1 | None |
| `docs/agent_memory/godot-architecture.md` | 1 | M1 | None |
| `.codex/agents/luna-low-worker.toml` | 1 | M2 | None |
| `.codex/agents/luna-worker.toml` | 1 | M2 | None |
| `.codex/agents/luna-reviewer.toml` | 1 | M2 | None |
| `.codex/agents/terra-low-worker.toml` | 1 | M2 | None |
| `.codex/agents/terra-low-reviewer.toml` | 1 | M2 | None |
| `.codex/agents/terra-scout.toml` | 1 | M2 | None |
| `.codex/agents/terra-validator.toml` | 1 | M2 | None |
| `CLAUDE.md` | 1 | M2 | None |
| `.claude/agents/repo-scout.md` | 1 | M2 | None |
| `AGENTS.md` | 1 | M3 | None |
| `docs/agent-workflow.md` | 1 | M3 | None |
| `docs/planning/ROUTING.md` | 1 | M3 | None |
| `docs/planning/templates/SPEC.md` | 1 | M3 | None |
| `docs/planning/templates/PLAN.md` | 1 | M3 | None |
| `docs/planning/templates/PACKETS.md` | 1 | M3 | None |
| `docs/planning/templates/STATUS.md` | 1 | M3 | None |
| `plans/README.md` | 1 | M3 | None |
| `tools/validate_plan_workspace.ps1` | 1 | M3 | None |
| `tools/validate_planning_workflow.ps1` | 1 | M3 | None |

## Milestones

### M1: Runnable validation facts

| Field | Record |
|---|---|
| Wave | 1 |
| Dependencies | None |
| Design state | Frozen |
| Contract IDs | C1 |
| Assigned profile | terra_low_worker |
| Routing inputs | Long documentation; four files; one ownership area; no shared runtime interface; deterministic |
| Risk flags | None |
| Owned files/modules | `docs/agent_memory/validation-commands.md`, `README.md`, `docs/agent_memory/animal-stat-system.md`, `docs/agent_memory/godot-architecture.md` |
| Line-anchored edit sites | `docs/agent_memory/validation-commands.md:1`, `README.md:77`, `docs/agent_memory/animal-stat-system.md:133`, `docs/agent_memory/godot-architecture.md:1` |
| Allowed interfaces | Documentation only |
| Forbidden scope | Runtime code, tests, profiles, templates, and tools |
| Pre-authorized ownership expansion | None beyond C1 |
| Work | Verify and repair exact validation documentation and stale-memory warning. |
| Acceptance IDs | A1 |
| Validation IDs | V1 |
| Validation output | Bounded |
| Parallel safety | Frozen C1, disjoint files/interfaces, independent V1, and material benefit beside M2/M3 |
| Worktree | No |
| Blocks | Integration |

#### Split attempt

Not required by tier.

### M2: Routing profiles and Claude scout

| Field | Record |
|---|---|
| Wave | 1 |
| Dependencies | None |
| Design state | Frozen |
| Contract IDs | C2 |
| Assigned profile | terra_low_worker |
| Routing inputs | Long roster/profile context; bounded config; no runtime interface; deterministic |
| Risk flags | None |
| Owned files/modules | `.codex/agents/luna-low-worker.toml`, `.codex/agents/luna-worker.toml`, `.codex/agents/luna-reviewer.toml`, `.codex/agents/terra-low-worker.toml`, `.codex/agents/terra-low-reviewer.toml`, `.codex/agents/terra-scout.toml`, `.codex/agents/terra-validator.toml`, `CLAUDE.md`, `.claude/agents/repo-scout.md` |
| Line-anchored edit sites | `.codex/agents/luna-low-worker.toml:1`, `.codex/agents/terra-low-worker.toml:1`, `.codex/agents/terra-low-reviewer.toml:1`, `.codex/agents/terra-scout.toml:1`, `.codex/agents/terra-validator.toml:1`, `CLAUDE.md:1`, `.claude/agents/repo-scout.md:1` |
| Allowed interfaces | Named profile roster and Claude planner bridge |
| Forbidden scope | AGENTS.md, workflow/routing guides, templates, tools, and runtime |
| Pre-authorized ownership expansion | Existing Luna profiles named in C2 |
| Work | Verify and repair roster, short-context gates, and scout boundaries. |
| Acceptance IDs | A2 |
| Validation IDs | V2 |
| Validation output | Bounded |
| Parallel safety | Frozen C2, disjoint files/interfaces, independent V2, and material benefit beside M1/M3 |
| Worktree | No |
| Blocks | Integration |

#### Split attempt

Not required by tier.

### M3: V2 workflow schema and validators

| Field | Record |
|---|---|
| Wave | 1 |
| Dependencies | None |
| Design state | Frozen |
| Contract IDs | C3 |
| Assigned profile | terra_worker |
| Routing inputs | Long cross-document tooling context; bounded choice absent; deterministic |
| Risk flags | None |
| Owned files/modules | `AGENTS.md`, `docs/agent-workflow.md`, `docs/planning/ROUTING.md`, `docs/planning/templates/SPEC.md`, `docs/planning/templates/PLAN.md`, `docs/planning/templates/PACKETS.md`, `docs/planning/templates/STATUS.md`, `plans/README.md`, `tools/validate_plan_workspace.ps1`, `tools/validate_planning_workflow.ps1` |
| Line-anchored edit sites | `AGENTS.md:1`, `docs/agent-workflow.md:1`, `docs/planning/ROUTING.md:1`, `tools/validate_plan_workspace.ps1:1`, `tools/validate_planning_workflow.ps1:1` |
| Allowed interfaces | Planning lifecycle, routing, future workspace schema, and static gates |
| Forbidden scope | Profiles, Claude files, runtime code, tests, and historical plans |
| Pre-authorized ownership expansion | None beyond C3 |
| Work | Verify and repair instructions, future templates, linter checks 1-25, and roster consistency. |
| Acceptance IDs | A3-A4 |
| Validation IDs | V3 |
| Validation output | Bounded |
| Parallel safety | Frozen C3, disjoint files/interfaces, independent V3 syntax/shape check, and material benefit beside M1/M2 |
| Worktree | No |
| Blocks | Integration |

#### Split attempt

Not required by tier.

### Integration: Full acceptance and focused review

| Field | Record |
|---|---|
| Wave | 2 |
| Dependencies | M1-M3 |
| Design state | Frozen |
| Contract IDs | C1, C2, C3 |
| Assigned profile | terra_validator |
| Routing inputs | Bounded full static output; no source ownership |
| Risk flags | None |
| Owned files/modules | None |
| Line-anchored edit sites | Not applicable |
| Allowed interfaces | None |
| Forbidden scope | All repository edits |
| Pre-authorized ownership expansion | None |
| Work | Run the full applicable suite for workflow and workspace shape, then record historical self-checks. |
| Acceptance IDs | A1-A4 |
| Validation IDs | V4, V5 |
| Validation output | Bounded |
| Parallel safety | Sequential after all writers |
| Worktree | No |
| Blocks | Completion |

#### Split attempt

Not required by tier.

## Recommended Execution

- **Shape:** Sol lead plus three frozen shared-checkout writers, then validator integration.
- **Wave order:** M1 + M2 + M3, then Integration.
- **Cheap-tier share:** 2 of 3 implementation stages.
- **Safety:** C1-C3 are frozen; owned paths are disjoint; stage checks are independent; full cross-artifact checks wait for integration.
- **Launch:** Dispatch the three stage packets, then the validator packet.

### Stage Model Allocation

| Stage/wave | Assigned profile | Actual profile | Routing | Escalation trigger | After stage |
|---|---|---|---|---|---|
| M1 / Wave 1 | terra_low_worker | terra_low_worker | Parallel worker | Target inventory contradicts C1 | Integration |
| M2 / Wave 1 | terra_low_worker | terra_low_worker | Parallel worker | Roster conflicts with project config | Integration |
| M3 / Wave 1 | terra_worker | terra_worker | Parallel worker | A shape rule contradicts the source plan | Integration |
| Integration | terra_validator | terra_validator | Sequential validator | A gate requires source repair | Complete |
