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

- **Always-loaded rules.** Root `AGENTS.md` (request boundaries, Engineering
  standards, definition of done, planning trigger and size gate, launch, and
  project contracts) and a root `CLAUDE.md` that imports it and adds the
  roster, skills, planner read ladder, and validation reach. Per-directory
  `CLAUDE.md` files hold rules that matter only in one folder.
- **On-demand guides.** `docs/agent-workflow.md` (lifecycle, interview, design
  states, design-reference planning, risk, workspace shapes, evidence) and
  `docs/planning/ROUTING.md` (tier table, fork or fresh, roster, packets,
  ownership, waves, launch, validator, review). They load only for planning or
  plan implementation.
- **Tools the rules call.** Four named agents, four skills, the `/handoff`
  command, the plan templates, the workspace linter, project-contract and
  validation-catalog documents, decision records, and optional hooks.

## Kit layout

| Source | Destination in the target repository |
|---|---|
| `templates/AGENTS.md` | `AGENTS.md`, adapted and merged |
| `templates/CLAUDE.md` | `CLAUDE.md` (root), adapted and merged |
| `templates/directory-CLAUDE.md` | `<ownership area>/CLAUDE.md`, one per area that has real rules |
| `templates/agent-workflow.md` | `docs/agent-workflow.md` |
| `templates/ROUTING.md` | `docs/planning/ROUTING.md` |
| `templates/planning-CLAUDE.md` | `docs/planning/CLAUDE.md` |
| `templates/planning/*.md` | `docs/planning/templates/*.md` |
| `templates/PROJECT-CONTRACTS.md` | `docs/agent_memory/project-contracts.md` |
| `templates/VALIDATION-COMMANDS.md` | `docs/agent_memory/validation-commands.md` |
| `templates/agent-memory-CLAUDE.md` | `docs/agent_memory/CLAUDE.md` |
| `templates/decisions-README.md` | `docs/decisions/README.md` |
| `templates/plans-README.md` | `plans/README.md` |
| `templates/agents/*.md` | `.claude/agents/*.md` (`repo-scout`, `plan-reviewer`, `design-reviewer`, `validator`) |
| `templates/skills/*/SKILL.md` | `.claude/skills/*/SKILL.md` (`design-first`, `systematic-debugging`, `verify-before-done`, `receiving-review`) |
| `templates/commands/handoff.md` | `.claude/commands/handoff.md` |
| `templates/validate-plan-workspace.ps1` | `tools/validate_plan_workspace.ps1` |
| `templates/hooks/*.ps1` | `tools/*.ps1`, optional; wiring in `templates/hooks/README.md` |
| `templates/validate-plan-workspace.local.ps1` | `tools/validate_plan_workspace.local.ps1`, only when the project has command invariants to enforce |
| `templates/MIGRATION.md` | `docs/planning/MIGRATION.md`, upgrades only |
| `UPGRADING.md` | Not installed; the generation markers and rule mapping for upgrades |
| `ADOPTION-CHECKLIST.md` | Not installed; every item is completed or reported |
| `fixtures/` | Not installed; `run-smoke-test.ps1` proves the installed linter |
| `validate-kit.ps1` | Not installed; checks that this kit is intact and self-consistent |

## Placeholder convention

Two kinds of brackets appear in the templates, and they are filled at
different times:

- `[PROJECT: ...]` is filled **once, at install time**, from repository
  evidence. It always says what to fill in and usually gives an example from
  the source repository. When the subject does not exist in the target (no
  native code, no live-app bridge), delete the placeholder together with the
  sentence, bullet, or marked optional block around it; never write "N/A".
- Plain `[...]` inside `docs/planning/templates/` is filled **per plan** by the
  planner and stays in the installed templates.

Two more install-time markers are removed during install. A line or comment
starting `Install note` is guidance for the installer; delete it once its
file is filled. A block between `<!-- BEGIN optional live-app block -->` and
`<!-- END optional live-app block -->` is either deleted whole or kept with its
BEGIN and END lines and its `[PROJECT:` header removed.

**Install-marker scan.** After install, a case-sensitive search for the
regular expression `\[PROJECT:|Install note|optional live-app block` in every
file outside the kit folder must find nothing.

