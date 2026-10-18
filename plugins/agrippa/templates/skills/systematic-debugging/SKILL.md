---
name: systematic-debugging
description: "Find the root cause of a bug, failing test, crash, or performance regression in this repo before changing code. Use when a test fails, [PROJECT: the project-specific failure surfaces. Example from a Godot repo: a scene errors, the native worker or GPU path misbehaves, a sim capture shows a hitch], or a previous fix attempt did not hold. Produces a reproduction, a single hypothesis, and a fix at the owning site, and stops after three failed fixes."
---

# Systematic debugging

Find the cause before changing code. A fix applied to a symptom is not done,
and in this codebase it usually lands as a call-site special case that the
Engineering standards in `AGENTS.md` forbid. Follow the four phases in order.
Each phase ends with something written in the reply so the user can see the
chain of evidence.

Apply this even when the fix looks obvious, when the user is waiting, and
especially after one attempt has already failed. Adapted from the
`systematic-debugging` skill in obra/superpowers, trimmed to this repo's
tooling.

## 1. Establish what actually happened

1. **Read the whole output, not the verdict line.** A runtime can print
   errors, stack traces, and file:line for runtime errors, and the test
   harness can still print a passing verdict after one. Grep the output for
   the runtime's error marker before trusting any result. [PROJECT: the
   error marker to grep for and whether the harness enforces it. Example
   from a Godot repo: grep for `SCRIPT ERROR`; where a test reports through
   `TestReport.finish()`, that check is automatic, and older tests need it
   by hand.]
2. **Know the messages that mean something specific here.** [PROJECT:
   messages that mean something specific in this toolchain, one bullet
   each. Example from a Godot repo: `Could not find base class` means the
   class-name cache is stale; run the cache prelude from
   `docs/agent_memory/validation-commands.md` and retry before reading
   anything else into it. `Nonexistent function 'new' in base 'GDScript'`
   means a script up the preload chain failed to parse, so the error is in
   a different file from the one named.] Some messages are expected in a
   headless or CI environment: a run without a GPU or display may fall back
   to a CPU path, so a headless run may never exercise the GPU path.
   [PROJECT: the expected headless messages. Example from a Godot repo:
   `no local RenderingDevice` or `GPU compute unavailable` is expected under
   `--headless`.]
3. **Reproduce it on one named target.** Use the exact invocation from
   `docs/agent_memory/validation-commands.md`. [PROJECT: the invocation
   forms for each kind of target. Example from a Godot repo: `-s` for
   `extends SceneTree` scripts, a rendered-frame cap for scenes.] A frame or
   time cap may count something other than seconds, so a run that "passed
   for 90 seconds" may have run for one. [PROJECT: the cap and its unit.
   Example from a Godot repo: `--quit-after N` counts frames, not seconds.]
   Run targets one at a time when they share a log or output file.
   [PROJECT: the shared log path. Example from a Godot repo: every run
   writes the same `user://logs/godot.log`.] If it does not reproduce,
   gather more output; do not start guessing.
4. **Check what changed.** `git diff` and `git status` first. Then the ways
   a change hides:
   - A gitignored local override layer applied after the defaults can
     silently shadow a default you changed. [PROJECT: the override layer.
     Example from a Godot repo: `user_properties.cfg` is applied after
     `default_properties.cfg`.]
   - A native change needs a rebuild and a restart of the running process
     before the tests mean anything. [PROJECT: the rebuild and restart
     steps. Example from a Godot repo: a scons rebuild of both configs and a
     Godot restart before the running DLL reflects it.]
   - A file moved without the companion files the toolchain tracks with it,
     or a rename the tooling did not see. [PROJECT: companion files and
     rename traps. Example from a Godot repo: a `.gd` or `.tscn` moved
     without its `.uid` sidecar, or a rename made outside the editor without
     reopening the project.]
   - A file in a sibling worktree that is not on this branch. [PROJECT: where
     worktrees live. Example: `.claude/worktrees/`.]
