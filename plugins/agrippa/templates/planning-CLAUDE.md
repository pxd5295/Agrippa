# docs/planning/

The routing guide and the plan-workspace templates ship with the `agrippa`
plugin's `plan` skill, not in this folder. Load `agrippa:plan` to read them,
and never keep a local copy: the plugin's linter parses the plugin's
templates, so a copy here drifts from the linter that checks plans.

- `MIGRATION.md`, when present, records how this repository adopted or
  upgraded the methodology. It is history; do not edit its decisions.
