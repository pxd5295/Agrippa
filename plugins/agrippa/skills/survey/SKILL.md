---
name: survey
description: Survey the repository's folders and write or refresh .agrippa/area-map.md, the on-demand index of entry points, covering tests, governing contracts, and recorded traps that planning reads first. Read-only discovery; it changes no application code and writes no other file. Run it only when the user explicitly asks, by typing /agrippa:survey or by asking to survey or map this repository for Agrippa; never load it on your own initiative.
argument-hint: "[folder to refresh, default the whole repository]"
---

# Survey the repository into an area map

This skill writes one project document, `.agrippa/area-map.md`, from
the template `${CLAUDE_PLUGIN_ROOT}/templates/AREA-MAP.md`. The map is read on
demand, by the planner and by `agrippa:repo-scout` before a census, and never
at session start. It adds nothing to the always-loaded files: the one
independent study of instruction files found more cost and no gain, so the
knowledge layer grows here, where it is read only when a plan needs it, and
only as far as the evidence in plan workspaces shows it helps.

Surveying authorizes one document write. Never change application code, never
write a per-directory `CLAUDE.md` (the install decides those, one per area
with real rules), never edit `.agrippa/project-rules.md`, and preserve every unrelated user
change, including uncommitted ones.

## 1. Check the ground

Run `git rev-parse --show-toplevel` and work from that folder. If it is not a
git repository, stop and say so. If `.agrippa/project-contracts.md`
is missing, stop and recommend `/agrippa:install`: the map's "Ownership area"
column comes from that file's "Ownership areas" section.

Record `git rev-parse --short HEAD`; it becomes the map's `Built at` commit.
If the worktree is dirty, say so and survey the committed tree, because the
`Built at` commit must describe what the rows describe.

## 2. Read what exists, read-only

- The template, completely, and the README's placeholder convention.
- The existing `.agrippa/area-map.md`, if any, and its `Built at`
  commit. When the skill argument names a folder, or the map exists, this is a
  refresh (step 4); otherwise a full survey (step 3).
- "Ownership areas" and "Contract documents" in `project-contracts.md`, and
  "Full-suite inventory" in `validation-commands.md`, which names the test
  targets a row may cite.
- Every per-directory `CLAUDE.md`, every record in `.agrippa/decisions/`, and the
  `EVIDENCE.md` of recent plan workspaces, for recorded traps. Dated plan
  workspaces are read, never edited.

## 3. Discover, read-only

Change nothing in this step. For each folder in `git ls-files`, decide its
depth: a folder gets its own row when its ownership area, its entry points, or
its covering tests differ from its parent's; otherwise it folds into the
parent's row. Then record, with evidence:

- **Entry points.** The symbols the rest of the code imports, calls, or
  registers through: public classes and functions, registration points, main
  files, the funnels the "Architecture owners" table names. Each is a
  `file:symbol` you have opened. For a language with a language server, use
  `LSP` for definitions and references before `Grep`.
- **Covering tests.** Every test file or inventory target that references a
  file in the folder, found by searching the folder's file stems and module
  names across the test tree. `None` when the search finds nothing.
- **Contract.** The `.agrippa/` document that governs the folder, or
  `None`.
- **Traps.** Only what step 2 found recorded, each with the observation that
  revealed it and where it is recorded. Never infer a trap from reading code.
- **Not mapped.** Generated, vendored, build-output, and data folders, each
  with the reason.

You may delegate the discovery of large areas to `agrippa:repo-scout`, which
is read-only, and keep only its sourced conclusions.

## 4. Refresh instead of rebuilding

When the map exists, run `git diff --name-only <Built at> -- .` (or the named
folder). Re-survey only the rows whose folders have changes, keep every other
row, and keep every trap unless its recording is shown to be gone. Set
`Built at` to the current commit. If the recorded commit is not in this
history, say so and do a full survey.

## 5. Write the map

Fill every install-time slot from step 3 and follow the README's
placeholder convention: delete a slot with its row or bullet when the subject
does not exist, write `None` only where the slot offers it, and keep every
section heading. Delete every `Install note` comment once its section is
filled. Cells hold paths, `file:symbol` entries, and short phrases; a rule
belongs in the folder's `CLAUDE.md` or in `.agrippa/project-rules.md`, never
here.

The planner and `repo-scout` read the whole file before a census, so keep it
under about 8,000 characters by folding subfolders into their parents, never by
dropping a recorded trap. Record a justified exception in the plan's
`EVIDENCE.md` when the map must be larger.

Do not add the map to the "Contract documents" table of
`project-contracts.md`. The agents treat that table as the source of truth for
shared interfaces, and the map is an index that goes stale; its rows point at
the sources and are never themselves a `Contract source:`.

## 6. Validate

Run each check and paste the exact command and its result.

- Every path in "Folders" and "Not mapped" exists in `git ls-files`.
- Every `file:symbol` resolves: the symbol is defined in that file.
- Every covering test is a file that exists or a target registered in the
  "Full-suite inventory".
- `Built at` is the short hash of the commit the rows describe.
- The README's install-marker scan over `.agrippa/area-map.md` finds
  nothing.

## 7. Report

List the rows written, the folders not mapped and why, the traps recorded with
their sources, and any folder you could not resolve. Then ask with
`AskUserQuestion` whether to commit the map in one commit; write nothing else
and commit nothing without a yes.

Say how the map is judged: every plan that consults it appends an `area map`
entry to its `EVIDENCE.md`, saying which rows were used, which were stale, and
whether they saved a wider read or misled. After a few plans those entries say
whether to keep the map, refresh it more often, or drop it, and they are the
condition for any larger knowledge layer.
