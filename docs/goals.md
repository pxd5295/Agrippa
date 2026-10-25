# Goals for work on Agrippa

This document is for an agent left to work on this repository for a long
time, across sessions, with little or no instruction beyond what is written
here. It says what the project is trying to become, how to tell whether a
piece of work helped, what an unattended agent may never do on its own, and
where to find the next task. It was written on 2026-10-25 from an interview
with the owner and is meant to stay short. A goal grows into more text only
when a long run shows the shorter version was not enough.

`CLAUDE.md` holds the working rules for any session here. This document does
not repeat them; it sits above them and decides between them when they do
not settle a choice.

## Purpose

Agrippa is a Claude Code plugin that makes an agent plan before it builds,
show evidence before it calls anything done, and leave work another session
can pick up. The owner's own repositories are its real users. Public users
are welcome and nothing may break for them, but they do not set priorities.

## Directions and how they rank

Four directions matter over the next six months. When two conflict, the
first one wins; the other three are peers, and each advances only on
measurement.

1. **Harden what exists.** Every rule, check, and template earns its place
   with evidence from installed repositories. A new rule is accepted only
   when it does not weaken one that already works, and a proven rule is not
   replaced by a cheaper or more elegant one that is less proven.
2. **Cut token cost.** Normal mode gets cheaper and low-usage mode gets
   better measured, without moving any correctness floor. A saving that
   cannot be measured on a real plan is not a saving.
3. **Wider adoption.** Install and upgrade work for repositories and people
   the owner does not control: other languages, continuous integration,
   macOS and Linux as well as Windows.
4. **Grow the knowledge layer.** The area map, decision records, and plan
   evidence become memory that later sessions actually use. This direction
   waits for the `area map` evidence entries to show a gain; it is not
   pursued on belief.

## Goals and their measures

Each goal names the measure an agent reads to know whether it is getting
closer. A measure that is not recorded somewhere cannot be used, so the
first task under any goal is often to start recording it.

- **The kit stays proven.** `node dev/validate-kit.mjs` prints `PASS` after
  every change, and the audit of an installed repository with
  `-InstalledRepo` reports no more findings than it did before the change.
  Record the audit's finding and check counts in `docs/worklog.md` so the
  comparison has a baseline.
- **Plans pass the linter sooner.** A plan in an installed repository
  reaches `agrippa-lint` `PASS` in fewer rounds. The lint-trap list in
  `docs/design-notes.md` is the backlog for this: each trap becomes either
  template wording that prevents it or a linter message that explains it.
- **Plans finish.** Plans that start implementation reach done without a
  repair wave, and stages that are reported done stay done. Count these from
  `STATUS.md` and `EVIDENCE.md` in installed repositories' recent plans.
- **Evidence accumulates and is read.** `EVIDENCE.md` entries about the
  area map, low-usage mode, and packet gaps exist in real plans, and no rule
  in those areas changes without citing them.
- **Token cost per plan goes down.** Measured from spawn logs or session
  usage on comparable plans, never estimated. Until a measurement exists,
  cost claims in a commit or note say so.
- **The code stays within its constraints.** The plugin runs on POSIX `sh`
  and Perl 5.30 with core modules only, the self-check's own check count
  does not fall, and every script change keeps the parity method the design
  notes describe: run old and new on the same real plans and compare output
  byte for byte.

## Hard limits for an unattended agent

These hold no matter how long the run has been or how confident the agent
is. Each needs the owner's explicit yes in that session.

- **No release.** Never change the version in `plugin.json` or the
  marketplace entry, create or move a git tag, or edit the pinned `ref` in
  any README.
- **No contract break without an upgrade path.** The local-checks
  interface (`tools/validate_plan_workspace.local.pl`), the `.agrippa/`
  layout, the `agrippa-lint` command and its output format, and the names of
  the agents and skills change only with a matching `UPGRADING.md` entry and
  the owner's yes.
- **No change to the fixed limits.** The 10,000-character cap on the core
  rules, the correctness floors that low-usage mode may not move, and the
  license stay as they are.
- **No edits to installed repositories.** nuro-battler and any other
  repository that uses the plugin are read-only proof targets from a session
  here. The sandbox at `../agrippa-sandbox` is the one place to run the
  plugin live from this checkout, and editing it is what it is for.
