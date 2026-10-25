# Worklog

One dated entry per session that changes this repository, newest first. Each
entry says what was done, what was proven and how, what comes next, and any
decision made on a default because only the owner could settle it. The
format and the reason for the log are in `docs/goals.md`.

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
