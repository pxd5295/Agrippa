# Evidence Log

> Cold, append-only evidence for this workspace. Do not rewrite earlier
> entries; correct them with a dated follow-up. Read selectively only when a
> current decision, failure, or acceptance/validation result needs its detail.

## Entries

### 2026-11-01 Planning baseline

- **Kind:** command
- **Acceptance IDs:** A1, A6, A9
- **Validation IDs:** V1, V2, V4
- **Command/check:** `git status --short`; `node dev/validate-kit.mjs`; `node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler`; `wc -c plugins/agrippa/scripts/core-rules.md`; the `HEAD` linter on every nuro-battler plan folder
- **Outcome:** The worktree was clean on `goal/plan-levels` at `dae02f0`.
  The self-check printed
  `PASS: 2273 kit checks, 61 required files, smoke test passed, 2 warning(s).`
  The installed-repository audit printed
  `../evolution-game/nuro-battler passed 81 checks` with no finding, at
  nuro-battler `cb66c22` with a clean tree. This replaces the 26-from-67
  baseline in `docs/worklog.md`, which predates nuro-battler's upgrade to
  `.agrippa/project-rules.md`; the measure for A9 is therefore zero findings.
  `core-rules.md` is 9,817 characters, and its "Planning trigger" section is
  1,436. The `HEAD` linter's stdout, stderr, and exit code were saved for all
  74 nuro-battler plan folders (all 74 print `FAIL`, mostly check 24 on
  finished plans, which is expected).
- **Follow-up:** V2 compares the changed linter against these saved outputs.

### 2026-11-01 Planning inspection

- **Kind:** manual check
- **Acceptance IDs:** A6, A7
- **Validation IDs:** None
- **Command/check:** `ls plans/*/BRIEF.md` in nuro-battler; a read of `inject_core_rules.sh`, `low-usage.md`, the README, `templates/hooks/README.md`, and `dev/validate-kit.mjs`
- **Outcome:** No nuro-battler plan folder holds a `BRIEF.md`. Its seven
  `*-BRIEF.md` files are loose files in `plans/`, which the linter rejects as
  "not a directory" before and after this change. So the medium branch
  cannot fire on any existing workspace, and parity rests on the shared
  validation-row code alone. The hook's low-usage line names no count of
  rules, so A7's "the hook's low-usage line says six" is met by leaving it
  without a count; adding one would cost core-rules room. The words "seven"
  that count the low-usage rules are in `low-usage.md`, the `plan` skill, the
  README (twice), `templates/hooks/README.md`, the self-check, and the
  2026-10-25 design note. This repository has no
  `.agrippa/validation-commands.md`, so the matrix takes its commands from
  `CLAUDE.md` and `docs/goals.md`.
- **Follow-up:** None.

### 2026-11-01 Defaults revisited during planning

- **Kind:** routing outcome
- **Acceptance IDs:** A3, A6
- **Validation IDs:** None
- **Command/check:** `SPEC.md` rows marked `default`
- **Outcome:** Two `default` rows are refined, not changed. "What the linter
  checks for a medium plan": the linter also checks the `Level: medium` line
  and that each `BRIEF.md` section heading is present, because a dropped
  State or Resume prompt section would defeat the reason the medium plan
  needs no handoff file, and checking headings costs nothing at runtime.
  "Validation commands match `validation-commands.md`" is made mechanical as
  a match against the catalog's backticked commands with `<...>` placeholders
  as wildcards, exempting `manual` rows and the kit's own `agrippa-lint`. The
  contents row ("What `BRIEF.md` contains") gains a `## Census` heading for
  the census with covering tests, which the row already lists.
- **Follow-up:** Record both in the worklog as defaults the owner can
  overturn.

### 2026-11-01 Planning lint rounds

