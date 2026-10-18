---
name: design-first
description: "Design a code change in this repo before editing it. Use before the first edit of any change, fix, or feature request that touches more than one function, adds a class, conditional, constant, or config key, or touches [PROJECT: the shared base classes, performance-owned subsystems, and configuration layer that need design care. Example from a Godot repo: WorldBase, AnimalBase, the native worker, the cfg layer], or a docs/agent_memory contract. Produces the design statement and placement decision required by the Engineering standards in the Agrippa core rules."
---

# Design first

The Engineering standards in the core rules require a design statement before the
first edit and a definition-of-done report at the end. This skill is the
procedure for producing both in this codebase. It applies whether or not the
change goes through a plan workspace.

## 1. Locate the change in the architecture

Answer these before reading more code than needed. Use `docs/agent_memory/`
first, then the `CLAUDE.md` in the subfolder you are about to edit.

1. **Which ownership area** (from `docs/agent_memory/project-contracts.md`):
   [PROJECT: the ownership areas. Example from a Godot repo: `scripts/`,
   `native/`, `tests/`, or `docs/agent_memory/`.] A change that needs two
   areas is not a direct edit; say so and follow the planning trigger.
2. **Which layer**:
   - **Configuration** -- a value that differs by mode, environment, or
     tuning belongs in the configuration layer and is read through the
     existing loaders. If a gitignored local override layer is applied after
     the defaults, it shadows them, so never "fix" a default by editing the
     override. [PROJECT: the default configuration file, its loaders, and
     any override layer. Example from a Godot repo: a new property belongs
     in `default_properties.cfg`; `user_properties.cfg` is gitignored and
     shadows defaults.]
   - **Shared base class** -- holds behavior shared by every variant and
     exposes it through hooks. [PROJECT: the shared base classes with their
     file paths. Example from a Godot repo: `WorldBase`
     (`scripts/world/world_base.gd`) and `AnimalBase`
     (`scripts/animal/animal_base.gd`) hold behavior shared by training and
     evolution.]
   - **Variant subclass** -- holds behavior that exists in one variant (one
     mode, platform, or product) only. [PROJECT: the variant subclasses.
     Example from a Godot repo: `*_training.gd` / `*_evolution.gd` hold
     behavior that exists in one mode only.]
   - **Native or performance-owned subsystem** -- owns a hot path.
     Higher-level code configures and reads it; it never reimplements it.
     [PROJECT: the performance-owned subsystems and what they own. Example
     from a Godot repo: movement, collision, the grid, resident vision,
     sensor rows, and packed brain actions live in `NuroMovementWorker`
     (`native/`); GDScript configures and reads it.]
   - **Engine/service funnels** -- the shared engines, registries, and
     single entry points that every consumer goes through. [PROJECT: the
     funnels by `file:symbol`. Example from a Godot repo: the stat engine
     (`animal_stats.gd`), `Genome` (`GENE_SPECS`), the static-entity funnel
     (`_register_static_entity`), the vision-slot registry (`_vs_register` /
     `_vs_move` / `_vs_unregister`), the reference-trace codec.]
3. **Which existing owner** already handles the closest thing. Grep for it.
   The answer is a `file:symbol`, not "nothing similar exists" unless you
   checked.
4. **Is this a new subsystem or a shared-interface change?** A new base
   class or class family, [PROJECT: the other kinds of new subsystem in this
   project. Example from a Godot repo: native worker or extension class,
   editor panel], or ownership area is a new subsystem and runs
   `engineering:system-design` first. A change to a shared interface
   [PROJECT: the shared interfaces from `docs/agent_memory/project-contracts.md`.
   Example from a Godot repo: sensor order, network shape, GPU layout,
   serialization, scene/node contracts, or saved configuration] needs a
   decision record from `engineering:architecture` first. Both are saved
   under `docs/decisions/` (see its README) before the first edit.

## 2. Decide placement with these rules

