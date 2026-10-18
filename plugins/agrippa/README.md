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
  workspace shapes, evidence) and `ROUTING.md` (tier table, fork or fresh,
  roster, packets, ownership, waves, launch, validator, review) as reference
  files. They load only for planning or plan implementation.
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
| `templates/planning-CLAUDE.md` | `docs/planning/CLAUDE.md`, which says the guides and templates are in the plugin |
| `templates/PROJECT-CONTRACTS.md` | `docs/agent_memory/project-contracts.md` |
| `templates/VALIDATION-COMMANDS.md` | `docs/agent_memory/validation-commands.md` |
| `templates/LIVE-APP.md` | `docs/agent_memory/live-app.md`, only when the project has an MCP server that observes the running application |
| `templates/agent-memory-CLAUDE.md` | `docs/agent_memory/CLAUDE.md` |
| `templates/decisions-README.md` | `docs/decisions/README.md` |
| `templates/plans-README.md` | `plans/README.md` |
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
| `skills/plan/templates/*.md` | Not installed; the blank plan-workspace files, copied into each `plans/YYYY-MM-DD-<name>/` |
| `skills/handoff/SKILL.md` | Not installed; the `/agrippa:handoff` skill, which writes a short session handoff |
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
  evidence. It always says what to fill in and usually gives an example from
  the source repository. When the subject does not exist in the target (no
  native code, no live-app bridge), delete the placeholder together with the
  sentence, bullet, or marked optional block around it; never write "N/A".
- Plain `[...]` inside the `plan` skill's templates (`skills/plan/templates/`)
  is filled **per plan** by the planner, in the workspace copy, and stays in
  the templates.

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
file is filled. The scan below also looks for `optional live-app block`, the
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
  by hand in the shape `docs/decisions/README.md` gives.
- The named agents have no `tools:` allowlist. Their `disallowedTools` lines
  remove the editing tools, so a project's MCP tools reach them without being
  listed. A live-app bridge's authoring tools reach them too, which is why
  `docs/agent_memory/live-app.md` lists those tools and every agent is told
  never to call them.

## Setup prompt: project with no planning methodology

Copy the kit folder, `plugins/agrippa/` in Agrippa, into the target
repository. Keep an Agrippa checkout next to the target repository for the
smoke test and the self-check. Start Claude Code at the target repository's
root on a strong model at high effort, and paste:

```text
Install the planning methodology from the kit folder named `agrippa` in this
repository. If more than one folder has that name, stop and ask which one to
use.

1. Read the kit completely before changing anything: README.md,
   ADOPTION-CHECKLIST.md, and every file under templates/. The installed
   methodology must match these templates; adapt only what is marked
   `[PROJECT: ...]` or what conflicts with an existing stricter rule.

2. Discover the repository, read-only. Record: any existing AGENTS.md and
   CLAUDE.md files at any depth; existing .claude/agents, skills, commands,
   settings.json hooks and permissions; languages, build systems, test
   runners, lint and typecheck tools, and the exact commands that run them
   (run each one once to prove it works, and note what it needs: working
   directory, prerequisites, network, GPU, display, services); the natural
   ownership areas; shared interfaces (public APIs, schemas, protocols,
   persisted formats, saved configuration, ABIs, layouts) and their consumers;
   base classes, hooks, config layers, registration funnels, and hot-path
   subsystems; known red tests at HEAD; the dirty worktree. You may delegate
   read-only discovery of large areas to subagents and keep the conclusions.

3. Ask me with AskUserQuestion only about material choices the repository
   cannot answer: ownership boundaries that are ambiguous, which interfaces
   count as frozen, risk classes, and whether to install the optional hooks.
   Recommend an option for each.

4. Install every layout-table row whose destination is a repository path,
   except the upgrade-only MIGRATION.md. Follow the placeholder convention in
   the README: resolve every `[PROJECT: ...]` slot from what you found in step
   2, using the source example only as a shape; delete or keep optional
   blocks as described there; delete install notes. Create a per-directory
   CLAUDE.md only for an ownership area with real rules to state. Never edit
   the shared linter; if this repository has command invariants worth
   enforcing in every plan, write tools/validate_plan_workspace.local.ps1 from
   its template, otherwise do not install it. If I chose the optional hooks:
   turn on the plugin's spawn logger with AGRIPPA_SPAWN_LOG=1 as
   templates/hooks/README.md says; for the edit-lint hook, write the script
   following every rule in templates/hooks/README.md and prove it by making
   one deliberate lint error and reverting it, or leave it unwired and say
   so; merge hooks and the permission allowlist into .claude/settings.json
   without replacing existing entries. Enable the plugin in
   .claude/settings.json as the README section "Enabling the plugin in a
   project" shows. Never copy the plugin's agents, skills, linter, or spawn
   logger into this repository. Do not change application code. Preserve
   every unrelated user change.

5. Validate, and paste the exact command and result for each:
   - `dev/fixtures/run-smoke-test.ps1 -RepoRoot <this repository>` from the
     Agrippa checkout must print PASS;
   - the README's install-marker scan must find nothing;
   - each command in docs/agent_memory/validation-commands.md must have been
     run once and its result recorded;
   - if a local linter file was installed, write one small real plan
     workspace for a trivial change, lint it, and delete it;
   - `dev/validate-kit.ps1 -InstalledRepo <this repository>` from the Agrippa
     checkout must print PASS.

6. Report: the files installed, each project-specific adaptation and the
   evidence behind it, every ADOPTION-CHECKLIST item as done or not done with
   the reason, and the one live smoke test left for me (a real "Make a plan"
   request). Do not call the install complete while any checklist item is
   unreported.
```

