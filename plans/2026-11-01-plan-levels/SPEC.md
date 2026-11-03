# Change Specification

## Objective

Every change request in a repository that uses the plugin gets a planning
level sized to the work: no plan, a medium plan, or the full plan workspace.
The model picks the level, states it in one line, and asks the user only when
the choice is close. Medium-sized features, a few files in one ownership area,
get a single `BRIEF.md` instead of the five-file workspace, without giving up
the quality floors.

## Background

The kit has two workspace shapes and a way to skip the workspace. The
skip-workspace gate in the core rules allows only a diff that fits in one
sentence. The single-stage shape in `agent-workflow.md` still needs all five
linted files, a packet that is never dispatched, and a separate `Integration`
stage. A medium feature, roughly 100 to 400 lines across a few files, is too
large for the first and pays nearly the full cost of the second. The owner
finds the methodology effective for large features but too costly for small
and medium ones, while plain prompting does not hold enough quality.

Low-usage mode already widens the skip-workspace gate in its "One-writer
planning" row, but only for projects that turn the mode on to save tokens. It
is a budget switch, not a size level. The 2026-10-25 design note "Low-usage
mode: one switch, seven rules" rejected low, medium, and high profiles because
the alternative rules drift. The levels here are on a different axis, the size
and risk of the work, and the "One-writer planning" row is deleted so that the
two do not overlap.

The decisions below come from a conversation and an interview with the owner
on 2026-10-29 and 2026-11-01. Two critiques written in that conversation
changed the design: the overlap with the handoff skill, and the finding that
`design-first` already covers most of what a medium plan needs.

## Planning interview decisions

