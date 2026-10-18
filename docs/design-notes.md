# Kit design notes

These are the choices behind the kit that the files themselves do not
explain. They were first recorded in nuro-battler between 2026-09-13 and
2026-10-01 and moved here when the kit became its own repository.

## Placeholders

- Install-time slots are written `[PROJECT: ...]`. Plain `[...]` stays in the
  installed templates and is filled per plan.
- An installed repository must contain no `[PROJECT:` outside the kit folder.
  The README's install-marker scan enforces this.

## Generations

`UPGRADING.md` recognizes three generations:

- **G1**: the dual toolchain, with `.codex/` TOML profiles for three worker
  tiers and a gate that switched the session to a high-effort planner.
- **G2**: the first Claude-only kit, with three agents and no Engineering
  standards.
- **G3**: the current kit.

Only `UPGRADING.md` and `validate-kit.ps1` may name the old vocabulary, because
they need it to recognize and search for an old install.

## The linter

- The kit linter is the linter every installed repository runs. It is never
  edited per project.
- Project checks go in an optional `tools/validate_plan_workspace.local.ps1`,
  which the linter dot-sources. It defines `Test-LocalValidationRow` (run once
  per validation-matrix row) and `Test-LocalValidationMatrix` (run once per
  matrix). The template carries nuro-battler's Godot checks as the example.
- `-SkipLocalChecks` exists for the smoke test, whose generic fixture cannot
  satisfy project rules.
- With nuro-battler's local file installed, the kit linter reproduced the old
  repository linter's error and check counts on the ten newest plans. It also
  caught a gap the old linter missed: the old linter's hard-coded extension
  list ignored `.js` and `.mjs`, so one plan owned files its ownership matrix
  never listed.
- Accepted loss in that switch: check 20 now matches `layout` rather than
  `sensor`.
- A fresh worktree checkout resets file modification times, so check 24
  (freshness) counts differ between a worktree and the main checkout.
- `validate-kit.ps1` compares an installed linter with the kit's after
  normalizing line endings, because git converts them on checkout. A
  byte-for-byte hash failed on CRLF versus LF on 2026-10-18.

## Proof

`fixtures/run-smoke-test.ps1` is the one end-to-end proof: the valid fixture
must pass and a mutated copy must fail. `validate-kit.ps1` runs it against a
simulated install in a temporary folder.

## Plugin feature checks (2026-10-18)

Phase 0 of `docs/plugin-conversion-plan.md` tested the Claude Code features the
plugin conversion depends on. The tests used a throwaway plugin loaded from a
local directory marketplace, in a desktop-app session on Claude Code 2.1.299
on Windows 11.

- **SessionStart context.** A plugin `SessionStart` hook's `additionalContext`
  reached the session at startup. The hook ran again after `/compact`, with
  `source` set to `compact`, and its new text was in the compacted session.
  A second, fresh session gave the same result.
  The startup text survived only as a mention in the compaction summary, so
  the injected rules depend on the hook running again after compaction, and
  it does. A resumed session was not tested.
- **Path substitution.** `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_SKILL_DIR}` were
  substituted in skill text, with forward slashes. Hook scripts also receive
  `CLAUDE_PLUGIN_ROOT` as an environment variable. A plugin from a local
  directory marketplace loads in place rather than from a cache copy.
- **`bin/` on PATH.** A file in the plugin's `bin/` folder ran by bare name
  from the Bash tool. It did not run from the PowerShell tool, whether named
  with no extension, `.ps1`, or `.cmd`. So a matrix row that calls a `bin/`
  command must run through the Bash tool.
- **Plugin agents.** An agent spawned as `agprobe:echo-agent` with a `model`
  override ran on that model. The `PreToolUse` hook received
  `subagent_type: agprobe:echo-agent` and `model: sonnet`. The
  `SubagentStart` hook received `agent_type: agprobe:echo-agent`.
- **`disallowedTools`.** A plugin agent with no `tools:` line and
  `disallowedTools: Write, Edit, NotebookEdit` had none of those three tools.
  It kept every other tool, including the user's MCP tools. That is how a
  shared agent can stay read-only and still use a project's live-app bridge.
