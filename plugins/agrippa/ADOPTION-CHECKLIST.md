# Adoption Checklist

The receiving Claude session completes or explicitly reports every applicable
item before declaring installation complete. "Reported" means the item is
named as not done, with the reason.

## Repository discovery

- [ ] `node --version` succeeds, or the user chose to install without Node
      and every item below that needs the hooks or the linter is reported as
      not done with the reason "Node.js is not installed".
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

- [ ] The `agrippa` plugin is enabled, and a new session shows its core rules
      (request boundaries, Engineering standards, definition of done,
      planning size gate, launch, roster, skills, planner read ladder, and
      validation reach) without reading any file.
- [ ] Root `AGENTS.md` holds only the project contracts and project rules.
- [ ] The "Architecture owners" table in `project-contracts.md` names this
      repository's real base classes, funnels, configuration layer, and
      performance-owned subsystem, which the Engineering standards and the
      design-reviewer size floor refer to.
- [ ] Root `CLAUDE.md` imports `AGENTS.md` (`@AGENTS.md`) and lists any
      project skills.
- [ ] Each ownership area with real rules has a per-directory `CLAUDE.md`;
      `.agrippa/CLAUDE.md` exists.
- [ ] No project-wide pin of the lead's model or reasoning effort exists.

## Project facts

- [ ] `project-contracts.md` is populated from repository evidence, and each
      fact was checked against the code.
- [ ] `validation-commands.md` has exact executables, working directories,
      sandbox stance, determinism, verdict and error-line rules, retry rules,
      prerequisites, known red at `HEAD`, targeted checks, and the full-suite
      inventory.
- [ ] `.agrippa/decisions/README.md` and `plans/README.md` exist as the short
      pointers from `templates/`, with no copy of the rules the `plan` and
      `design-first` skills hold, and `docs/planning/` has no `CLAUDE.md`
      from an older kit.
- [ ] `.agrippa/area-map.md` was written by `/agrippa:survey` with a
      `Built at` commit and every row checked against the tree, or the user
      declined the survey and the file does not exist.
- [ ] The `engineering:*` skills are available, or the hand-written fallback
      is noted.
- [ ] The README's install-marker scan finds nothing outside the kit folder.

## Agents, skills, commands, hooks

- [ ] `.claude/settings.json` is committed, declares the `agrippa`
      marketplace in `extraKnownMarketplaces`, and enables `agrippa@agrippa`
      in `enabledPlugins`.
- [ ] The four agents (`agrippa:repo-scout`, `agrippa:plan-reviewer`,
      `agrippa:design-reviewer`, `agrippa:validator`) come from the plugin,
      and `.claude/agents/` has no copy of them. If the project has an MCP
      server that observes the running application,
      `.agrippa/live-app.md` exists and lists every one of its
      authoring tools; otherwise that file does not exist.
- [ ] The four skills (`agrippa:design-first`, `agrippa:systematic-debugging`,
      `agrippa:verify-before-done`, `agrippa:receiving-review`) come from the
      plugin, and `.claude/skills/` has no copy of them.
      Every section of `.agrippa/project-contracts.md` and
      `.agrippa/validation-commands.md` that they read names this
      repository's real owners, traps, and commands, or was deleted because
      it provably does not apply.
- [ ] The plugin's `/agrippa:handoff` skill is available, and its transcript
      path rule fits this machine.
- [ ] Optional hooks are switched on or installed and merged into existing
      settings, or reported as declined. The plugin's spawn logger is on only
      with `AGRIPPA_SPAWN_LOG=1` in `.claude/settings.json` and
      `subagent-spawns.log` in `.gitignore`. An edit-lint hook follows the
      rules in `templates/hooks/README.md`.

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
- [ ] For design-reference planning, the "Contract documents" table in
      `project-contracts.md` names the style-token document and "UI capture"
      in `validation-commands.md` names the in-app capture path, or each says
      there is none.
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

- [ ] Agrippa's `node dev/validate-kit.mjs -InstalledRepo <this repository>`
      prints PASS.
- [ ] Agrippa's `node dev/fixtures/run-smoke-test.mjs -RepoRoot <this
      repository>` prints PASS with the plugin's linter (valid fixture passes,
      broken fixture fails with the expected errors).
- [ ] The shared linter runs from the plugin, and the repository has no copy
      of it at `tools/validate_plan_workspace.ps1`, nor of the spawn logger's
      scripts. This repository's command invariants and
      any narrower `commandPathExtensions` list live in
      `tools/validate_plan_workspace.local.mjs`, proved by linting one real
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
- [ ] `.agrippa/MIGRATION.md` records the generation, mapping,
      adaptations, preservation audit, and residual smoke tests.