| Topic | Decision | Resolved by | Rationale |
|---|---|---|---|
| What notices a change request | The model, through a rewritten "Planning trigger" section in `scripts/core-rules.md`. No new hook. | user | A `UserPromptSubmit` hook is a POSIX `sh` script that can only match keywords, cannot judge size, and adds text to every prompt, including questions. The model already loads the core rules at every session start. |
| Ask or tell | The model states the level and the reason in one line and continues. It asks, with the three levels as options and the recommendation first, only on a close call, such as a second ownership area turning up in the census. | user | Asking on every change request slows small fixes, and a question asked every time gets clicked through. Asking on close calls gives the user a say where their knowledge (stakes, budget, whether the work spans sessions) matters. |
| The user's words versus the model's level | Words such as "plan it" or "just do it" decide whether there is a plan. The model picks the level unless the user names one. | default | Proposed in the conversation and not contested. Explicit planning requests already start planning under the core rules. |
| What decides the level | Risk signals set the lowest allowed level, and the model picks the cheapest level at or above it. A size estimate can raise the level but never lower it. | user | The owner asked for a balance of quality and token efficiency. The floor holds quality; picking the cheapest safe level holds cost. Line count alone is rejected because it is known only after the work and does not track risk. |
| Which risk signals | The number of ownership areas, whether a shared interface changes, how uncertain the approach is, and whether the work will span sessions. | default | These are the signals the existing gate already uses. |
| How far a medium plan reaches | One ownership area. Tests that cover the change do not count as a second area. | user | In nuro-battler, `tests/` is its own area in `.agrippa/project-contracts.md`, so counting tests would push almost every medium feature into a workspace (found by inspection). One area also matches `design-first` step 1, which says a change needing two areas is not a direct edit. In nuro-battler, any GDScript-only feature qualifies, and anything touching `native/` goes to a workspace. |
| Finding more scope during implementation | If a medium plan's implementation finds a second ownership area or a shared interface, the model stops and asks the user whether to move up, narrow the scope, or continue. | user | The owner wants the call each time rather than an automatic move to a workspace. |
| Where a medium plan lives | A folder, `plans/YYYY-MM-DD-name/BRIEF.md`, with an optional `design/` subfolder. | user | Plans sometimes carry pictures: three of nuro-battler's 74 plans hold PNG concepts or HTML mockups (inspection). A folder also keeps `agrippa-lint -PlanPath` working unchanged, since the linter accepts only a directory. |
| The medium plan's file name | `BRIEF.md`. | user | It differs from every workspace file, so the linter cannot mistake a full workspace with a missing `SPEC.md` for a medium plan. |
| The one definition of a medium plan's contents | The `BRIEF.md` template. The medium section of `design-first` points to it and does not repeat the list. | user | One owner for the list, so the skill and the template cannot drift apart. |
| What `BRIEF.md` contains | A level line, an acceptance list, the design statement, the census with covering tests, the exact validation commands from `validation-commands.md`, the implementation cost estimate, a short State section, and the resume prompt. | default | Taken from the worked example in the conversation. It is unproven until backlog item 2 measures which parts later sessions read. |
| The handoff skill | Left out of this change. `BRIEF.md` carries its own State section, which the model updates when it stops partway, so medium work never needs a handoff file. Reworking or removing `/agrippa:handoff` is a separate backlog item. | user | The owner wants the handoff skill reworked or removed anyway. Removing it changes a skill name, which needs an `UPGRADING.md` entry and the owner's yes. |
| Where implementation happens | After writing `BRIEF.md`, the model estimates the implementation cost from the sizes of the census files and covering tests, plus room for rereads, edits, test output, and reasoning, and writes the estimate into `BRIEF.md`. If the current context plus the estimate stays under 300k tokens, it recommends implementing in the same session; otherwise it recommends a fresh session with the resume prompt. The user confirms either way. | user | The owner wants no session to reach 400k to 500k tokens, because model quality drops above 300k to 400k. Most implementation cost is reading code, which happens in either session, so a fresh session costs little extra. Both the estimate and the model's sense of its own context size are approximate, and the confirmation covers the error. |
| Recording the level | Only in plan files: a level line in `BRIEF.md` and `STATUS.md`. No commit trailer and no log. | user | The owner accepted that nothing will show whether a "no plan" call was right. The rejected options cost under 100 tokens per change (commit trailer) or about 150 to 200 (log file); the choice was about coverage, not cost. |
| Low-usage mode's "One-writer planning" row | Deleted. "Seven rules" becomes "six" in the low-usage line the hook appends, in `low-usage.md`, in the README, in the design notes, and in the self-check's row count. | user | The normal-mode medium level now covers most of what the row did. |
| Order of work | Build the levels first, then measure them on the next medium features (backlog item 2 in `docs/goals.md`). | user | The owner accepted that the template's contents and the estimate formula stay unproven until then. `docs/goals.md` says a saving that cannot be measured is not a saving, so any cost claim says it is unmeasured. |
| Upgrade note | `UPGRADING.md` gets an entry for the behavior change. | default | No installed file format changes, but sessions start announcing a level and sometimes asking about it, which an existing user will notice. |
| What the linter checks for a medium plan | `agrippa-lint` accepts a plan folder that holds `BRIEF.md` and optionally `design/`. It checks that acceptance and validation IDs are present, that the validation commands match `validation-commands.md`, and that the covering-test paths exist. Checks on full workspaces and the output format are unchanged. | default | The `agrippa-lint` command and its output format are listed contracts in `docs/goals.md`. |
| Room in the core rules | The rewritten "Planning trigger" section is no longer than the current one, and the detail lives in the `plan` skill. | inspection | `scripts/core-rules.md` is 9,817 characters; with the low-usage line about 30 characters remain under the 10,000-character cap. |

## Scope and constraints

**In scope**

- The three-level routing rule in the core rules.
- The medium level: the `BRIEF.md` template, its description in
  `agent-workflow.md` and the `plan` skill, and the medium section of
  `design-first`.
- The implementation-location rule with the 300k ceiling.
- Linter support for a plan folder that holds only `BRIEF.md`.
- Deleting low-usage mode's "One-writer planning" row.
- The README layout table, `UPGRADING.md`, the self-check, the smoke fixture,
  and a dated entry in `docs/design-notes.md`.

**Out of scope**

- Reworking or removing the handoff skill (backlog item 10 in
  `docs/goals.md`).
- Moving loose design files into `design/` (backlog item 11).
- Measuring the levels (backlog item 2).
- A commit trailer, a decision log, or any new file under `.agrippa/`.
- Any change to the full workspace shape or its existing linter checks.

**Interfaces and constraints**

- The injected core rules stay under the 10,000-character hook context cap,
  with and without low-usage mode.