The shared linter is never edited per project. A project's own command
invariants (one required binary, an invocation shape per test kind, a
prerequisite that must come first) go in `tools/validate_plan_workspace.local.ps1`
from `templates/validate-plan-workspace.local.ps1`, which the linter loads when
present. A later kit upgrade replaces the shared linter and keeps the local
file. The smoke test runs with `-SkipLocalChecks`, because its generic fixture
cannot satisfy project rules; prove local checks by linting one real plan
workspace. The fixture's consumer census also expects line 1 of the installed
`docs/agent-workflow.md` to read `# Planning and implementation workflow`.

## Requirements and fallbacks

- PowerShell for the linter, the smoke test, and the hooks: Windows PowerShell
  5.1 or PowerShell 7 (`pwsh`) on macOS and Linux. All scripts are 5.1-clean.
- `AskUserQuestion` for the planning interview. Without it, ask the same
  focused questions in chat and record the answers the same way.
- The `engineering:architecture` and `engineering:system-design` skills (the
  `engineering` plugin) write decision records. Without them, write the record
  by hand in the shape `docs/decisions/README.md` gives.
- Named-agent `tools:` lines are complete allowlists. An agent that should use
  an MCP server lists each tool by full name; MCP access is not implied.

## Setup prompt: project with no planning methodology

Copy the kit folder into the target repository, start Claude Code at the
repository root on a strong model at high effort, and paste:

```text
Install the planning methodology from the kit folder named
`planning-methodology-kit` in this repository. If more than one folder has that
name, stop and ask which one to use.

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
   install the spawn logger as-is; for the edit-lint hook, write the script
   following every rule in templates/hooks/README.md and prove it by making
   one deliberate lint error and reverting it, or leave it unwired and say
   so; merge hooks and the permission allowlist into .claude/settings.json
   without replacing existing entries. Do not change application code.
   Preserve every unrelated user change.

5. Validate, and paste the exact command and result for each:
   - `fixtures/run-smoke-test.ps1 -RepoRoot .` from the kit must print PASS;
   - the README's install-marker scan must find nothing;
   - each command in docs/agent_memory/validation-commands.md must have been
     run once and its result recorded;
   - if a local linter file was installed, write one small real plan
     workspace for a trivial change, lint it, and delete it;
   - the kit's `validate-kit.ps1` must print PASS.

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
named `planning-methodology-kit`. If more than one folder has that name, stop
and ask which one to use.

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
   replaced, never hand-merged. Install hooks as in the new-project prompt.
   Remove project-wide model or reasoning-effort pins and old toolchain
   configuration only after I confirmed it in step 3; otherwise list it under
   "Deprecated, awaiting confirmation". Never edit, move, rename, or convert a
   dated plan workspace. Do not change application code. Preserve every
   unrelated user change.

5. Validate, and paste the exact command and result for each:
   - `fixtures/run-smoke-test.ps1 -RepoRoot .` from the kit must print PASS;
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
   - the kit's `validate-kit.ps1` must print PASS.
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

Small changes skip the workspace under the size gate in `AGENTS.md` and are
implemented directly after a design statement. A plan ends with the first
allocation and an exact resume prompt. `Implement plan [path]` then runs the
lead plus routed subagents; no opt-in phrase or per-spawn confirmation is
needed. `/handoff` writes a short brief when a session ends mid-plan.

## Keeping the kit current

The kit is a copy, not a link. In the source repository, a change to
`AGENTS.md`, the guides, the templates, the agents, the skills, or the linter
does not reach the kit until someone ports it here. After porting, run
`validate-kit.ps1`; it checks file presence, required methodology clauses,
leftover vocabulary from older toolchains, encoding, script parsing, and an
end-to-end smoke test against a simulated install.

The linter is the exception: the source repository's
`tools/validate_plan_workspace.ps1` is a byte-identical copy of
`templates/validate-plan-workspace.ps1`, with its own rules in
`tools/validate_plan_workspace.local.ps1`. Change the kit copy and copy it
over the installed one. When the kit sits at `docs/<kit>/` in a repository
with the linter installed, `validate-kit.ps1` fails while the two differ.
