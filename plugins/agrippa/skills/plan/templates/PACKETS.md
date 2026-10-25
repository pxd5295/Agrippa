# Dispatch Packets

> The planner writes frozen contracts and one verbatim, copy-pasteable packet
> per stage. `PLAN.md` references contract IDs and never restates contract
> bodies. Replace every bracketed value.

The workspace linter parses these lines exactly, so write them this way:

- `Contract source:` is one backticked `path:line` with a single line
  number, then `(read YYYY-MM-DD)`. A line range inside the backticks fails
  check 24; put the range after the date.
- The census label is exactly `Consumer census:`, with nothing between the
  words and the colon. Each entry is a backticked repository-relative
  `path:line`, optionally followed by a colon and a backticked snippet. The
  linter opens that file, and the snippet must appear in that line once
  whitespace is collapsed (check 25), so give the path its folders and copy
  the snippet from the line.
- A packet's `Owned files:` is read from its own line only. Put every owned
  file on that line, each in backticks and separated by commas, or write
  `None`.
- A packet has one `- A#:` line for every acceptance ID and one `- V#:` line
  for every validation ID that its `PLAN.md` stage lists. The text after
  `- A#:` is the SPEC.md criterion copied exactly, including backticks and
  other Markdown, apart from whitespace (check 4). Put stage notes on a
  separate `Acceptance notes:` line, never after the copied text.
- Each `PLAN.md` stage has exactly one packet, headed `### Packet M#` or
  `### Packet Integration` with nothing after the stage ID. A validator or
  reviewer that runs inside Integration gets no heading of its own: its
  instructions go inside the one Integration packet, because any further
  `###` heading ends the packet above it.

## Frozen contracts

### C1: [Contract name]

Contract source: `path/to/source.ext:123` (read YYYY-MM-DD)

- Exact contract: [signature, layout, constant, ordering, or exact patch.]
- Enumerated edit sites: `path/to/owned.ext:45`, `path/to/owned.ext:78`.
- Consumer census:
  - `path/to/consumer.ext:90`: `[matching call-site text]`
- Pre-authorized ownership expansion: [enumerated consumer paths, or `None`].
- Covering tests: `tests/test_owned.ext`, `tests/other_owned_test.ext`, or `None`.

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

Owned files: `path/to/owned.ext`, `path/to/other_owned.ext`

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
- V1: [exact command; style; sandbox; determinism]
Covering tests: [copied from the contract, run alongside V#; or None]
Validation output: Bounded

Relevant references:
- C1
- [specific architecture section]
- [Visible UI with a design reference: plans/YYYY-MM-DD-name/design/[file] and
  the visual inventory rows this stage builds; otherwise omit]

Dirty/user-owned warnings:
- [paths and preservation instructions, or None]

Stop/escalate when:
- [unexpected consumer, ownership conflict, interface ambiguity, or failed bounded repair]

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```

Add one packet per implementation, validator, and review stage. A
`validator` packet must say `Owned files: None`.