- `agrippa-lint`, its arguments, and its output format do not change for
  existing workspaces; the parity method in `docs/design-notes.md` (old and
  new linter on the same real plans, output compared byte for byte) proves it.
- No skill or agent is renamed or removed, and the `.agrippa/` layout does
  not change.
- Scripts stay POSIX `sh` and Perl 5.30 with core modules only, written as
  ASCII.
- A new template file is added to the kit README's layout table.

## Design reference

None: no design reference.

## Design rationale

**Chosen design**

- The routing lives in the "Planning trigger" section of the core rules,
  which every session already loads. The medium level reuses the plan
  folder, the `plan` skill's templates, the `design-first` skill, and the
  existing linter, adding one template and one recognized folder shape.

**Generalization**

- A further level would be one more template and one more shape in
  `agent-workflow.md`, and the linter tells shapes apart by which files the
  folder holds. The routing rule picks the cheapest level at or above the
  risk floor, so a new level slots in without changing the rule.

**Alternatives rejected**

| Alternative | Why not |
|---|---|
| A `UserPromptSubmit` hook that detects change requests | It can only match keywords and costs tokens on every prompt. |
| Always asking which level | It slows small fixes and the question gets clicked through. |
| Choosing the level by line count | The count is known only after the work, and it does not track risk. |
| A medium plan covering two areas | Two-area work usually changes a shared interface, and `design-first` already treats it as more than a direct edit. |
| A flat `plans/name.md` file | It would change the linter's `-PlanPath` contract and leaves no place for pictures. |
| Naming the file `PLAN.md` | A full workspace with a missing `SPEC.md` would be linted as a medium plan. |
| Building the medium plan from the handoff file | The handoff skill runs only when the user asks, is written at the end of a session rather than before editing, and has a 300-word limit. |
| A commit trailer or a log of levels | The owner chose plan files only. |
| Keeping the low-usage row | It would overlap the normal-mode medium level. |
| Low, medium, and high profiles | Rejected on 2026-10-25 for drift; these levels follow the size of the work, not the token budget. |

**Decision record**

- None: the kit has no `.agrippa/` contracts of its own. The reasons go into
  `docs/design-notes.md` when the rules ship.

## Acceptance criteria

- [ ] **A1:** The "Planning trigger" section of `scripts/core-rules.md` names
  the three levels, the risk floor with the cheapest safe level, the
  one-line statement of the level, and asking only on a close call. The
  injected rules stay under 10,000 characters with low-usage mode on.
- [ ] **A2:** `agent-workflow.md` describes the medium level: one ownership
  area with covering tests not counted, no shared-interface change,
  deterministic validation, and stopping to ask when more scope turns up.
- [ ] **A3:** A `BRIEF.md` template with the sections in the decisions table
  exists in `skills/plan/templates/`, and the `plan` skill and the kit
  README's layout table list it.
- [ ] **A4:** `design-first` has a section that applies only to medium work
  and points to the `BRIEF.md` template. Its steps for smaller changes are
  unchanged.
- [ ] **A5:** The plan skill tells the model to estimate implementation cost,
  write it into `BRIEF.md`, recommend this session or a fresh one against the
  300k ceiling, and ask the user to confirm.
- [ ] **A6:** `agrippa-lint` accepts a plan folder holding `BRIEF.md` and an
  optional `design/`, and checks its IDs, validation commands, and
  covering-test paths. On real full workspaces its output is byte-identical
  to the current linter's.
- [ ] **A7:** `low-usage.md` has six rule rows without "One-writer planning",
  and the hook's low-usage line, the README, the design notes, and the
  self-check say six.
- [ ] **A8:** `UPGRADING.md` describes the behavior change, and
  `docs/design-notes.md` has a dated entry with the reasons above.
- [ ] **A9:** `node dev/validate-kit.mjs` passes; the installed-repository
  audit of nuro-battler reports no more findings than before; and a fresh
  session in `../agrippa-sandbox` shows the model stating a level for a small
  and a medium request.

## Handoff gate

- Open questions: None. No `Planning interview decisions` row is unresolved.
- Every implementation stage is `Frozen` or `Bounded-choice`; `Open` design
  does not hand off.
- Acceptance text copied into `PACKETS.md` is verbatim apart from whitespace
  normalization.
