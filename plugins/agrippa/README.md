# Portable Planning Methodology Kit

This folder installs the planning and implementation methodology of the
repository it was extracted from into another Claude Code project, or upgrades
an older version of it. It is project-neutral: the receiving Claude session
inspects the target repository and fills in ownership, shared interfaces, risk
gates, validation commands, and agent tools from evidence.

The kit is a methodology source, not an application-code template. Installing
it authorizes planning and configuration changes only, never application
behavior changes.

It is a single-toolchain kit: Claude both authors plan workspaces and
implements them, in the same session or a later one. There is no second
toolchain, no model-switch handshake, and no allocation target the lead
"assigns" to anyone else. Per-stage tiers (`haiku`/`sonnet`/`opus`, with
reasoning effort as the finer lever) apply only to subagents the lead spawns.

## What gets installed

The methodology has three layers, and the kit installs all of them.

- **Always-loaded rules.** The plugin's core rules (`scripts/core-rules.md`:
  request boundaries, Engineering standards, definition of done, planning
  trigger and size gate, launch, roster, skills, planner read ladder, and
  validation reach), which a `SessionStart` hook adds to every session and a
  `SubagentStart` hook adds to every subagent. The project keeps only its own
  facts in a root `AGENTS.md` (project contracts and project rules) and a root
  `CLAUDE.md` that imports it and lists project skills. Per-directory
  `CLAUDE.md` files hold rules that matter only in one folder.
- **On-demand guides.** The plugin's `plan` skill holds `agent-workflow.md`
  (lifecycle, interview, design states, design-reference planning, risk,
  workspace shapes, evidence), `ROUTING.md` (tier table, fork or fresh,
  roster, packets, ownership, waves, launch, validator, review), and
  `workspace-files.md` (what each workspace file owns, handoff files,
  selective reads, linting) as reference files. They load only for planning
  or plan implementation. The `design-first` skill holds
  `decision-records.md`, the decision-record rules, which load only when a
  record is written.
- **Tools the rules call.** Four named agents, four skills, the plugin's
  `/agrippa:handoff` skill, the plan templates in the `plan` skill, the
  workspace linter that runs from the plugin as `agrippa-lint`,
  project-contract and validation-catalog documents, decision records, and
  optional hooks.

## Kit layout

