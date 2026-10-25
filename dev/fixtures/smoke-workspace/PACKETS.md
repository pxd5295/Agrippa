# Dispatch Packets

> Kit smoke-test fixture.

## Frozen contracts

### C1: Project contracts pointer in the project rules

Contract source: `.agrippa/project-rules.md:1` (read __TODAY__)

- Exact contract: the project rules name
  `.agrippa/project-contracts.md` as the owner of the project
  contracts.
- Enumerated edit sites: none; this smoke test makes no edit.
- Consumer census:
  - `.agrippa/project-rules.md:1`: `# Project rules`
- Pre-authorized ownership expansion: None.
- Covering tests: None.

## Stage packets

### Packet M1

```text
Plan: __PLAN__
Stage: M1 - Confirm the project contracts pointer
Goal: confirm the project rules name the project contracts document
Dependencies: None
Owner / assigned tier: sonnet
Design state: Frozen
Contract IDs: C1

Owned files:
- .agrippa/project-rules.md

Line-anchored edit sites:
- .agrippa/project-rules.md:1

Allowed interfaces:
- None

Forbidden scope:
- Every other path

Pre-authorized ownership expansion:
- None

Acceptance:
- A1: The project rules file names the project contracts document.

Validation:
- V1: git grep -n "project-contracts.md" -- .agrippa/project-rules.md; lint; sandboxed; deterministic
Covering tests: None
Validation output: Bounded

Relevant references:
- C1

Dirty/user-owned warnings:
- None

Stop/escalate when:
- the project contracts pointer is missing

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
- A1: The project rules file names the project contracts document.
- A2: The plan-workspace linter reports PASS for this workspace.

Validation:
- V2: agrippa-lint -PlanPath __PLAN__, through the Bash tool; lint; sandboxed; deterministic
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