- **Shared by every variant** -> base class, exposed to subclasses through an
  existing virtual hook. [PROJECT: the hook list per base class. Example from
  a Godot repo: world hooks `_init_before_start`, `_start`, `_on_process`,
  `_setup_hud`, `_new_animal`, `_configure_animal`, `_handle_animal_death`;
  animal hooks `_on_ready`, `_on_pre_stat_step`, `_on_movement_step`,
  `_final_fitness`, `_on_plant_consumed`, `_initial_mass`.] Adding a hook is
  a shared-interface change and must be documented in `docs/agent_memory/`
  [PROJECT: the contract file that lists the hooks. Example from a Godot
  repo: `docs/agent_memory/class-architecture.md`].
- **One variant only** -> the subclass. Never `if mode == ...` in a base
  class.
- **Differs only by value** -> the configuration layer, not code. [PROJECT:
  a variant that shows how thin a value-only variant should be. Example from
  a Godot repo: the foraging and scavenger worlds are 15 to 18 lines on
  purpose.]
- **A new entry in a schema-driven list** -> one entry in the schema that
  every consumer iterates; never a parallel list. Bump the schema version if
  the persisted shape changes. [PROJECT: the schema-driven lists and their
  version constants. Example from a Godot repo: a new heritable trait is one
  `GENE_SPECS` entry; mutation, cloning, and serialization iterate it; bump
  `SCHEMA_VERSION` if the persisted shape changes.]
- **A new derived value or modifier** -> the engine that owns derived
  values, through its public API. Never write the underlying fields
  directly. [PROJECT: the engine API and the fields it owns. Example from a
  Godot repo: the stat engine through `set_base`, `set_modifier[_batch]`,
  `remove_source`, `set_condition`; never write `_health` / `_energy`
  directly.]
- **A new registered entity or renderer** -> through the existing
  registration funnel. [PROJECT: the registration funnels and what depends
  on them. Example from a Godot repo: through `_register_static_entity` and
  the vision-slot registry; every overlay indexes those slots.]
- **A value used by more than one consumer** -> one definition with one
  owner. Code copies are copies. [PROJECT: the contract files that own
  shared constants. Example from a Godot repo: V10 sensor and brain
  constants come only from `docs/agent_memory/sensor-contract.md`.]
- **Per-hot-path work** -> multiplied by how often the hot path runs.
  Anything new on the hot path needs a cost estimate, and bulk work at a
  phase transition must be sliced under the existing time budget. [PROJECT:
  the hot path, its multiplier, and the budget. Example from a Godot repo:
  per-tick work is multiplied by the speed preset, and bulk work on restart
  or generation transition must be sliced under the existing frame budget.]
- **A gated subsystem's state, geometry, or dispatch** -> must pass its gate
  on a fresh build. [PROJECT: the gated subsystems, their gate targets, and
  the build step. Example from a Godot repo: native state, geometry, or
  dispatch must pass the serial-versus-pool equivalence gate
  (`tests/test_native_smoke.gd` and
  `tests/test_threaded_tick_equivalence.tscn`) and needs a scons rebuild of
  both configs first.]

## 3. Write the design statement

Put this in the reply before the first edit. Three sentences, complete
sentences, no headings:

1. Where the change lives: ownership area, layer, and the `file:symbol` that
   owns it.
2. What it extends or reuses: the existing hook, funnel, engine, or config
   path, by name. If nothing fits, say what new owner you are introducing and
   why the existing ones do not fit.
3. What the second occurrence looks like: how the next similar need would be
   served by this change without copying it. If the answer is "copy it",
   stop and redesign.

If the change touches a shared interface (the list in step 1, item 4), add a
fourth sentence naming every consumer the change affects, found by grep, not
memory.

## 4. Check for structural problems you are about to build on

While reading the edit site, look for duplicated logic, a mode branch in a
base class, a copied constant, or a call-site special case an owner should
hold. Apply the refactor-or-file rule from the core rules: fix it in this change
if it stays in one ownership area and under roughly 50 lines; otherwise flag
it as a separate task in the reply. Never extend the problem silently.

## 5. Report against the definition of done

At the end of the change, list the six items from the definition of done in
the core rules and state which you verified, with the exact validation command
and outcome. Exact commands and run limits are in
`docs/agent_memory/validation-commands.md`. [PROJECT: any once-per-session
setup step before the first validation run. Example from a Godot repo: run
the class-cache prelude once per session first.]

## What this skill does not do

It does not replace a plan workspace when the planning trigger applies, and it
does not review the finished diff. Review is the `design-reviewer` agent's
job.
