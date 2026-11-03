# Brief: kit smoke test for the medium plan

Level: medium. The fixture reads one file in one ownership area, changes no
shared interface, and its validation is deterministic.

> Kit smoke-test fixture, written from `skills/plan/templates/BRIEF.md`.
> `dev/fixtures/run-smoke-test.mjs` copies it into a project and deletes it.

## Acceptance

- [ ] **A1:** The project rules file names the project contracts document.
- [ ] **A2:** The plan linter reports PASS for this medium plan.

## Design statement

The check lives in the project rules, `.agrippa/project-rules.md`, which
every installed project keeps. It reuses the plan linter's medium-plan branch
and makes no edit. A second fixture would copy this folder with other
criteria.

## Census

Ownership area: the project documents.

Owned files: `.agrippa/project-rules.md`

Consumer census:

- `.agrippa/project-rules.md:1`: `# Project rules`

Covering tests: `.agrippa/project-rules.md`

## Validation

| Validation ID | Acceptance IDs | Exact command or check | Style | Sandbox | Determinism | When |
|---|---|---|---|---|---|---|
| V1 | A2 | `agrippa-lint -PlanPath __PLAN__` | lint | sandboxed | deterministic | Before the edit |
| V2 | A1 | Read the project rules file and find the project contracts document named in it | manual | sandboxed | manual | After the edit |

## Implementation estimate

- Census files and covering tests: one short file, under 1k tokens.
- Rereads, edits, test output, and reasoning: under 1k tokens.
- Total: about 2k tokens. Current context: not applicable to a fixture.
- Recommendation: this session.
- Confirmed by the user: not applicable to a fixture.

## State

- Phase: Planned
- Done: nothing
- Next: lint
- Updated: __TODAY__

## Resume prompt

```text
Implement __PLAN__/BRIEF.md. Read it first, then the census files.
```
