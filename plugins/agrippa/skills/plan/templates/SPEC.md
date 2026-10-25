# Change Specification

> Replace bracketed text. `SPEC.md` is the authoritative source for stable
> acceptance IDs. Keep observable requirements here; sequencing belongs in
> `PLAN.md`.

## Objective

[User or system outcome.]

## Background

[Relevant current behavior and reason for the change.]

## Planning interview decisions

Every uncertainty whose answer would change the plan is a row, including the
ones inspection settled without asking. `Resolved by` is `inspection`, `user`,
or `default` (the recommendation, carried as a `Bounded-choice`). The
interview ends when no entry is left for the user; see step 2 of the
lifecycle in the `agrippa:plan` skill's `agent-workflow.md`.

| Topic | Decision | Resolved by | Rationale |
|---|---|---|---|
| [Material question] | [Chosen answer] | [inspection, user, or default] | [Why, or what was read] |

## Scope and constraints

**In scope**

- [Required behavior or deliverable.]

**Out of scope**

- [Excluded behavior or cleanup.]

**Interfaces and constraints**

- [Named API, schema, protocol, file format, persisted record, shared layout,
  performance, security, platform, compatibility, or migration constraint.]

## Design reference

[For a plan that starts from a mockup or design canvas, follow "Plans that
start from a design reference" in the `agrippa:plan` skill's
`agent-workflow.md`. Otherwise write
"None: no design reference." and delete the two tables below.]

- Source: [artboard URL and artboard name, read YYYY-MM-DD]
- Frozen copy: `plans/YYYY-MM-DD-name/design/[file]` and its render.

**Visual inventory**

| Element | Concrete values from the frozen source | Built by |
|---|---|---|
| [Region, text, bar, legend, or state] | [Container, text, font, size, color token, height, spacing] | [C# or D#] |

**Deviations from the design**

| ID | Design shows | User will see instead | Why | User decision |
|---|---|---|---|---|
| D1 | [Element as drawn] | [Visible result] | [Rule, missing data, reused part, missing token] | [Interview answer] |

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

- [Link to `.agrippa/decisions/YYYY-MM-DD-slug.md` when a shared interface
  changes; otherwise "None: no shared interface changes."]

## Acceptance criteria

Each **Acceptance ID** is stable for this workspace. Do not renumber an ID
after a worker or validation record references it; mark removed work as
superseded with its original ID.

- [ ] **A1:** [Observable criterion and unambiguous pass condition.]
- [ ] **A2:** [Edge case, compatibility, performance, or regression criterion.]

With a design reference, one criterion reads: the built UI matches the frozen
design in `design/` except for the listed deviations.

## Handoff gate

- Open questions: None. No `Planning interview decisions` row is unresolved.
- Every implementation stage is `Frozen` or `Bounded-choice`; `Open` design
  does not hand off.
- Acceptance text copied into `PACKETS.md` is verbatim apart from whitespace
  normalization.
