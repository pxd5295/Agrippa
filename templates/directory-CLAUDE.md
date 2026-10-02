# [PROJECT: folder path] — [PROJECT: one-line description of what lives here]

<!-- Install note: one copy of this file goes in each ownership-area root and
in any subfolder whose code has rules the root files do not state. Claude Code
loads it automatically when it reads or edits a file in this folder, so it is
the place for rules that only matter here. Keep it to rules and pointers;
delete every section that has nothing real to say. Delete this comment. -->

This is the **[PROJECT: ownership-area name]** ownership area (root
`AGENTS.md`). [PROJECT: if subfolders have their own `CLAUDE.md`, say so and
say that this file covers only what applies across the whole tree.]

## Canonical contracts (read before deep work; do not restate them from memory)

- `docs/agent_memory/[PROJECT: contract file]` — [PROJECT: what it owns and
  whether it is authoritative for a frozen shared interface. Say plainly that
  copies of its constants in code are copies.]

## Architecture in one paragraph

[PROJECT: where shared behavior lives, where variant-only behavior lives, how
the folder is grouped and why, and the entry points a new reader needs.]

## Rules for code in this folder

- [PROJECT: placement rules specific to this folder, each with the reason.
  Example: "A new static entity registers through `_register_static_entity`;
  every overlay indexes those slots, so a direct `add_child` is invisible to
  them."]
- [PROJECT: known traps found the hard way, each with the observation that
  revealed it. Example: "Setting mass before `add_child` is a no-op because the
  setter reads a node that does not exist yet."]

## Validation for this folder

- [PROJECT: the targeted commands from `docs/agent_memory/validation-commands.md`
  that cover this folder, named by their catalog purpose, not restated.]

## If you edit a file here

- [PROJECT: shell or language constraints, couplings to other files that must
  change together, and anything that must stay read-only.]
