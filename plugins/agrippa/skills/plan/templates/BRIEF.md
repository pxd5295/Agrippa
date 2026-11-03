# Brief: [change name]

Level: medium. [One sentence: the one ownership area, no shared-interface
change, and deterministic validation.]

> The medium plan. It lives at `plans/YYYY-MM-DD-name/BRIEF.md`, with an
> optional `design/` folder for images or mockups, and it is the whole plan:
> no other workspace file sits beside it. If implementation finds a second
> ownership area or a shared-interface change, stop and ask the user whether
> to move up to a workspace, narrow the scope, or continue. Lint it with
> `agrippa-lint -PlanPath plans/YYYY-MM-DD-name` through the Bash tool.

## Acceptance

Write each criterion as an `A#` item; tests that cover the change are listed
under Census, not here.

- [ ] **A1:** [Observable outcome.]
- [ ] **A2:** [Observable outcome.]

## Design statement

[The three sentences from the `agrippa:design-first` skill: where the change
lives (ownership area, layer, and the owning `file:symbol`), what it extends
or reuses, and what the second occurrence would look like.]

## Census

Ownership area: [the one area, from `.agrippa/project-contracts.md`]

Owned files: `path/to/file.ext`, `path/to/other.ext`

Consumer census, one entry per call site of every symbol the change deletes
or changes:

- `path/to/consumer.ext:90`: `[matching call-site text]`

Covering tests: `tests/test_owned.ext`, or None.

The linter checks that every backticked path on the line above exists, so
list only tests that exist now. A test this change adds is named in the
Validation table through a command that names existing paths.

## Validation

Copy each command from `.agrippa/validation-commands.md`; the linter checks
that it is there, with each `<...>` placeholder filled in by one word. A `manual` row and
the `agrippa-lint` row are exempt. Write every ID out, separated by commas.

| Validation ID | Acceptance IDs | Exact command or check | Style | Sandbox | Determinism | When |
|---|---|---|---|---|---|---|
| V1 | A1, A2 | `[exact command from the catalog]` | [style] | [sandboxed / outside-sandbox] | [deterministic / noisy-retry / skips-headless / manual] | After the edit |
| V2 | A1, A2 | `agrippa-lint -PlanPath plans/YYYY-MM-DD-name` | lint | sandboxed | deterministic | Before the edit |

## Implementation estimate

- Census files and covering tests: [file list with line counts], about
  [N]k tokens to read.
- Rereads, edits, test output, and reasoning: about [N]k tokens.
- Total: about [N]k tokens. Current context: about [N]k tokens.
- Recommendation: [this session / a fresh session with the resume prompt
  below], by the rule in "Make a medium plan" in the `agrippa:plan` skill.
- Confirmed by the user: [this session / fresh session, YYYY-MM-DD].

This estimate is unmeasured until real medium plans are compared with it.

## State

- Phase: [Planned / Implementing / Stopped / Done]
- Done: [what is finished, with the validation IDs that passed]
- Next: [the next concrete step]
- Updated: [YYYY-MM-DD]

Update this section whenever the work stops partway, so a later session can
resume from this file alone.

## Resume prompt

```text
Implement plans/YYYY-MM-DD-name/BRIEF.md. Read it first, then the census
files. Follow its State section, and stop and ask if a second ownership area
or a shared-interface change turns up.
```
