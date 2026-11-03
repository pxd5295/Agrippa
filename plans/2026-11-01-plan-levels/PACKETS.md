# Dispatch Packets

> The lead implements every stage directly, so these packets record
> ownership, acceptance, and validation rather than a dispatch. `PLAN.md`
> references the contract IDs and never restates their bodies.

## Frozen contracts

### C1: The linter's medium-plan branch

Contract source: `plugins/agrippa/scripts/validate_plan_workspace.pl:558` (read 2026-11-01)

- Exact contract:
  - Shape selection happens after the plan root is resolved and checked
    (`validate_plan_workspace.pl:543-550`). When the folder holds `BRIEF.md`
    and none of `SPEC.md`, `PLAN.md`, `PACKETS.md`, and `STATUS.md`, it is
    linted as a medium plan. Otherwise it is linted as a workspace exactly as
    today. When `BRIEF.md` sits beside any workspace file, the workspace lint
    runs unchanged and adds one error at the end:
    `[Files] BRIEF.md shares a folder with workspace files; a plan folder holds either BRIEF.md or the five workspace files.`
    A folder without `BRIEF.md` takes no new check, so the check count,
    every message, their order, and the summary line stay byte-identical on
    every existing workspace.
  - Checks 13 to 18 and the local-check calls move, unchanged and in the
    same order, into one sub that both shapes call. The local checks file is
    loaded at the same point in the workspace lint as today.
  - The medium lint checks, in this order: a line `Level: medium` (message
    `[Brief] BRIEF.md must have the line "Level: medium".`); the headings
    `## Acceptance`, `## Design statement`, `## Census`, `## Validation`,
    `## Implementation estimate`, `## State`, and `## Resume prompt`
    (`[Brief] BRIEF.md is missing the section '## X'.`); acceptance IDs
    parsed with the workspace's `- [ ] **A#:**` pattern, at least one
    (`[Brief] BRIEF.md defines no acceptance ID.`); checks 1 and 2 over
    `BRIEF.md` with the workspace's messages; check 3's undefined-reference
    message for any `C#`, since a medium plan has no contracts; the
    validation table, through the shared checks 13 to 18 and the local
    checks; each non-manual row's commands against the catalog; and the
    covering tests.
  - Catalog match: each backticked span in a row's `Exact command or check`
    cell, or the whole cell when it has none, must equal a backticked span
    in the "Exact command" column of the "Command catalog" or "Full-suite
    inventory" table of `.agrippa/validation-commands.md` after whitespace is
    collapsed, where an `<...>` placeholder in the catalog matches one word
    without spaces and a span of placeholders only is ignored. (Refined
    2026-11-01 after the design review; see `EVIDENCE.md`.) A row
    whose Determinism is `manual`, and a command that starts with
    `agrippa-lint`, are exempt. Message:
    `[Brief] V# command is not in .agrippa/validation-commands.md: <command>`.
    With no catalog and a non-exempt row, one error:
    `[Brief] .agrippa/validation-commands.md is missing; a medium plan's commands come from it.`
  - The covering-tests line of `BRIEF.md`, read up to the next blank line:
    each backticked path in it must exist under the repository root
    (`[Check 26] BRIEF.md covering test does not exist: <path>.`), and a
    missing line is an error (`[Brief] BRIEF.md has no Covering tests line under Census; list the tests that reference the owned files, or None.`).
  - The summary line keeps the workspace format:
    `PASS: N workspace-shape checks. This result does not validate contract truth.`
    or `FAIL: N shape error(s), N checks. Shape validation never proves contract truth.`
- Enumerated edit sites: `plugins/agrippa/scripts/validate_plan_workspace.pl:552`, `plugins/agrippa/scripts/validate_plan_workspace.pl:812`, `plugins/agrippa/scripts/validate_plan_workspace.pl:831`.
- Consumer census:
  - `plugins/agrippa/bin/agrippa-lint:28`: `exec perl`
  - `dev/fixtures/run-smoke-test.mjs:151`: `spawnSync(perl, [linter, '-PlanPath', planRelative`
  - `dev/validate-kit.mjs:1238`: `const smoke = run(node`
- Pre-authorized ownership expansion: None.
- Covering tests: `dev/fixtures/run-smoke-test.mjs`, `dev/validate-kit.mjs`.