| Source | Destination in the target repository |
|---|---|
| `templates/AGENTS.md` | `AGENTS.md`, adapted and merged |
| `templates/CLAUDE.md` | `CLAUDE.md` (root), adapted and merged |
| `templates/directory-CLAUDE.md` | `<ownership area>/CLAUDE.md`, one per area that has real rules |
| `templates/PROJECT-CONTRACTS.md` | `docs/agent_memory/project-contracts.md` |
| `templates/VALIDATION-COMMANDS.md` | `docs/agent_memory/validation-commands.md` |
| `templates/LIVE-APP.md` | `docs/agent_memory/live-app.md`, only when the project has an MCP server that observes the running application |
| `templates/agent-memory-CLAUDE.md` | `docs/agent_memory/CLAUDE.md` |
| `templates/decisions-README.md` | `docs/decisions/README.md`, a short pointer that says what the folder holds. It has no rules; they are in the `design-first` skill |
| `templates/plans-README.md` | `plans/README.md`, a short pointer that says what the folder holds. It has no rules; they are in the `plan` skill |
| `agents/*.md` | Not installed; the plugin's agents `agrippa:repo-scout`, `agrippa:plan-reviewer`, `agrippa:design-reviewer`, and `agrippa:validator`. A project keeps no copy in `.claude/agents/` |
| `skills/*/SKILL.md` | Not installed; the plugin's skills `agrippa:design-first`, `agrippa:systematic-debugging`, `agrippa:verify-before-done`, and `agrippa:receiving-review`, plus `plan` and `handoff` below. A project keeps no copy in `.claude/skills/` |
| `templates/hooks/README.md` | Not installed; how to opt in to the plugin's spawn logger, the edit-lint hook a project writes for itself, and the permission allowlist |
| `templates/validate-plan-workspace.local.ps1` | `tools/validate_plan_workspace.local.ps1`, only when the project has command invariants to enforce |
| `templates/MIGRATION.md` | `docs/planning/MIGRATION.md`, upgrades only |
| `UPGRADING.md` | Not installed; the generation markers and rule mapping for upgrades |
| `ADOPTION-CHECKLIST.md` | Not installed; every item is completed or reported |
| `.claude-plugin/plugin.json` | Not installed; the plugin manifest |
| `scripts/core-rules.md` | Not installed; the core rules the plugin adds to every session, kept under 10,000 characters |
| `scripts/inject_core_rules.ps1` | Not installed; prints `scripts/core-rules.md` as hook context |
| `scripts/validate_plan_workspace.ps1` | Not installed; the shared plan-workspace linter, run from the plugin |
| `bin/agrippa-lint` | Not installed; the plugin puts it on the Bash tool's PATH, and it runs `scripts/validate_plan_workspace.ps1` under `powershell` or `pwsh` |
| `scripts/log_subagent_spawns.ps1` | Not installed; the spawn logger, which does nothing unless the project sets `AGRIPPA_SPAWN_LOG=1` |
| `scripts/hook_payload.ps1` | Not installed; reads a hook payload for the spawn logger |
| `hooks/hooks.json` | Not installed; runs `scripts/inject_core_rules.ps1` on `SessionStart` and `SubagentStart`, and `scripts/log_subagent_spawns.ps1` on `PreToolUse` for the Agent tool and on `SubagentStart` |
| `skills/plan/SKILL.md` | Not installed; the `/agrippa:plan` skill, the planning entry point |
| `skills/plan/reference/agent-workflow.md` | Not installed; the lifecycle guide, a `plan` skill reference file |
| `skills/plan/reference/ROUTING.md` | Not installed; the routing guide, a `plan` skill reference file |
| `skills/plan/reference/workspace-files.md` | Not installed; what each plan-workspace file owns, handoff files, selective reads, soft budgets, and linting, a `plan` skill reference file |
| `skills/design-first/reference/decision-records.md` | Not installed; where decision records go, when one is required, and their shape, a `design-first` skill reference file |
| `skills/plan/templates/*.md` | Not installed; the blank plan-workspace files, copied into each `plans/YYYY-MM-DD-<name>/` |
| `skills/handoff/SKILL.md` | Not installed; the `/agrippa:handoff` skill, which writes a short session handoff |
| `skills/install/SKILL.md` | Not installed; the `/agrippa:install` skill, which installs the methodology in a repository that has none |
| `skills/upgrade/SKILL.md` | Not installed; the `/agrippa:upgrade` skill, which upgrades an older methodology using `UPGRADING.md` |
| `LICENSE`, `NOTICE` | Not installed as methodology files; they stay with the kit folder. The Apache-2.0 license and the attribution notice that redistributed copies must carry |

Two development files live outside this folder, in the `dev/` folder of the
Agrippa repository, and are never installed. `dev/fixtures/run-smoke-test.ps1`
proves the plugin's linter, and `dev/validate-kit.ps1` checks that this kit
is intact and self-consistent.

## Enabling the plugin in a project

A project enables the plugin in its committed `.claude/settings.json`. The
marketplace's `ref` pins the release the project gets; use a release tag once
Agrippa publishes one.

```json
{
  "extraKnownMarketplaces": {
    "agrippa": {
      "source": { "source": "github", "repo": "pxd5295/Agrippa", "ref": "v1.0.0" }
    }
  },
  "enabledPlugins": { "agrippa@agrippa": true }
}
```

Merge these two keys into the existing file; never replace its other entries.
The settings take effect once the user trusts the folder.

## Placeholder convention

Two kinds of brackets appear in the templates, and they are filled at
different times:

