---
name: verify-before-done
description: Produce the evidence behind any claim that work is done, a test passes, a build succeeds, a bug is fixed, or performance held. Use before reporting a change as done, before a commit, before closing a plan stage, and whenever a subagent or validator reports success. Turns the definition of done in the Agrippa core rules into a concrete gate with the repo's own commands and known false-positive traps.
---

# Verify before done

No claim of success without a command run in this session whose output you
have read. The definition of done in the core rules lists six items; this skill
is the procedure for item one, the named validation, and for saying honestly
which of the other five you verified. Adapted from the
`verification-before-completion` skill in obra/superpowers, trimmed to this
repo's tooling.

## The gate

Run this before every positive status statement, including "fixed",
"passes", "builds", "no regression", and "done":

1. **Name the command that proves the claim.** Take it from
   `docs/agent_memory/validation-commands.md`, or from the plan's validation
   matrix when one exists. If no existing target covers the claim, say so;
   that is a finding, not a reason to skip.
2. **Run it fresh, in this session, on the current tree.** A result from
   before the last edit does not count. [PROJECT: any once-per-session setup
   step. Example from a Godot repo: run the class-cache prelude once per
   session before the first Godot target.] Run targets one at a time when
   they share a log or output file.
3. **Read the whole output.** Not the last line. Specifically:
   - Require a verdict line. [PROJECT: the verdict format. Example from a
     Godot repo: a `PASS` or `FAIL` line.] A run that exits 0 with no
     verdict is a failure. [PROJECT: how that happens in this toolchain.
     Example from a Godot repo: a runtime error inside `_ready()` itself
     means nothing ever calls `quit()`, and the frame cap exits 0.]
   - Grep for the runtime's error marker. [PROJECT: the marker and whether
     the harness enforces it. Example from a Godot repo: grep for
     `SCRIPT ERROR`; where the test reports through `TestReport.finish()`,
     this is enforced, and elsewhere do it by hand.]
   - Count the failures the output names. Compare against the known
     pre-existing red for that target, and prove "pre-existing" by running
     the same target at `HEAD` in a worktree or stash, not by recalling it.
   - Check that the run lasted long enough to mean anything. A frame or
     time cap may count something other than seconds. [PROJECT: the cap and
     its unit. Example from a Godot repo: `--quit-after` counts rendered
     frames; a cap of 60 is about a second.]
4. **Decide whether the output supports the claim.** If it does not, report
   the actual state with the output. If it does, make the claim and cite the
   command and result next to it.

Skipping a step and reporting anyway is false reporting, whatever the
intent.

## What each claim needs

| Claim | Evidence that counts |
|---|---|
| Test passes | The exact command, its verdict line, zero new failures, no runtime error marker in the output |
| Linter clean | [PROJECT: how the linter reports. Example from a Godot repo: the PostToolUse hook reports only changed lines; a full `gdlint` on the file is the whole-file answer.] A green linter is never evidence a contract is correct |
| Native builds | The build exits 0 for every configuration, and the running process was restarted before any test ran against the new build. [PROJECT: the build command and configurations. Example from a Godot repo: scons for both configs exits 0, and Godot was restarted before any test ran against the new DLL] |
| Gated change safe | The subsystem's gate passed on the fresh build. [PROJECT: the gated subsystems and gate targets. Example from a Godot repo: a native change is safe when the serial-versus-pool equivalence gate (`test_native_smoke.gd`, `test_threaded_tick_equivalence.tscn`) passed] |
| GPU path works | A run in an environment that has the GPU or display, because a headless or CI run may only ever exercise a CPU fallback. [PROJECT: the environment that exercises it. Example from a Godot repo: a windowed run, because `--headless` has no rendering device] |
| Bug fixed | The check that reproduced the original symptom now passes, and it was seen failing before the fix |
| No perf regression | A baseline and an after measurement from the same target, with the noisy-retry rule applied once at most and both outcomes recorded. [PROJECT: the authoritative measurement for production performance claims. Example from a Godot repo: for sim-speed claims, a perf recorder capture from a real windowed run] |
| Plan stage complete | Every Acceptance ID and required Validation ID passed, or the exact remaining gap is named |
| Subagent or validator reported success | You read its raw command output, or re-ran the target yourself. A summary from another agent is a claim, not evidence |
| Work complete | `git diff --stat` matches the intended edit sites and nothing else, and the six definition-of-done items are each marked verified or not |

## Where the evidence goes

Inside a plan workspace, append the command, outcome, retries, and any
unrelated failure to `EVIDENCE.md`, and keep `STATUS.md` to the gate state.
Outside a plan, put the command and outcome in the reply, in a fenced block,
next to the claim it supports. Distinguish an environment limit from a
regression every time. [PROJECT: the environment limits that recur here.
Example from a Godot repo: no Vulkan headless, missing gdtoolkit.]

## Stop signs

Rewrite the sentence, then go run the command, if you are about to write:

- "should work", "probably passes", "seems fine", "I'm confident".
- "The validator said it passed" without having read the output.
- "Tests pass" when only some of the named targets ran.
- "Done" when a named gate was not run. Say "not run" and why instead.
- Anything before a commit or a stage close that has not been through the
  gate on the current tree.

## What this skill does not do

It does not choose which targets a change needs; the plan's validation
matrix or the design statement does that. It does not make a red target
green by rerunning it. Correctness failures are never retried, and benchmark
retries follow the noisy-retry rule in
`docs/agent_memory/validation-commands.md`.