- **No edits under `history/plans/`.** They are dated records.
- **No commits to `main`.** Work lands on a branch. The owner merges.
- **No permission or settings changes.** Never add allow rules, hooks, or
  permission modes to any settings file, in this repository or the sandbox,
  without the owner's yes to that specific change.

## Non-goals

An agent does not start work in these areas, however reasonable the next
step looks.

- **Other agent platforms.** Agrippa targets Claude Code. No compatibility
  work for other agents or generic instruction formats.
- **Compiled or packaged tooling.** No binaries, package registries, or
  build pipeline. `sh` and Perl with core modules are the whole runtime, and
  the development tools stay on Node's built-in modules.
- **Application code generation.** The plugin plans, reviews, and verifies.
  It never becomes a generator or template engine for application code.
- **A hosted service or shipped user interface.** No dashboard, telemetry
  server, or account, and nothing of that kind inside `plugins/agrippa/`.
  The one exception is a local tool for the owner's own visibility while
  developing the plugin, for example a page that shows what the hooks
  injected or what the spawn log recorded. Such a tool lives under `dev/`,
  is never installed, and is never required by a check.

## How a long run works

- **Start by reading** this document, `CLAUDE.md`, the latest entries in
  `docs/worklog.md`, and the most recent section of `docs/design-notes.md`.
- **Take the top backlog item** below that can be finished and proven in
  the time available. Do not start a second item while the first is
  unproven.
- **Prove before reporting.** Every change ends with the self-check, and a
  change to the linter or a hook also runs against the sandbox and, read
  only, against an installed repository as `CLAUDE.md` requires.
- **Record as you go.** A session that spans more than one piece of work,
  or a piece of work that spans more than one session, gets a plan
  workspace at `plans/YYYY-MM-DD-<name>/` copied by hand from
  `plugins/agrippa/skills/plan/templates/`, and linted with
  `perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath <path> -RepoRoot .`
  from this checkout. The plugin is never installed in this repository,
  because it would load the files being edited and write project documents
  next to the templates they came from.
- **End every session** with a dated entry in `docs/worklog.md` that says
  what was done, what was proven and how, what comes next, and every
  decision the agent made on a default because only the owner could settle
  it, with the default chosen, so the owner can overturn it cheaply. A
  change to the reason behind any rule also gets its dated entry in
  `docs/design-notes.md` before the session ends.

## Backlog

Ordered. The owner edits this list; an agent takes the first item it can
finish and prove, and may add an item it discovered at the bottom with a
one-line reason. An item is removed when its worklog entry says it was
proven, not when its code is written.

1. **Prove the kit on macOS and Linux.** Add a GitHub Actions workflow that
   runs `node dev/validate-kit.mjs` on Ubuntu, macOS, and Windows at each
   push. Everything so far ran only on Windows under Git Bash; the design
   notes name this as the recommended follow-up to the 0.4.0 port.
2. **Prove the install and upgrade interviews end to end.** Run
   `/agrippa:install` in a fresh sandbox session and `/agrippa:upgrade` on a
   sandbox copy of an older install, and record what each interview asked,
   skipped, and got wrong. The self-check requires their clauses but nothing
   has yet run them.
3. **Retire the lint traps.** Work through the trap list in
   `docs/design-notes.md` ("These cost three lint rounds"). For each, change
   the template wording or the linter message so a first-time planner does
   not hit it, and keep the check itself unchanged.
4. **Start recording packet gaps.** Add the `packet gap` entry kind to
   `EVIDENCE.md` that `docs/research-2026-08.md` leaves open, so the
   question of how often full-shape packets are incomplete gets data.
5. **Baseline the installed-repo audit.** Record the current finding and
   check counts of `node dev/validate-kit.mjs -InstalledRepo` for
   nuro-battler in the worklog, so the "no more findings" measure has a
   starting point.
6. **Time the two-writer wave.** Run one real two-writer wave sequentially
   and in parallel in the sandbox and record the difference, which the
   research note says has never been measured.
7. **Development visibility.** A small local page or report under `dev/`
   that shows, for a sandbox session, what the hooks injected and what the
   spawn log recorded. Low priority; it exists to help the owner watch the
   plugin work, not to ship.

## Decisions reserved for the owner

These are open, and an agent does not settle them on a default.

- Whether installed projects should pin release tags, as the README
  recommends, or follow `main`.
- When a change to an installed repository's layout or contract is worth a
  breaking release.
- Whether the knowledge layer grows past the area map, once the `area map`
  evidence entries exist to decide it.
