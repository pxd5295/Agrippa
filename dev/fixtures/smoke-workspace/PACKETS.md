# Dispatch Packets

> Kit smoke-test fixture.

## Frozen contracts

### C1: Planning trigger in root instructions

Contract source: `AGENTS.md:1` (read __TODAY__)

- Exact contract: the root instructions name `Make a plan` as a planning
  trigger.
- Enumerated edit sites: none; this smoke test makes no edit.
- Consumer census:
  - `docs/agent-workflow.md:1`: `# Planning and implementation workflow`
- Pre-authorized ownership expansion: None.
- Covering tests: None.

## Stage packets

### Packet M1

```text
Plan: __PLAN__
Stage: M1 - Confirm the planning trigger
Goal: confirm the root instructions name the planning trigger
Dependencies: None
Owner / assigned tier: sonnet
Design state: Frozen
Contract IDs: C1

Owned files:
- AGENTS.md

Line-anchored edit sites:
- AGENTS.md:1

Allowed interfaces:
- None

Forbidden scope:
- Every other path

Pre-authorized ownership expansion:
- None

Acceptance:
- A1: The root AGENTS.md names the planning trigger phrase.

Validation:
- V1: git grep -n "Make a plan" -- AGENTS.md; lint; sandboxed; deterministic
Covering tests: None
Validation output: Bounded

Relevant references:
- C1

Dirty/user-owned warnings:
- None

Stop/escalate when:
- the trigger phrase is missing

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```

### Packet Integration

```text
Plan: __PLAN__
Stage: Integration - Full acceptance and focused review
Goal: run the full applicable suite
Dependencies: M1
Owner / assigned tier: lead
Design state: Frozen
Contract IDs: C1

Owned files:
- None beyond cross-cutting fixes

Allowed interfaces:
- None without a recorded contract update

Forbidden scope:
- Unrelated systems and user-owned changes

Pre-authorized ownership expansion:
- None

Acceptance:
- A1: The root AGENTS.md names the planning trigger phrase.
- A2: The plan-workspace linter reports PASS for this workspace.

Validation:
- V2: powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1 -PlanPath __PLAN__; lint; sandboxed; deterministic
Validation output: Bounded

Relevant references:
- C1

Dirty/user-owned warnings:
- None

Stop/escalate when:
- the linter reports FAIL

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```