- **Kind:** command
- **Acceptance IDs:** None
- **Validation IDs:** V6
- **Command/check:** `perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-11-01-plan-levels -RepoRoot .`
- **Outcome:** Two rounds. The first failed five check 26 errors on C3: its
  exact-contract prose named the label "Covering tests" with a colon, and
  the linter read the covering-test list from that first occurrence. The
  prose was reworded; the second round printed
  `PASS: 447 workspace-shape checks. This result does not validate contract truth.`
  This is a lint trap the template wording does not warn about yet.
- **Follow-up:** Candidate for backlog item 5 (lint traps).

### 2026-11-01 M1 complete

- **Kind:** command
- **Acceptance IDs:** A3, A6
- **Validation IDs:** V1, V2
- **Command/check:** `node dev/validate-kit.mjs`; the parity script on all 74 nuro-battler plan folders
- **Outcome:** Pass. Self-check:
  `PASS: 2353 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  Parity: stdout, stderr, and exit code identical to the saved `HEAD`
  output on all 74 folders, and on this workspace (447 checks both). The
  first self-check run failed: the medium lint reported V1 and V2 as
  orphaned, because a `BRIEF.md` has no stage records that cite them. The
  traceability sub now takes the ID kinds whose use is checked; a workspace
  passes none and keeps all three. The smoke test proves a valid
  `BRIEF.md`, a missing section, a missing covering test, and an
  uncatalogued command; the self-check's simulated project proves a
  placeholder match, a non-match, and a `BRIEF.md` beside `SPEC.md`.
  After M1, this workspace's own lint fails check 25 on eight census
  entries whose lines moved in `dev/validate-kit.mjs` and
  `dev/fixtures/run-smoke-test.mjs`; that is the expected freshness result
  once a plan's sources change, and both linters print it identically.
- **Follow-up:** V6 is re-run at Integration and reported against this.

### 2026-11-01 M2 complete

- **Kind:** command
- **Acceptance IDs:** A1, A2, A3, A4, A5
- **Validation IDs:** V1
- **Command/check:** `node dev/validate-kit.mjs`; `wc -c` on `core-rules.md` and its "Planning trigger" section; the hook run with `AGRIPPA_LOW_USAGE=1`
- **Outcome:** Pass:
  `PASS: 2381 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  The first rewrite of "Planning trigger" was 1,551 characters, and the
  injection with low-usage mode on was 10,089, over the cap. The
  redundant sentence on the design statement was dropped, giving 1,428.
- **Follow-up:** None.

### 2026-11-01 Budget exception: agent-workflow.md

- **Kind:** budget exception
- **Acceptance IDs:** A2
- **Validation IDs:** V1
- **Command/check:** the self-check's guide-length warning
- **Outcome:** `agent-workflow.md` grew from 18,737 to about 21,250
  characters, against a 9,000-character soft target it already exceeded.
  The "Planning levels" section is the one definition of the levels, which
  the core rules point to because they have no room, so it cannot move to a
  file that loads less often.
- **Follow-up:** Splitting the guide is not part of this change.

### 2026-11-01 M3 complete