- `[PROJECT: ...]` is filled **once, at install time**, from repository
  evidence, or during an upgrade for `MIGRATION.md`. It always says what to
  fill in and usually gives an example from the source repository. Every
  install-time blank in the project-side templates (`templates/`) uses this
  form, so the install-marker scan finds any that are left.
- Plain `[...]` inside the `plan` skill's templates (`skills/plan/templates/`)
  is filled **per plan** by the planner, in the workspace copy, and stays in
  the templates.

**When a subject does not apply.** Delete what does not apply and keep the
structure the agents and skills read:

- Delete the placeholder together with its sentence, bullet, table row, or
  marked optional block. Never write "N/A".
- Write `None` only where the slot itself offers it (a slot that says
  `or None`). It records that the subject was checked and does not exist.
- Keep every section heading, because the agents and skills read sections by
  name, unless the template says to delete that section. When everything
  under a kept heading is deleted, write one sentence there saying that this
  repository has no such subject and how you know.

The agents and skills, including the `plan` skill's guides and templates,
contain no `[PROJECT: ...]` slot, and `dev/validate-kit.ps1` fails if one
appears. They are project-neutral and
read the project's facts from named sections of
`docs/agent_memory/project-contracts.md`,
`docs/agent_memory/validation-commands.md`, and, when the project has a
live-app bridge, `docs/agent_memory/live-app.md`. So a project fact goes in
one of those documents, never in an agent or skill.

One more install-time marker is removed during install. A line or comment
starting `Install note` is guidance for the installer; delete it once its
file is filled. An example from the source repository that is not inside a
slot sits in an `Install note` comment; use it only as a shape, and delete it
with the comment, because it holds another project's facts. The scan below also looks for `optional live-app block`, the
marker an older kit used around agent sections; none may survive an upgrade.

**Install-marker scan.** After install, a case-sensitive search for the
regular expression `\[PROJECT:|Install note|optional live-app block` in every
file outside the kit folder must find nothing.

The shared linter, `scripts/validate_plan_workspace.ps1`, runs from the
plugin and is never copied into or edited in a project. Inside Claude Code a
plan runs it as `agrippa-lint -PlanPath plans/YYYY-MM-DD-name` through the
Bash tool, because the plugin's `bin/` folder is on the Bash tool's PATH
only. Without `-RepoRoot`, the linter uses the git top-level folder of the
current directory. Outside Claude Code, run it from a checkout of Agrippa at
the project's pinned tag with `-RepoRoot`. A project's own command invariants
(one required binary, an invocation shape per test kind, a prerequisite that
must come first) go in `tools/validate_plan_workspace.local.ps1` from
`templates/validate-plan-workspace.local.ps1`, which the linter loads from the
repository root when present. A plugin upgrade replaces the shared linter and
keeps the local file. The smoke test runs with `-SkipLocalChecks`, because its
generic fixture cannot satisfy project rules; prove local checks by linting
one real plan workspace. The fixture's consumer census also expects line 1 of
the project's `AGENTS.md` to read `# Agent Workflow`.

## Requirements and fallbacks

- PowerShell for the linter, the smoke test, and the hooks: Windows PowerShell
  5.1 or PowerShell 7 (`pwsh`) on macOS and Linux. All scripts are 5.1-clean.
- `AskUserQuestion` for the planning interview. Without it, ask the same
  focused questions in chat and record the answers the same way.
- The `engineering:architecture` and `engineering:system-design` skills (the
  `engineering` plugin) write decision records. Without them, write the record
  by hand in the shape the `design-first` skill's `decision-records.md` gives.
- The named agents have no `tools:` allowlist. Their `disallowedTools` lines
  remove the editing tools, so a project's MCP tools reach them without being
  listed. A live-app bridge's authoring tools reach them too, which is why
  `docs/agent_memory/live-app.md` lists those tools and every agent is told
  never to call them.

## Installing in a project with no planning methodology

