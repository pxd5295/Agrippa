# Authoritative Validation Commands

> Replace every bracketed value with commands verified in the target
> repository. Plans copy commands from this catalog verbatim. A representative
> command establishes syntax only; it is never the complete suite by
> implication.

Run commands from `[repository root / named working directory]` using
`[shell]` unless a row states otherwise.

## Runtime and invocation rules

- Required executable/version: `[exact executable or discovery rule]`.
- Prerequisite ordering: [cache generation, service startup, build, migration,
  fixture setup, or `None`].
- Environment stance: [workspace / full-fs / network / credentials / gpu / gui
  / service / manual requirements].
- Bounded-run rule: [timeout/frame cap/noninteractive termination contract].
- Retry rule: [exact environmental-noise observation that permits a retry;
  assertion/correctness failures never retry into green].
- Existing-failure rule: [how to identify and report pre-existing failures].

## Command catalog

| Purpose | Working directory | Style | Environment | Determinism | Exact command or manual check |
|---|---|---|---|---|---|
| Fast targeted unit check | `[path]` | unit | workspace | deterministic | `[exact command]` |
| Shared-interface gate | `[path]` | integration | `[stance]` | deterministic | `[exact command]` |
| Build/typecheck | `[path]` | build | `[stance]` | deterministic | `[exact command]` |
| Lint/format check | `[path]` | lint | workspace | deterministic | `[exact command]` |
| Performance check | `[path]` | benchmark | `[stance]` | noisy-retry | `[exact bounded command and threshold]` |
| Manual behavior check | `[path]` | manual | `[stance]` | manual | [observable procedure and pass condition] |
| Complete applicable suite | `[path]` | full-suite | `[stance]` | `[determinism]` | `[exact command sequence or enumerated rows]` |

Allowed plan-matrix determinism values are `deterministic`, `noisy-retry`,
`skips-headless`, and `manual`. Every validation row records Style,
Environment, Determinism, and When.

## Full-suite inventory

List every target that can be applicable and the observation that makes it
applicable. Do not use a single representative test as the complete suite.

| Area or target | Exact command/check | Applies when | Expected duration/output bound |
|---|---|---|---|
| `[module/test target]` | `[exact command]` | [trigger] | [bound] |

## Workspace-linter adaptations

Mirror durable command invariants in
`tools/validate_plan_workspace.ps1`, including:

- repository file extensions or path conventions recognized in ownership and
  edit-site fields, if a narrower set than "any dotted extension" is useful;
- exact executable/path rules, if the project has one required launcher or
  wrapper binary that every relevant command must go through;
- prerequisite ordering, such as a required prelude command before the first
  test in a session;
- working-directory requirements for a given test runner or subproject;
- environment classification (workspace-only vs. full filesystem, network,
  credentials, GPU, GUI, or external services);
- bounded invocation and retry syntax.

The portable linter in this kit ships with these checks as commented-out
extension points rather than hardcoded rules, because they are specific to
one project's toolchain. Add the target repository's exact invariants there.

The linter checks shape and freshness, never semantic truth.
