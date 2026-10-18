---
description: Write a short handoff file so the next session can resume without reading this one
argument-hint: [output path, default plans/handoff-YYYY-MM-DD-<slug>.md]
---

Write a handoff file for the next session, from the conversation you already
have in context. Do not re-read files to compile it and do not search the
repository; if a fact is not already in this session, leave it out and link to
where it lives instead.

Output path: `$ARGUMENTS` if given, otherwise
`plans/handoff-<YYYY-MM-DD>-<short-slug>.md`.

## Size rule

Under 300 words. Count words, not lines -- a long wrapped line is not cheaper
than two short ones. Every line is either a fact or a path. A handoff that
needs scrolling has failed.

Link, never restate. If something is in `SPEC.md`, `PLAN.md`, `STATUS.md`,
`EVIDENCE.md`, a `docs/agent_memory/` contract, a decision record, or a commit,
cite the path or SHA and write nothing else about it.

Leave out entirely: what happened in what order, errors that were fixed, and
anything the next session would rediscover in one command. Abandoned approaches
are left out too, except the few that clear the bar in "Ruled out" below.

## Template

```
# Handoff <date> -- <goal in one line>

State: <what is true now, 1-2 sentences>
Verified: `<exact command>` -> <verdict line>
Not verified: <what was skipped> | pre-existing red at HEAD: <tests>
Uncommitted: <paths, or "git status">
Decisions not in code yet: <choice> -- <one-sentence why>
Ruled out: <approach> -- <the observation that killed it>
Next: <one concrete action>
Refs: <plan workspace, contract paths, commit SHAs>

More context (only if the above is not enough):
- Transcript: <path>.jsonl (<size>) -- SEARCH it, never read it whole
- Search: the session-transcript search tool if available, or
  `grep -n '<term>' <path>` / `Select-String -Path <path> -Pattern '<term>'`
- <other session transcripts relevant to this thread, if any>

Resume prompt: Read <this file>. Before touching anything, tell me what you
think the state is and what you plan to do. Then: <next action>.
```

## Filling the context links

Resolve this session's transcript path as
`~/.claude/projects/<project-dir-slug>/<session-id>.jsonl`. The
`<project-dir-slug>` is the repo's absolute path with every path separator
and the drive colon replaced by `-`; for example `C:\Users\me\src\app`
becomes `C--Users-me-src-app`, and `/home/me/src/app` becomes
`-home-me-src-app`. Take `<session-id>` from the scratchpad directory name in
your environment if one is available. If not, use the most recently modified
`.jsonl` in that directory. Report its size, so the next session can see the
cost of reading it and search instead.

Name a term or two worth searching for -- a function name, a test name, a
measured number -- so the next session can jump straight to the exchange it
needs.

## Ruled out

At most three lines, and only for approaches a competent person would try next.
The test is: would the next session, knowing only the rest of this handoff,
plausibly spend a turn on this? If not, leave it out -- this section is not a
diary of everything that failed.

Each line names the approach and the observation that killed it, not a verdict.
"Caching the parsed config -- parsing measured 0.4 ms of a 120 ms request, so
it is not the cost" is useful. "Caching does not help" is not, because the
next session cannot tell whether that still holds after its own changes.

Include a conclusion here even when it overturned an earlier one, and say so.
Projects overturn their own findings, and a handoff that silently drops the
correction invites the old answer straight back.

## Verification honesty

The `Verified` line carries the exact command and its verdict, never a
paraphrase. Anything claimed but not run this session belongs in `Not verified`,
and the known pre-existing red at `HEAD` is carried forward every time so the
next session does not have to re-establish it.

After writing the file, print the resume prompt in the reply so it can be
copied straight into the next session.
