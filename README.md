# Portable Planning Methodology Kit

This folder installs the repository's current planning and planned-
implementation methodology in another Claude Code project. It is
project-neutral: the receiving Claude session must inspect the target
repository and adapt ownership, shared interfaces, risk gates, validation
commands, and agent availability.

The kit is a methodology source, not an application-code template. Installing
it authorizes planning/configuration changes only.

This is a single-toolchain kit: Claude both authors plan workspaces and
implements them, in the same session or a later one. There is no second
toolchain, no model-switch handshake, and no allocation target the lead
"assigns" to anyone else — per-stage tiers (`haiku`/`sonnet`/`opus`, optionally
with a reasoning-effort suffix) apply only to subagents the lead spawns.

## Methodology reproduced by this kit

- Natural requests such as `Make a plan` trigger planning without a special
  mode, prefix, or model-switch handshake; planning starts on whatever model
  the user's session already has.
- Ordinary non-planning work preserves the user's selected model and
  reasoning effort; project config never pins the active lead.
- Planning uses narrow inspection, focused questions (`AskUserQuestion`), and
  an `rg` consumer census for every symbol that will change or be deleted.
- Every implementation stage is `Frozen` or `Bounded-choice`. `Open`
  design cannot hand off.
- Frozen contracts carry sourced signatures/layouts/constants, exact edit
  sites, consumer censuses, and bounded pre-authorized ownership expansion.
- Workspaces contain `SPEC.md`, `PLAN.md`, `PACKETS.md`, `STATUS.md`,
  and `EVIDENCE.md`, with stable A/V/C identifiers.
- Objective routing starts with long-context need, then mechanical/behavioral
  judgment and risk. An Opus allocation requires a recorded split-first
  attempt.
- Implementation workers are inline `general-purpose` subagent spawns with a
  verbatim packet and a routed `model`, rather than rereading a complete
  workspace. The named roster stays lean: `repo-scout`, `plan-reviewer`,
  `validator`.
- Two concurrent writers are the default ceiling. Three are allowed only for a
  fully Frozen, linter-proven, disjoint and independently validated wave.
- Milestones run the smallest relevant checks, integration runs the complete
  applicable suite once, and material integration risk gets one focused
  independent review.
- The workspace linter checks artifact shape and source freshness; it never
  proves that a frozen contract is semantically correct.

## Kit layout

| Source | Intended destination |
|---|---|
| `templates/AGENTS.md` | Repository-root `AGENTS.md`, adapted and merged |
| `templates/agent-workflow.md` | `docs/agent-workflow.md` |
| `templates/ROUTING.md` | `docs/planning/ROUTING.md` |
| `templates/PROJECT-CONTRACTS.md` | `docs/agent_memory/project-contracts.md`, adapted |
| `templates/VALIDATION-COMMANDS.md` | `docs/agent_memory/validation-commands.md`, adapted |
| `templates/planning/*.md` | `docs/planning/templates/*.md` |
| `templates/plans-README.md` | `plans/README.md` |
| `templates/agents/*.md` | `.claude/agents/*.md` |
| `templates/validate-plan-workspace.ps1` | `tools/validate_plan_workspace.ps1`, adapted |
| `templates/MIGRATION.md` | `docs/planning/MIGRATION.md` for migrations |
| `ADOPTION-CHECKLIST.md` | Required installation decisions and validation |

This kit installs no toolchain configuration file and no separate
"does-the-workflow-doc-say-the-right-thing" validator: Claude Code's only
project-level entry point is `AGENTS.md` (optionally imported by a root
`CLAUDE.md` via an `@AGENTS.md` line, the way this repository does), and the
one offline check worth shipping is the plan-workspace linter, because it is
the only one that can be exercised against a concrete filled-in workspace. If
the target repository has no root `CLAUDE.md`, create a minimal one containing
`@AGENTS.md` so Claude Code loads the installed methodology automatically.

## Installation flow

1. Copy this complete folder anywhere inside the target repository.
2. Start a Claude Code session at the target repository root.
3. Paste the appropriate setup prompt below.
4. Answer only material questions that repository inspection cannot resolve.
5. Let Claude merge and adapt the workflow, then run the workspace linter.

Do not manually overwrite an existing `AGENTS.md`. Project safety rules and
unrelated configuration must be merged conservatively. Historical dated plan
workspaces remain immutable provenance.

## Setup prompt: new project or no established workflow

