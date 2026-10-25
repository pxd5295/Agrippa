---
name: plan
description: Planning entry point for the Agrippa methodology. Use for "Make a plan", "Plan ...", or "Create an implementation plan" once the size gate in the core rules calls for a workspace, and for "Implement plan <path>". Holds the lifecycle guide, the routing guide, the workspace-file rules, and the five plan-workspace templates, and says how to lint a workspace.
argument-hint: "[change to plan, or implement <plan path>]"
---

# Plan

The Agrippa core rules decide whether a request gets a plan workspace at all.
This skill holds what the work needs once it does. Read only the guide the
step needs; never load them all eagerly.

| File | Read it for |
|---|---|
| `${CLAUDE_SKILL_DIR}/reference/agent-workflow.md` | Plan creation: lifecycle, interview, design states, design-reference planning, risk, workspace shapes, evidence, and the launch read order |
| `${CLAUDE_SKILL_DIR}/reference/ROUTING.md` | Assigning and dispatching stages: tier table, fork or fresh, roster, packets, ownership, waves, launch, validator, and review |
| `${CLAUDE_SKILL_DIR}/reference/workspace-files.md` | What each workspace file owns, session handoff files, selective reads and soft budgets, and linting outside Claude Code |
| `${CLAUDE_SKILL_DIR}/reference/low-usage.md` | Only when the core rules say low-usage mode is on: the seven rules the mode replaces with cheaper ones, and how a plan records what the mode changed |
| `${CLAUDE_SKILL_DIR}/templates/` | `SPEC.md`, `PLAN.md`, `PACKETS.md`, `STATUS.md`, and `EVIDENCE.md`, the blank workspace files |

The project's own facts are not in this skill. They are in
`.agrippa/project-contracts.md` (ownership areas, architecture
owners, shared interfaces, risk classes) and
`.agrippa/validation-commands.md` (every exact command), and in
`.agrippa/live-app.md` when the project has a live-app bridge.

## Make a plan

1. Read `agent-workflow.md` and follow its lifecycle, and read
   `workspace-files.md` for what each workspace file owns. When the core
   rules say low-usage mode is on, read `low-usage.md` too; it replaces seven
   rules of the other guides with cheaper ones.
2. Create `plans/YYYY-MM-DD-short-name/` in the repository. If that folder
   exists, append `-2`, `-3`, and so on; never overwrite a workspace.
3. Copy the five templates into it unchanged, then fill them in the copy.
   Never edit the templates themselves.
4. Read `ROUTING.md` before assigning tiers and writing packets.
5. Lint the workspace through the Bash tool, and fix every error before
   handoff:

   ```bash
   agrippa-lint -PlanPath plans/YYYY-MM-DD-name
   ```

   `agrippa-lint` is on the Bash tool's PATH only, so it never runs from the
   PowerShell tool. It checks shape, never truth. A plan's validation matrix
   names it the same way, and the row runs through the Bash tool too.

A planning-only response ends with the first implementation allocation and the
exact resume prompt.

## Implement a plan

Use the plan the user names, or else only the plan established in the current
task. Read the launch section of `agent-workflow.md`, then follow `ROUTING.md`
for dispatch, waves, the validator, allocation continuity, escalation, and
review.

## The templates are the linter's contract

The linter parses the section shapes and the `A#`, `V#`, and `C#` id
conventions of these templates. A change to a template changes every future
plan, never an existing one, and must be mirrored in the plugin's
`scripts/validate_plan_workspace.pl`. Dated plan workspaces keep the shape
they were written in.

A repository keeps no copy of these guides or templates, for example under
`docs/planning/`. The plugin's linter parses the plugin's templates, so a copy
drifts from the linter that checks plans.
