# Change Specification

> Kit smoke-test fixture. `run-smoke-test.mjs` copies this workspace into
> `plans/`, replaces its date and path tokens, lints it, and deletes it. It
> references only the root `AGENTS.md`, the one file every project keeps.

## Objective

Prove that the agrippa plugin's workspace linter works in this repository.

## Background

The project keeps its own `AGENTS.md`. The agrippa plugin provides the plan
templates and the linter, which runs as `agrippa-lint`. This single-stage
workspace exercises every linter check against `AGENTS.md` without changing
it.

## Planning interview decisions

| Topic | Decision | Resolved by | Rationale |
|---|---|---|---|
| Interview | None needed | inspection | The smoke test has no material choice. |

## Scope and constraints

**In scope**

- Lint this workspace with the plugin's linter.

**Out of scope**

- Any change to repository files.

**Interfaces and constraints**

- None.

## Design reference

None: no design reference.

## Design rationale

**Chosen design**

- The workspace uses the single-stage shape from the `agrippa:plan` skill.

**Generalization**

- Any later plan copies the same templates; nothing here is reused.

**Alternatives rejected**

| Alternative | Why not |
|---|---|
| A hand-written sample per install | Slower, and each one could pass or fail for its own reasons. |

**Decision record**

- None: no shared interface changes.

## Acceptance criteria

- [ ] **A1:** The root AGENTS.md names the project contracts document.
- [ ] **A2:** The plan-workspace linter reports PASS for this workspace.

## Handoff gate

- Open questions: None.
- Every implementation stage is `Frozen` or `Bounded-choice`; `Open` design
  does not hand off.
- Acceptance text copied into `PACKETS.md` is verbatim apart from whitespace
  normalization.