```text
Locate the single folder named `planning-methodology-kit` in this repository.
If more than one exists, stop and ask which one to use.

Read its README and adoption checklist completely. Inspect any existing
AGENTS.md and CLAUDE.md, the dirty worktree, architecture docs, languages and
build systems, tests and exact commands, public/shared interfaces,
persistence/security/performance risks, and any already-installed
.claude/agents profiles. Ask focused questions only for material choices that
cannot be discovered.

Adapt and merge the kit; do not blindly copy it. Install the root AGENTS.md,
docs/agent-workflow.md, docs/planning/ROUTING.md,
docs/agent_memory/project-contracts.md,
docs/agent_memory/validation-commands.md,
docs/planning/templates/{SPEC,PLAN,PACKETS,STATUS,EVIDENCE}.md,
plans/README.md, and .claude/agents/{repo-scout,plan-reviewer,validator}.md.
Do not install any toolchain config file and do not install a separate
workflow-document validator; install only
tools/validate_plan_workspace.ps1. If the repository has no root CLAUDE.md,
create one containing `@AGENTS.md` so Claude Code loads the workflow.

Preserve the complete methodology contract: user-controlled non-planning
model/effort; focused interview; plan-time consumer censuses;
Frozen/Bounded-choice handoff; sourced C# contracts; stable A#/V#
traceability; objective first-match tier routing; split-first Opus
allocation; verbatim packets; whole-file ownership; two writers by default and
the exact three-writer exception; targeted-then-full validation; risk-triggered
focused review; and minimal launch reads.

Adapt the validation catalog and workspace linter to real repository commands,
file types, executable rules, ordering prerequisites, working directories,
environment stance, determinism, and retry behavior. Do not change application
behavior. Preserve unrelated user changes. Run the adapted workspace linter
against a representative filled workspace and scoped formatting checks, and
report installed files, project-specific adaptations, results, and any
remaining live smoke test. Do not declare success until every applicable
adoption-checklist item passes or is explicitly reported.
```

## Setup prompt: migrate an older planning workflow

```text
Locate the single folder named `planning-methodology-kit` in this repository.
If more than one exists, stop and ask which one to use.

Read its README and adoption checklist completely. Inventory every applicable
AGENTS.md/CLAUDE.md, any other toolchain's agent config or worker profiles,
planning guide/template/shortcut, validation catalog and tool, project
contract, dated plan root, and dirty user change. Before editing, produce a
concise retain/merge/replace/deprecate mapping and ask focused questions for
material conflicts.

Merge conservatively. Preserve stricter project safety and quality rules and
unrelated configuration. Remove any project-wide active-lead model/reasoning
pins left over from a prior toolchain. Install the current future-workspace
methodology: AGENTS.md, docs/agent-workflow.md, docs/planning/ROUTING.md,
project contracts and validation catalog, five planning templates including
PACKETS, plans/README.md, the three .claude/agents/*.md files
(repo-scout/plan-reviewer/validator), the workspace linter, and
docs/planning/MIGRATION.md.

Preserve natural planning-trigger language, user-controlled non-planning
model/effort, focused interview, changed/deleted-symbol consumer censuses,
Frozen/Bounded-choice handoff, sourced frozen contracts, objective tier
routing, split-first Opus allocation, verbatim packets, whole-file wave
ownership, the exact two/three-writer gates, targeted-then-full validation,
focused review, and minimal launch reads.

Adapt commands and linter rules from the real repository. Do not change
application behavior and do not overwrite, move, or bulk-convert dated plan
workspaces. Run the workspace linter, audit historical-plan preservation, and
report the mapping, changed files, adaptations, validation results, and
unresolved smoke tests.
```

## Portability notes

- Model identifiers and available named-agent roles vary by Claude Code
  release and account; verify locally and record every substitution.
- Keep project-specific ownership/risk facts in `project-contracts.md` and
  exact commands in `validation-commands.md`; do not duplicate them across
  the methodology.
- The portable workspace linter ships with its project-specific invariants
  (a required launcher binary, a mandatory prelude command, a fixed test
  working directory, and similar toolchain-exact rules) as documented
  extension points rather than hardcoded checks — fill them in for the
  target repository. Static validation checks shape, never truth.
- Apply the new schema to future plans only.

## Normal use after installation

```text
Make a plan for [change]
```

Implementation uses the lead plus routed subagents by default — the routing
table in `docs/planning/ROUTING.md` already selects a tier per stage, so there
is no separate opt-in phrase needed to get worker-backed execution. The
planning handoff names the exact first allocation, required action, and
resume prompt.
