# Agrippa Install Record

This file records how this repository adopted the Agrippa planning
methodology: which plugin version, what the install interview decided and how
each decision was resolved, which optional features were chosen, and what the
install-time checks found. It is a record: never edit its decisions
afterwards. An upgrade writes its own record, `MIGRATION.md`, beside it.

## Scope and date

- Date: [PROJECT: YYYY-MM-DD]
- Plugin version: [PROJECT: the `agrippa` plugin version and the marketplace
  `ref` pinned in `.claude/settings.json`, or "unpinned local directory" while
  the marketplace points at a checkout]
- Installed by: [PROJECT: the model and the Claude Code surface, for example
  "Claude Opus 5.5 in the desktop app"]
- Dirty user-owned files preserved: [PROJECT: paths from `git status` at the
  start, or None]

## Interview decisions

One row per install-time slot the templates asked for, including the ones
inspection settled without a question. `Resolved by` is `inspection` (the code
or configuration answered it; say what was read), `user` (a person answered it;
the documents mark such facts `per maintainer`), or `default` (the user chose
to proceed on the recommendations, or declined to answer, and the recommended
option was taken).

| Topic | Decision | Resolved by | Rationale |
|---|---|---|---|
| [PROJECT: the slot, for example "Ownership areas"] | [PROJECT: what was decided] | [PROJECT: inspection / user / default] | [PROJECT: the evidence read, or the tradeoff the user accepted] |

## Optional features

| Feature | Chosen | Where it is recorded |
|---|---|---|
| Area map (`/agrippa:survey`) | [PROJECT: yes / no] | `.agrippa/area-map.md` |
| Spawn logger (`AGRIPPA_SPAWN_LOG`) | [PROJECT: yes / no] | `.claude/settings.json` `env` and `.gitignore` |
| Low-usage mode (`AGRIPPA_LOW_USAGE`) | [PROJECT: yes / no] | `.claude/settings.json` `env` |
| Edit-lint hook | [PROJECT: yes / no, and the script path when yes] | `.claude/settings.json` `hooks` and `tools/` |
| `engineering` plugin | [PROJECT: yes / no] | `.claude/settings.json` `enabledPlugins` |
| Permission allowlist | [PROJECT: yes / no] | `.claude/settings.json` `permissions.allow` |
| Local linter checks | [PROJECT: yes / no, and why] | `tools/validate_plan_workspace.local.pl` |

## Validation results

| Check | Result | Notes |
|---|---|---|
| Install-marker scan | [PROJECT: 0 hits / list] | [PROJECT: the command run] |
| Settings file parses, declares the marketplace, enables the plugin | [PROJECT: Pass / Fail] | [PROJECT: the `ref`, or "unpinned" with the reason] |
| No plugin file copied into the repository | [PROJECT: Pass / Fail] | [PROJECT: details] |
| Validation catalog commands run once | [PROJECT: Pass / Fail] | [PROJECT: each command and its result, or where they are recorded] |
| Throwaway plan linted with `agrippa-lint` | [PROJECT: Pass / Fail / Not run] | [PROJECT: details, or "Perl is not installed"] |
| Installed-repository check (`node dev/validate-kit.mjs -InstalledRepo .` from an Agrippa checkout) | [PROJECT: Pass / Fail / Not run] | [PROJECT: details] |
| Smoke test (`node dev/fixtures/run-smoke-test.mjs -RepoRoot .` from an Agrippa checkout) | [PROJECT: Pass / Fail / Not run] | [PROJECT: details] |

## Live checks pending

- First real "Make a plan" request: [PROJECT: Pending, or the plan workspace
  that completed it and the date]
- Known red targets at `HEAD` when installed: [PROJECT: the targets and the
  date, or None]
