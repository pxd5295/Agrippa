# Project Contracts

> Replace every bracketed item with repository evidence. Keep stable
> architecture and ownership facts here; keep executable validation syntax in
> `docs/agent_memory/validation-commands.md`.

## Ownership areas

Treat these as separate writer boundaries unless a plan explicitly combines
them after freezing the shared contract:

- `[path or module]`: [responsibility, authoritative interface, primary tests].
- `[path or module]`: [responsibility, authoritative interface, primary tests].
- `[path or module]`: [responsibility, authoritative interface, primary tests].

## Shared and public interfaces

Establish these contracts before parallel consumers. A plan that changes or
deletes a symbol records an `rg` consumer census with file:line snippets and
pre-authorizes only the enumerated ownership expansion.

| Interface | Contract source | Owners/consumers | Compatibility gate |
|---|---|---|---|
| `[API, schema, protocol, ABI, file format, persisted record, etc.]` | `[path:line]` | `[modules]` | `[Validation catalog purpose/ID]` |

## High-risk change classes

| Risk class | Trigger | Required contract/review/gate |
|---|---|---|
| Native/ABI | [trigger] | [compatibility/equivalence gate and reviewer] |
| Persistence/migration | [trigger] | [forward/backward compatibility and rollback] |
| Security/trust boundary | [trigger] | [threat/permission check and reviewer] |
| Concurrency/performance | [trigger] | [deterministic equivalence or baseline/target] |
| Deployment/external system | [trigger] | [approval, credential, or environment boundary] |

Delete rows that provably do not apply; add project-specific risks discovered
from code and architecture references.

## Worktree and integration contracts

- [Generated files, formatter ownership, code-generation, or merge constraints.]
- [Paths that cannot be written concurrently in a shared checkout.]
- [Required merge owner and immediate shared-interface gates.]

## Environment boundaries

- [Required SDK/runtime/tool versions and read-only discovery commands.]
- [Checks requiring network, credentials, GPU, GUI, services, or user action.]
- Preserve dirty user-owned changes and distinguish existing failures or
  environment limits from regressions introduced by the active change.
