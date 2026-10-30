# Worklog

One dated entry per session that changes this repository, newest first. Each
entry says what was done, what was proven and how, what comes next, and any
decision made on a default because only the owner could settle it. The
format and the reason for the log are in `docs/goals.md`.

## 2026-10-29: packet gaps are recorded (backlog item 4)

Unattended session on branch `goal/packet-gap-evidence`, not pushed.

- **Done.** `EVIDENCE.md` offers a `packet gap` entry kind, and
  `workspace-files.md` says what an entry records: the stage, the packet
  field that was missing or wrong, how the gap surfaced, and how it was
  closed. The `PACKETS.md` template's `Return only:` line asks the worker for
  packet gaps, and `ROUTING.md` lists them in worker results and has the lead
  record each one. `dev/validate-kit.mjs` gained seven clauses that keep the
  wording in place. The design notes have a dated entry, "Packet gaps are
  recorded", and the research note's open question points at it.
- **Proven.** `node dev/validate-kit.mjs`:
  `PASS: 2280 kit checks, 61 required files, smoke test passed, 2 warning(s).`
  (2273 on `main`). With the four plugin files stashed, the same run failed
  with 7 errors, one for each new clause. A scratch harness linted a copy of
  the smoke fixture in a throwaway repository, once as it is and once with
  the new `Return only:` line and a `packet gap` entry; both passed 118
  workspace-shape checks. No linter, hook, or core-rules file changed, so no
  sandbox run was needed.
- **Audit baseline (backlog item 5).** `node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler`
  reports 0 findings from 81 checks on `main` and on this branch, and leaves
  nuro-battler's working tree clean. nuro-battler has been upgraded to 0.4.2
  since the 26-from-67 count of 2026-10-25, so 0 from 81 is the new baseline.
- **Not proven.** How often packets are incomplete; that needs plans in an
  installed repository that dispatch packets after this change.
- **Next.** Backlog item 1 still needs a push to GitHub for its macOS leg.
  Its Linux leg could be proven locally first under WSL, whose `/bin/sh` is
  dash. Items 3 and 4 can be removed from the backlog once the owner agrees
  they are proven, and item 5 once the owner accepts the baseline above.
- **Decided on a default.**
  - Items 1 and 2 were skipped again, for the reasons in the 2026-10-25
    entry: item 1 needs a push and item 2 needs a person to answer the
    interviews. Item 3's work is already on `main`.
  - Gaps get an entry only when they happen; a clean stage records nothing,
    and the denominator is the dispatched packets in `PACKETS.md`. The
    alternative, an entry or line per stage, gives a surer denominator at a
    token cost on every plan. The design notes say what to do if the counts
    look too low.
  - Only dispatched packets count, not the packet of a single-stage plan the
    lead implements itself.
  - The smoke fixture keeps the old `Return only:` wording, so it keeps
    covering older plans.
  - The `design-reviewer` pass was skipped under the size floor: 12 lines of
    code in `dev/validate-kit.mjs`, with no class, conditional, constant, or
    config key. The rest of the diff is documentation.
  - No plan workspace was made, because the session held one backlog item.
  - The backlog in `docs/goals.md` was not edited, because the owner edits it.

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