- **Kind:** command
- **Acceptance IDs:** A7, A8
- **Validation IDs:** V1
- **Command/check:** `node dev/validate-kit.mjs`
- **Outcome:** Pass:
  `PASS: 2390 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  `low-usage.md` has six rule rows; the self-check counts them, rejects the
  old row, and rejects "seven rules" or the wider skip-workspace gate in
  `low-usage.md`, the plan skill, the README, and `templates/hooks/README.md`.
- **Follow-up:** None.

### 2026-11-01 Design review and dispositions

- **Kind:** routing outcome
- **Acceptance IDs:** A1, A6
- **Validation IDs:** V1, V2
- **Command/check:** `agrippa:design-reviewer` over the whole diff
- **Outcome:** Two Design findings and five Optional.
  - D1, the covering-test check copied into the medium lint: fixed, with a
    shared `check_covering_paths`.
  - D2, the catalog match reading every backticked span of the catalog:
    fixed. Commands now come only from the "Exact command" column of the
    "Command catalog" and "Full-suite inventory" tables; placeholder-only
    spans are skipped; the catalog template says the linter reads it. C1
    was refined to match.
  - Optional 1, the 300k figure in the template: fixed; the plan skill owns
    it and the self-check rejects a copy in the template.
  - Optional 2, heading clauses repeated in the self-check: fixed; the
    derived loop over the linter's list stays.
  - Optional 3, the no-plan conditions missing from the core rules (C2 said
    they stay): fixed. The conditions are back in the routing paragraph,
    and the inspection, interview, and risk list became a pointer to
    `agent-workflow.md`, whose lifecycle owns them. Section 1,393
    characters, file 9,774, low-usage injection 9,931.
  - Optional 4, the stale "Skip the workspace" scenario row: fixed.
  - Optional 5, seven positional parameters: no change; a hash reference
    when an eighth appears.
  - Forwarded: the C1 message wording differed from the code; C1 now quotes
    the code's message. Census entries in a `BRIEF.md` are not checked
    against their lines, which is intended (the `SPEC.md` row lists IDs,
    commands, and covering tests only).
  A follow-up test against a copy of nuro-battler's catalog in a scratch
  repository showed a placeholder matching any text accepted
  `-s res://tests/test_fat_store.gd --quit-after 9`; a placeholder now
  matches one word, and that command fails while the plain one passes.
  After the fixes: self-check
  `PASS: 2387 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  (three fewer than M3 because duplicated heading clauses were removed),
  parity identical on all 74 nuro-battler folders.
- **Follow-up:** None.

### 2026-11-01 Integration suite

- **Kind:** command
- **Acceptance IDs:** A6, A9
- **Validation IDs:** V2, V3, V4, V6
- **Command/check:** the parity script; `perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-10-01-inspector-redesign -RepoRoot ../evolution-game/nuro-battler`; `node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler`; this workspace's lint
- **Outcome:** V2 pass: identical stdout, stderr, and exit code on all 74
  folders after every linter edit. V3: `FAIL: 27 shape error(s), 875 checks.`,
  identical to the `HEAD` linter (stale sources in a finished plan, with
  nuro-battler's local checks loaded). V4 pass:
  `../evolution-game/nuro-battler passed 81 checks`, zero findings, the same
  as the baseline; nuro-battler's tree stayed clean. V6: this workspace
  passed before implementation (447 checks) and now prints
  `FAIL: 22 shape error(s), 447 checks.`, all check 25 on census lines this
  change edited or moved, byte-identical under both linters.
- **Follow-up:** V5, the live sandbox test, is recorded separately.

### 2026-11-01 V5 live routing, first run: not passed

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** two fresh Code sessions in `../agrippa-sandbox`, started at the same time. Small request: make the unknown-command error in `src/cli/index.js` list the valid commands. Medium request: add `findTask`, `searchTasks`, and `countTasks` to `src/core/tasks.js`, refactor `completeTask` and `removeTask` onto `findTask`, with tests, and no CLI change. Afterwards each session's transcript was searched for the injected rules.
- **Outcome:** Not passed; neither session stated a level.
  - The small session was given the old 0.4.1 core rules (its transcript
    holds "Skip the workspace entirely" and not "one of three levels") and
    loaded `design-first` from `~/.claude/plugins/cache/agrippa/agrippa/0.4.1`.
    It treated the CLI output as a shared interface, wrote a decision
    record, implemented, and committed `bbd7f8b` on a new branch
    `cli-unknown-command-help`. It tells nothing about this change.
  - The medium session was given the new core rules and loaded
    `design-first` from this checkout. Its only reasoning about planning,
    before the first edit, was "No planning is needed: the change stays
    within `src/core/tasks.js` and its test file, with no shared interface
    affected." It said nothing about a level to the user, wrote no
    `BRIEF.md`, implemented directly, and committed `0856faf` on a new
    branch `task-query-helpers`. So it chose "no plan" silently for work
    that does not fit in one sentence.
  - Cause of the version split, read from `~/.claude` without changing it:
    the user settings enable `agrippa@agrippa` from the GitHub marketplace
    named `agrippa`, installed at 0.4.1 in the plugin cache, and the
    sandbox's committed settings declare a directory marketplace with the
    same name pointing at this checkout. `installed_plugins.json` records the
    sandbox's project-scope install with the 0.4.1 cache path, and
    `known_marketplaces.json` now lists `agrippa` as the directory source.
    Which copy a new session loads is not reliable while both share a name.
  - Change made from this: the routing sentence now reads "Before the first
    edit, state the level and why in one line, even for no plan". Section
    1,434 characters, file 9,815, low-usage injection 9,972; self-check
    `PASS: 2387 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  - Side effects in the sandbox: both sessions left uncommitted edits on
    `main` in `src/cli/index.js`, `src/core/tasks.js`, `test/tasks.test.js`,
    and the untracked `.agrippa/` documents of the user's install, and each
    created one local branch. Nothing was pushed.
