# Worklog

One dated entry per session that changes this repository, newest first. Each
entry says what was done, what was proven and how, what comes next, and any
decision made on a default because only the owner could settle it. The
format and the reason for the log are in `docs/goals.md`.

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