Enable the plugin for the session first. Either add the two entries from
"Enabling the plugin in a project" to the target repository's
`.claude/settings.json`, or install it once for yourself:

```text
/plugin marketplace add pxd5295/Agrippa
/plugin install agrippa@agrippa
```

Then start Claude Code at the target repository's root on a strong model at
high effort and run:

```text
/agrippa:install
```

The skill discovers the repository read-only, asks with `AskUserQuestion`
only about choices the repository cannot answer, writes the project-side
documents from `templates/`, and shows every `.claude/settings.json` change
before it writes it. It changes no application code and copies no plugin file
into the repository. It ends with the install-marker scan, its own checks,
and two development checks that run from an Agrippa checkout:
`dev/validate-kit.ps1 -InstalledRepo` and
`dev/fixtures/run-smoke-test.ps1 -RepoRoot`. An optional argument names the
release tag to pin.

## Upgrading an older planning methodology

Use this for any repository that already has planning rules: an earlier
copied-in version of this kit, the dual-toolchain generation whose markers
`UPGRADING.md` lists, a current install that has drifted, or a different
planning process. Enable the plugin as above, then run:

```text
/agrippa:upgrade
```

The skill identifies the generation with `UPGRADING.md` and records a SHA-256
manifest of every dated plan workspace before its first edit. It shows a
Retain, Merge, Replace, or Deprecate mapping before any edit, and asks with
`AskUserQuestion` before every deletion. It never edits, moves, or converts a
dated plan workspace, and it records the upgrade in
`docs/planning/MIGRATION.md`. For a copied-in kit, the "From G3" section of
`UPGRADING.md` says which copied files the plugin replaces and where their
project facts move.

## Normal use after installation

```text
Make a plan for [change]
```

Small changes skip the workspace under the size gate in the core rules and are
implemented directly after a design statement. A plan ends with the first
allocation and an exact resume prompt. `Implement plan [path]` then runs the
lead plus routed subagents; no opt-in phrase or per-spawn confirmation is
needed. `/agrippa:handoff` writes a short brief when a session ends mid-plan.

## Keeping the kit current

The kit is maintained in its own repository, Agrippa, and that copy is the
source of truth. Change the methodology there first, run
`dev/validate-kit.ps1`, and then upgrade each installed repository: change its
marketplace `ref` to the new tag, or run `/agrippa:upgrade` when the project
documents must change too. A rule first tried out in an installed repository
reaches other repositories only after it is ported back to the kit.

`dev/validate-kit.ps1` checks the plugin layout, that `plugin.json` and the
marketplace entry carry the same version, agent and skill frontmatter and
their `agrippa:` names, that no `[PROJECT: ...]` slot appears outside
`templates/`, that the core rules stay under 10,000 characters and the hooks
print them, required methodology clauses, leftover vocabulary from older
toolchains, encoding, script parsing, that the two copies of `LICENSE` and of
`NOTICE` are identical, and an end-to-end smoke test against a simulated
project that has no copy of the linter.

`dev/validate-kit.ps1 -InstalledRepo <path>` also checks a project that uses
the plugin. Its committed `.claude/settings.json` must declare the `agrippa`
marketplace and enable `agrippa@agrippa`.
`docs/agent_memory/project-contracts.md` and
`docs/agent_memory/validation-commands.md` must exist. It must keep no copy of
what the plugin provides: the agents in `.claude/agents/`, the plugin's skills
in `.claude/skills/`, `.claude/commands/handoff.md`,
`tools/validate_plan_workspace.ps1`, the spawn logger, its
`hook_payload.ps1` helper unless a project script still uses it, or a
`settings.json` hook or permission that runs them. It must also keep no full
copy of the rules that now ship in the skills: a `plans/README.md` or
`docs/decisions/README.md` with the old methodology sections instead of the
short pointer, or the old `docs/planning/CLAUDE.md`. Each failure names the
file or setting and what to do. Without `-InstalledRepo`, it checks only the
kit.
