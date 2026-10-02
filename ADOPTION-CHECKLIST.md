# Adoption Checklist

The receiving Claude session completes or explicitly reports every applicable
item before declaring installation complete. "Reported" means the item is
named as not done, with the reason.

## Repository discovery

- [ ] Read every existing `AGENTS.md` and `CLAUDE.md`, at any depth.
- [ ] Inventory `.claude/agents`, skills, commands, `settings.json` hooks and
      permissions, planning guides, templates, shortcuts, validators, project
      contracts, decision records, and historical plan roots.
- [ ] Identify languages, build systems, test runners, lint/typecheck
      commands, deployment boundaries, and expensive or environment-dependent
      checks. Run each command once and record what it needs.
- [ ] Identify ownership areas, architecture owners (base classes and hooks,
      config layer, funnels, hot-path subsystems), shared interfaces and their
      consumers, and native/persistence/security/concurrency/performance
      risks.
- [ ] Record the tests that are red at `HEAD` before any change.
- [ ] Inspect the dirty worktree and preserve unrelated user changes.
- [ ] Ask only material questions that repository inspection cannot answer.
- [ ] Upgrades: identify the generation from the `UPGRADING.md` markers and
      list the markers found.

## Always-loaded rules

- [ ] Root `AGENTS.md` keeps its role (triggers, safety, Engineering
      standards, definition of done, planning size gate, launch, project
      contracts) and routes lifecycle and routing detail to the two guides.
- [ ] Questions about possible features are answer-and-offer, never edits.
- [ ] Engineering standards name this repository's real base classes,
      funnels, and contract owners; the design-reviewer size floor names the
      subsystems that always get the pass.
- [ ] Root `CLAUDE.md` imports `AGENTS.md` (`@AGENTS.md`) and lists the
      roster, skills, planner read ladder, and validation reach.
- [ ] Each ownership area with real rules has a per-directory `CLAUDE.md`;
      `docs/agent_memory/CLAUDE.md` and `docs/planning/CLAUDE.md` exist.
- [ ] No project-wide pin of the lead's model or reasoning effort exists.

## Project facts

- [ ] `project-contracts.md` is populated from repository evidence, and each
      fact was checked against the code.
- [ ] `validation-commands.md` has exact executables, working directories,
      sandbox stance, determinism, verdict and error-line rules, retry rules,
      prerequisites, known red at `HEAD`, targeted checks, and the full-suite
      inventory.
- [ ] `docs/decisions/README.md` exists, and the `engineering:*` skills are
      available or the hand-written fallback is noted.
- [ ] The README's install-marker scan finds nothing outside the kit folder.

## Agents, skills, commands, hooks

- [ ] Four agents are installed: `repo-scout`, `plan-reviewer`,
      `design-reviewer`, `validator`, all on `sonnet` by default. Each
      `tools:` line lists any MCP tool by full name; optional live-app blocks
      are filled or deleted whole.
- [ ] Four skills are installed (`design-first`, `systematic-debugging`,
      `verify-before-done`, `receiving-review`) with every placement rule,
      trap, and command naming this repository's real owners.
- [ ] `/handoff` is installed and its transcript path rule fits this machine.
- [ ] Optional hooks are installed and merged into existing settings, or
      reported as declined. An edit-lint hook follows the rules in
      `templates/hooks/README.md`.

## Planning behavior

- [ ] Natural planning requests (`Make a plan`, `Plan:`, ...) trigger
      immediately on the user's current model, without a special mode.
- [ ] Non-planning requests never trigger a model-switch request.
- [ ] The size gate skips the workspace for a one-sentence diff, and the
      single-stage shape exists for bounded one-writer work.
- [ ] The interview uses `AskUserQuestion` (or a recorded fallback) and records
      decisions and rationale in `SPEC.md`.
- [ ] Every changed or deleted symbol gets a plan-time consumer census, and
      every contract lists `Covering tests:`.
- [ ] Every stage is `Frozen` or `Bounded-choice`; `Open` cannot hand off.
- [ ] `SPEC.md` records the design rationale and links a decision record for
      a shared-interface change.
- [ ] Design-reference planning names this repository's style-token source
      and in-app capture path, or says there is none.
- [ ] New workspaces contain SPEC/PLAN/PACKETS/STATUS/EVIDENCE with `A#`/`V#`/
      `C#` traceability and verbatim packet acceptance text.

## Routing, execution, and quality

- [ ] The first-match tier table starts with long-context need and maps to
      `haiku`/`sonnet`/`opus`; Opus routing records a split-first attempt.
- [ ] Fork-or-fresh rules are present; a forked stage records its forfeited
      tier.
- [ ] Implementation workers receive verbatim inline packets and do not
      reread full workspaces.
- [ ] Whole-file ownership is exclusive within a shared-checkout wave;
      concurrent same-file writers need worktrees and a merge owner.
- [ ] Two writers are the default; three require every listed gate plus a
      stated, accepted token-cost multiplier.
- [ ] Allocation rows finish atomically, and an unchanged allocation continues
      automatically after the boundary report.
- [ ] Milestones run targeted checks; integration runs the full applicable
      suite once.
- [ ] Review topology: `plan-reviewer` for risk; `design-reviewer` for the
      diffs the Engineering standards name, minus those under the size floor;
      Blocking/Optional and Design/Note classes; and the recommended
      `receiving-review` disposition procedure.
- [ ] STATUS stays hot, EVIDENCE stays cold and append-only, and every A/V gate
      passes or the exact gap is reported.

## Offline validation

- [ ] The kit's `validate-kit.ps1` prints PASS.
- [ ] `fixtures/run-smoke-test.ps1 -RepoRoot .` prints PASS against the
      installed linter (valid fixture passes, broken fixture fails with the
      expected errors).
- [ ] The shared linter is unedited. This repository's command invariants and
      any narrower `$CommandPathExtensions` live in
      `tools/validate_plan_workspace.local.ps1`, proved by linting one real
      workspace, or the file is deliberately not installed.
- [ ] Optional edit-lint hook: written to the rules in
      `templates/hooks/README.md` and proved with one deliberate lint error,
      or reported as not wired.
- [ ] Scoped whitespace/format checks pass on the installed files.
- [ ] The report states that shape validation does not prove contract truth.

## Upgrade-only checks

- [ ] A Retain/Merge/Replace/Deprecate mapping was shown to the user before
      editing, and material conflicts were asked about.
- [ ] Old toolchain configuration, shortcuts, model pins, and agent profiles
      are removed after confirmation or listed as awaiting confirmation.
- [ ] A search for the old toolchain's markers finds nothing outside
      `MIGRATION.md`, dated plan workspaces, and the kit folder.
- [ ] Stricter project safety and validation contracts are preserved.
- [ ] No historical dated workspace was edited, moved, or converted: a
      SHA-256 manifest taken before the first edit equals one taken after
      (`git status` proves nothing when `plans/` is gitignored).
- [ ] `docs/planning/MIGRATION.md` records the generation, mapping,
      adaptations, preservation audit, and residual smoke tests.
