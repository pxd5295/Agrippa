# Authoritative Validation Commands

> Install note: fill every install-time placeholder with commands verified in
> this repository by running them, then delete this note. Plans copy commands
> from this catalog verbatim. A representative command establishes syntax
> only; it is never the complete suite by implication.

Run commands from `[PROJECT: repository root / named working directory]` using
`[PROJECT: shell]` unless a row states otherwise.

## Runtime and invocation rules

- Required executable/version: `[PROJECT: exact executable path or discovery
  rule; never a bare name on PATH when more than one version can be installed]`.
- Prerequisite ordering: [PROJECT: cache generation, service startup, build,
  migration, fixture setup, or `None`]. A prerequisite that must run once per
  session becomes the first row of every plan's validation matrix.
- Invocation shape per target kind: [PROJECT: for example "a script target
  uses `-s` and no frame cap; a scene target uses a numeric frame cap".]
- Bounded-run rule: [PROJECT: timeout, frame cap, or noninteractive
  termination contract, and the unit it counts. A frame cap counts frames, not
  seconds.]
- Verdict rule: [PROJECT: the verdict line every test prints, and what a run
  that exits 0 without one means (it is a failure).]
- Error-line rule: [PROJECT: the runtime error marker to grep for even when
  the verdict says pass.]
- Retry rule: performance and benchmark gates are `noisy-retry`: run once in
  isolation and retry once only when the output identifies environmental
  noise; record both outcomes. Assertion and correctness failures never retry
  into green.
- Existing-failure rule: prove a failure is pre-existing by running the same
  target at `HEAD` in a worktree or stash, not by recalling it. Keep the
  current list of known red targets here: [PROJECT: targets red at HEAD, with
  the date checked].
- One at a time: [PROJECT: say whether targets share a log, cache, or port and
  must therefore run sequentially.]

## Sandbox stance

Every plan-matrix row records a Sandbox value:

- `sandboxed` — the command reads and writes only inside the workspace and
  needs no network, GPU, display, or external service.
- `outside-sandbox` — the command writes caches or user data outside the
  workspace, or needs network, credentials, a GPU, a display, or a service.

[PROJECT: name which targets are `outside-sandbox` and why.]

## Command catalog

| Purpose | Working directory | Style | Sandbox | Determinism | Exact command or manual check |
|---|---|---|---|---|---|
| Prerequisite | `[path]` | prerequisite | `[stance]` | deterministic | `[PROJECT: exact command, or delete the row]` |
| Fast targeted unit check | `[path]` | unit | `[stance]` | deterministic | `[PROJECT: exact command]` |
| Shared-interface gate | `[path]` | integration | `[stance]` | deterministic | `[PROJECT: exact command]` |
| Build/typecheck | `[path]` | build | `[stance]` | deterministic | `[PROJECT: exact command]` |
| Lint/format check | `[path]` | lint | sandboxed | deterministic | `[PROJECT: exact command]` |
| Performance check | `[path]` | benchmark | `[stance]` | noisy-retry | `[PROJECT: exact bounded command and threshold]` |
| Manual behavior check | `[path]` | manual | `[stance]` | manual | [PROJECT: observable procedure and pass condition] |
| Complete applicable suite | `[path]` | full-suite | `[stance]` | `[determinism]` | `[PROJECT: exact command sequence or enumerated rows]` |

Allowed plan-matrix determinism values are `deterministic`, `noisy-retry`,
`skips-headless`, and `manual`. Every validation row records Style, Sandbox,
Determinism, and When.

## Live application bridge

[PROJECT: optional. Delete this section if the project has no MCP server that
observes the running application. Otherwise name the server, its
preconditions (what must be running, which plugin enabled), the tool names for
run, stop, capture, log reading, and state inspection, and the traps: confirm
the active session is this checkout before trusting it, never persist from a
run, a backgrounded window returns a stale frame, load and parse errors live
in a different log from runtime errors, and any bridge test runner whose
discovery does not match this repository's tests.]

## Full-suite inventory

List every target that can be applicable and the observation that makes it
applicable. Do not use a single representative test as the complete suite. A
target must be registered here before a plan can cite it.

| Area or target | Exact command/check | Applies when | Expected duration/output bound |
|---|---|---|---|
| `[PROJECT: module/test target]` | `[exact command]` | [trigger] | [bound] |

## Plan-matrix contract

- Commands are copied verbatim into a plan's validation matrix, with this
  catalog's Style, Sandbox, and Determinism values.
- Before implementing a plan, run its matrix commands once to confirm every
  named target exists and executes; a speculative matrix is the main way the
  process fails quietly.
- Durable command invariants (one required binary, an invocation shape per
  target kind, a prerequisite that must come first, a required working
  directory) are mirrored as checks in
  `tools/validate_plan_workspace.local.ps1`, which the shared linter loads.
  Never edit the shared linter for them. The linter checks shape and
  freshness, never semantic truth.