### C2: The "Planning trigger" section of the core rules

Contract source: `plugins/agrippa/scripts/core-rules.md:106` (read 2026-11-01)

- Exact contract: the section keeps its first paragraph (planning requests
  start at once; recommend a stronger model once) and the closing paragraphs
  on historical plans and `Open` stages. The two middle paragraphs become
  the routing rule: every change request gets one of three levels, no plan,
  a medium plan (`BRIEF.md`), or the full workspace; the risk signals
  (ownership areas, a shared-interface change, an uncertain approach, work
  spanning sessions) set the lowest allowed level, and the model picks the
  cheapest level at or above it, with a size estimate able to raise the
  level but never lower it; the model states the level and its reason in one
  line and continues, asking with `AskUserQuestion`, recommendation first,
  only on a close call; the user's words decide whether there is a plan, and
  a level the user names is used. The no-plan conditions stay those of the
  current skip-workspace gate. The detail of each level lives in
  `agent-workflow.md`. The section is no longer than its current 1,436
  characters, and the injected rules stay under 10,000 characters with
  low-usage mode on.
- Enumerated edit sites: `plugins/agrippa/scripts/core-rules.md:113`, `plugins/agrippa/scripts/core-rules.md:118`.
- Consumer census:
  - `dev/validate-kit.mjs:458`: `'## Planning trigger',`
  - `dev/validate-kit.mjs:459`: `Skip the workspace`
  - `plugins/agrippa/skills/plan/reference/agent-workflow.md:12`: `The core rules own the trigger`
  - `plugins/agrippa/skills/plan/reference/agent-workflow.md:171`: `Two shapes are allowed`
  - `plugins/agrippa/skills/design-first/SKILL.md:24`: `follow the planning trigger`
  - `plugins/agrippa/ADOPTION-CHECKLIST.md:114`: `The size gate skips the workspace`
- Pre-authorized ownership expansion: None.
- Covering tests: `dev/validate-kit.mjs`.

### C3: The medium plan and its `BRIEF.md`

Contract source: `plans/2026-11-01-plan-levels/SPEC.md:50` (read 2026-11-01)

- Exact contract:
  - The template `skills/plan/templates/BRIEF.md` holds, in order: a title,
    the line `Level: medium` with the reason, `## Acceptance` (`- [ ] **A#:**`
    items), `## Design statement` (the three sentences from `design-first`),
    `## Census` (owned files, consumer-census entries, and one
    covering-tests line), `## Validation` (the workspace's validation
    matrix columns), `## Implementation estimate`, `## State`, and
    `## Resume prompt`. It lives at `plans/YYYY-MM-DD-name/BRIEF.md`, with an
    optional `design/` folder.
  - `agent-workflow.md` gets a "Planning levels" section: the medium level
    is one ownership area, with tests that cover the change not counted as a
    second area, no shared-interface change, and deterministic validation;
    when implementation finds a second area or a shared interface, the model
    stops and asks whether to move up, narrow the scope, or continue. The
    full workspace keeps its single-stage and full shapes.
  - The `plan` skill gets "Make a medium plan": copy the template, fill it,
    lint it, estimate the implementation cost from the sizes of the census
    files and covering tests plus room for rereads, edits, test output, and
    reasoning, write the estimate into `BRIEF.md`, recommend this session when
    the current context plus the estimate stays under 300k tokens and a fresh
    session with the resume prompt otherwise, and ask the user to confirm.
    The State section is updated whenever the work stops partway.
  - `design-first` gets a section that applies only to medium work: the
    design statement goes into `BRIEF.md`, whose template is the one list of
    a medium plan's contents. Steps 1 to 5 stay unchanged.
  - The `STATUS.md` template gets a `- Level:` line, so a workspace records
    its level too.
- Enumerated edit sites: `plugins/agrippa/skills/plan/SKILL.md:19`, `plugins/agrippa/README.md:88`, `plugins/agrippa/skills/design-first/SKILL.md:123`.
- Consumer census:
  - `plugins/agrippa/skills/plan/SKILL.md:19`: `the blank workspace files`
  - `plugins/agrippa/README.md:88`: `the blank plan-workspace files`
  - `dev/validate-kit.mjs:278`: `...planningNames.map((name) =>`
  - `plugins/agrippa/skills/design-first/SKILL.md:125`: `It does not replace a plan workspace`
