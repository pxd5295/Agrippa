# Change Specification

> Replace bracketed text. `SPEC.md` is the authoritative source for stable
> acceptance IDs. Keep observable requirements here; sequencing belongs in
> `PLAN.md`.

## Objective

[User or system outcome.]

## Background

[Relevant current behavior and reason for the change.]

## Planning interview decisions

| Topic | Decision | Rationale |
|---|---|---|
| [Material question] | [Chosen answer] | [Why] |

## Scope and constraints

**In scope**

- [Required behavior or deliverable.]

**Out of scope**

- [Excluded behavior or cleanup.]

**Interfaces and constraints**

- [Named API, schema, protocol, file format, persistence, performance,
  security, platform, compatibility, or migration constraint.]

## Design rationale

**Chosen design**

- [Where the change lives and the existing owner, hook, or interface it
  extends.]

**Generalization**

- [How the next similar need is served by this change without copying it.]

**Alternatives rejected**

| Alternative | Why not |
|---|---|
| [Option] | [Reason] |

**Decision record**

- [Link to `docs/decisions/YYYY-MM-DD-slug.md` when a shared interface
  changes; otherwise "None: no shared interface changes."]

## Acceptance criteria

Each **Acceptance ID** is stable for this workspace. Do not renumber an ID
after a worker or validation record references it; mark removed work as
superseded with its original ID.

- [ ] **A1:** [Observable criterion and unambiguous pass condition.]
- [ ] **A2:** [Edge case, compatibility, performance, or regression criterion.]

## Handoff gate

- Open questions: None.
- Every implementation stage is `Frozen` or `Bounded-choice`; `Open` design
  does not hand off.
- Acceptance text copied into `PACKETS.md` is verbatim apart from whitespace
  normalization.
