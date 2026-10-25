# Planning Workflow Migration

This file records how this repository upgraded to the Agrippa planning
methodology: the generation found, the rule mapping, what the upgrade
interview decided and how each decision was resolved, the preservation audit,
and the upgrade-time check results. It is a record: never edit its decisions
afterwards. A first install writes `INSTALL.md` instead.

## Scope and date

- Date: [PROJECT: YYYY-MM-DD]
- Plugin version: [PROJECT: the `agrippa` plugin version and the marketplace
  `ref` pinned in `.claude/settings.json`]
- Generation detected: [PROJECT: None / Other / G1 / G2 / G3 / G4 with drift;
  list the markers found, see the plugin's `UPGRADING.md`]
- Existing plans covered: Future workspaces only; historical plans unchanged

## Existing workflow inventory

- Root/nested agent instructions: [PROJECT: paths, e.g. `AGENTS.md`,
  `CLAUDE.md`, per-directory `CLAUDE.md` files]
- Named Claude agents, skills, commands, and hooks: [PROJECT: paths]
- Any other toolchain's agent configuration or worker profiles: [PROJECT: paths]
- Lifecycle/routing docs, templates, shortcuts, and validators: [PROJECT: paths]
- Historical plan roots: [PROJECT: paths]
- Project contracts, decision records, and validation catalogs: [PROJECT: paths]
- Dirty user-owned files: [PROJECT: paths or None]

## Rule mapping

| Existing source/rule | Disposition | New authoritative location | Rationale |
|---|---|---|---|
| `[PROJECT: path: rule]` | Retain / Merge / Replace / Deprecate | `[PROJECT: path/section]` | [PROJECT: Reason; stricter rule preserved] |

## Interview decisions

One row per decision the upgrade needed: each material conflict between an
old rule and a new one, each proposed deletion, the pins and old toolchain
configuration removed, every install-time slot the templates asked for, and
each optional feature, including the entries inspection settled without a
question. `Resolved by` is `inspection` (the code, the configuration, or an
old document answered it; say what was read), `user` (a person answered it;
the documents mark such facts `per maintainer`), or `default` (the user chose
to proceed on the recommendations, or declined to answer, and the recommended
option was taken; a deletion is never resolved this way).

| Topic | Decision | Resolved by | Rationale |
|---|---|---|---|
| [PROJECT: the decision, for example "Delete the copied-in planner agent" or "Debugging map"] | [PROJECT: what was decided] | [PROJECT: inspection / user / default] | [PROJECT: the old document or code read, or the tradeoff the user accepted] |

## Methodology migration

- Engineering standards, definition of done, and design-reviewer size floor:
  [PROJECT: result]
- Design states and frozen `C#` contracts: [PROJECT: result]
- Changed/deleted-symbol consumer census and covering tests: [PROJECT: result]
- `A#`/`V#`/`C#` traceability and PACKETS: [PROJECT: result]
- Objective tier-routing table, split-first rule, and fork-or-fresh rule:
  [PROJECT: result]
- Whole-file ownership, two/three-writer gates, and cost multiplier:
  [PROJECT: result]
- Planning size gate and single-stage shape: [PROJECT: result]
- Minimal launch reads, planner read ladder, and Stage Model Allocation
  continuity: [PROJECT: result]
- Targeted/full validation, focused review, and review disposition:
  [PROJECT: result]
- Decision records and per-directory `CLAUDE.md` files: [PROJECT: result]

## Configuration, agent, skill, and hook changes

- [PROJECT: Removed project-wide model/effort pins and old toolchain config,
  retained unrelated configuration, enabled the plugin in
  `.claude/settings.json`, deleted local copies of what the plugin provides
  after confirmation, moved their project facts into the project documents,
  and kept the project's own hooks and skills.]

## Project-specific adaptations

- Ownership/shared interfaces/high-risk classes: [PROJECT: summary]
- Validation catalog and full-suite inventory: [PROJECT: summary]
- Local linter checks (`tools/validate_plan_workspace.local.pl`), or why none:
  [PROJECT: summary]
- Install-time placeholders and install notes: [PROJECT: all resolved, or each
  remaining one and why]
- `AskUserQuestion` and `engineering:*` skill availability and fallback:
  [PROJECT: summary]

## Historical preservation audit

- Audit command/check: [PROJECT: the hash manifest taken before any edit and
  compared after, or `git status --short plans/` when dated workspaces are
  tracked; a gitignored `plans/` makes `git status` prove nothing]
- Result: [PROJECT: No historical dated plan changed, or exact exception]

## Deprecated, awaiting confirmation

- [PROJECT: Old files the mapping deprecates that have not been deleted yet,
  or None]

## Validation and residual risks

| Check | Result | Notes |
|---|---|---|
| Installed-repository check (`node dev/validate-kit.mjs -InstalledRepo .` from an Agrippa checkout) | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Smoke test (`node dev/fixtures/run-smoke-test.mjs -RepoRoot .` from an Agrippa checkout) | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Install-marker scan (kit README) | [PROJECT: 0 hits / list] | [PROJECT: details] |
| Local linter checks against one real workspace | [PROJECT: Pass/Fail/None installed] | [PROJECT: details] |
| Validation catalog commands run once | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Scoped formatting | [PROJECT: Pass/Fail] | [PROJECT: details] |
| Live planning smoke test | [PROJECT: Pending/Pass] | [PROJECT: details] |
| Live implementation smoke test | [PROJECT: Pending/Pass] | [PROJECT: details] |