- Pre-authorized ownership expansion: None.
- Covering tests: `dev/validate-kit.mjs`, `dev/fixtures/run-smoke-test.mjs`.

### C4: Low-usage mode without "One-writer planning"

Contract source: `plugins/agrippa/skills/plan/reference/low-usage.md:24` (read 2026-11-01)

- Exact contract: the row is deleted, leaving six rule rows. Every text that
  counts or lists the rules says six and no longer names the wider
  skip-workspace gate. The hook's appended line names no count and is left
  unchanged. The 2026-10-25 design note keeps its title as a dated record and
  gains a one-line pointer to the new note.
- Enumerated edit sites: `plugins/agrippa/skills/plan/reference/low-usage.md:7`, `plugins/agrippa/skills/plan/reference/low-usage.md:24`.
- Consumer census:
  - `plugins/agrippa/skills/plan/reference/low-usage.md:7`: `seven rules with cheaper ones`
  - `dev/validate-kit.mjs:921`: `One-writer planning`
  - `dev/validate-kit.mjs:928`: `must have exactly seven rule rows`
  - `plugins/agrippa/README.md:86`: `the seven rules low-usage mode replaces`
  - `plugins/agrippa/README.md:338`: `replaces seven`
  - `plugins/agrippa/README.md:341`: `a wider skip-workspace gate`
  - `plugins/agrippa/templates/hooks/README.md:55`: `The mode replaces seven rules`
  - `plugins/agrippa/templates/hooks/README.md:60`: `other five apply to plans`
  - `plugins/agrippa/templates/hooks/README.md:64`: `single-stage shape whenever one sequential writer`
  - `plugins/agrippa/skills/plan/SKILL.md:18`: `the seven rules the mode replaces`
  - `plugins/agrippa/skills/plan/SKILL.md:31`: `it replaces seven`
  - `docs/design-notes.md:679`: `one switch, seven rules`
- Pre-authorized ownership expansion: None.
- Covering tests: `dev/validate-kit.mjs`.

### C5: The upgrade note for the behavior change

Contract source: `plugins/agrippa/UPGRADING.md:280` (read 2026-11-01)

- Exact contract: a new section `### From G4 v0.4.2`, between "From G4
  v0.4.1" and "Always", says that no installed file changes, that sessions
  now state a level for each change request and sometimes ask, that a medium
  plan is a `BRIEF.md` folder that `agrippa-lint` accepts, that new
  `STATUS.md` files carry a level line while dated plans keep their shape,
  and that low-usage mode lost its "One-writer planning" row. The self-check
  requires the heading.
- Enumerated edit sites: `plugins/agrippa/UPGRADING.md:303`.
- Consumer census:
  - `dev/validate-kit.mjs:730`: `### From G4 v0`
- Pre-authorized ownership expansion: None.
- Covering tests: `dev/validate-kit.mjs`.

## Stage packets

### Packet M1

```text
Plan: plans/2026-11-01-plan-levels
Stage: M1 - The medium plan's shape, linted
Goal: the BRIEF.md template exists and agrippa-lint lints a BRIEF.md folder, with full workspaces unchanged
Dependencies: None
Owner / assigned tier: lead
Design state: Frozen
Contract IDs: C1, C3

Owned files: `plugins/agrippa/scripts/validate_plan_workspace.pl`, `plugins/agrippa/skills/plan/templates/BRIEF.md`, `dev/fixtures/smoke-brief/BRIEF.md`, `dev/fixtures/run-smoke-test.mjs`, `dev/validate-kit.mjs`

Line-anchored edit sites:
- plugins/agrippa/scripts/validate_plan_workspace.pl:552-937
- dev/fixtures/run-smoke-test.mjs:171-205
- dev/validate-kit.mjs:244-287
- dev/validate-kit.mjs:1231-1244

Allowed interfaces:
- agrippa-lint arguments and output format, unchanged

Forbidden scope:
- The full-workspace checks and their messages; the local-checks interface; the core rules and guides

Pre-authorized ownership expansion:
- None

Acceptance:
- A3: A `BRIEF.md` template with the sections in the decisions table exists in `skills/plan/templates/`, and the `plan` skill and the kit README's layout table list it.
- A6: `agrippa-lint` accepts a plan folder holding `BRIEF.md` and an optional `design/`, and checks its IDs, validation commands, and covering-test paths. On real full workspaces its output is byte-identical to the current linter's.
Acceptance notes: the plan skill and README listings of A3 land in M2.

Validation:
- V1: node dev/validate-kit.mjs; lint; outside-sandbox; deterministic
- V2: parity of the HEAD and changed linters on every nuro-battler plan folder; manual; outside-sandbox; deterministic
- V3: perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-10-01-inspector-redesign -RepoRoot ../evolution-game/nuro-battler; lint; sandboxed; deterministic
Covering tests: dev/fixtures/run-smoke-test.mjs, dev/validate-kit.mjs
Validation output: Bounded

Relevant references:
- C1
- C3

Dirty/user-owned warnings:
- nuro-battler is read-only

Stop/escalate when:
- any nuro-battler plan's output differs between the two linters

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```

