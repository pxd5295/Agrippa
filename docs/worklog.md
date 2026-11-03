# Worklog

One dated entry per session that changes this repository, newest first. Each
entry says what was done, what was proven and how, what comes next, and any
decision made on a default because only the owner could settle it. The
format and the reason for the log are in `docs/goals.md`.

## 2026-11-01: three planning levels built (backlog item 1, not yet proven)

Session on branch `goal/plan-levels`, nothing committed or pushed.

- **Done.** `PLAN.md`, `PACKETS.md`, and `EVIDENCE.md` for
  `plans/2026-11-01-plan-levels/`, linted in two rounds. Then A1 to A8:
  the "Planning trigger" section routes every change request to no plan, a
  medium plan, or a full workspace and is shorter than before; a "Planning
  levels" section in `agent-workflow.md`; the `BRIEF.md` template; "Make a
  medium plan" in the `plan` skill with the 300k rule; a medium section in
  `design-first`; a `Level:` line in the `STATUS.md` template; the linter's
  medium branch with a smoke fixture and self-check cases; low-usage mode at
  six rules; "From G4 v0.4.2" in `UPGRADING.md`; a note in the catalog
  template that the linter reads it; and the design note "Three planning
  levels". A `design-reviewer` pass found two Design issues (a copied
  covering-test check, a catalog match that read every backticked span),
  both fixed.
