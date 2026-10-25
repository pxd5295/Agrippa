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