5. **Localize across layers.** Use the boundaries the repo already has: an
   equivalence or comparison check at a layer boundary tells you which side
   is wrong, and a temporary probe that prints state at a boundary is
   cheaper than reasoning about it. Delete probes afterwards. [PROJECT: the
   layers of the failing path in order, the boundary checks, and the probe
   naming convention. Example from a Godot repo: the tick path is GDScript
   world and animal code, then `NuroMovementWorker` in `native/`, then the
   GPU brain and vision shaders; the serial-versus-pool equivalence gate
   (`tests/test_native_smoke.gd`, `tests/test_threaded_tick_equivalence.tscn`)
   tells you whether the native worker agrees with itself; probes are
   `tests/_probe_*.gd`.]
6. **For performance problems, a measurement from a real production-like
   run is the evidence.** Headless benchmarks are secondary diagnostics and
   may not see GPU cost at all. [PROJECT: the authoritative performance
   evidence. Example from a Godot repo: the perf recorder capture from a
   real windowed run.] Name the section or counter that moved before
   proposing a cause.

## 2. Compare against the working case

1. Find the closest thing that works: [PROJECT: the usual working
   counterparts. Example from a Godot repo: the other mode's subclass, the
   other entity type through the same funnel], the same test on `HEAD`. Use
   a worktree or `git stash` to run the failing target at `HEAD` when you
   need to prove a failure is pre-existing. Record which it is.
2. Read the working path completely, not the first screen of it.
3. List every difference between the working and failing paths, including
   configuration values, ordering, and lifecycle state. [PROJECT: kinds of
   difference that have mattered here before. Example from a Godot repo:
   spawn order, and whether the object was in the tree when a setter ran.]
   Known traps of that kind are recorded in `docs/agent_memory/`; check
   there before assuming a difference cannot matter.

## 3. One hypothesis, one change

1. Write the hypothesis in the reply as one sentence: what causes the
   symptom and why.
2. Make the smallest change that tests it. One variable at a time. Do not
   stack a second change on an untested first one.
3. Run the same target as in phase 1 and read the full output again. If the
   hypothesis was wrong, say so, and form a new one from the new evidence.
   Do not leave the failed change in place while trying the next.
4. If you do not understand a piece of the path, say which piece. Do not
   describe it as if you did.

## 4. Fix at the owner

1. Before the fix, have a check that fails for the original symptom: an
   existing test target, a new assertion in one, or a one-off probe. The
   check must fail before the fix and pass after it, and you must have run
   both.
2. Place the fix with the rules in `.claude/skills/design-first/SKILL.md`.
   A bug found at a call site is usually owned by a base class, a hook, an
   engine, a funnel, or the configuration layer. [PROJECT: the usual owners
   by name. Example from a Godot repo: the stat engine, the static-entity
   funnel, the cfg layer.] Fix the owner. Do not add a conditional at the
   call site to route around it.
3. One fix per change. No incidental improvements, and no bundled refactor
   beyond the refactor-or-file rule in `AGENTS.md`.
4. Verify with `verify-before-done` before reporting. A fix touching a gated
   subsystem is not done until its gate has run on a fresh build. [PROJECT:
   the gated subsystems and their gates. Example from a Godot repo: a fix
   touching native state, geometry, or dispatch is not done until the
   equivalence gate has run on a fresh build.]
5. **After three failed fixes, stop.** Three failures on the same symptom
   mean the problem is structural, which in this repo means the planning
   trigger applies. Write down what the three attempts showed, and either
   create a plan workspace or ask the user, rather than attempting a fourth
   fix.

## Stop signs

Any of these thoughts means going back to phase 1:

- "Just try changing X and see."
- "It's probably the config, let me fix that first."
- "I'll change these three things and run the suite."
- "I'll check it manually instead of writing the probe."
- "One more attempt" after two failures.
- Each fix reveals a new problem in a different file.

## What this skill does not do

It does not replace the design statement for the fix itself; that still
comes from `design-first`. It does not decide whether a failing benchmark is
environmental noise; the noisy-retry rule in
`docs/agent_memory/validation-commands.md` does, and a correctness failure
is never retried into green.
