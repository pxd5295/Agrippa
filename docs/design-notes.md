# Kit design notes

These are the choices behind the kit that the files themselves do not
explain. They were first recorded in nuro-battler between 2026-09-13 and
2026-10-01 and moved here when the kit became its own repository.

## Placeholders

- Install-time slots are written `[PROJECT: ...]`. Plain `[...]` stays in the
  installed templates and is filled per plan.
- An installed repository must contain no `[PROJECT:` outside the kit folder.
  The README's install-marker scan enforces this.

## Generations

`UPGRADING.md` recognizes three generations:

- **G1**: the dual toolchain, with `.codex/` TOML profiles for three worker
  tiers and a gate that switched the session to a high-effort planner.
- **G2**: the first Claude-only kit, with three agents and no Engineering
  standards.
- **G3**: the current kit.

Only `UPGRADING.md` and `validate-kit.ps1` may name the old vocabulary, because
they need it to recognize and search for an old install.

## The linter

- The kit linter is the linter every installed repository runs. It is never
  edited per project.
- Project checks go in an optional `tools/validate_plan_workspace.local.ps1`,
  which the linter dot-sources. It defines `Test-LocalValidationRow` (run once
  per validation-matrix row) and `Test-LocalValidationMatrix` (run once per
  matrix). The template carries nuro-battler's Godot checks as the example.
- `-SkipLocalChecks` exists for the smoke test, whose generic fixture cannot
  satisfy project rules.
- With nuro-battler's local file installed, the kit linter reproduced the old
  repository linter's error and check counts on the ten newest plans. It also
  caught a gap the old linter missed: the old linter's hard-coded extension
  list ignored `.js` and `.mjs`, so one plan owned files its ownership matrix
  never listed.
- Accepted loss in that switch: check 20 now matches `layout` rather than
  `sensor`.
- A fresh worktree checkout resets file modification times, so check 24
  (freshness) counts differ between a worktree and the main checkout.
- `validate-kit.ps1` compares an installed linter with the kit's after
  normalizing line endings, because git converts them on checkout. A
  byte-for-byte hash failed on CRLF versus LF on 2026-10-18.

## Proof

`fixtures/run-smoke-test.ps1` is the one end-to-end proof: the valid fixture
must pass and a mutated copy must fail. `validate-kit.ps1` runs it against a
simulated install in a temporary folder.

## Linter rules that are easy to trip over

These cost three lint rounds (62 errors down to 0) on one nuro-battler plan.
The templates do not make them obvious, so they are candidates for either
template wording or friendlier linter messages.

- `Contract source:` must be `` `path:NNN` (read YYYY-MM-DD) `` with one line
  number. A range like `:19-29` fails check 24; put the range after the date.
- The census label must be literally `Consumer census:`. A parenthetical
  between the words and the colon fails check 25. Backticked
  `` `dir/file.ext:NNN` ``: `` `snippet` `` entries are verified against the
  real line, so paths need their directory and snippets must be substrings.
- Packet `- A#:` bullets must be the SPEC text verbatim, including backticks
  (check 4). Stage notes go on a separate `Acceptance notes:` line. There is
  one `- V#:` line per validation ID the stage lists.
- `Owned files:` in a packet is read from that one line only, so every file
  goes on that line in backticks.
- Check 13 rejects a matrix command that names a file that does not exist yet,
  so a new test file cannot be in the matrix. Add cases to a registered test
  instead.
- There must be exactly one `### Packet Integration`, with validator and
  reviewer packets inside it. It needs its own `- V#:` line for every ID its
  PLAN row lists (a range like "V1 to V9" fails), and PLAN's Integration row
  must contain the literal phrase "full applicable suite".
- A `Bounded-choice` stage needs a `| Bounded choice |` row containing the
  literal "Options:", "Default:" and "Change observation:", with no C-ids or
  paths in it.
- Any `V` followed by digits anywhere in a workspace (for example a product
  version name) is read as a validation ID and fails as undefined.
