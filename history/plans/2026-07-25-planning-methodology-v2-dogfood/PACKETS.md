# Dispatch Packets

## Frozen contracts

### C1: Runnable validation documentation

Contract source: `docs/agent_memory/validation-commands.md:1` (read 2026-07-25)

- Exact contract: one real Godot binary, prelude-first ordering, `-s` for all eight SceneTree scripts, numeric rendered-frame caps for all 21 scenes, pytest working directory, sandbox stance, and allowed determinism values.
- Enumerated edit sites: `docs/agent_memory/validation-commands.md:1`, `README.md:77`, `docs/agent_memory/animal-stat-system.md:133`, `docs/agent_memory/godot-architecture.md:1`.
- Consumer census: None; this is additive validation documentation, not a changed code symbol.
- Pre-authorized ownership expansion: the four enumerated documentation files only.

### C2: Twelve-profile routing roster

Contract source: `docs/planning/ROUTING.md:1` (read 2026-07-25)

- Exact contract: the routing roster contains exactly the 12 TOML `name` values specified by the source plan; Luna profiles carry short-context gates; scout is read-only; validator owns no files.
- Enumerated edit sites: `.codex/agents/luna-low-worker.toml:1`, `.codex/agents/terra-low-worker.toml:1`, `.codex/agents/terra-low-reviewer.toml:1`, `.codex/agents/terra-scout.toml:1`, `.codex/agents/terra-validator.toml:1`, `CLAUDE.md:1`, `.claude/agents/repo-scout.md:1`.
- Consumer census: None; profile names are checked mechanically against the routing table.
- Pre-authorized ownership expansion: existing Luna profiles for the shared short-context phrase.

### C3: V2 schema and shape validation

Contract source: `tools/validate_plan_workspace.ps1:1` (read 2026-07-25)

- Exact contract: the workspace linter implements checks 1-25 from the source plan and states it checks shape, never truth; the workflow checker enforces roster consistency and moved-document invariants.
- Enumerated edit sites: `tools/validate_plan_workspace.ps1:1`, `tools/validate_planning_workflow.ps1:1`, `docs/planning/templates/SPEC.md:1`, `docs/planning/templates/PLAN.md:1`, `docs/planning/templates/PACKETS.md:1`, `docs/planning/templates/STATUS.md:1`, `AGENTS.md:1`, `docs/agent-workflow.md:1`, `docs/planning/ROUTING.md:1`, `plans/README.md:1`.
- Consumer census: None; the change adds a new plan schema and retargets its checker.
- Pre-authorized ownership expansion: the enumerated workflow, template, and tool files only.

## Stage packets

### Packet M1

```text
Plan: plans/2026-07-25-planning-methodology-v2-dogfood
Stage: M1 — Runnable validation facts
Goal: Conform validation documentation and stale-memory quarantine to C1.
Dependencies: User source plan and C1 frozen.
Owner / assigned profile: terra_low_worker
Design state: Frozen
Contract IDs: C1
Owned files: docs/agent_memory/validation-commands.md, README.md, docs/agent_memory/animal-stat-system.md, docs/agent_memory/godot-architecture.md
Allowed interfaces: Documentation only.
Forbidden scope: Runtime code, tests, profiles, templates, and tools.
Pre-authorized ownership expansion: None beyond C1.
Acceptance:
- A1: Published validation examples use the real Godot binary, distinguish script and scene styles, explain rendered-frame caps, and record sandbox and determinism.
Validation:
- V1: Targeted documentation search; powershell; workspace-write; deterministic.
Validation output: Bounded
Relevant references: C1 and docs/agent_memory/validation-commands.md.
Dirty/user-owned warnings: Preserve unrelated model archives and all runtime changes.
Stop/escalate when: A listed target count disagrees with the repository.
Return only: files changed; behavior implemented; validation results; unresolved dependencies/risks.
```

### Packet M2

