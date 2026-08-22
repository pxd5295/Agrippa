# Adoption Checklist

The receiving Claude session completes or explicitly reports every applicable
item before declaring installation complete.

## Repository discovery

- [ ] Read any existing `AGENTS.md` and root `CLAUDE.md`.
- [ ] Inventory planning guides, templates, shortcuts, any already-installed
      `.claude/agents/*.md` profiles, validators, project contracts, and
      historical plan roots.
- [ ] Identify languages, build systems, test runners, lint/typecheck commands,
      deployment boundaries, and expensive or environment-dependent checks.
- [ ] Identify ownership areas, public/shared interfaces, changed-symbol
      consumers, and native/persistence/security/concurrency/performance risks.
- [ ] Inspect the dirty worktree and preserve unrelated user changes.
- [ ] Ask only material questions that repository inspection cannot answer.

## Project adaptation

- [ ] Keep root `AGENTS.md` within its trigger/safety/shortcut/project-contract
      role; route detailed lifecycle and routing rules to their guides.
- [ ] Ensure a root `CLAUDE.md` imports `AGENTS.md` (for example `@AGENTS.md`)
      so Claude Code loads the workflow automatically.
- [ ] Populate `project-contracts.md` from repository evidence.
- [ ] Populate `validation-commands.md` with exact executables, working
      directories, styles, environment stance, determinism, retry rules,
      prerequisites, targeted checks, and full-suite inventory.
- [ ] Preserve compatible unrelated config and stricter safety rules.
- [ ] Do not pin a project-wide active-lead model or reasoning effort for
      ordinary non-planning work.
- [ ] Install only the `.claude/agents/*.md` roles this project needs
      (`repo-scout`, `plan-reviewer`, `validator` by default) and document any
      substitution while preserving the objective routing roles.
- [ ] Fill in the workspace linter's project-specific extension points
      (required launcher/wrapper commands, prelude ordering, test working
      directories) for the target repository's toolchain.

## Planning behavior

- [ ] Natural planning requests (`Make a plan`, `Plan:`, ...) trigger
      immediately, on the user's current model, without a special mode.
- [ ] Non-planning requests never trigger a model-switch request.
- [ ] Focused questions (`AskUserQuestion` or the local equivalent) record
      decisions and rationale in `SPEC.md`.
- [ ] Every changed/deleted symbol has a plan-time `rg` consumer census.
- [ ] Every stage is `Frozen` or `Bounded-choice`; `Open` cannot hand off.
- [ ] Frozen C# contracts record exact sourced interfaces/edit sites, consumer
      censuses, and bounded pre-authorized ownership expansion.
- [ ] New unique workspaces contain SPEC/PLAN/PACKETS/STATUS/EVIDENCE.
- [ ] A#/V#/C# traceability and verbatim packet acceptance text are preserved.
- [ ] Opus-tier routing records the required split-first attempt.

## Routing, execution, and quality

- [ ] The objective first-match tier table starts with long-context need and
      maps to `haiku`/`sonnet`/`opus`, optionally with a reasoning-effort
      suffix.
- [ ] Haiku work is mechanical, line-anchored, bounded, and exactly validated;
      behavioral ambiguity routes to Sonnet or stronger.
- [ ] Implementation workers receive verbatim inline packets and do not
      reread full workspaces.
- [ ] Whole-file ownership is exclusive within a shared-checkout wave.
- [ ] Two writers are the default; three require every documented Frozen,
      disjointness, validation, stability, and benefit gate.
- [ ] Worktrees and a merge owner are required for concurrent same-file
      writers.
- [ ] Allocation rows finish atomically and unchanged allocation continues
      automatically after the required boundary report.
- [ ] Milestones run targeted checks; integration runs the full applicable
      suite once.
- [ ] Multi-writer or high-risk integration receives one focused independent
      review (`plan-reviewer`); routine work receives a lead self-review.
- [ ] STATUS stays hot, EVIDENCE stays cold and append-only, and every A/V gate
      passes or the exact gap is reported.

## Offline validation

- [ ] A representative filled workspace passes
      `tools/validate_plan_workspace.ps1`.
- [ ] The representative failure fixture proves the workspace linter rejects
      at least an Open stage, missing packet text, or ownership collision.
- [ ] Scoped whitespace/format checks pass.
- [ ] The checker states that shape validation does not prove contract truth.

## Migration-only checks

- [ ] Record a retain/merge/replace/deprecate rule mapping.
- [ ] Resolve contradictory shortcuts, model pins, agent profiles, and launch
      rules left over from a prior toolchain.
- [ ] Preserve stricter project safety and validation contracts.
- [ ] Do not bulk-convert historical dated workspaces.
- [ ] Record the preservation audit and residual smoke tests in MIGRATION.md.
