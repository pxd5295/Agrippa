---
name: plan
description: Planning entry point for the Agrippa methodology. Use for "Make a plan", "Plan ...", or "Create an implementation plan", and whenever the planning level in the core rules is a medium plan or a full workspace, and for "Implement plan <path>". Holds the lifecycle guide with the planning levels, the routing guide, the workspace-file rules, the five plan-workspace templates and the medium plan's BRIEF.md template, and says how to lint a plan.
argument-hint: "[change to plan, or implement <plan path>]"
---

# Plan

The Agrippa core rules give every change request a planning level: no plan,
a medium plan, or a full workspace. This skill holds what the work needs when
the level is a plan. Read only the guide the step needs; never load them all
eagerly.

| File | Read it for |
|---|---|
| `${CLAUDE_SKILL_DIR}/reference/agent-workflow.md` | Plan creation: the planning levels, lifecycle, interview, design states, design-reference planning, risk, workspace shapes, evidence, and the launch read order |
| `${CLAUDE_SKILL_DIR}/reference/ROUTING.md` | Assigning and dispatching stages: tier table, fork or fresh, roster, packets, ownership, waves, launch, validator, and review |
| `${CLAUDE_SKILL_DIR}/reference/workspace-files.md` | What each workspace file owns, session handoff files, selective reads and soft budgets, and linting outside Claude Code |
| `${CLAUDE_SKILL_DIR}/reference/low-usage.md` | Only when the core rules say low-usage mode is on: the six rules the mode replaces with cheaper ones, and how a plan records what the mode changed |
| `${CLAUDE_SKILL_DIR}/templates/` | `SPEC.md`, `PLAN.md`, `PACKETS.md`, `STATUS.md`, and `EVIDENCE.md`, the blank workspace files, and `BRIEF.md`, the medium plan |

The project's own facts are not in this skill. They are in
`.agrippa/project-contracts.md` (ownership areas, architecture
owners, shared interfaces, risk classes) and
`.agrippa/validation-commands.md` (every exact command), and in
`.agrippa/live-app.md` when the project has a live-app bridge.

## Make a plan

1. Read `agent-workflow.md` and follow its lifecycle, and read
   `workspace-files.md` for what each workspace file owns. When the core
   rules say low-usage mode is on, read `low-usage.md` too; it replaces six
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

## Make a medium plan

A medium plan is one `BRIEF.md`. "Planning levels" in `agent-workflow.md`
says when the level applies and when to stop and ask.

1. Create `plans/YYYY-MM-DD-short-name/`, appending `-2`, `-3`, and so on if
   it exists, and copy `${CLAUDE_SKILL_DIR}/templates/BRIEF.md` into it.
   Pictures or mockups go in a `design/` folder beside it. The template is the
   one list of what a medium plan contains; fill every section in the copy.
2. Inspect narrowly, run the consumer census and find the covering tests as
   step 1 of the lifecycle in `agent-workflow.md` says, and write the design
   statement from `agrippa:design-first` into `BRIEF.md`. Copy each
   validation command from `.agrippa/validation-commands.md`.
3. Lint it through the Bash tool with `agrippa-lint -PlanPath plans/YYYY-MM-DD-name`
   and fix every error.
4. Estimate the implementation cost: the sizes of the census files and the
   covering tests, read at about four characters per token, plus room for
   rereads, edits, test output, and reasoning. Write the estimate into the
   Implementation estimate section. The estimate is unmeasured until real
   medium plans are compared with it, so say so if you cite it.
5. Recommend where to implement. If the current context plus the estimate
   stays under 300k tokens, recommend this session; otherwise recommend a
   fresh session started with the resume prompt in `BRIEF.md`. Ask the user to
   confirm with `AskUserQuestion`, and record the answer in `BRIEF.md`.
6. Update the State section whenever the work stops partway, so a later
   session resumes from `BRIEF.md` alone and needs no handoff file.

## Implement a plan

Use the plan the user names, or else only the plan established in the current
task. For a medium plan, read `BRIEF.md`, follow its State section, and
implement it directly. For a workspace, read the launch section of
`agent-workflow.md`, then follow `ROUTING.md` for dispatch, waves, the
validator, allocation continuity, escalation, and review.

## The templates are the linter's contract

The linter parses the section shapes and the `A#`, `V#`, and `C#` id
conventions of these templates, and the headings and level line of
`BRIEF.md`. A change to a template changes every future
plan, never an existing one, and must be mirrored in the plugin's
`scripts/validate_plan_workspace.pl`. Dated plan workspaces keep the shape
they were written in.

A repository keeps no copy of these guides or templates, for example under
`docs/planning/`. The plugin's linter parses the plugin's templates, so a copy
drifts from the linter that checks plans.
