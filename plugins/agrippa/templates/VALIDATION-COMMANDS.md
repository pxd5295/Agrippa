# Authoritative Validation Commands

> Install note: fill every install-time placeholder with commands verified in
> this repository by running them, then delete this note. Plans copy commands
> from this catalog verbatim. A representative command establishes syntax
> only; it is never the complete suite by implication. The Agrippa agents and
> skills read the sections of this file by name, so keep the section headings
> as they are and delete a section only when it provably does not apply. This
> file holds this repository's commands and facts only; the rules for using
> them (retries, pre-existing failures, matrix values) are in the plugin's
> skills, so do not copy them in here.

Run commands from `[PROJECT: repository root / named working directory]` using
`[PROJECT: shell]` unless a row states otherwise.

## Runtime and invocation rules

- Required executable/version: `[PROJECT: exact executable path or discovery
  rule; never a bare name on PATH when more than one version can be installed]`.
- Prerequisite ordering: [PROJECT: cache generation, service startup, build,
  migration, fixture setup, or `None`]. A prerequisite that must run once per
  session is described under "Session setup" and becomes the first row of
  every plan's validation matrix.
- Invocation shape per target kind and the bounded-run rule: see "Run caps".
- Known red targets at `HEAD`: [PROJECT: targets red at HEAD, with the date
  checked, or `None`].
- One at a time: see "Shared log paths".

## Session setup

[PROJECT: the step that must run once per session before the first validation
run, with its exact command, or `None`. Example from a game project: run the
class-cache prelude once per session before the first Godot target.]

## Verdict line

[PROJECT: the verdict line every test prints, and how a run can exit 0 without
one in this toolchain. A run that exits 0 with no verdict is a failure.
Example from a game project: every test prints a `PASS` or `FAIL` line. A
runtime error inside `_ready()` itself means nothing ever calls `quit()`, and
the frame cap exits 0.]

## Error grep

[PROJECT: the runtime error marker to grep for even when the verdict says
pass, and whether the test harness enforces it. Example from a game project:
grep for `SCRIPT ERROR`; where a test reports through `TestReport.finish()`,
that check is automatic, and older tests need it by hand.]

## Known messages

- Messages that mean something specific in this toolchain: [PROJECT: one
  bullet each, with what to do. Example from a game project:
  `Could not find base class` means the class-name cache is stale; run the
  session setup step and retry before reading anything else into it.
  `Nonexistent function 'new' in base 'GDScript'` means a script up the
  preload chain failed to parse, so the error is in a different file from the
  one named.]
- Messages that are expected in a headless or CI run: [PROJECT: one bullet
  each. Example from a game project: `no local RenderingDevice` or
  `GPU compute unavailable` is expected under `--headless`.]

## Failure surfaces

[PROJECT: the places a failure shows up here besides a failing test, which
call for the `systematic-debugging` skill. Example from a game project: a
scene errors, the native worker or GPU path misbehaves, or a sim capture shows
a hitch.]

## Run caps

[PROJECT: the invocation form for each kind of target, and the frame or time
cap with the unit it counts. A frame cap counts frames, not seconds. Example
from a game project: `-s` for `extends SceneTree` scripts, with no frame cap;
a rendered-frame cap for scenes. `--quit-after N` counts rendered frames, so a
cap of 60 is about a second.]

## Shared log paths

[PROJECT: the log or output files that targets share, so those targets run one
at a time, or `None`. Example from a game project: every run writes the same
`user://logs/godot.log`.]

## Build

[PROJECT: the build command, every configuration it must build, and the
restart a running process needs before tests see the new build, or `None`.
Example from a game project: a scons rebuild of both configs, which must each
exit 0, then a Godot restart before the running DLL reflects the change.
Native code changes need this rebuild before validation means anything.]

## Performance evidence

[PROJECT: the authoritative measurement for production performance claims,
and why headless benchmarks are only secondary diagnostics here. Example from
a game project: for sim-speed claims, a perf recorder capture from a real
windowed run.]

