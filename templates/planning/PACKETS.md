# Dispatch Packets

> The planner writes frozen contracts and one verbatim, copy-pasteable packet
> per stage. `PLAN.md` references contract IDs and never restates contract
> bodies. Replace every bracketed value.

## Frozen contracts

### C1: [Contract name]

Contract source: `path/to/source.ext:123` (read YYYY-MM-DD)

- Exact contract: [signature, layout, constant, ordering, or exact patch.]
- Enumerated edit sites: `path/to/owned.ext:45`, `path/to/owned.ext:78`.
- Consumer census:
  - `path/to/consumer.ext:90`: `[matching call-site text]`
- Pre-authorized ownership expansion: [enumerated consumer paths, or `None`].

## Stage packets

### Packet M1

```text
Plan: plans/YYYY-MM-DD-name
Stage: M1 — [name]
Goal: [bounded outcome]
Dependencies: [passed gates]
Owner / assigned tier: [tier]
Design state: Frozen
Contract IDs: C1

Owned files:
- path/to/owned.ext

Line-anchored edit sites:
- path/to/owned.ext:45-62

Allowed interfaces:
- [named interface or None]

Forbidden scope:
- [paths, modules, or interfaces]

Pre-authorized ownership expansion:
- [enumerated paths/bound, or None]

Acceptance:
- A1: [whitespace-normalized exact text copied from SPEC.md]

Validation:
- V1: [exact command; style; environment; determinism]
Validation output: Bounded

Relevant references:
- C1
- [specific architecture section]

Dirty/user-owned warnings:
- [paths and preservation instructions, or None]

Stop/escalate when:
- [unexpected consumer, ownership conflict, interface ambiguity, or failed bounded repair]

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```

Add one packet per implementation, validator, and review stage. A
`validator` packet must say `Owned files: None`.
