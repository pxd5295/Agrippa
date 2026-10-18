---
name: receiving-review
description: Act on review findings from the design-reviewer or plan-reviewer agents, /code-review, or the user without either arguing them away or applying them blindly. Use when a review comes back on a diff you own, before editing anything in response. Produces a per-finding disposition that matches the Blocking/Optional and Design rules in the Agrippa core rules and ROUTING.md.
---

# Receiving review

Verify each finding against the code before acting on it, and answer with
the change or a technical reason, not with agreement. Adapted from the
`receiving-code-review` skill in obra/superpowers, fitted to this repo's
reviewer roles.

Reviews here come from four places, and the rules for what must be fixed
differ:

- `design-reviewer` reports `Design` findings against the Engineering
  standards. The core rules say these are fixed before the change is reported
  done.
- `plan-reviewer` and `/code-review` classify findings as `Blocking` or
  `Optional`. `ROUTING.md` in the `agrippa:plan` skill says the lead does
  not act on `Optional` findings to close a review, and a finding that cannot
  be bound to correctness, a contract ID, or an acceptance ID is `Optional`
  by definition.
- The user's own comments take precedence over every reviewer and over this
  skill. If you raised a concern and the user reaffirmed the request,
  proceed as asked and say that you are.

## Procedure

1. **Read the whole review before touching anything.** Do not start fixing
   the first finding while the last one is unread; findings often overlap,
   and one correct fix at the owner can close several.
2. **Restate each finding in one sentence** in the reply, with its class
   (`Blocking`, `Optional`, or `Design`) and the file it names. If a finding
   is unclear, collect every unclear one and ask about all of them at once.
   For a subagent reviewer, continue the same agent with `SendMessage` so
   it keeps its context; do not spawn a fresh reviewer to re-explain.
3. **Verify against the tree, not against the review.** Open the cited
   `file:line`, grep for the identifiers the reviewer claims are
   duplicated, and read the contract it cites in `docs/agent_memory/`.
   Reviewers work from the diff and can miss the configuration layer, a hook
   that already exists, or a sibling worktree.
4. **Decide per finding:**
   - **Fix** when the finding holds. Place the fix with `design-first`, one
     finding at a time, and run the affected validation target after each
     fix rather than after the batch, so a fix that breaks something is
     attributable.
   - **Push back** when the fix would add a mode or variant branch to a base
     class, add abstraction or defensive code for a case the frozen
     contracts exclude, contradict a decision record under `docs/decisions/`,
     break a named acceptance ID, or rests on a misreading of the code. State
     the reason with the `file:line` or contract path that shows it. A
     pushback without a citation is a guess.
   - **File** when the finding is real but lies outside the diff or the
     ownership area, or would exceed the roughly-50-line refactor-or-file
     rule in the core rules. Name it as a separate task in the reply.
   - **Decline without action** for `Optional` findings you are not taking.
     Say so in one line each; do not silently drop them and do not pad the
     diff with them.
5. **Report the disposition** as a list: one line per finding, the class,
   the action taken, and for fixes the validation command and outcome from
   `verify-before-done`.

## How to write the response

- For a fix: "Fixed. " followed by what changed. No thanks, no praise of the
  finding. The diff shows the finding was heard.
- For a pushback: the technical reason and the citation. No apology and no
  hedging, and no restating the finding as if it might still apply.
- Never "You're absolutely right" or "Great catch". Never agree with a
  finding you have not verified.
- A review with zero blocking findings is a valid result. Accept it and move
  on. Do not look for extra work to make the review feel thorough.

## What this skill does not do

It does not decide whether a review is needed at all; the size floor and the
review topology in the core rules and `ROUTING.md` in `agrippa:plan` do. It
does not close a plan stage; that still requires every acceptance and validation ID
through `verify-before-done`.
