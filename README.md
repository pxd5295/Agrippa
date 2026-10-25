# Agrippa

Agrippa is a Claude Code plugin that gives a repository a planning and
implementation methodology. Enable it, run `/agrippa:install` once, and every
Claude Code session in that repository follows the same engineering rules,
plans larger changes in a structured workspace, implements them with routed
subagents, and shows evidence before calling anything done.

## What it does

Left alone, an agent working on a non-trivial change tends to explore too
widely, skip the design step, add a special case where an owner already
exists, and report "done" without running the tests. Agrippa addresses each of
those with rules that load in every session and a plan workspace for changes
that need one.

- A **small change** gets a design statement before the first edit, the
  change, the named validation command, and a definition-of-done report.
- A **large change** gets a plan workspace first: what is being built, the
  stages and who owns each, the exact packet each subagent receives, status
  and risk, and the evidence collected along the way. Implementation then runs
  stage by stage, with review and validation between waves.

## Features

- **Core rules in every session.** A short rule set is added at session start
  and to every subagent: what a request does and does not authorize,
  engineering standards (state the design first, one owner per shared value,
  refactor or file it, shared interfaces start with a decision record), a
  definition of done, and when a change is big enough to plan.
- **Plan workspaces.** `Make a plan for <change>` creates
  `plans/YYYY-MM-DD-<name>/` with five files: `SPEC.md`, `PLAN.md`,
  `PACKETS.md`, `STATUS.md`, and `EVIDENCE.md`. No stage ships as open. Each
  is either frozen (exact interfaces, edit sites, and consumer census) or a
  bounded choice with one default. `Implement plan <path>` then runs it.
- **Routed subagents.** The lead session plans and implements. Subagents get a
  per-stage model tier and a verbatim packet, and run in waves grouped by
  ownership area so two writers never touch the same files.
- **Four read-only agents.** `repo-scout` gathers consumer census and contract
  facts for planning. `plan-reviewer` checks a diff against the plan's frozen
  contracts. `design-reviewer` looks for duplication, special cases, misplaced
  logic, and file growth. `validator` runs the plan's validation matrix
  verbatim.
- **Five working skills.** `design-first` (required before any edit),
  `systematic-debugging`, `verify-before-done`, `receiving-review`, and
  `/agrippa:handoff`, which writes a short brief when a session ends mid-plan.
- **A plan linter.** `agrippa-lint -PlanPath plans/<name>` checks a workspace's
  traceability, dispatch shape, ownership, and command syntax. It checks
  shape, never truth. A project can add its own command invariants in a small
  local file that the linter loads.
- **Install and upgrade skills.** `/agrippa:install` sets up a repository that
  has no planning rules. `/agrippa:upgrade` migrates one that already has
  some, from an earlier copy of Agrippa or from a different process, and
  never edits a dated plan.
- **Optional hooks.** An opt-in log of every subagent spawn, so you can see
  which spawns inherited the lead's model instead of the routed tier, and a
  documented pattern for an edit-lint hook that feeds lint findings back to
  the agent.

## How it works

The methodology has three layers, and only one of them is written into your
repository.

1. **Rules the plugin injects.** The core rules, the planning and routing
   guides, the agents, the skills, the plan templates, and the linter all live
   in the plugin. A `SessionStart` hook adds the core rules to every session
   and a `SubagentStart` hook adds them to every subagent. Nothing here is
   copied into the project, so a plugin upgrade updates all of it at once.
2. **Your project's facts.** `/agrippa:install` reads the repository and
   writes a root `AGENTS.md` (ownership areas, shared interfaces, project
   rules), `docs/agent_memory/project-contracts.md` (architecture owners, risk
   classes, compatibility gates), and
   `docs/agent_memory/validation-commands.md` (every exact test and build
   command). The agents and skills read project facts only from these
   documents, which is what keeps the plugin itself project-neutral.
3. **Plans your sessions produce.** Each plan workspace is a dated folder
   under `plans/`. Workspaces are records: they are never overwritten, and an
   upgrade never touches them.

Your repository pins a release tag. Upgrading is moving that tag, plus
`/agrippa:upgrade` when the project documents need to change too.

## Install

Add the marketplace and enable the plugin in the repository's committed
`.claude/settings.json`. Merge these two keys into the existing file:

```json
{
  "extraKnownMarketplaces": {
    "agrippa": {
      "source": { "source": "github", "repo": "pxd5295/Agrippa", "ref": "v0.1.2" }
    }
  },
  "enabledPlugins": { "agrippa@agrippa": true }
}
```

Or install it once for yourself instead:

```text
/plugin marketplace add pxd5295/Agrippa
/plugin install agrippa@agrippa
```

Then start Claude Code at the repository root, on a strong model, and run:

```text
/agrippa:install
```

The skill inspects the repository read-only, asks only about choices the code
cannot answer, writes the project documents, shows every settings change
before making it, and changes no application code. If the repository already
has planning rules of any kind, run `/agrippa:upgrade` instead. It maps every
old rule to its new home before editing and confirms each deletion.

## Day to day

```text
Make a plan for <change>
Implement plan plans/2026-10-24-<name>
/agrippa:handoff
```

Changes under the size gate skip the workspace and are implemented directly
after a design statement. A plan ends with the first implementation allocation
and an exact resume prompt.

## Requirements

- Node.js, on every OS. The hooks that add the core rules to every session
  and subagent run on it, and so does the plan linter, `agrippa-lint`.
  Without it the rules do not load and plans cannot be linted. Nothing else
  is needed: the plugin has no dependencies to install, and since 0.2.0
  neither the plugin nor this repository's own checks contain any PowerShell.
  Developing the plugin needs the same Node and nothing more.
- Optional: the `engineering` plugin, whose `architecture` and `system-design`
  skills write decision records. Without it, the `design-first` skill gives
  the shape to write one by hand.

## This repository

| Path | What it is |
|---|---|
| `plugins/agrippa/` | The plugin. Its [README](plugins/agrippa/README.md) is the full reference: every file, where it goes, and the placeholder convention. |
| `dev/` | The self-check, `validate-kit.mjs`, and the smoke-test fixture. Not shipped. |
| `docs/` | Design notes and the research behind the rules. Not shipped. |
| `history/plans/` | The plan workspaces that built earlier versions. Read-only history. |

To work on the plugin, see [CLAUDE.md](CLAUDE.md). Every change must leave
`node dev/validate-kit.mjs` printing `PASS`.

## License

Apache License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE). You may use,
modify, and redistribute Agrippa, including commercially, as long as the
license and attribution travel with it and modified files say they were
changed. The license does not grant use of the name Agrippa except to say
where the work came from.