## Setup prompt: upgrade an older planning methodology

Use this for any repository that already has planning rules: an earlier
version of this methodology (including the dual-toolchain generation whose
markers `UPGRADING.md` lists), an earlier copy of this kit, a current install
that has drifted, or a different planning process. Paste:

```text
Upgrade this repository's planning methodology to the one in the kit folder
named `agrippa`. If more than one folder has that name, stop and ask which one
to use.

1. Read the kit completely before changing anything: README.md, UPGRADING.md,
   ADOPTION-CHECKLIST.md, and every file under templates/. The result must
   match these templates; adapt only what is marked `[PROJECT: ...]` or what
   an existing stricter rule overrides.

2. Inventory the current methodology, read-only: every AGENTS.md and CLAUDE.md
   at any depth; .claude/agents, skills, commands, settings.json hooks and
   permissions; any other toolchain's configuration or agent profiles (the
   markers table in UPGRADING.md lists the known ones); planning guides,
   routing docs, templates, shortcuts, and validators; docs/agent_memory or
   equivalent contract docs; decision records; dated plan workspaces; the
   validation commands actually in use (run each once); and the dirty
   worktree. Identify the generation using the markers table in UPGRADING.md
   and list the markers you found. Before any edit, record a SHA-256 manifest
   of every file under the dated plan workspaces (they are often gitignored,
   so git status cannot prove they were left alone).

3. Before editing, write the rule mapping: one row per existing rule or
   artifact with Retain, Merge, Replace, or Deprecate, its new location, and
   the reason, starting from the mapping tables in UPGRADING.md. Keep the
   stricter rule whenever old and new disagree. Show me the mapping and ask
   with AskUserQuestion about every material conflict and every file you
   propose to delete. Wait for my answers.

4. Apply the mapping. Install or update every layout-table row whose
   destination is a repository path, including docs/planning/MIGRATION.md
   filled from the template. Follow the placeholder convention in the README,
   carrying over the project facts the old methodology already recorded
   (ownership areas, shared interfaces, commands, known traps) rather than
   rediscovering them. Project-specific checks that an old linter enforced
   move to tools/validate_plan_workspace.local.ps1; the shared linter is
   replaced, never hand-merged. Install hooks and enable the plugin as in the
   new-project prompt. Delete this repository's copies of what the plugin
   now provides (agents in .claude/agents, the kit skills in .claude/skills,
   .claude/commands/handoff.md, tools/validate_plan_workspace.ps1, the
   spawn-logger scripts, and the settings.json hook entries and permissions
   that run them) only after I confirmed each deletion in step 3.
   Remove project-wide model or reasoning-effort pins and old toolchain
   configuration only after I confirmed it in step 3; otherwise list it under
   "Deprecated, awaiting confirmation". Never edit, move, rename, or convert a
   dated plan workspace. Do not change application code. Preserve every
   unrelated user change.

5. Validate, and paste the exact command and result for each:
   - `dev/fixtures/run-smoke-test.ps1 -RepoRoot <this repository>` from the
     Agrippa checkout must print PASS;
   - the README's install-marker scan must find nothing;
   - a search of AGENTS.md, CLAUDE.md, docs/, and .claude/ for the old
     toolchain's markers from UPGRADING.md must find nothing outside
     MIGRATION.md, dated plan workspaces, and the kit folder;
   - the dated-workspace manifest recomputed now must equal the one from
     step 2;
   - if a local linter file was installed, one existing recent workspace must
     lint with no error from the local checks (freshness errors on landed
     plans are expected);
   - each command in docs/agent_memory/validation-commands.md must have been
     run once and its result recorded;
   - `dev/validate-kit.ps1 -InstalledRepo <this repository>` from the Agrippa
     checkout must print PASS.
   Record all of it in docs/planning/MIGRATION.md.

6. Report: the generation found, the mapping, the files changed, each
   adaptation and its evidence, every ADOPTION-CHECKLIST item as done or not
   done with the reason, anything deprecated but not yet deleted, and the live
   smoke tests left for me. Old workspaces failing the new linter is expected;
   say so rather than fixing them.
```

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
`dev/validate-kit.ps1`, and then upgrade each installed repository with the
upgrade prompt above. A rule first tried out in an installed repository
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
`tools/validate_plan_workspace.ps1`, the spawn-logger scripts, or a
`settings.json` hook or permission that runs them. Each failure names the file
or setting and what to do. Without `-InstalledRepo`, it checks only the kit.