### Packet M2

```text
Plan: plans/2026-11-01-plan-levels
Stage: M2 - The routing rule and the medium level in the guides
Goal: the core rules route every change request to a level, and the guides describe the medium level
Dependencies: M1
Owner / assigned tier: lead
Design state: Frozen
Contract IDs: C2, C3

Owned files: `plugins/agrippa/scripts/core-rules.md`, `plugins/agrippa/skills/plan/reference/agent-workflow.md`, `plugins/agrippa/skills/plan/reference/workspace-files.md`, `plugins/agrippa/skills/plan/SKILL.md`, `plugins/agrippa/skills/plan/templates/STATUS.md`, `plugins/agrippa/skills/design-first/SKILL.md`, `plugins/agrippa/README.md`, `plugins/agrippa/ADOPTION-CHECKLIST.md`, `dev/validate-kit.mjs`

Line-anchored edit sites:
- plugins/agrippa/scripts/core-rules.md:106-132
- plugins/agrippa/skills/plan/reference/agent-workflow.md:169-187
- plugins/agrippa/skills/plan/SKILL.md:1-50
- plugins/agrippa/skills/design-first/SKILL.md:123-127
- dev/validate-kit.mjs:447-472

Allowed interfaces:
- None

Forbidden scope:
- The linter; the low-usage guide and the upgrade guide; the full workspace shape

Pre-authorized ownership expansion:
- None

Acceptance:
- A1: The "Planning trigger" section of `scripts/core-rules.md` names the three levels, the risk floor with the cheapest safe level, the one-line statement of the level, and asking only on a close call. The injected rules stay under 10,000 characters with low-usage mode on.
- A2: `agent-workflow.md` describes the medium level: one ownership area with covering tests not counted, no shared-interface change, deterministic validation, and stopping to ask when more scope turns up.
- A3: A `BRIEF.md` template with the sections in the decisions table exists in `skills/plan/templates/`, and the `plan` skill and the kit README's layout table list it.
- A4: `design-first` has a section that applies only to medium work and points to the `BRIEF.md` template. Its steps for smaller changes are unchanged.
- A5: The plan skill tells the model to estimate implementation cost, write it into `BRIEF.md`, recommend this session or a fresh one against the 300k ceiling, and ask the user to confirm.

Validation:
- V1: node dev/validate-kit.mjs; lint; outside-sandbox; deterministic
Covering tests: dev/validate-kit.mjs
Validation output: Bounded

Relevant references:
- C2
- C3

Dirty/user-owned warnings:
- None

Stop/escalate when:
- the core rules cannot fit under the cap with low-usage mode on

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```

### Packet M3