## Linter scope

[PROJECT: how the linter reports, and the command that gives the whole-file
answer. Example from a game project: the PostToolUse hook reports only changed
lines; a full `gdlint` on the file is the whole-file answer.] A green linter is
never evidence that a contract is correct.

## Invocation traps

[PROJECT: the invocation mistakes a validator must not make, in one or two
sentences. Example from a game project: "Runs use the real console binary
after the cache prelude; script tests take the script flag without an
early-exit flag; scene tests take a rendered-frame cap."]

## Runtime writes and caches

[PROJECT: the runtime cache and output writes the build or test tooling makes,
which a validation run may make but must not commit, and any cache that must
never be deleted, for example dependency caches, build artifacts, import or
class caches, test logs, and app user data. Example from a game project: Godot
writes its class cache, import files, logs, and user data.]

## Environment limits

[PROJECT: the environment limits that recur here, and the environment that
exercises any GPU or display path, because a headless or CI run may only ever
exercise a CPU fallback. Example from a game project: no Vulkan headless, and
gdtoolkit may be missing. The GPU path runs only in a windowed run, because
`--headless` has no rendering device.]

## UI capture

[PROJECT: how a design-fidelity check captures the rendered UI in-app (a live
tool bridge, a browser pane, a simulator, or the app's own render-to-image
path), and whether operating-system screen capture is allowed on this
project's machines, or `None` when the project has no UI. Example from a game
project: the live editor bridge's game screenshot; operating-system screen
capture is not allowed.]

## Sandbox stance

[PROJECT: name which targets are `outside-sandbox` and why, or say that every
target is `sandboxed`. The two values are defined under "Validation matrix
values" in the `plan` skill's `agent-workflow.md`.]

## Command catalog

| Purpose | Working directory | Style | Sandbox | Determinism | Exact command or manual check |
|---|---|---|---|---|---|
| Prerequisite | `[PROJECT: path]` | prerequisite | `[PROJECT: stance]` | deterministic | `[PROJECT: exact command, or delete the row]` |
| Fast targeted unit check | `[PROJECT: path]` | unit | `[PROJECT: stance]` | deterministic | `[PROJECT: exact command]` |
| Shared-interface gate | `[PROJECT: path]` | integration | `[PROJECT: stance]` | deterministic | `[PROJECT: exact command]` |
| Build/typecheck | `[PROJECT: path]` | build | `[PROJECT: stance]` | deterministic | `[PROJECT: exact command]` |
| Lint/format check | `[PROJECT: path]` | lint | sandboxed | deterministic | `[PROJECT: exact command]` |
| Performance check | `[PROJECT: path]` | benchmark | `[PROJECT: stance]` | noisy-retry | `[PROJECT: exact bounded command and threshold]` |
| Manual behavior check | `[PROJECT: path]` | manual | `[PROJECT: stance]` | manual | [PROJECT: observable procedure and pass condition] |
| Complete applicable suite | `[PROJECT: path]` | full-suite | `[PROJECT: stance]` | `[PROJECT: determinism]` | `[PROJECT: exact command sequence or enumerated rows]` |

## Live application bridge

[PROJECT: optional. Delete this section if the project has no MCP server that
observes the running application. Otherwise name the catalog rows that need
the live app or a GPU and so cannot run headless. The server, its tools, and
its traps are in `.agrippa/live-app.md`.]

## Full-suite inventory

| Area or target | Exact command/check | Applies when | Expected duration/output bound |
|---|---|---|---|
| `[PROJECT: module/test target]` | `[PROJECT: exact command]` | [PROJECT: trigger] | [PROJECT: bound] |

<!-- Install note: list every target that can be applicable and the
observation that makes it applicable, one row each. A plan can cite only a
target registered here, so a single representative test is never the whole
suite. Delete this comment once the table is filled. -->
