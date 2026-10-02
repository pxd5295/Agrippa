# docs/planning/ — routing guide & plan-workspace templates

`ROUTING.md` owns topology, tier selection, packets, waves, ownership, launch,
and review; read it directly rather than a summary of it. `templates/` holds the
blank `SPEC.md` / `PLAN.md` / `PACKETS.md` / `STATUS.md` / `EVIDENCE.md` that are
**copied** into each new `plans/YYYY-MM-DD-<name>/`, never edited per-plan.

Two things are not stated in `ROUTING.md` itself:

- **Editing a template changes all future plans**, not existing ones. Keep the
  `A#`/`V#`/`C#` id conventions and the section shape
  `tools/validate_plan_workspace.ps1` parses — templates are the contract that
  linter checks against, and a template change must be mirrored there.
- `MIGRATION.md`, when present, records how this repository adopted or
  upgraded the methodology. It is history; do not edit its decisions.
