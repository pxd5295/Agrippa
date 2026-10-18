# Evidence

> Cold, append-only evidence. Record command results, manual checks, routing
> outcome, retries, escalations, planning-cost observations, and exceptions.

## 2026-07-25 planning

- Source: user-supplied Planning Methodology v2.
- Planning cost proxy: one implementation task; four stages including integration.
- Historical workspaces were not rewritten.

## 2026-07-25 routing

- Wave 1 dispatched three concurrent writers only after the workspace linter
  passed 128 checks: M1 `terra_low_worker`, M2 `terra_low_worker`, and M3
  `terra_worker`.
- Ownership is disjoint by whole file and the lead retains the plan workspace.

## 2026-07-25 Wave 1 results

- M1 / `terra_low_worker`: verified 8 SceneTree scripts and 21 scene targets;
  V1 passed; documentation-only fixes retained explicit existing caps where
  present.
- M2 / `terra_low_worker`: no repair needed; 12 TOMLs parsed and the exact
  roster/short-context/scout assertions passed.
- M3 / `terra_worker`: compacted lifecycle and routing below 9,000 characters;
  V3 passed 128 workspace checks; workflow checker passed 185 checks with zero
  warnings at the stage boundary.

## 2026-07-25 runtime command proof

- Python initially lacked sandbox-visible pytest. After installing
  `requirements-dev.txt` outside the sandbox, `Set-Location neural_network;
  python -m pytest` passed 21 tests.
- Godot class-cache prelude exited 0.
- `test_brain_contract.gd` first exceeded a 120-second command timeout; the
  spawned processes were stopped. One verbose isolated retry exited 0 after
  215 seconds with `[BrainContractTest] PASS`.
- `test_threaded_tick_equivalence.tscn --quit-after 300` exited 0 with
  `[ThreadedTickEquivalenceTest] PASS`.
- The pytest-generated tracked bytecode was restored to its exact pre-test
  state; no runtime source changed.

## 2026-07-25 integration and review

- `terra_validator` ran V4 and V5 with no file ownership. The workflow checker
  passed 203 checks across 13 TOMLs with zero warnings; the dogfood linter
  passed 317 checks. Git status was unchanged by validation.
- Historical self-check: the known deferred-design performance plan failed
  with five Check 5 and five Check 8 findings. The planning-workflow-efficiency
  workspace produced no ownership or determinism-classification errors while
  still failing the expected missing-v2-schema gates.
- Focused `terra_reviewer` found packet/stage mapping, ownership-matrix
  reconciliation, roster-mapping, packet interface/reference, and Integration
  ownership gaps. All were repaired. The final re-review reported no
  actionable findings.
- Final `git diff --check` passed. Root instructions are 9,530 characters,
  lifecycle 8,946, and routing 8,976: all within their soft targets.
