# Change Specification

> Kit smoke-test fixture. `run-smoke-test.ps1` copies this workspace into
> `plans/`, replaces its date and path tokens, lints it, and deletes it. It
> references only files the kit installs.

## Objective

Prove that the installed planning methodology and its workspace linter work in
this repository.

## Background

The kit installs `AGENTS.md`, `docs/agent-workflow.md`, and
`tools/validate_plan_workspace.ps1`. This single-stage workspace exercises
every linter check against those files without changing any of them.

## Planning interview decisions

| Topic | Decision | Rationale |
|---|---|---|
| Interview | None needed | The smoke test has no material choice. |

## Scope and constraints

**In scope**

- Lint this workspace with the installed linter.

**Out of scope**

- Any change to repository files.

**Interfaces and constraints**

- None.

## Design reference

None: no design reference.

## Design rationale

**Chosen design**

- The workspace uses the single-stage shape from `docs/agent-workflow.md`.

**Generalization**

- Any later plan copies the same templates; nothing here is reused.

**Alternatives rejected**

| Alternative | Why not |
|---|---|
| A hand-written sample per install | Slower, and each one could pass or fail for its own reasons. |

**Decision record**

- None: no shared interface changes.

## Acceptance criteria

- [ ] **A1:** The root AGENTS.md names the planning trigger phrase.
- [ ] **A2:** The plan-workspace linter reports PASS for this workspace.

## Handoff gate

- Open questions: None.
- Every implementation stage is `Frozen` or `Bounded-choice`; `Open` design
  does not hand off.
- Acceptance text copied into `PACKETS.md` is verbatim apart from whitespace
  normalization.
