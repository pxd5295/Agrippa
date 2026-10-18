# Hooks that support the methodology

Hooks are optional. The methodology works without them, but two of them close
gaps that instructions alone leave open: lint errors the agent never sees, and
subagent spawns that silently inherit the lead's model instead of the routed
tier. Install the scripts under `tools/` and wire them in the project's
`.claude/settings.json`. Merge into an existing `hooks` object; never replace
one.

## Subagent spawn log (portable, install as-is)

`log_subagent_spawns.ps1` and its helper `hook_payload.ps1` go in `tools/`.
The logger runs on two events and appends one line per spawn to
`subagent-spawns.log` at the repository root. Add `subagent-spawns.log` (or
`*.log`) to `.gitignore`.

It is observational. It writes nothing to stdout and always exits 0, so it
never blocks, allows, or rewrites a spawn. The count it exists for is
`agent=general-purpose model=NONE` on a `PreToolUse` row: that spawn named no
tier, so it inherited the lead's model instead of the tier
`docs/planning/ROUTING.md` routed. A `SubagentStart` row with no matching
`PreToolUse` row is a spawn that bypassed the Agent tool, which is the normal
shape for agents a dynamic workflow spawns.

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Agent|Task",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File tools/log_subagent_spawns.ps1",
            "timeout": 10
          }
        ]
      }
    ],
    "SubagentStart": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -File tools/log_subagent_spawns.ps1",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```

On macOS or Linux without PowerShell, either install `pwsh` and replace
`powershell -NoProfile -ExecutionPolicy Bypass -File` with `pwsh -NoProfile
-File`, or port the two scripts to the project's shell with the same rules:
always exit 0, swallow every failure, retry the append briefly because several
agents can start at once.

## Edit-lint hook (pattern, write one per project)

A `PostToolUse` hook with matcher `Edit|Write|MultiEdit` runs the project's
linter on the one file just edited and feeds findings back to the agent. Exit
code 2 with the findings on stderr is what Claude Code returns to the session
as context, so the agent fixes its own lint errors on the next action instead
of a human relaying them.

The source repository's version (`lint_gd_file.ps1`, for GDScript) earned
these rules the hard way. Keep all of them in a port:

- **Report only what the change introduced.** Filter findings to lines the
  working tree changed against `HEAD`, and say how many pre-existing findings
  were withheld. An unfiltered hook in a tree with a lint backlog reports the
  backlog on every edit, and a check that is mostly noise gets ignored. Treat
  an untracked file as changed in full. Never filter parse errors.
- **Ask git about the file in the file's own checkout.** Run
  `git rev-parse --show-toplevel` from the file's directory. A `git worktree`
  has its own `HEAD` and index; asking the launching checkout makes git answer
  "outside repository", which reads as "no baseline" and reports the whole
  backlog. Locate the linter executable separately, from the checkout the hook
  script lives in, because a linked worktree may not have the tool installed.
- **Never rewrite the file.** A hook that reformats behind the agent
  desynchronizes the next edit from what the harness believes the file holds.
  Whole-file formatters cannot be scoped to a change; run them by hand.
- **Exit 0 in silence when the linter is missing**, and offer an `-Explain`
  switch for manual runs that says why the hook did nothing. Silence is what
  hides wiring bugs, so `-Explain` is how they are found. Never set it in the
  hook command itself.
- **Keep rule configuration in the linter's own config file** with the reason
  for each tuned rule. Disable a rule that cannot be satisfied by a scoped
  change, and a rule that would become a second owner for a value the Agrippa core
  rules already own (for example a maximum file length).
- Style and syntax only. The structural rules in the core rules (duplication,
  file growth, contract drift) are diff-level and belong to `design-reviewer`.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "[PROJECT: the edit-lint hook command]",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

## Permission allowlist

Read-only git commands, the plan-workspace linter, and the project's exact test
and build executables are the calls the methodology makes most often. Allowing
them in `.claude/settings.json` removes most permission prompts during
planning and validation without allowing anything destructive:

```json
{
  "permissions": {
    "allow": [
      "Bash(git status:*)",
      "Bash(git diff:*)",
      "Bash(git log:*)",
      "Bash(git show:*)",
      "Bash(git ls-files:*)",
      "Bash(git rev-parse:*)",
      "PowerShell(powershell -NoProfile -ExecutionPolicy Bypass -File tools/validate_plan_workspace.ps1:*)",
      "[PROJECT: the exact test and build executables from validation-commands.md]"
    ]
  }
}
```
