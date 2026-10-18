# Project Contracts

> Install note: fill every install-time placeholder with repository evidence,
> then delete this note. Keep stable architecture and ownership facts here;
> keep executable validation syntax in `docs/agent_memory/validation-commands.md`.
> Plans freeze contracts against this file, so a wrong fact here poisons every
> plan that cites it: verify each one against the code (`git grep` the symbol
> or constant) when you write it.

## Ownership areas

Treat these as separate writer boundaries unless a plan explicitly combines
them after freezing the shared contract. An area whose code has rules of its
own carries a `CLAUDE.md` at its root stating them.

- `[PROJECT: path or module]`: [responsibility, authoritative interface,
  primary tests].
- `[PROJECT: path or module]`: [responsibility, authoritative interface,
  primary tests].
- `docs/agent_memory/`: stable contracts. A change here that alters a frozen
  interface is a change to the interface itself.

## Architecture owners

The Engineering standards in the Agrippa core rules and the `design-first`
skill place every change at an existing owner, and they name the owners only
by the row kinds below. List the owners here so placement is a lookup, not a
search.

| Owner kind | Where it lives | What it owns |
|---|---|---|
| Shared base classes and their hooks | `[PROJECT: file:symbol]` | [behavior shared by every variant] |
| Variant subclasses | `[PROJECT: file pattern]` | [behavior that exists in one variant only] |
| Configuration layer | `[PROJECT: default config file and loader]` | [value-only differences; name any gitignored override layer that shadows defaults] |
| Engines, services, and funnels | `[PROJECT: file:symbol]` | [registration, derived values, serialization] |
| Performance-owned subsystem | `[PROJECT: path, or None]` | [hot-path work other code configures but never reimplements] |

## Shared and public interfaces

Establish these contracts before parallel consumers. A plan that changes or
deletes a symbol records an `rg` consumer census with file:line snippets and
pre-authorizes only the enumerated ownership expansion. A change to any row
starts with a decision record in `docs/decisions/` before the first edit.

| Interface | Contract source | Owners/consumers | Compatibility gate |
|---|---|---|---|
| `[PROJECT: API, schema, protocol, ABI, file format, persisted record, saved configuration, layout]` | `[path:line]` | `[modules]` | `[Validation catalog purpose]` |

## High-risk change classes

| Risk class | Trigger | Required contract/review/gate |
|---|---|---|
| Native/ABI | [PROJECT: trigger] | [compatibility/equivalence gate, rebuild step, and reviewer] |
| Persistence/migration | [PROJECT: trigger] | [forward/backward compatibility, schema version, rollback] |
| Security/trust boundary | [PROJECT: trigger] | [threat/permission check and reviewer] |
| Concurrency/performance | [PROJECT: trigger] | [deterministic equivalence or baseline/target] |
| Deployment/external system | [PROJECT: trigger] | [approval, credential, or environment boundary] |

Delete rows that provably do not apply; add project-specific risks discovered
from code and architecture references. These rows feed the `Risk flags` field
of every plan stage, and a risk flag keeps a stage off Haiku.

## Worktree and integration contracts

- [PROJECT: generated or tool-serialized files that are never hand-edited, and
  any sidecar files that must move with the file they name.]
- [PROJECT: paths that cannot be written concurrently in a shared checkout.]
- [PROJECT: worktree setup gaps, for example a missing virtual environment or
  submodule that silences a hook or breaks the build in a fresh worktree.]
- [PROJECT: required merge owner and immediate shared-interface gates.]

## Environment boundaries

- [PROJECT: required SDK/runtime/tool versions and read-only discovery
  commands.]
- [PROJECT: checks requiring network, credentials, GPU, display, services, or
  user action, and what a headless or sandboxed run silently skips.]
- Preserve dirty user-owned changes and distinguish existing failures or
  environment limits from regressions introduced by the active change.