```text
Plan: plans/2026-07-25-planning-methodology-v2-dogfood
Stage: M2 — Routing profiles and Claude scout
Goal: Conform the profile roster and Claude bridge to C2.
Dependencies: User source plan and C2 frozen.
Owner / assigned profile: terra_low_worker
Design state: Frozen
Contract IDs: C2
Owned files: .codex/agents/luna-low-worker.toml, .codex/agents/luna-worker.toml, .codex/agents/luna-reviewer.toml, .codex/agents/terra-low-worker.toml, .codex/agents/terra-low-reviewer.toml, .codex/agents/terra-scout.toml, .codex/agents/terra-validator.toml, CLAUDE.md, .claude/agents/repo-scout.md
Allowed interfaces: Named profile roster and Claude planner bridge.
Forbidden scope: AGENTS.md, workflow/routing guides, templates, tools, and runtime.
Pre-authorized ownership expansion: Existing Luna profiles only, as named by C2.
Acceptance:
- A2: The Codex roster contains 12 parseable profiles, exactly matches the routing roster, enforces Luna short-context use, and includes the read-only Claude repository scout.
Validation:
- V2: TOML parse and roster count; python; read-only; deterministic.
Validation output: Bounded
Relevant references: C2 and docs/planning/ROUTING.md roster.
Dirty/user-owned warnings: Preserve .claude/settings.local.json byte-for-byte.
Stop/escalate when: A required profile name conflicts with active project config.
Return only: files changed; behavior implemented; validation results; unresolved dependencies/risks.
```

### Packet M3

```text
Plan: plans/2026-07-25-planning-methodology-v2-dogfood
Stage: M3 — V2 workflow schema and validators
Goal: Conform instructions, templates, and validators to C3.
Dependencies: User source plan and C3 frozen.
Owner / assigned profile: terra_worker
Design state: Frozen
Contract IDs: C3
Owned files: AGENTS.md, docs/agent-workflow.md, docs/planning/ROUTING.md, docs/planning/templates/SPEC.md, docs/planning/templates/PLAN.md, docs/planning/templates/PACKETS.md, docs/planning/templates/STATUS.md, plans/README.md, tools/validate_plan_workspace.ps1, tools/validate_planning_workflow.ps1
Allowed interfaces: Planning lifecycle, routing, future workspace schema, and static gates.
Forbidden scope: Profiles, Claude files, runtime code, tests, and historical plans.
Pre-authorized ownership expansion: None beyond C3.
Acceptance:
- A3: Future templates and both validators enforce design separation, traceability, ownership, routing, runnable validation shape, and freshness while stating that shape never proves truth.
- A4: The dogfood plan has no Open stage, assigns a cheap tier to a majority of implementation stages, permits one linter-proven three-writer wave, and records assigned versus actual profiles.
Validation:
- V3: Workspace linter on this plan; powershell; workspace-write; deterministic.
Validation output: Bounded
Relevant references: C3 and the user-supplied frozen methodology.
Dirty/user-owned warnings: Preserve the existing AGENTS.md Luna edit and historical plans.
Stop/escalate when: A shape rule cannot be represented without contradicting the source plan.
Return only: files changed; behavior implemented; validation results; unresolved dependencies/risks.
```

### Packet Integration

```text
Plan: plans/2026-07-25-planning-methodology-v2-dogfood
Stage: Integration
Goal: Run the two full static gates and historical self-check.
Dependencies: M1-M3 complete.
Owner / assigned profile: terra_validator
Design state: Frozen
Contract IDs: C1, C2, C3
Owned files: None
Allowed interfaces: None.
Forbidden scope: All repository edits.
Pre-authorized ownership expansion: None.
Acceptance:
- A1: Published validation examples use the real Godot binary, distinguish script and scene styles, explain rendered-frame caps, and record sandbox and determinism.
- A2: The Codex roster contains 12 parseable profiles, exactly matches the routing roster, enforces Luna short-context use, and includes the read-only Claude repository scout.
- A3: Future templates and both validators enforce design separation, traceability, ownership, routing, runnable validation shape, and freshness while stating that shape never proves truth.
- A4: The dogfood plan has no Open stage, assigns a cheap tier to a majority of implementation stages, permits one linter-proven three-writer wave, and records assigned versus actual profiles.
Validation:
- V4: Full workflow checker; powershell; workspace-write; deterministic.
- V5: Full workspace checker; powershell; workspace-write; deterministic.
Validation output: Bounded
Relevant references: C1, C2, and C3.
Dirty/user-owned warnings: Any new repository diff is an integration error.
Stop/escalate when: A command requires source repair.
Return only: commands, exit status, concise outcomes, and unexpected diff.
```
