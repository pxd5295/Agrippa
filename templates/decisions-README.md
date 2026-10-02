# Architecture decision records

One file per decision, named `YYYY-MM-DD-<slug>.md`. Records are tracked in
git even when `plans/` is not; a plan workspace links here rather than holding
the record itself.

## When a record is required

`AGENTS.md` requires one before the first edit of any shared interface listed
in `docs/agent_memory/project-contracts.md`. Write it with the
`engineering:architecture` skill when that skill is installed, or by hand in
the shape below. A new subsystem (a new base class or class family, native or
extension module, editor panel, service, or ownership area) also runs
`engineering:system-design` first, and its output goes in the same record. A
record is optional but welcome for any other change whose design was a real
choice between alternatives.

## Shape

Keep each record short and keep these headings so records stay comparable:

- **Status** — `Proposed`, `Accepted`, `Superseded by <file>`.
- **Context** — the problem, the constraint that forced a choice, and the
  consumers affected (found by grep, listed by path).
- **Decision** — what was chosen, and the owner, hook, or interface it
  extends.
- **Alternatives** — each option considered and the one-sentence reason it
  lost.
- **Consequences** — what becomes easier, what becomes harder, and what the
  next similar change should do.

A record is never edited to change its decision. Write a new one and mark the
old one superseded.
