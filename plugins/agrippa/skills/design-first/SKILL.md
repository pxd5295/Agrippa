---
name: design-first
description: "Design a code change in this repo before editing it. Use before the first edit of any change, fix, or feature request that touches more than one function, adds a class, conditional, constant, or config key, or touches a shared base class, a performance-owned subsystem, the configuration layer (the owners listed in the Architecture owners table of docs/agent_memory/project-contracts.md), or a docs/agent_memory contract. Produces the design statement and placement decision required by the Engineering standards in the Agrippa core rules."
---

# Design first

The Engineering standards in the core rules require a design statement before the
first edit and a definition-of-done report at the end. This skill is the
procedure for producing both in this codebase. It applies whether or not the
change goes through a plan workspace.

The project's own owners are not named here. They are in
`docs/agent_memory/project-contracts.md`; read its "Ownership areas",
"Architecture owners", and "Shared and public interfaces" sections before step
1. A section named below is in that file unless another file is named.

## 1. Locate the change in the architecture

Answer these before reading more code than needed. Use `docs/agent_memory/`
first, then the `CLAUDE.md` in the subfolder you are about to edit.

1. **Which ownership area**, from "Ownership areas". A change that needs two
   areas is not a direct edit; say so and follow the planning trigger.
2. **Which layer**, from the rows of "Architecture owners":
   - **Configuration** -- a value that differs by mode, environment, or
     tuning belongs in the configuration layer and is read through the
     existing loaders. If a gitignored local override layer is applied after
     the defaults, it shadows them, so never "fix" a default by editing the
     override. The "Configuration layer" row names the default file, its
     loaders, and any override layer.
   - **Shared base class** -- holds behavior shared by every variant and
     exposes it through hooks. The "Shared base classes" row names them with
     their file paths.
   - **Variant subclass** -- holds behavior that exists in one variant (one
     mode, platform, or product) only. The "Variant subclasses" row names
     them.
   - **Native or performance-owned subsystem** -- owns a hot path.
     Higher-level code configures and reads it; it never reimplements it. The
     "Performance-owned subsystem" row names it and what it owns.
   - **Engine/service funnels** -- the shared engines, registries, and
     single entry points that every consumer goes through. The "Engines,
     services, and funnels" row names them by `file:symbol`.
3. **Which existing owner** already handles the closest thing. Grep for it.
   The answer is a `file:symbol`, not "nothing similar exists" unless you
   checked.
4. **Is this a new subsystem or a shared-interface change?** A new base
   class or class family, a kind the "New subsystem kinds" row lists, or a
   new ownership area is a new subsystem and runs `engineering:system-design`
   first. A change to a shared interface listed in "Shared and public
   interfaces" needs a decision record from `engineering:architecture` first.
   Both are saved under `docs/decisions/` before the first edit, in the shape
   `${CLAUDE_SKILL_DIR}/reference/decision-records.md` gives.

## 2. Decide placement with these rules

- **Shared by every variant** -> base class, exposed to subclasses through an
  existing virtual hook. The "Hooks per base class" row names the contract
  file that lists the hooks. Adding a hook is a shared-interface change and
  must be documented in that file.
- **One variant only** -> the subclass. Never `if mode == ...` in a base
  class.
- **Differs only by value** -> the configuration layer, not code. The
  "Configuration layer" row names a variant that shows how thin a value-only
  variant should be.
- **A new entry in a schema-driven list** -> one entry in the schema that
  every consumer iterates; never a parallel list. Bump the schema version if
  the persisted shape changes. The "Schema-driven lists" row names the lists
  and their version constants.
- **A new derived value or modifier** -> the engine that owns derived
  values, through its public API. Never write the underlying fields
  directly. The "Derived-value engines" row names the API and the fields it
  owns.
- **A new registered entity or renderer** -> through the existing
  registration funnel. The "Engines, services, and funnels" row names the
  funnels and what depends on them.
- **A value used by more than one consumer** -> one definition with one
  owner. Code copies are copies. The "Contract source" column of "Shared and
  public interfaces" names the file that owns each shared constant.
- **Per-hot-path work** -> multiplied by how often the hot path runs.
  Anything new on the hot path needs a cost estimate, and bulk work at a
  phase transition must be sliced under the existing time budget. The "Hot
  path" row names the hot path, its multiplier, and the budget.
- **A gated subsystem's state, geometry, or dispatch** -> must pass its gate
  on a fresh build. The "Gated subsystems" row names the subsystems and their
  gate targets, and "Build" in `docs/agent_memory/validation-commands.md`
  names the build step.

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
`docs/agent_memory/validation-commands.md`. Run its "Session setup" step once
per session before the first validation run.

## What this skill does not do

It does not replace a plan workspace when the planning trigger applies, and it
does not review the finished diff. Review is the `design-reviewer` agent's
job.
