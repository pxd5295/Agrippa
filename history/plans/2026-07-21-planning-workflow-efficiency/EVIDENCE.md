# Planning Workflow Efficiency Evidence

> Cold append-only evidence for this plan. Workers should not read this file
> unless their stage packet names a specific entry. `STATUS.md` owns the hot
> handoff state.

## Baseline measurements

| Artifact | Approximate size | Observation |
|---|---:|---|
| Root `AGENTS.md` | 25,283 characters / about 6,300 estimated tokens | Automatically repeated context is the largest durable-instruction target |
| `docs/agent-workflow.md` | 21,660 characters / about 5,400 estimated tokens | Substantially duplicates root guidance |
| Recent complete plan workspace | 41,925 characters / about 10,500 estimated tokens | `STATUS.md` alone reached about 3,500 estimated tokens |
| Project active allocation | Project config pins Sol High for every task | Non-planning work cannot naturally preserve an arbitrary user-selected model/effort |
| Agent concurrency | Four threads, depth one | Appropriate ceiling; not a target to increase |

Token estimates use characters divided by four only for comparative planning;
they are not billing measurements.

## Planning interview evidence

| Decision area | Resolved outcome |
|---|---|
| Planner quality | Start every plan with Sol High |
| Downgrade | Only after Sol High completes inspection and interview and proves low risk |
| High entry | Ordinary-language planning pauses for a Sol-High switch without relying on a special planning mode |
| Non-planning allocation | Remove project lead-model/effort pins | Preserve any model and reasoning effort the user selects outside planning |
| Context | Thin root instructions, on-demand detailed guide, inline stage packets |
| State | Hot `STATUS.md`, cold `EVIDENCE.md` |
| Execution | Conservative automatic parallelism, maximum two writers |
| Validation/review | Targeted then full once; one risk-triggered reviewer |
| Luna | Allowed only with very high orchestrator confidence and exact mechanical gates |
| Migration | Future plans only |

## Routing outcomes

| Stage | Planned allocation | Actual allocation | Escalations/retries | Result |
|---|---|---|---|---|
| Planning | Sol High | Unverified runtime; policy selected by user | None | Complete |
| M1 | Sol Medium | User-confirmed Sol Medium active lead | None | Complete |
| M2 + M3 | Two Terra Medium workers | Two parallel `terra_worker` agents | None | Complete |
| M4 | Sol Medium | Sol Medium active lead | Two script repair attempts | Complete |
| Integration/review | Sol Medium + Terra Medium reviewer | Sol Medium lead + `terra_reviewer` | None | Complete; no findings |

## Validation evidence

| Check | Result | Notes |
|---|---|---|
| Targeted repository inspection | Pass | Confirmed High/High defaults, full-workspace reads in Terra/Sol profiles, verbose templates, and four-thread/depth-one configuration |
| Relevant architecture memory | Not applicable | `docs/agent_memory/` contains Godot/runtime contracts, not Codex workflow contracts |
| Historical workspace preservation | Pass at planning time | Only this new dated plan directory was created |
| M1 project TOML parse | Pass | All eight `.codex` TOML files parsed with `tomllib` |
| M1 active lead allocation audit | Pass | `.codex/config.toml` has no project-level model or reasoning-effort pin |
| M1 root instruction budget | Pass | 8,203 characters, about 2,051 estimated tokens; target about 10,000 characters |
| M1 detailed guide budget | Pass | 13,854 characters, about 3,464 estimated tokens; target about 14,000 characters |
| M1 routing contract scan | Pass | Sol-High entry, post-interview downgrade, worker override, two-writer cap, and on-demand guide are present |
| M1 scoped `git diff --check` | Pass | No whitespace errors in `AGENTS.md`, workflow guide, or project config |
| M2 artifact contract scan | Pass | Stable Acceptance IDs, one Validation ID matrix, hot status, cold evidence, soft budgets, and selective reads are present |
| M2 scoped `git diff --check` | Pass | No whitespace errors in templates or `plans/README.md` |
| M3 agent profile TOML parse | Pass | All seven custom agent profiles parsed with `tomllib` |
| M3 full-workspace-read audit | Pass | No profile instructs a complete SPEC/PLAN/STATUS or assigned-workspace reread |
| M3 scoped `git diff --check` | Pass | No whitespace errors in custom agent profiles |
| M4 workflow checker | Pass | 111 invariant checks, eight TOML files parsed, zero soft-budget warnings |
| M4 bounded repairs | Pass | Corrected PowerShell variable interpolation and line-wrapped regex handling, then reran successfully |
| Integration workflow checker | Pass | 111 invariant checks, eight TOML files, zero soft-budget warnings |
| Independent TOML parse | Pass | Python `tomllib` parsed all eight project TOML files |
| Scoped formatting | Pass | `git diff --check` and a separate trailing-whitespace scan found no errors |
| Historical workspace preservation | Pass | Audit excludes the active workspace and matches dated plan directories only; no historical path changed |
| Focused Terra review | Pass | No actionable defects; residual live-routing smoke-test risk recorded below |

## Acceptance closure

| Acceptance IDs | Result | Evidence |
|---|---|---|
| A1-A4 | Pass | Project allocation pins removed; High-entry/downgrade and thin-root contracts pass checker scenarios and budgets |
| A5-A6 | Pass | Future templates implement hot/cold artifacts and all worker/reviewer profiles require compact inline packets |
| A7-A9 | Pass | Two-writer safety, pre-launch worker override, and conservative Luna gates pass checker scenarios |
| A10-A12 | Pass | Targeted/full validation, focused review topology, offline checker, and historical audit all pass |

## Residual validation risk

- The deterministic checker validates repository configuration, text, schema,
  and prompt-scenario invariants. It cannot simulate the desktop model selector
  or live agent dispatch, so the next real planning request and
  `Implement plan use workers` execution serve as manual smoke tests.
- The V7 command was corrected during integration to match only dated plan
  workspace paths. This prevents the intentionally maintained
  `plans/README.md` from being treated as historical content.

## Budget exceptions

- This bootstrap plan has about 5,650 estimated hot tokens across `SPEC.md`,
  `PLAN.md`, and `STATUS.md`, slightly above the proposed routine-plan target.
  It was produced under the current verbose milestone contract and specifies
  the workflow that will make later plans smaller; its cold `EVIDENCE.md` is
  excluded from the hot-context target by design.
