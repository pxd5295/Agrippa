# Methodology research, August 2026

On 2026-08-30 a deep-research run audited the methodology against 22 sources
and 24 verified claims. A follow-up on 2026-08-31 filled the report's "no
source found" gaps. The full report is a private artifact:
https://claude.ai/code/artifact/ebdf1459-e2eb-480d-bef3-3518301fe7df

These decisions came from external evidence rather than from code, so git
history alone does not explain them.

## Applied on 2026-08-30

- The planning size gate and the single-stage workspace shape (`AGENTS.md`,
  `agent-workflow.md`).
- The fork-or-fresh subagent section (`ROUTING.md`).
- The plan-reviewer's Blocking/Optional rule.
- The validator agent defaults to `sonnet`.
- Both guides trimmed under 9,000 characters. They have since grown back past
  that soft target, which `validate-kit.mjs` reports as a warning.

## Applied on 2026-08-31

- **The three-writer gate requires a stated cost multiplier.** It no longer
  cites "material wall-clock benefit"; it requires a stated, accepted
  token-cost multiplier (`ROUTING.md` waves section, the PLAN template's
  `Cost multiplier` bullet). Source: STORM (arXiv 2605.20563), which found
  cost grows linearly per writer, wall-clock time stays flat, and a single
  agent is cheapest per success.
- **Frozen contracts carry `Covering tests:`.** These are the tests and scenes
  that reference the owned files, found with `rg` during planning and copied
  into the packet's validation block. Linter check 26 warns when the line is
  absent and errors when a listed path is missing. Source: TDAD (arXiv
  2603.17973), where a targeted test map cut regressions from 6.08% to 1.82%,
  while TDD procedure text without a map made them worse (9.94%).

## Still open

- There is no data on how often full-shape packets turn out to be incomplete.
  A `packet gap` entry kind in `EVIDENCE.md` was suggested to collect it.
- The only independent study of instruction files (ETH, arXiv 2602.11988)
  found more than 20% extra cost and no gain in success rate. This is an
  unresolved bet, so keep the always-loaded pair (the root `CLAUDE.md` and
  the `.agrippa/project-rules.md` it imports, the root `AGENTS.md` before
  release 0.5.0) lean. On 2026-10-24 the on-demand area map (`/agrippa:survey`) became the
  experiment for this: each plan that consults it records an `area map` entry
  in `EVIDENCE.md`, and those entries are the data for whether a larger
  knowledge layer is worth building (`docs/design-notes.md`).
- The two-writer wave has never been timed sequentially against in parallel.

## Sourcing correction

The original report called the worktree and file-ownership rules unsourced.
They are the vendor's own guidance: cite
https://code.claude.com/docs/en/agent-teams ("Avoid file conflicts") and
https://code.claude.com/docs/en/worktrees rather than calling them a local
convention.
