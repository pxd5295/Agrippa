# Project Contracts

> Install note: fill every install-time placeholder with repository evidence,
> then delete this note. Keep stable architecture and ownership facts here;
> keep executable validation syntax in `docs/agent_memory/validation-commands.md`.
> Plans freeze contracts against this file, so a wrong fact here poisons every
> plan that cites it: verify each one against the code (`git grep` the symbol
> or constant) when you write it. The Agrippa agents and skills read the
> sections of this file by name, so keep the section headings and the owner
> kinds as they are.

## Project summary

[PROJECT: one or two sentences naming what the project is and what makes its
changes risky. Example from a game project: "This is a simulation game with a
native runtime and a GPU inference path."]

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

Example from a game project: `scripts/` (simulation and editor code),
`native/` (the native runtime), `tests/` (tests and benchmarks), and
`docs/agent_memory/` (stable contracts).

## Architecture owners

The Engineering standards in the Agrippa core rules and the `design-first`
skill place every change at an existing owner, and they name the owners only
by the row kinds below. List the owners here so placement is a lookup, not a
search. Delete a row that provably does not apply.

| Owner kind | Where it lives | What it owns |
|---|---|---|
| Shared base classes | `[PROJECT: file:symbol]` | [behavior shared by every variant] |
| Hooks per base class | `[PROJECT: the contract doc that lists them]` | [the virtual hooks each base class exposes; adding one is a shared-interface change] |
| Variant subclasses | `[PROJECT: file pattern]` | [behavior that exists in one variant only; name the variant axis] |
| Configuration layer | `[PROJECT: default config file and loader]` | [value-only differences; name any gitignored override layer that shadows defaults, and a value-only variant that shows how thin one should be] |
| Engines, services, and funnels | `[PROJECT: file:symbol]` | [registration, serialization, and what depends on each funnel] |
| Derived-value engines | `[PROJECT: file:symbol]` | [the public API for derived values and modifiers, and the fields that are never written directly] |
| Schema-driven lists | `[PROJECT: file:symbol of the list and its version constant]` | [the list every consumer iterates, and when the version is bumped] |
| Performance-owned subsystem | `[PROJECT: path, or None]` | [hot-path work other code configures but never reimplements; name the layer that is tempted to reimplement it] |
| Hot path | `[PROJECT: the loop or entry point]` | [what multiplies per-iteration cost, and the time budget bulk work must be sliced under] |
| Gated subsystems | `[PROJECT: path or class]` | [the state, geometry, or dispatch changes that must pass a gate, and the gate targets from the validation catalog] |
| New subsystem kinds | [PROJECT: kinds, or None] | [additions that count as a new subsystem besides a new base class, class family, or ownership area] |
| Language servers | `[PROJECT: languages and folders, or None]` | [which languages have a language server for the `LSP` tool, and the doc that owns when to prefer it over grep and where it does not apply] |

Example from a game project:

- Shared base classes: `WorldBase` (`scripts/world/world_base.gd`) and
  `AnimalBase` (`scripts/animal/animal_base.gd`) hold behavior shared by
  training and evolution.
- Hooks per base class, listed in `docs/agent_memory/class-architecture.md`:
  world hooks `_init_before_start`, `_start`, `_on_process`, `_setup_hud`,
  `_new_animal`, `_configure_animal`, `_handle_animal_death`; animal hooks
  `_on_ready`, `_on_pre_stat_step`, `_on_movement_step`, `_final_fitness`,
  `_on_plant_consumed`, `_initial_mass`.
- Variant subclasses: `*_training.gd` / `*_evolution.gd` hold behavior that
  exists in one mode only. The variant axis is training versus evolution.
- Configuration layer: a new property belongs in `default_properties.cfg`;
  `user_properties.cfg` is gitignored, is applied after the defaults, and
  shadows them. The foraging and scavenger worlds are 15 to 18 lines on
  purpose.
- Engines, services, and funnels: the stat engine (`animal_stats.gd`),
  `Genome` (`GENE_SPECS`), the static-entity funnel
  (`_register_static_entity`), the vision-slot registry (`_vs_register` /
  `_vs_move` / `_vs_unregister`), and the reference-trace codec. Every overlay
  indexes the vision slots.
- Derived-value engines: the stat engine through `set_base`,
  `set_modifier[_batch]`, `remove_source`, and `set_condition`; never write
  `_health` / `_energy` directly.
- Schema-driven lists: a new heritable trait is one `GENE_SPECS` entry;
  mutation, cloning, and serialization iterate it; bump `SCHEMA_VERSION` if
  the persisted shape changes.
- Performance-owned subsystem: movement, collision, the grid, resident vision,
  sensor rows, and packed brain actions live in `NuroMovementWorker`
  (`native/`); GDScript configures and reads it. GDScript code that
  reimplements native-owned work is misplaced.
- Hot path: per-tick work is multiplied by the speed preset, and bulk work on
  restart or generation transition must be sliced under the existing frame
  budget.
- Gated subsystems: `NuroMovementWorker` is the sole movement backend. Any
  movement, collision, grid, geometry, or dispatch change must pass the
  serial-versus-pool equivalence gate (`tests/test_native_smoke.gd` and
  `tests/test_threaded_tick_equivalence.tscn`) on a fresh build of both
  configs.
- New subsystem kinds: a native worker or extension class, or an editor panel.
- Language servers: C++ under `native/src/`; `native/src/CLAUDE.md` owns when
  to prefer `LSP` over grep.

## Contract documents

The contract documents in `docs/agent_memory/` besides this file and
`validation-commands.md`, one row each. Plans and reviewers cite them by path.

| Document | What it owns |
|---|---|
| `[PROJECT: docs/agent_memory/<name>.md, for example class architecture, a sensor or wire-format contract, data-model notes, or performance notes]` | [the interface or architecture facts it owns] |

Example from a game project: class architecture and hooks
(`class-architecture.md`), the sensor and brain contract
(`sensor-contract.md`), the stat system (`animal-stat-system.md`), UI style
tokens (`ui-style-tokens.md`), and generation performance notes
(`perf-generation.md`).

## Shared and public interfaces

Establish these contracts before parallel consumers. A plan that changes or
deletes a symbol records an `rg` consumer census with file:line snippets and
pre-authorizes only the enumerated ownership expansion. A change to any row
starts with a decision record in `docs/decisions/` before the first edit.
Reviewers give these rows extra scrutiny. A constant of one of these
interfaces comes only from its contract source.

| Interface | Contract source | Owners/consumers | Compatibility gate |
|---|---|---|---|
| `[PROJECT: API, schema, protocol, ABI, file format, persisted record, saved configuration, layout]` | `[path:line]` | `[modules]` | `[Validation catalog purpose]` |

Example from a game project: sensor order, network shape, GPU weight layout,
the persisted archive format, scene/node contracts, and saved configuration.
The V10 sensor and brain constants come only from
`docs/agent_memory/sensor-contract.md`.

## High-risk change classes

| Risk class | Trigger | Required contract/review/gate |
|---|---|---|
| Native/ABI | [PROJECT: trigger, naming the highest-risk dispatch layer] | [compatibility/equivalence gate, rebuild step, and reviewer] |
| Persistence/migration | [PROJECT: trigger] | [forward/backward compatibility, schema version, rollback] |
| Security/trust boundary | [PROJECT: trigger] | [threat/permission check and reviewer] |
| Concurrency/performance | [PROJECT: trigger] | [deterministic equivalence or baseline/target] |
| Deployment/external system | [PROJECT: trigger] | [approval, credential, or environment boundary] |

Delete rows that provably do not apply; add project-specific risks discovered
from code and architecture references. These rows feed the `Risk flags` field
of every plan stage, and a risk flag keeps a stage off Haiku. Example from a
game project: the Native/ABI trigger is any change to native dispatch, which
needs the equivalence gate after a rebuild of both build configs.

## Debugging map

- Layers of the main runtime path, in order, with the check at each boundary
  that tells you which side is wrong: [PROJECT: layers and boundary checks].
- Temporary probes: [PROJECT: the probe file naming convention].
- Working counterparts to compare a failing path against: [PROJECT: the usual
  ones].
- Kinds of difference that have mattered before: [PROJECT: for example
  ordering or lifecycle state].

Example from a game project: the tick path is GDScript world and animal code,
then `NuroMovementWorker` in `native/`, then the GPU brain and vision shaders;
the serial-versus-pool equivalence gate (`tests/test_native_smoke.gd`,
`tests/test_threaded_tick_equivalence.tscn`) tells you whether the native
worker agrees with itself; probes are `tests/_probe_*.gd`. Working
counterparts are the other mode's subclass and the other entity type through
the same funnel. Spawn order, and whether the object was in the tree when a
setter ran, have both mattered.

## Worktree and integration contracts

- [PROJECT: generated or tool-serialized files that are never hand-edited, any
  sidecar files that must move with the file they name, and renames the
  tooling must see. Example from a game project: a `.gd` or `.tscn` moved
  without its `.uid` sidecar, or a rename made outside the editor without
  reopening the project.]
- [PROJECT: where git worktrees live. Example: `.claude/worktrees/`.]
- [PROJECT: paths that cannot be written concurrently in a shared checkout.]
- [PROJECT: worktree setup gaps, for example a missing virtual environment or
  submodule that silences a hook or breaks the build in a fresh worktree.]
- [PROJECT: required merge owner and immediate shared-interface gates.]

## Environment boundaries

- [PROJECT: required SDK/runtime/tool versions and read-only discovery
  commands.]
- Checks that need network, credentials, a GPU, a display, services, or user
  action, and what a headless or sandboxed run silently skips, are listed under
  "Environment limits" in `docs/agent_memory/validation-commands.md`.
- Preserve dirty user-owned changes and distinguish existing failures or
  environment limits from regressions introduced by the active change.
