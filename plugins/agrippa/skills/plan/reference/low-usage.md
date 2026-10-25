# Low-usage mode

Load this file only when the core rules say low-usage mode is on. It is a
reference file of the `agrippa:plan` skill. The project turned the mode on
with `AGRIPPA_LOW_USAGE=1` in the `env` block of `.claude/settings.json`, for
token limits that the normal methodology would exhaust. The mode replaces
seven rules with cheaper ones and changes nothing else. Every floor still
holds: the design statement, the definition of done, the consumer census and
covering tests, `Frozen` or `Bounded-choice` only, the decision record for a
shared-interface change, the linter before handoff, the `verify-before-done`
gate, and the full applicable suite once at Integration. The lead's own model
and reasoning effort stay the user's.

The normal column is the rule as the named file states it; this file lists
only what replaces it, so a normal session is never affected by this file.

| Rule | Normal, in the file that owns it | Low-usage mode |
|---|---|---|
| Design-reviewer size floor | Skip the pass below about 30 changed lines (core rules, "Size floor") | Skip the pass below about 80 changed lines. A base class, a shared interface, or the performance-owned subsystem always gets the pass, whatever the line count. |
| Reviewer self-escalation | `design-reviewer` and `plan-reviewer` escalate themselves to Opus when the question needs deeper analysis (their last paragraphs) | Neither reviewer escalates. Each names the question it could not settle at its tier, and the lead decides whether to pay for a second pass. |
| Opus row of the tier table | A risk-flagged bounded stage routes to `opus` after a recorded split attempt (`ROUTING.md`, "Model-tier routing table") | It routes to `sonnet` at high effort, with the escalation trigger written in the stage record. `opus` is only the ceiling, after a failed bounded repair. |
| Spawn reasoning effort | The harness default; escalate low, medium, high before escalating the model (`ROUTING.md`) | Every spawn starts at `low` effort and escalates only after a failed validation. |
| Concurrent writers | Two by default, three behind the listed gates (`ROUTING.md`, "Waves and parallelism") | One. Every wave is sequential, and the plan's cost multiplier is `Sequential`. |
| One-writer planning | Skip the workspace only for a one-sentence diff in one area; full shape across areas or for a shared-interface change (core rules, "Planning trigger"; `agent-workflow.md`, "Workspace shape") | Skip the workspace when one writer in one ownership area can do the work with no shared-interface change and deterministic validation, whatever the file count; say so and offer one. Use the single-stage shape whenever one sequential writer suffices, even across areas, with every area in the ownership matrix. |
| Read depth and the scout | Four rungs with one bounded follow-up read; `repo-scout` only when a census would dominate the turn (core rules, "Planner read ladder"; `agent-workflow.md`, "Inspect narrowly") | Rungs 1 to 3 and no follow-up read. A decision that reading could settle but the rungs did not is carried as a `Bounded-choice` whose change observation is the skipped read, which the stage that owns the code performs. It is never put to the user, and its `SPEC.md` row is `Resolved by: default` with the deferred read named in the rationale. Delegate any census over about 20 call sites, or any file over about 800 lines, to `repo-scout`. |

## Record what the mode changed

`STATUS.md` says `Low-usage mode: on`. Append one `EVIDENCE.md` entry each
time the mode changed a decision: a review pass skipped under the 80-line
floor, a stage routed to Sonnet that the table would have sent to Opus, a
workspace skipped under the wider gate, a read deferred into a
`Bounded-choice`. Those entries, with the `Resolved by: default` rows, are how
the mode is judged. A rule whose entries show up in repair waves leaves the
mode in a later release.