```text
Plan: plans/2026-11-01-plan-levels
Stage: M3 - Six low-usage rules and the upgrade note
Goal: low-usage mode replaces six rules, and UPGRADING.md and the design notes record the change
Dependencies: M2
Owner / assigned tier: lead
Design state: Frozen
Contract IDs: C4, C5

Owned files: `plugins/agrippa/skills/plan/reference/low-usage.md`, `plugins/agrippa/templates/hooks/README.md`, `plugins/agrippa/skills/plan/SKILL.md`, `plugins/agrippa/README.md`, `plugins/agrippa/UPGRADING.md`, `docs/design-notes.md`, `dev/validate-kit.mjs`

Line-anchored edit sites:
- plugins/agrippa/skills/plan/reference/low-usage.md:7
- plugins/agrippa/skills/plan/reference/low-usage.md:24
- plugins/agrippa/templates/hooks/README.md:55-66
- plugins/agrippa/UPGRADING.md:280
- dev/validate-kit.mjs:905-928

Allowed interfaces:
- None

Forbidden scope:
- The other six low-usage rules; the hook's low-usage line; the linter

Pre-authorized ownership expansion:
- None

Acceptance:
- A7: `low-usage.md` has six rule rows without "One-writer planning", and the hook's low-usage line, the README, the design notes, and the self-check say six.
- A8: `UPGRADING.md` describes the behavior change, and `docs/design-notes.md` has a dated entry with the reasons above.

Validation:
- V1: node dev/validate-kit.mjs; lint; outside-sandbox; deterministic
Covering tests: dev/validate-kit.mjs
Validation output: Bounded

Relevant references:
- C4
- C5

Dirty/user-owned warnings:
- None

Stop/escalate when:
- a "seven" remains that counts the low-usage rules outside dated records

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```

### Packet Integration

```text
Plan: plans/2026-11-01-plan-levels
Stage: Integration - Full acceptance and focused review
Goal: run the full applicable suite, review the diff, and record the results
Dependencies: M1, M2, M3
Owner / assigned tier: lead
Design state: Frozen
Contract IDs: C1, C2, C3, C4, C5

Owned files: `docs/worklog.md`

Allowed interfaces:
- None without a recorded contract update

Forbidden scope:
- Unrelated systems, user-owned changes, nuro-battler, history/plans, the version and tags

Pre-authorized ownership expansion:
- None

Acceptance:
- A1: The "Planning trigger" section of `scripts/core-rules.md` names the three levels, the risk floor with the cheapest safe level, the one-line statement of the level, and asking only on a close call. The injected rules stay under 10,000 characters with low-usage mode on.
- A2: `agent-workflow.md` describes the medium level: one ownership area with covering tests not counted, no shared-interface change, deterministic validation, and stopping to ask when more scope turns up.
- A3: A `BRIEF.md` template with the sections in the decisions table exists in `skills/plan/templates/`, and the `plan` skill and the kit README's layout table list it.
- A4: `design-first` has a section that applies only to medium work and points to the `BRIEF.md` template. Its steps for smaller changes are unchanged.
- A5: The plan skill tells the model to estimate implementation cost, write it into `BRIEF.md`, recommend this session or a fresh one against the 300k ceiling, and ask the user to confirm.
- A6: `agrippa-lint` accepts a plan folder holding `BRIEF.md` and an optional `design/`, and checks its IDs, validation commands, and covering-test paths. On real full workspaces its output is byte-identical to the current linter's.
- A7: `low-usage.md` has six rule rows without "One-writer planning", and the hook's low-usage line, the README, the design notes, and the self-check say six.
- A8: `UPGRADING.md` describes the behavior change, and `docs/design-notes.md` has a dated entry with the reasons above.
- A9: `node dev/validate-kit.mjs` passes; the installed-repository audit of nuro-battler reports no more findings than before; and a fresh session in `../agrippa-sandbox` shows the model stating a level for a small and a medium request.

Validation:
- V1: node dev/validate-kit.mjs; lint; outside-sandbox; deterministic
- V2: parity of the HEAD and changed linters on every nuro-battler plan folder; manual; outside-sandbox; deterministic
- V3: perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-10-01-inspector-redesign -RepoRoot ../evolution-game/nuro-battler; lint; sandboxed; deterministic
- V4: node dev/validate-kit.mjs -InstalledRepo ../evolution-game/nuro-battler; lint; outside-sandbox; deterministic
- V5: fresh sandbox session, one small and one medium change request, each reply states a level; manual; outside-sandbox; manual
- V6: perl plugins/agrippa/scripts/validate_plan_workspace.pl -PlanPath plans/2026-11-01-plan-levels -RepoRoot .; lint; sandboxed; deterministic
Validation output: Bounded

Relevant references:
- C1
- C2
- C3
- C4
- C5
- design-reviewer over the whole diff

Dirty/user-owned warnings:
- The sandbox holds the user's uncommitted install; a test session may add files but must not revert them

Stop/escalate when:
- the reviewer returns a Design finding, or a sandbox reply states no level

Return only: files changed; behavior implemented; validation results;
unresolved dependencies/risks.
```
