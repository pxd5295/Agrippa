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
  record is written. A project may add one on-demand knowledge document,
  `.agrippa/area-map.md`, which `/agrippa:survey` builds from the
  tree at a named commit: each folder's entry points, covering tests,
  governing contract, and recorded traps. The planner and `repo-scout` read it
  before a census and verify its rows in the code; it is never always-loaded
  and never a contract source.
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
| `templates/PROJECT-CONTRACTS.md` | `.agrippa/project-contracts.md` |
| `templates/VALIDATION-COMMANDS.md` | `.agrippa/validation-commands.md` |
| `templates/LIVE-APP.md` | `.agrippa/live-app.md`, only when the project has an MCP server that observes the running application |
| `templates/AREA-MAP.md` | `.agrippa/area-map.md`, only when the user runs `/agrippa:survey`; an on-demand index of folders with the commit it was built at |
| `templates/agrippa-CLAUDE.md` | `.agrippa/CLAUDE.md` |
| `templates/decisions-README.md` | `.agrippa/decisions/README.md`, a short pointer that says what the folder holds. It has no rules; they are in the `design-first` skill |
| `templates/plans-README.md` | `plans/README.md`, a short pointer that says what the folder holds. It has no rules; they are in the `plan` skill |
| `agents/*.md` | Not installed; the plugin's agents `agrippa:repo-scout`, `agrippa:plan-reviewer`, `agrippa:design-reviewer`, and `agrippa:validator`. A project keeps no copy in `.claude/agents/` |
| `skills/*/SKILL.md` | Not installed; the plugin's skills `agrippa:design-first`, `agrippa:systematic-debugging`, `agrippa:verify-before-done`, and `agrippa:receiving-review`, plus `plan` and `handoff` below. A project keeps no copy in `.claude/skills/` |
| `templates/hooks/README.md` | Not installed; how to opt in to the plugin's spawn logger, the edit-lint hook a project writes for itself, and the permission allowlist |
| `templates/validate-plan-workspace.local.mjs` | `tools/validate_plan_workspace.local.mjs`, only when the project has command invariants to enforce |
| `templates/MIGRATION.md` | `.agrippa/MIGRATION.md`, upgrades only |
| `UPGRADING.md` | Not installed; the generation markers and rule mapping for upgrades |
| `ADOPTION-CHECKLIST.md` | Not installed; every item is completed or reported |
| `.claude-plugin/plugin.json` | Not installed; the plugin manifest |
| `scripts/core-rules.md` | Not installed; the core rules the plugin adds to every session, kept under 10,000 characters |
| `scripts/inject_core_rules.mjs` | Not installed; a Node script that prints `scripts/core-rules.md` as hook context |
| `scripts/validate_plan_workspace.mjs` | Not installed; the shared plan-workspace linter, a Node script run from the plugin |
| `bin/agrippa-lint` | Not installed; the plugin puts it on the Bash tool's PATH. It is a Node script that runs `scripts/validate_plan_workspace.mjs` and passes every argument through |
| `scripts/log_subagent_spawns.mjs` | Not installed; the spawn logger, a Node script that does nothing unless the project sets `AGRIPPA_SPAWN_LOG=1` |
| `hooks/hooks.json` | Not installed; runs `scripts/inject_core_rules.mjs` on `SessionStart` and `SubagentStart`, and `scripts/log_subagent_spawns.mjs` on `PreToolUse` for the Agent tool and on `SubagentStart`, all with `node` |
| `skills/plan/SKILL.md` | Not installed; the `/agrippa:plan` skill, the planning entry point |
| `skills/plan/reference/agent-workflow.md` | Not installed; the lifecycle guide, a `plan` skill reference file |
| `skills/plan/reference/ROUTING.md` | Not installed; the routing guide, a `plan` skill reference file |
| `skills/plan/reference/workspace-files.md` | Not installed; what each plan-workspace file owns, handoff files, selective reads, soft budgets, and linting, a `plan` skill reference file |
| `skills/design-first/reference/decision-records.md` | Not installed; where decision records go, when one is required, and their shape, a `design-first` skill reference file |
| `skills/plan/templates/*.md` | Not installed; the blank plan-workspace files, copied into each `plans/YYYY-MM-DD-<name>/` |
| `skills/handoff/SKILL.md` | Not installed; the `/agrippa:handoff` skill, which writes a short session handoff |
| `skills/install/SKILL.md` | Not installed; the `/agrippa:install` skill, which installs the methodology in a repository that has none |
| `skills/upgrade/SKILL.md` | Not installed; the `/agrippa:upgrade` skill, which upgrades an older methodology using `UPGRADING.md` |
| `skills/survey/SKILL.md` | Not installed; the `/agrippa:survey` skill, which writes or refreshes `.agrippa/area-map.md` from repository evidence |
| `LICENSE`, `NOTICE` | Not installed as methodology files; they stay with the kit folder. The Apache-2.0 license and the attribution notice that redistributed copies must carry |