- **Proven.** `node dev/validate-kit.mjs`:
  `PASS: 2387 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  (2273 before). The old and new linter printed byte-identical stdout,
  stderr, and exit codes on all 74 nuro-battler plan folders, rerun after
  every linter edit. `node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler`:
  0 findings from 81 checks, the same as before the change. The 26-from-67
  baseline in the entry below is out of date, because nuro-battler has since
  been upgraded; 0 from 81 is the new baseline. The injected rules are 9,972
  characters with low-usage mode on.
- **Not proven.** A9's live routing test. Two fresh sandbox sessions stated
  no level. One was given the old 0.4.1 rules from the plugin cache, because
  the user settings and the sandbox both name a marketplace `agrippa`. The
  other had the new rules, decided "no planning is needed" in its reasoning
  without saying so, and implemented a three-function change with no plan.
  The routing sentence now requires the statement before the first edit and
  for "no plan" too; that wording has not been tested live. Details are in
  the plan's `EVIDENCE.md`. The template contents and the 300k estimate stay
  unmeasured until backlog item 2.
  On 2026-11-02 the test was rerun one session at a time. The small request
  got the new rules and chose "no plan" with its reason before the first
  edit, but only in visible thinking; the reply said it after the edit. The
  medium request got the 0.4.1 rules again, so it tells nothing. On
  2026-11-03 a retried medium request, of the same size, got the new rules
  and was still implemented with no plan and no stated level. With the
  owner's yes, `design-first` gained a level step (step 1, item 5) and its
  step 3 now opens the reply with the level line; the self-check then gave
  `PASS: 2392 kit checks, 63 required files, smoke test passed, 2 warning(s).`
  The next medium request stated a medium plan before its first edit,
  wrote a `BRIEF.md` that lints clean, and implemented. It skipped the
  `AskUserQuestion` confirmation of where to implement.
  The owner chose to leave the skipped confirmation unfixed, and did not
  accept the small result. A small rerun (rename a private helper) had the
  new rules and never named a level at all; small changes do not load
  `design-first`.
  With the owner's choice, the core-rules sentence became "Start your reply
  with the level and why in one line, even for no plan" (low-usage
  injection 9,965 characters). The next small run (rename a private
  helper) opened its reply with "No plan needed: this is a one-sentence
  rename of a private helper inside one file." V5 has now passed once for
  each request size.
- **Next.** Commit on this branch once the owner approves.
- **Decided on a default.**
  - The linter also checks the `Level: medium` line and the seven
    `BRIEF.md` section headings, beyond the IDs, commands, and covering tests
    the `SPEC.md` row lists. It does not check a `BRIEF.md`'s census lines.
  - Catalog matching reads only the "Exact command" column of the "Command
    catalog" and "Full-suite inventory" tables; a `<...>` placeholder matches
    one word; `manual` rows and `agrippa-lint` are exempt.
  - The cost estimate reads file sizes at about four characters per token.
  - A validation ID in a `BRIEF.md` is not checked for use beyond its own
    table.
  - The hook's low-usage line was left without a count of rules, which
    satisfies "says six" without spending core-rules room.
  - Integration ran as one lead with a `design-reviewer` pass and no
    `plan-reviewer` pass.
  - The live test ran both requests at once in the shared sandbox checkout.
    The sessions left uncommitted edits on the sandbox's `main`, including
    in the untracked `.agrippa/` documents of the owner's install, and the
    local branches `cli-unknown-command-help` and `task-query-helpers`.

## 2026-11-01: three planning levels decided

- **Done.** The owner set a new top goal: plans sized to the work, with three
  levels (no plan, a medium `BRIEF.md`, the full workspace) and a routing
  rule that states the level and asks only on close calls. After a
  discussion, two critiques, and an interview, every decision was recorded
  with who made it and why in `plans/2026-11-01-plan-levels/SPEC.md`. The
  goal and backlog items 1, 2, 10, and 11 were added to `docs/goals.md`, and
  the older items were renumbered 3 to 9. No kit file changed.
- **Proven.** `node dev/validate-kit.mjs`:
  `PASS: 2273 kit checks, 61 required files, smoke test passed, 2 warning(s).`
  The two warnings are the existing guide-length soft targets. The workspace
  holds only `SPEC.md` and `STATUS.md` and is not linted yet.
- **Next.** Write `PLAN.md`, `PACKETS.md`, and `EVIDENCE.md` for the plan and
  lint it, then build backlog item 1.
- **Decided on a default.** Five rows in the `SPEC.md` decisions table say
  `default`: the user's words decide whether there is a plan but not its
  level; the risk signals are the existing gate's; the contents of
  `BRIEF.md`; the `UPGRADING.md` note; and what the linter checks for a
  medium plan. Each can be overturned by editing its row.
- **Decided by the owner, with trade-offs accepted.** Building before
  measuring, so the template and the 300k estimate are unproven until
  backlog item 2. Recording the level only in plan files, so nothing shows
  whether a "no plan" call was right.

## 2026-10-27: release 0.4.2

- **Done.** The plugin is released as 0.4.2: the version in `plugin.json`
  and the marketplace entry, the pinned `ref` in both READMEs, and tag
  `v0.4.2` on the release commit. The move of the project rules into
  `.agrippa/project-rules.md`, planned as 0.5.0, ships in this release, so
  `UPGRADING.md`, the self-check messages, and the design and research notes
  now say v0.4.2 where they said v0.5.0.
- **Proven.** `node dev/validate-kit.mjs`; the result is in the release
  commit message.
- **Next.** `/agrippa:upgrade` in a fresh session in the sandbox as the live
  proof of "From G4 v0.4.1", then the same in nuro-battler.
- **Decided by the owner.** The release and its number: the owner asked for
  0.4.2 rather than 0.5.0 although the release changes an installed
  repository's layout.

## 2026-10-25: project rules move out of the root AGENTS.md

- **Done.** The always-loaded project contracts and project rules now install
  as `.agrippa/project-rules.md` from `templates/PROJECT-RULES.md`, imported
  by the root `CLAUDE.md`, and the kit never writes to a repository's
  `AGENTS.md`. `UPGRADING.md` gained "From G4 v0.4.1", the install and
  upgrade skills, the core rules, the README, the checklist, the folder
  templates, and the smoke fixture follow the new path, and the installed
  repository check requires the file, the import, and a root `AGENTS.md`
  without the kit's opening sentence. `docs/design-notes.md` records why,
  including the two options rejected.
- **Proven.** `node dev/validate-kit.mjs` and the installed-repository check
  against `../agrippa-sandbox`; the results are in the session that made the
  change. The sandbox still has the 0.4.1 layout, so its check reports the
  move as the remaining step, which is the intended result. A fresh session
  in the sandbox with a temporary `@.agrippa/probe-rules.md` line in its
  root `CLAUDE.md` had the probe file's codeword in context at start, so the
  hidden-folder import loads; the probe files were removed afterwards.
- **Next.** Release 0.5.0, then `/agrippa:upgrade` in a fresh session in the
  sandbox as the live proof of "From G4 v0.4.1".
- **Deferred to the owner.** The version bump and the commit; the owner chose
  the move itself in the session.

## 2026-10-25: lint traps retired in the templates (backlog item 3)

Unattended session on branch `goal/retire-lint-traps`, not pushed. The
owner then asked for `main` to be merged into the branch so it merges back
without conflicts.

- **Done.** Each of the eight traps in the `docs/design-notes.md` trap list
  is now stated in the template where a planner writes the line it governs:
  `PACKETS.md` (contract source, census, one-line `Owned files:`, verbatim
  acceptance text with an `Acceptance notes:` line, one `- A#:` or `- V#:`
  line per ID, one packet per stage), `PLAN.md` (write IDs out with commas
  instead of ranges, check 13 and new test files, the "full applicable
  suite" phrase, the `Bounded choice` row), and `SPEC.md` (capital A, C, or
  V followed by digits in prose). The sample packet's `Owned files:` and the
  `PLAN.md` acceptance ranges, which taught two of the traps, were rewritten.
  No linter check or message changed. `dev/validate-kit.mjs` gained 15
  clauses that keep the wording in place. The design notes have a dated
  entry, "The lint traps move into the templates".
