# Agent Workflow

This repository uses the Agrippa planning methodology. The `agrippa` plugin
adds its core rules to every session: request boundaries, Engineering
standards, the definition of done, the planning trigger and size gate,
implementation launch, the roster and skills, the planner read ladder, and
validation reach. This file holds only this repository's project contracts and
project rules. Where a rule here is stricter than a core rule, this one wins.

## Project contracts

`docs/agent_memory/project-contracts.md` owns this repository's ownership
areas, architecture owners, shared interfaces, high-risk change classes, and
compatibility gates. `docs/agent_memory/validation-commands.md` owns every
exact command. Treat these as separate ownership areas unless a milestone
combines them:

[PROJECT: one bullet per ownership area, for example
- simulation and editor code in `scripts/` and root scene files;
- native runtime code in `native/`;
- tests and benchmarks in `tests/`;
- stable contracts in `docs/agent_memory/`.]

[PROJECT: one sentence naming the shared interfaces, for example "Sensor
order, network shape, GPU layout, serialization, scene/node contracts, and
saved configuration are shared interfaces."] Establish them before parallel
consumers. A change to any of them starts with the decision record the core
rules require.

[PROJECT: optional. Delete this paragraph if nothing applies. Generated or
tool-serialized files (engine scene and resource files, lockfiles, generated
code, schema snapshots) are data, not source text. Do not hand-edit them to
add, remove, or re-parent entries, renumber ids, or change references; that
belongs in the tool that owns them, and when the tool is unavailable, stop and
say so. Substituting a value on an existing line is fine when it changes no id
and no reference. Sidecar files (for example `.uid` or `.meta`) move, rename,
and delete in the same change as the file they name.]

[PROJECT: optional. Delete this paragraph if the project has no MCP server
that observes the running application. Name the server, what it is preferred
for (what the UI actually renders, the live object tree, editor-side load
errors, anything needing a GPU or a real display), and that every row in a
plan's validation matrix stays a headless command. Name any bridge test runner
whose discovery conventions do not match this repository's tests, so it is
never used for the suite. If the bridge is unreachable, say so and name the
headless command run instead; never report a visual or GPU-dependent check as
done when the bridge was down and nothing replaced it. If the bridge can also
author (create nodes, edit scenes, save resources), say that its edits write
real files, that it is the sanctioned path for tool-serialized files rather
than an exception to the rule above, and that such edits need the user's
go-ahead and belong in a change the user can see.]

[PROJECT: optional. Name any subsystem whose state, geometry, or dispatch
changes must pass a dedicated equivalence or compatibility gate before
completion, for example "`NuroMovementWorker` is the sole movement backend;
any state, geometry, or dispatch change must pass the native serial-versus-pool
tick equivalence gate."]

## Project rules

[PROJECT: optional. Rules that apply across this whole repository and are
stricter than, or in addition to, the core rules, one bullet each with its
reason. Rules for one folder go in that folder's `CLAUDE.md` instead. Delete
this section if there are none.]