- **Skill `allowed-tools`.** A skill's `allowed-tools` line did not
  pre-approve its command. In a fresh session in Ask permissions mode, a
  skill's PowerShell command still asked for permission, even though it
  matched the skill's `PowerShell(...)` rule exactly. Bash could not be tested
  this way, because this environment ran every Bash command without a prompt,
  with or without a skill. The first run's "no prompt" results came from that
  automatic Bash approval and from the session being in auto mode. The plan
  does not depend on `allowed-tools`, because a project can allow
  `Bash(agrippa-lint:*)` in its settings.
- **Hook changes need a new session.** A hook matcher changed while a session
  was running did not take effect in that session.
- **Skills after compaction.** A skill invoked again after compaction was not
  delivered again. Claude Code pointed to the copy of the skill kept in the
  compacted context.
- **GitHub access.** `pxd5295/Agrippa` is public, so installing and updating
  the plugin needs no GitHub credentials.

## Core rules injection (2026-10-18)

Phase 2 of `docs/plugin-conversion-plan.md` moved the generic always-loaded
rules out of the `AGENTS.md` and `CLAUDE.md` templates into
`plugins/agrippa/scripts/core-rules.md`. `scripts/inject_core_rules.ps1`
prints that file as `additionalContext`.

- **Two hooks, one script.** The plan named only a `SessionStart` hook. A
  subagent does not receive `SessionStart` context; it starts with its own
  prompt, the task, and the `CLAUDE.md` files. Before the split, subagents saw
  the rules because the root `CLAUDE.md` imports `AGENTS.md`. Without a second
  hook, `design-reviewer` and implementation workers would lose the
  Engineering standards they are told to apply. A `SubagentStart` hook adds
  the same text to every subagent before its first prompt.
- **The 10,000-character cap.** Claude Code caps each context string at
  10,000 characters and shows only a preview above that. The cap applies to
  the `additionalContext` string, not to the JSON around it, so
  `validate-kit.ps1` fails when `core-rules.md` reaches 10,000 characters. The
  first version is 9,645 characters, so new rules need an equal cut or the
  overflow skill the plan's risks section describes.
- **Project names became table references.** The Engineering standards used
  to name project classes inline. They now point to the "Architecture owners"
  table in `docs/agent_memory/project-contracts.md`, so the same text works in
  every project.
- **The decision-record rule moved too.** "A shared-interface change starts
  with a decision record" is methodology, so it is in the core rules. The
  project's `AGENTS.md` names which interfaces are shared.
- **UTF-8 output.** Windows PowerShell 5.1 encodes piped stdout in the console
  code page, so the script writes UTF-8 bytes to the standard output stream
  directly.
- **Proof.** On 2026-10-18 a fresh desktop session (Claude Code 2.1.299,
  Windows 11) enabled the plugin from this repository as a local directory
  marketplace. It listed all eight Engineering standards without reading any
  file. A `general-purpose` subagent it spawned quoted the rules and said they
  arrived as `SubagentStart` context.

## Linter rules that are easy to trip over

These cost three lint rounds (62 errors down to 0) on one nuro-battler plan.
The templates do not make them obvious, so they are candidates for either
template wording or friendlier linter messages.

- `Contract source:` must be `` `path:NNN` (read YYYY-MM-DD) `` with one line
  number. A range like `:19-29` fails check 24; put the range after the date.
- The census label must be literally `Consumer census:`. A parenthetical
  between the words and the colon fails check 25. Backticked
  `` `dir/file.ext:NNN` ``: `` `snippet` `` entries are verified against the
  real line, so paths need their directory and snippets must be substrings.
- Packet `- A#:` bullets must be the SPEC text verbatim, including backticks
  (check 4). Stage notes go on a separate `Acceptance notes:` line. There is
  one `- V#:` line per validation ID the stage lists.
- `Owned files:` in a packet is read from that one line only, so every file
  goes on that line in backticks.
- Check 13 rejects a matrix command that names a file that does not exist yet,
  so a new test file cannot be in the matrix. Add cases to a registered test
  instead.
- There must be exactly one `### Packet Integration`, with validator and
  reviewer packets inside it. It needs its own `- V#:` line for every ID its
  PLAN row lists (a range like "V1 to V9" fails), and PLAN's Integration row
  must contain the literal phrase "full applicable suite".
- A `Bounded-choice` stage needs a `| Bounded choice |` row containing the
  literal "Options:", "Default:" and "Change observation:", with no C-ids or
  paths in it.
- Any `V` followed by digits anywhere in a workspace (for example a product
  version name) is read as a validation ID and fails as undefined.
