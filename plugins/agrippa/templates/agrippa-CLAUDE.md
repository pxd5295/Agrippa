# .agrippa/ — canonical architecture contracts

This is the **stable-contracts** ownership area (root `AGENTS.md`). These
Markdown files are the repository's own source-of-truth memory. Code and plans
cite them; they must stay accurate.

The folder is hidden so that it never collides with the repository's own
`docs/`. Claude Code's Read, Glob, and Grep tools and `git grep` see it, but
command-line `rg` and most `find`-style tools skip hidden folders unless told
to look (`rg --hidden`). When a search for a contract name finds nothing,
check that the tool searched this folder before concluding that the fact is
unrecorded.

## The files

- `project-contracts.md` — ownership areas, architecture owners, shared
  interfaces, high-risk change classes, and environment boundaries.
- `validation-commands.md` — the **authoritative** command catalog; every plan
  copies exact commands, run caps, and determinism from here.
- [PROJECT: one bullet per further contract file, saying what it owns and
  whether it is authoritative for a frozen interface. Mark a superseded file
  as quarantined rather than deleting it.]
- `area-map.md` — an index of folders (entry points, covering tests,
  governing contract, recorded traps) that `/agrippa:survey` builds at a named
  commit. It is **not** a contract: nothing freezes against it, and a row is
  verified in the code before it is cited. [PROJECT: delete this bullet if
  the survey has not been run.]
- `[PROJECT: INSTALL.md or MIGRATION.md, whichever this repository has]` —
  the record of how this repository adopted or upgraded the methodology:
  the plugin version, every interview decision with how it was resolved, the
  optional features chosen, and the check results. A record, never edited
  afterwards, and never a contract source.

## Rules for editing

- **These are contracts, not scratch notes.** A wrong constant here silently
  poisons every plan that freezes it — the plan-workspace linter checks shape,
  never truth. When you change one, verify it against the code in the same pass
  (`git grep` the constant or signature) and update it; don't guess.
- **Match documentation to reality, both directions.** If the code changed,
  update the doc; if the doc is authoritative for a frozen interface, changing
  it means the interface itself changed — that is a shared-contract change
  requiring every consumer to move together, with a decision record in
  `.agrippa/decisions/`.
- **Preserve the frozen numbers exactly.** Do not casually round, reword, or
  re-derive a frozen value — copy it from the file that owns it.
- **Prefer dated, append-style additions** over rewriting history. Do not
  delete a section to save space; quarantine it if it becomes obsolete, and say
  in this file's list that it must not be cited.
- Keep `validation-commands.md` in sync with the test tree — a target must be
  registered there for a plan to cite it.
- A new hook, base-class API, funnel, or shared interface gets a paragraph in
  the relevant contract in the same change that adds it (the Engineering
  standards in the Agrippa core rules).

## Note on Claude's separate memory

Do not confuse this directory with Claude's per-user auto-memory under
`~/.claude/projects/.../memory/` (the `MEMORY.md` index). `.agrippa/`
is **checked-in repository documentation** shared by everyone working the
repo; the auto-memory is Claude's private cross-session notes.
