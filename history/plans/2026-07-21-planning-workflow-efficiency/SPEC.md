# Planning Workflow Efficiency Specification

## Objective

Reduce recurring Codex context and reasoning usage while preserving Sol High
for trusted planning decisions, dependency-safe execution, explicit validation,
and risk-appropriate review.

## Background

The current root instructions are about 25,000 characters, and recent plan
workspaces reach roughly 8,000-10,500 estimated tokens. Some worker profiles
then reread the full instruction and plan workspace. Project configuration also
pins the active lead to Sol High even outside planning. The workflow is safe,
but repeated instructions, histories, validation prose, context handoffs, and
an unnecessary repository-wide model default consume more usage than the work
requires.

## Planning interview decisions

| Topic | Decision | Rationale |
|---|---|---|
| Planner entry | Every substantial plan begins with Sol High | Favor a High-planned Medium change over a Medium-planned High-risk change |
| Small-plan downgrade | Sol High may hand off to Sol Medium only after targeted inspection and the planning interview | High retains architecture and design judgment; Medium only writes a proven-low-risk plan |
| High-start mechanism | Every ordinary-language planning request pauses for Sol-High confirmation before inspection | Matches the user's actual workflow without relying on a special planning mode |
| Non-planning model choice | Remove project-level active model and reasoning defaults | The user may choose any available model and effort for work that is not plan creation |
| Instruction layout | Thin root `AGENTS.md` plus an on-demand `docs/agent-workflow.md` | Avoid loading the complete methodology for unrelated tasks and every worker |
| Plan artifacts | Add `EVIDENCE.md`; keep `STATUS.md` hot and small | Preserve durable command evidence without rereading it at every stage |
| Worker context | Inline compact stage packets | Avoid new per-stage files and prevent full-workspace rereads |
| Parallelism | Conservative automatic parallelism with at most two writers | Gain wall-clock speed only after contracts and ownership are safe |
| Validation | Targeted stage checks, immediate shared-contract gates, and one full integration suite | Remove broad repeated test matrices without weakening acceptance gates |
| Review | One risk-triggered focused reviewer | Preserve independent challenge for high-risk or multi-writer work without generic duplicate reviews |
| Document limits | Soft, measurable budgets with documented exceptions | Control drift without deleting necessary detail from unusually complex plans |
| Luna usage | Planner may choose Luna only with very high confidence; favor mechanical work with exact checks | Capture savings without assigning behavioral ambiguity to the weakest worker |
| Worker shortcut | Resolve `Implement plan use workers` before the launch handshake | Prevent an unnecessary active-model switch before sequential workers start |
| Migration | Apply the new format only to future plans | Preserve historical and active plan provenance |

## In scope

- Split durable trigger/safety rules from detailed planning methodology.
- Remove project-level active model/reasoning pins so non-planning work follows
  the user's current selection.
- Detect planning requests in default mode and require Sol-High confirmation
  before inspection or interview.
- Add the conservative post-interview downgrade gate for demonstrably small
  plans.
- Compact plan templates with acceptance IDs, validation IDs, a hot status,
  and cold evidence.
- Replace full-plan worker/reviewer reads with lead-authored inline stage
  packets.
- Make sequential workers first-class and cap automatic concurrent writers at
  two.
- Centralize validation definitions and use targeted-then-full scheduling.
- Add a lightweight static workflow checker and routing-outcome evidence.
- Update workflow documentation and shortcuts consistently.

## Out of scope

- Rewriting any existing plan workspace other than this plan's execution state.
- Changing Godot, native C++, Python, dashboard, gameplay, or test behavior.
- Changing global Codex configuration, account settings, or weekly limits.
- Adding recursive agent delegation or raising the four-thread ceiling.
- Automatically measuring account billing or weekly usage that Codex does not
  expose to the repository.

## Interfaces and constraints

- Planning is triggered by ordinary requests such as `Make a plan` or
  `Plan: ...`; the workflow must not depend on a special planning mode.
- If runtime metadata does not verify Sol High, every planning request must ask
  the user to select and confirm Sol High before repository inspection.
- Non-planning requests must not trigger model-selection instructions or have
  their active model/reasoning constrained by project defaults.
- Sol High owns inspection, the planning interview, risk classification, and
  material design decisions. Downgrade requires all low-risk gates to pass and
  an exact Sol-Medium resume handshake.
- Root instructions must still protect dirty worktrees, plan-only boundaries,
  ownership, shared interfaces, validation, and completion claims.
- `max_threads = 4`, `max_depth = 1`, and
  `default_mode_request_user_input = true` remain enabled.
- Soft budgets warn rather than fail when an exception is justified in the
  plan. Proposed targets are: root instructions about 10,000 characters,
  detailed workflow about 14,000 characters, stage packets at most about 800
  tokens, and routine plan workspaces about 3,500-5,000 hot tokens excluding
  `EVIDENCE.md`.
- Historical plan directories remain untouched.

## Acceptance criteria

- [x] **A1:** Project configuration does not pin the active lead model or
  reasoning effort; non-planning work preserves the user's selection.
- [x] **A2:** Any planning request that is not runtime-verified as Sol High
  first gives an exact Sol-High switch and resume prompt in the current task.
- [x] **A3:** Sol High may downgrade only after inspection and interview, using
  explicit low-risk gates and an exact Sol-Medium handoff; otherwise it
  continues automatically on High.
- [x] **A4:** Root `AGENTS.md` contains only triggers, hard safety/quality rules,
  shortcuts, and on-demand workflow routing; detailed explanations occur once
  in the workflow guide.
- [x] **A5:** New templates use stable acceptance and validation IDs, keep
  `STATUS.md` focused on current state/deltas, and store detailed evidence in
  `EVIDENCE.md`.
- [x] **A6:** Worker and reviewer profiles consume an inline assigned-stage
  packet and relevant code/architecture only, not the full plan workspace.
- [x] **A7:** Automatic parallel execution uses at most two writers and requires
  stable contracts, disjoint ownership, independent validation, and compact
  packets; otherwise workers are sequential.
- [x] **A8:** `Implement plan use workers` is resolved before launch allocation
  checks and never requests the superseded active-model switch.
- [x] **A9:** Luna is limited to planner-approved, mechanically bounded work
  with exact validation; behavioral code defaults to Terra Medium or stronger.
- [x] **A10:** Milestones run targeted checks and immediate contract gates; the
  full applicable suite runs once after integration unless evidence justifies
  expansion.
- [x] **A11:** One focused reviewer is used only for multi-writer, native ABI,
  persistence, security, or unresolved integration risk.
- [x] **A12:** A static checker validates TOML and workflow invariants, reports
  soft-budget warnings, and all historical plan workspaces remain unchanged.

## Validation requirements

- **V1:** Parse every project `.toml` file with Python `tomllib`.
- **V2:** Run the new planning-workflow checker and receive no invariant
  failures.
- **V3:** Verify root/guide and template sizes are reported against soft
  budgets without turning justified exceptions into failures.
- **V4:** Verify no worker/reviewer profile instructs a full
  `SPEC.md`/`PLAN.md`/`STATUS.md` reread.
- **V5:** Exercise documented prompt scenarios for ordinary-language planning,
  non-planning model freedom, High-to-Medium downgrade, normal launch, and
  `use workers` override.
- **V6:** Run scoped `git diff --check` on workflow files.
- **V7:** Confirm no historical plan file changed.

## Open questions

- None.