The project documents and the decision records live in `.agrippa/` at the
repository root, a hidden folder named after the plugin, so that the kit never
claims part of a repository's own `docs/`. Claude Code loads
`.agrippa/CLAUDE.md` when a session reads a file in the folder, as it does for
any folder. Command-line `rg` skips hidden folders unless given `--hidden`;
`git grep` and Claude Code's own search tools do not. Plan workspaces stay in
`plans/`, where people work in them every day.

Two development files live outside this folder, in the `dev/` folder of the
Agrippa repository, and are never installed. `dev/fixtures/run-smoke-test.mjs`
proves the plugin's linter, and `dev/validate-kit.mjs` checks that this kit
is intact and self-consistent. Both run with `node`.

## Enabling the plugin in a project

A project enables the plugin in its committed `.claude/settings.json`. The
marketplace's `ref` pins the release the project gets. Set it to a release
tag, such as the current `v0.3.1`.

```json
{
  "extraKnownMarketplaces": {
    "agrippa": {
      "source": { "source": "github", "repo": "pxd5295/Agrippa", "ref": "v0.3.1" }
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
contain no `[PROJECT: ...]` slot, and `dev/validate-kit.mjs` fails if one
appears. They are project-neutral and
read the project's facts from named sections of
`.agrippa/project-contracts.md`,
`.agrippa/validation-commands.md`, when the project has a
live-app bridge, `.agrippa/live-app.md`, and, when the project ran
`/agrippa:survey`, `.agrippa/area-map.md`. So a project fact goes in
one of those documents, never in an agent or skill.

One more install-time marker is removed during install. A line or comment
starting `Install note` is guidance for the installer; delete it once its
file is filled. An example from the source repository that is not inside a
slot sits in an `Install note` comment; use it only as a shape, and delete it
with the comment, because it holds another project's facts. The scan below also looks for `optional live-app block`, the
marker an older kit used around agent sections; none may survive an upgrade.

**Install-marker scan.** After install, a case-sensitive search for the
regular expression `\[PROJECT:|Install note|optional live-app block` in every
file outside the kit folder must find nothing. The search must include the
hidden `.agrippa/` folder: use `git grep`, or give `rg` the `--hidden` flag.

The shared linter, `scripts/validate_plan_workspace.mjs`, runs from the
plugin and is never copied into or edited in a project. Inside Claude Code a
plan runs it as `agrippa-lint -PlanPath plans/YYYY-MM-DD-name` through the
Bash tool, because the plugin's `bin/` folder is on the Bash tool's PATH
only. Without `-RepoRoot`, the linter uses the git top-level folder of the
current directory. Outside Claude Code, run it with
`node <Agrippa>/plugins/agrippa/scripts/validate_plan_workspace.mjs` from a
checkout of Agrippa at the project's pinned tag, with `-RepoRoot`. A
project's own command invariants (one required binary, an invocation shape
per test kind, a prerequisite that must come first) go in
`tools/validate_plan_workspace.local.mjs` from
`templates/validate-plan-workspace.local.mjs`, an ES module the linter
imports from the repository root when present. It may export
`checkValidationRow` (called once per validation-matrix row),
`checkValidationMatrix` (called once with every row), and
`commandPathExtensions` (the extensions check 13 verifies); each is optional.
A plugin upgrade replaces the shared linter and keeps the local file. A
`tools/validate_plan_workspace.local.ps1` from a plugin before 0.2.0 is no
longer loaded; the linter fails with a `[Local]` error until the file is
ported, as `UPGRADING.md` describes. The smoke test runs with
`-SkipLocalChecks`, because its generic fixture cannot satisfy project rules;
prove local checks by linting one real plan workspace. The fixture's consumer
census also expects line 1 of the project's `AGENTS.md` to read
`# Agent Workflow`.

## Requirements and fallbacks

- Node.js, for the hooks and the linter. They are ES modules that use only
  Node's built-in modules, so the plugin needs no `npm install` and no other
  runtime. Without Node, the core rules do not load and `agrippa-lint` cannot
  run. `bin/agrippa-lint` runs through Claude Code's Bash tool, which on
  Windows is Git Bash; that is Claude Code's own requirement, not one the
  plugin adds.
- Agrippa's development checks, `dev/validate-kit.mjs` and
  `dev/fixtures/run-smoke-test.mjs`, run on the same Node and need nothing
  else. PowerShell is not required anywhere, for the plugin or for the
  repository that develops it.
- `AskUserQuestion` for the planning interview. Without it, ask the same
  focused questions in chat and record the answers the same way.
- The `engineering:architecture` and `engineering:system-design` skills (the
  `engineering` plugin) write decision records. Without them, write the record
  by hand in the shape the `design-first` skill's `decision-records.md` gives.
- The named agents have no `tools:` allowlist. Their `disallowedTools` lines
  remove the editing tools, so a project's MCP tools reach them without being
  listed. A live-app bridge's authoring tools reach them too, which is why
  `.agrippa/live-app.md` lists those tools and every agent is told
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
`node dev/validate-kit.mjs -InstalledRepo` and
`node dev/fixtures/run-smoke-test.mjs -RepoRoot`. An optional argument names the
release tag to pin.

## Surveying the repository

```text
/agrippa:survey
```

The skill reads the tree read-only and writes `.agrippa/area-map.md`
from `templates/AREA-MAP.md`: one row per folder with its ownership area,
entry points as `file:symbol`, covering tests, and governing contract, a list
of folders deliberately not mapped, and the traps recorded in per-directory
`CLAUDE.md` files, decision records, and plan evidence. The map's `Built at`
line names the commit it describes. Run it again, with a folder as the
argument to refresh only that folder, when the rows go stale.

The map is on demand. Nothing about it is loaded at session start, because the
one independent study of instruction files found more cost and no gain. The
planner and `repo-scout` open it only when a plan touches a folder, verify the
rows they use in the code, and record in the plan's `EVIDENCE.md` whether the
map saved a read or misled. Those entries decide whether the map is kept,
refreshed, or dropped, and whether a larger knowledge layer is worth building.

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
`.agrippa/MIGRATION.md`. For a copied-in kit, the "From G3" section of
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
`node dev/validate-kit.mjs`, and then upgrade each installed repository: change its
marketplace `ref` to the new tag, or run `/agrippa:upgrade` when the project
documents must change too. A rule first tried out in an installed repository
reaches other repositories only after it is ported back to the kit.

`node dev/validate-kit.mjs` checks the plugin layout, that `plugin.json` and the
marketplace entry carry the same version, agent and skill frontmatter and
their `agrippa:` names, that no `[PROJECT: ...]` slot appears outside
`templates/`, that the core rules stay under 10,000 characters and the hooks
print them, required methodology clauses, leftover vocabulary from older
toolchains, encoding, script parsing, that the two copies of `LICENSE` and of
`NOTICE` are identical, and an end-to-end smoke test against a simulated
project that has no copy of the linter.

`node dev/validate-kit.mjs -InstalledRepo <path>` also checks a project that uses
the plugin. Its committed `.claude/settings.json` must declare the `agrippa`
marketplace and enable `agrippa@agrippa`.
`.agrippa/project-contracts.md` and
`.agrippa/validation-commands.md` must exist, and the folders under `docs/`
where plugins up to 0.2.0 kept the project documents and the decision records
must be gone, moved as "From G4 v0.2.0" in `UPGRADING.md` says. It must keep
no copy of
what the plugin provides: the agents in `.claude/agents/`, the plugin's skills
in `.claude/skills/`, `.claude/commands/handoff.md`,
`tools/validate_plan_workspace.ps1`, the old PowerShell spawn logger, its
`hook_payload.ps1` helper unless a project script still uses it, a
`settings.json` hook or permission that runs them, or a
`tools/validate_plan_workspace.local.ps1` not yet ported to
`tools/validate_plan_workspace.local.mjs`. It must also keep no full
copy of the rules that now ship in the skills: a `plans/README.md` or
`.agrippa/decisions/README.md` with the old methodology sections instead of the
short pointer, the old `docs/planning/CLAUDE.md`, or the generic rule
sentences that templates up to v0.1.1 wrote into `project-contracts.md`,
`validation-commands.md`, `live-app.md`, and `AGENTS.md`, which it recognizes
by their template wording. A `.agrippa/area-map.md`, when present,
must carry its `Built at` commit and no install marker. Each failure names the
file or setting and what to do. Without `-InstalledRepo`, it checks only the
kit.