- **Follow-up:** Rerun V5 with the new wording, in sessions the user starts
  or approves, after confirming each loads this checkout; resolving the
  marketplace-name clash is a settings change for the owner.

### 2026-11-02 V5 live routing, second run, small request

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** one fresh Code session in `../agrippa-sandbox`, started alone after the user approved the rerun. Request: in `src/core/tasks.js`, change the empty-title error from `A task needs a title.` to `A task needs a non-empty title.`, and update any test that checks that message. Afterwards its transcript (`5a74a5f1-fba3-49ab-aa77-d2c72dc62eba.jsonl`) was searched for the injected rules and read for its statements.
- **Outcome:** Level correct; statement placement partly met.
  - The session was given the new core rules: the transcript holds the
    new "Planning trigger" wording three times.
  - Before its first edit, after reading the code, the CLI contract, and
    the catalog, it wrote in visible thinking: "No plan is needed for this
    one-line message change in src/core/ and its test, since the
    empty-title message isn't among the frozen tasks stderr lines and the
    exit code stays 1." Its user-facing reply came only after the edit and
    said "No plan was needed because this is a one-line message change."
  - It changed two lines, ran the catalog's syntax check, `npm test` (12 of
    12 pass), and the CLI smoke check, skipped the design review under the
    size floor with the line count, and did not commit or branch.
- **Follow-up:** Run the medium request in a fresh session. Whether a level
  stated only in visible thinking before the edit meets A9 is the owner's
  call; the rule says "state", which the reply did only after the edit.

### 2026-11-02 V5 live routing, second run, medium request: no result

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** one fresh Code session in `../agrippa-sandbox`, started alone after the small one finished. Request: add `renameTask(tasks, id, title)` and `clearDone(tasks)` to `src/core/tasks.js`, sharing the title validation with `addTask`, finding the task with `findTask`, with tests and no CLI change. Its transcript (`f4fa43ff-68c2-4025-8b0e-8b0cf334b2cb.jsonl`) was searched for the injected rules.
- **Outcome:** No result for this change. The session was given the old
  0.4.1 core rules: its transcript holds "Skip the workspace entirely" three
  times and "one of three levels" not at all, and it loaded `design-first`
  from `~/.claude/plugins/cache/agrippa/agrippa/0.4.1`. It stated no level,
  wrote no `BRIEF.md`, gave a design statement in visible thinking,
  implemented, updated the sandbox's `.agrippa/project-contracts.md` and
  `.agrippa/validation-commands.md`, and started a `design-reviewer` pass.
  It did not commit or branch.
- **Follow-up:** The marketplace-name clash decides which copy loads, so the
  medium request cannot be tested reliably until it is resolved. The user
  settings and the sandbox's `.claude/settings.json` both define a
  marketplace named `agrippa` (GitHub `pxd5295/Agrippa` and this checkout)
  and both enable `agrippa@agrippa`. Resolving it is a settings change for
  the owner.