- **Proven.** `node dev/validate-kit.mjs`:
  `PASS: 2137 kit checks, 61 required files, smoke test passed, 2 warning(s).`
  (2122 on `main` before the change), and 2273 checks after `main` was
  merged in. A scratch harness linted a copy of the
  smoke fixture in a throwaway repository: all eight recommended forms
  passed, and all 17 trap variants failed with the message the templates
  name. `node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler`
  reported 24 findings from 64 checks both before and after the change, and
  left nuro-battler's working tree clean. After `main` was merged into this
  branch, with the project rules moved to `.agrippa/project-rules.md`, the
  same audit reports 26 findings from 67 checks. The two new findings are the
  missing `.agrippa/project-rules.md` and the missing import of it in the
  root `CLAUDE.md`, which "From G4 v0.4.1" in `UPGRADING.md` resolves. The
  26-from-67 count is the baseline backlog item 5 asks for, as of the merge.
- **Not proven.** Whether first-time planners now pass in fewer lint rounds;
  that needs new plans in an installed repository.
- **Next.** Backlog item 1 still needs its macOS and Linux proof, which
  needs a push to GitHub (see below). This machine has WSL with Ubuntu 24.04,
  whose `/bin/sh` is dash, so the Linux leg could be proven locally first.
- **Deferred to the owner.**
  - Items 1 and 2 were skipped, not attempted. Item 1 can only be proven by
    a GitHub Actions run, which needs a push; the default chosen was not to
    push anything, since no instruction allowed it. Item 2 needs a person to
    answer the install and upgrade interviews.
  - Template wording only, no linter message changes. The default avoids
    touching the linter's output, which `docs/goals.md` lists as a contract,
    and the byte-for-byte parity work a linter change requires.
  - Item 3 was left in the backlog for the owner to remove, because the
    owner edits that list.
  - No plan workspace was made, because the session held one backlog item.
  - The smoke fixture still writes `Owned files:` as a one-item bullet list,
    which the linter accepts. It was left unchanged so the fixture keeps
    covering older plans.

## 2026-10-25: goals document

- **Done.** Wrote `docs/goals.md` from an interview with the owner: purpose,
  the four directions and their ranking, goals with measures, hard limits
  for an unattended agent, non-goals, how a long run works, a backlog, and
  the decisions reserved for the owner. Added this log and a pointer to both
  in `CLAUDE.md`.
- **Proven.** `node dev/validate-kit.mjs` was run after the change; its
  result is in the commit that carries it.
- **Next.** Backlog item 1 in `docs/goals.md`: a GitHub Actions workflow
  that runs the self-check on Ubuntu, macOS, and Windows.
- **Deferred to the owner.** None. Every choice in the document was the
  owner's answer in the interview.
