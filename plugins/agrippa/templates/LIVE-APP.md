# Live-App Bridge

> Install note: install this file only when the project has an MCP server that
> observes the running application, such as an editor bridge, a browser, or a
> simulator. Otherwise do not create it; the agents and skills treat a missing
> file as "no bridge". Fill every install-time placeholder by calling the
> bridge's tools once, then delete this note.

This file names the project's bridge to the running application. The Agrippa
agents and the `verify-before-done` skill read its sections by name; which
tools each agent may call, and the rules for using the bridge, are in the
plugin, not here.

## Server

- Server name and tool prefix: [PROJECT: the server name and its tool
  prefix. Example from a game project: the `godot-ai` live editor bridge, tool
  prefix `mcp__godot-ai__`.]
- Preconditions: [PROJECT: what must be running and enabled before the tools
  answer. Example from a game project: the Godot editor open on this project
  with the bridge's editor plugin enabled.]
- Confirming the checkout: [PROJECT: how to confirm the active session is this
  project and this checkout. Example from a game project: call `editor_state`
  first, and `session_manage` when more than one editor may be open, because
  worktrees under `.claude/worktrees/` carry the same addon.]

## Why the headless runtime cannot stand in

[PROJECT: what the bridge sees that a headless run cannot, so a row run
headless would look green and mean nothing. Example from a game project: the
headless console has no GPU (no Vulkan), so a GPU row run headless looks green
and means nothing.]

## Read-only tools

| Tool kind | Tool | Use |
|---|---|---|
| State | `[PROJECT: full tool name]` | Confirm the active session before trusting any answer |
| Session | `[PROJECT: full tool name]` | Pick the right instance when more than one may be open |
| Hierarchy | `[PROJECT: full tool name]` | Structure of a serialized resource as the app loads it |
| Find | `[PROJECT: full tool name]` | Locate one element |
| Properties | `[PROJECT: full tool name]` | A property's resolved value, including inherited and default values |
| Screenshot | `[PROJECT: full tool name and capture source]` | A rendered result |
| UI elements | `[PROJECT: full tool name and operation]` | Live element paths, text, and rects for layout checks |
| Runtime log | `[PROJECT: full tool name and source]` | Runtime errors |
| Load or parse log | `[PROJECT: full tool name and source]` | Load and parse errors, which never reach the runtime log |

Delete a row the bridge has no tool for.

<!-- Install note: an example from a game project, for shape only. Delete
this comment once the section is filled.
With the `mcp__godot-ai__` prefix left off: state `editor_state`; session
`session_manage`; hierarchy `scene_get_hierarchy`; find `node_find`; properties
`node_get_properties`; screenshot `editor_screenshot(source="game")`, or
`source="viewport_2d"` for the editor's 2D viewport, because this is a 2D
project and the default `"viewport"` source is the empty 3D one; UI elements
`game_manage(op="get_ui_elements")`, with `op="get_scene_tree"` and
`op="get_node_info"` for runtime structure; runtime log
`logs_read(source="game")`; load or parse log `logs_read(source="editor")`.
-->

## Run tools

| Tool kind | Tool | Required option |
|---|---|---|
| Run | `[PROJECT: full tool name]` | [PROJECT: the option that makes the run persist nothing] |
| Stop | `[PROJECT: full tool name and operation]` | None |

<!-- Install note: an example from a game project, for shape only. Delete
this comment once the section is filled.
Run `mcp__godot-ai__project_run(autosave=false)`,
always passing `autosave=false` so nothing is persisted; stop
`mcp__godot-ai__project_manage(op="stop")`.
-->

## Authoring tools

These tools write real files or change project state.

- [PROJECT: every authoring tool by full name. Example from a game project:
  `mcp__godot-ai__node_create`, `node_manage`, `node_set_property`,
  `scene_manage`, `scene_open`, `scene_save`, `script_create`, `script_attach`,
  `script_manage`, `script_patch`, `resource_manage`, `filesystem_manage`,
  `batch_execute`, `animation_create`, `project_manage` operations other than
  `stop`, and the other `*_manage` tools that edit animation, audio,
  materials, themes, tile maps, signals, autoloads, and the input map.]

## Serialized files

[PROJECT: the file types the tool serializes, which are error-prone to read as
text when the structure, element types, or a property's real value matters.
Example from a game project: scene files (`.tscn`) and resource files (`.tres`)
are engine-serialized, so prefer the hierarchy, find, and properties tools for
those facts.]

## Layout checks

Check layout numbers and spacing from the UI elements tool against
[PROJECT: the UI token or style document. Example from a game project:
`docs/agent_memory/ui-style-tokens.md`].

## Test runner

[PROJECT: name any bridge test runner whose discovery conventions do not match
this repository's tests, and the mismatch, so it is never used for the suite;
or delete this section. Example from a game project: do not use the bridge's
`test_run`. It discovers `test_*.gd` files and calls their `test_*` methods,
which does not match this repository's `extends SceneTree` scripts and `.tscn`
scene tests.]