### 2026-11-03 V5 live routing, medium request retried: not passed

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** the owner chose to retry without a settings change. One fresh Code session in `../agrippa-sandbox`. Because the previous session had already added `renameTask` and `clearDone`, the request was another of the same size: add `reopenTask(tasks, id)` and `moveTask(tasks, id, index)` to `src/core/tasks.js`, both using `findTask`, `moveTask` rejecting an index outside the list, with tests and no CLI change. Its transcript (`ec70f8d4-4cff-4fa1-bc68-7a3b0b679c3c.jsonl`) was searched for the injected rules and read for its statements.
- **Outcome:** Not passed. The session was given the new core rules ("one
  of three levels" three times, the old wording not at all) and loaded
  `design-first` from this checkout. Its own task list had a step "State
  design and planning level", but the only statement it made before the
  first edit was the design statement, in visible thinking: "I'm keeping
  this to `src/core/tasks.js`, adding `reopenTask` and `moveTask` beside the
  existing task functions, with a shared `updateTask` helper so the
  replace-the-matching-task logic isn't copied a third time." It named no
  level, wrote no `BRIEF.md`, implemented, ran the catalog checks (21 tests
  pass), updated the sandbox's `.agrippa/` contracts, and started a
  `design-reviewer` pass. The change is two functions, a helper, and tests,
  which does not fit a one-sentence diff, so its floor is a medium plan.
  This is the second session with the new rules to take a medium request
  as no plan without saying so.
- **Follow-up:** The core-rules sentence alone does not make the model state
  the level. Both medium sessions loaded `design-first` before their first
  edit, so that skill is where the model acts; the fix is the owner's
  choice.

### 2026-11-03 Level step added to design-first

- **Kind:** escalation
- **Acceptance IDs:** A4, A9
- **Validation IDs:** V1, V5
- **Command/check:** the owner approved moving the level statement into `design-first`. Step 1 gained item 5, "Which planning level", which checks the core rules' "Planning trigger" floors by pointer, names the one-sentence-diff floor, and loads `agrippa:plan` before step 2 for a medium plan or a workspace. Step 3 now puts the design statement in the reply "not only in your reasoning" and opens it with the level line. Five self-check clauses keep the wording. `node dev/validate-kit.mjs`
- **Outcome:** `PASS: 2392 kit checks, 63 required files, smoke test passed, 2 warning(s).` The core rules did not change.
- **Follow-up:** Rerun the medium request.

### 2026-11-03 V5 live routing, medium request after the design-first change: passed

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** one fresh Code session in `../agrippa-sandbox`. Request: add `duplicateTask(tasks, id)` (a copy with a new id, same title, always open, id given the way `addTask` does without copying that logic) and `completeAll(tasks)` to `src/core/tasks.js`, with tests and no CLI change. Its transcript (`ecb40eb6-62fb-42c8-abc0-775a7e19f845.jsonl`) was searched for the injected rules and read for its statements; its `BRIEF.md` was relinted.
- **Outcome:** Passed for the medium request.
  - The session was given the new core rules and loaded `design-first` and
    `plan` from this checkout; the transcript holds the new "Which planning
    level" item.
  - After `design-first` it loaded `agrippa:plan`, read the `BRIEF.md`
    template and "Planning levels", and before the first edit said to the
    user: "Writing a short medium plan (`BRIEF.md`) for the two new
    functions, then implementing them." The reason in full is the plan's
    `Level:` line: one ownership area, no shared interface, deterministic
    unit tests.
  - It wrote `plans/2026-11-03-duplicate-and-complete-all/BRIEF.md` and
    linted it: `PASS: 64 workspace-shape checks.`, the same on relint here.
    The plan has acceptance IDs, a design statement, a census, four catalog
    commands that matched, the estimate (about 16k tokens against about 45k
    in context), and a resume prompt. It then implemented, moving the id
    rule into a shared `nextId`, and started a `design-reviewer` pass.
  - Deviations: it did not ask with `AskUserQuestion` where to implement,
    and its `BRIEF.md` says "Confirmed by the user: this session" next to
    "Not asked with `AskUserQuestion`", reasoning that the request asked
    for implementation and the total was far under 300k. It kept the
    template's guidance blockquote and instruction lines.
- **Follow-up:** The skipped confirmation and the contradictory
  "Confirmed by the user" line are a gap in "Make a medium plan", for the
  owner to weigh. The small request was not rerun after this change; it
  does not load `design-first`, so its result from 2026-11-02 stands.
- **Owner decision, 2026-11-03:** leave "Make a medium plan" as it is; no
  change for the skipped confirmation.

### 2026-11-03 V5 live routing, small request rerun: not passed

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** the owner did not accept the 2026-11-02 small result and asked for a rerun. One fresh Code session in `../agrippa-sandbox`. Request: in `src/core/tasks.js`, rename the private helper `normalizeTitle` to `cleanTitle`. Its transcript (`2868690c-ea7a-4d0d-80cd-fc4173d2ebca.jsonl`) was searched for the injected rules and read for its statements.
- **Outcome:** Not passed. The session was given the new core rules ("one
  of three levels" three times, the old wording not at all). It did not
  load `design-first`. Before its first edit it wrote only a design
  statement, in visible thinking: "I'm renaming the module-private title
  check in src/core/tasks.js, which only changes the name, and updating the
  two references to it in .agrippa/project-contracts.md so the contract
  doesn't point at a missing function." It never named a level, in
  thinking or in the reply. The work itself was right for no plan: the
  rename, two contract mentions, all catalog checks passing, the design
  review skipped under the size floor with the line count.
- **Follow-up:** For a change too small to load `design-first`, only the
  core-rules sentence asks for the level, and three of three sessions with
  that sentence did not put the level in the reply before the first edit.
  The core rules have about 28 characters of room, and the `SPEC.md` rows
  "What notices a change request" (no new hook) and "Ask or tell" are the
  owner's, so the fix is the owner's choice.

### 2026-11-03 Level sentence reworded to open the reply

- **Kind:** escalation
- **Acceptance IDs:** A1, A9
- **Validation IDs:** V1, V5
- **Command/check:** the owner chose to reword and rerun. In `scripts/core-rules.md`, "Before the first edit, state the level and why in one line, even for no plan" became "Start your reply with the level and why in one line, even for no plan". The self-check clause and the one-sentence-diff row of the prompt-scenario table in `agent-workflow.md` follow it. `node dev/validate-kit.mjs`, then the hook run with `AGRIPPA_LOW_USAGE=1`.
- **Outcome:** `PASS: 2392 kit checks, 63 required files, smoke test passed, 2 warning(s).` `core-rules.md` is 9,808 characters; the low-usage injection is 9,965 (9,972 before).
- **Follow-up:** Rerun a small request.

### 2026-11-03 V5 live routing, small request after the rewording: passed

- **Kind:** manual check
- **Acceptance IDs:** A9
- **Validation IDs:** V5
- **Command/check:** one fresh Code session in `../agrippa-sandbox`. Request: in `src/core/tasks.js`, rename the private helper `nextId` to `nextTaskId`. Its transcript (`60db883b-8024-4b6b-910e-9de1e6898e47.jsonl`) was searched for the injected rules and read for its statements.
- **Outcome:** Passed. The session was given the reworded rules ("Start
  your reply" three times, neither earlier wording). Its first output,
  before any tool call, was "No plan needed: this is a one-sentence rename
  of a private helper inside one file." It then renamed the helper at its
  definition and both callers, updated the one contract line naming it,
  left the dated plan in `plans/` alone, ran the catalog checks (24 tests
  pass), and skipped the design review under the size floor with the line
  count. It did not commit or branch.
- **Follow-up:** V5 now has one passing small run and one passing medium
  run. The medium run used the wording before this change; its level
  statement comes from `design-first`, which this change does not touch.
