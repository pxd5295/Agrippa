# Planning Methodology v2 Dogfood Specification

## Objective

Finish and verify the planning-methodology v2 implementation using its own
design-state, packet, routing, ownership, and validation contracts.

## Planning interview decisions

| Topic | Decision | Rationale |
|---|---|---|
| Source plan | The user-supplied Planning Methodology v2 text | It fixes all material design choices for this implementation |
| Parallel wave | Three frozen, disjoint documentation/tooling stages | This exercises the explicit three-writer gate |
| Success horizon | Static gates now; routing efficiency measured over the next 3-5 plans | Longitudinal usage cannot be proved in one implementation |

## Scope and constraints

**In scope**

- Command catalog and stale-memory quarantine.
- Routing/templates, workspace linter, profiles, Claude scout, and validators.
- End-to-end static and historical self-checks.

**Out of scope**

- Runtime game behavior and historical plan rewrites.
- Claims about usage savings before 3-5 future plans provide evidence.

## Acceptance criteria

- [x] **A1:** Published validation examples use the real Godot binary, distinguish script and scene styles, explain rendered-frame caps, and record sandbox and determinism.
- [x] **A2:** The Codex roster contains 12 parseable profiles, exactly matches the routing roster, enforces Luna short-context use, and includes the read-only Claude repository scout.
- [x] **A3:** Future templates and both validators enforce design separation, traceability, ownership, routing, runnable validation shape, and freshness while stating that shape never proves truth.
- [x] **A4:** The dogfood plan has no Open stage, assigns a cheap tier to a majority of implementation stages, permits one linter-proven three-writer wave, and records assigned versus actual profiles.

## Handoff gate

- Open questions: None.
- Every implementation stage is Frozen.
