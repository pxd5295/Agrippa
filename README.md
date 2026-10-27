# Agrippa

Agrippa is a Claude Code plugin that teaches the agent to plan before it
builds. Once it is installed in a repository, every Claude Code session there
follows the same engineering rules, plans larger changes in a structured
workspace, and shows evidence before calling anything done.

## Setup

### 1. Enable the plugin

Pick one of two ways.

**For everyone who works in the repository.** Merge these two keys into the
repository's committed `.claude/settings.json`. The `ref` pins the release.

```json
{
  "extraKnownMarketplaces": {
    "agrippa": {
      "source": { "source": "github", "repo": "pxd5295/Agrippa", "ref": "v0.4.2" }
    }
  },
  "enabledPlugins": { "agrippa@agrippa": true }
}
```

**For yourself only.** Run these two commands inside Claude Code:

```text
/plugin marketplace add pxd5295/Agrippa
/plugin install agrippa@agrippa
```

### 2. Set up the repository

Start Claude Code at the repository root, on a strong model, and run:

```text
/agrippa:install
```

The skill reads the repository without changing it, asks only about the
choices the code cannot answer, and then writes a short set of project
documents. It shows every settings change before making it and never touches
application code.

If the repository already has planning rules of any kind, run
`/agrippa:upgrade` instead. It maps every old rule to its new home before
editing and confirms each deletion.

### Requirements

- Claude Code. On Windows you also need Git for Windows, which Claude Code's
  Bash tool needs anyway; it provides the `sh` and `perl` the plugin runs on.
  macOS and Linux ship both.
- Optional: the `engineering` plugin, whose skills write decision records.
  `/agrippa:install` offers to enable it. Without it, Agrippa gives the shape
  to write a record by hand.

## Day to day

```text
Make a plan for <change>
Implement plan plans/2026-10-24-<name>
/agrippa:handoff
```

Small changes skip the plan and are implemented directly after a design
statement. Larger ones get a plan first, which ends with an exact prompt for
resuming the work. `/agrippa:handoff` writes a short brief when a session
ends mid-plan.

If your token budget is tight, set `AGRIPPA_LOW_USAGE=1` in the repository's
settings. The methodology then uses smaller reviews and cheaper models while
keeping every rule that protects correctness.

## What you get

- **Rules in every session.** A short rule set loads at session start and
  into every subagent: what a request does and does not authorize, design
  before editing, one owner per shared value, a definition of done, and when
  a change is big enough to plan.
- **Plan workspaces.** `Make a plan for <change>` creates a dated folder
  under `plans/` with the spec, the stages and who owns each, the exact brief
  each subagent receives, status and risk, and the evidence collected along
  the way. `Implement plan <path>` then runs it stage by stage.
- **Routed subagents.** Each stage names a model tier. Subagents run in
  waves grouped by ownership area, so two writers never touch the same files.
- **Four read-only reviewers.** One gathers facts for planning, one checks a
  diff against the plan, one looks for duplication and misplaced logic, and
  one runs the validation commands exactly as written.
- **Working skills.** Design-first, systematic debugging, verify-before-done,
  receiving review, and handoff.
- **A plan linter.** `agrippa-lint` checks a plan's shape: traceability,
  ownership, and command syntax. A project can add its own command rules in a
  small local file.
- **Optional extras.** `/agrippa:survey` builds an index of the repository's
  folders that planning reads first, and an opt-in hook logs every subagent
  spawn.

## What goes in your repository

Almost nothing. The rules, agents, skills, templates, and linter all live in
the plugin and are never copied in, so moving the pinned `ref` to a new tag
upgrades all of them at once.

`/agrippa:install` writes only your project's facts: a hidden `.agrippa/`
folder with the project rules, ownership areas, risk gates, exact test
commands, and decision records, plus an import line in the root `CLAUDE.md`
that loads the project rules. It never touches an `AGENTS.md` your repository
already has. Plans your sessions produce go under `plans/` as dated folders
that are never overwritten.

## This repository

| Path | What it is |
|---|---|
| `plugins/agrippa/` | The plugin. Its [README](plugins/agrippa/README.md) is the full reference. |
| `dev/` | The self-check and smoke-test fixture. Not shipped. |
| `docs/` | Design notes and the research behind the rules. Not shipped. |
| `history/plans/` | The plans that built earlier versions. Read-only history. |

To work on the plugin, see [CLAUDE.md](CLAUDE.md). Every change must leave
`node dev/validate-kit.mjs` printing `PASS`.

## License

Mozilla Public License 2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE). You
may use, modify, and redistribute Agrippa, including commercially. A kit file
you change and pass on must stay under this license with its source
available. The files Agrippa installs into your repository, and the plans,
decision records, and code you produce with it, are yours with no license
obligation.
