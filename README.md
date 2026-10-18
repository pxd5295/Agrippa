# Agrippa

Agrippa is the home of a planning and implementation methodology for Claude
Code projects. It was developed inside the nuro-battler Godot project and
extracted here on 2026-10-18 so it can be developed on its own and installed
into other repositories.

Agrippa is being turned into a Claude Code plugin marketplace with one plugin,
`agrippa`. `docs/plugin-conversion-plan.md` describes the phases and their
status. Until that work is finished, a project still installs the kit by
copying `plugins/agrippa/` into it.

## Layout

| Path | What it is | Shipped to other repositories? |
|---|---|---|
| `.claude-plugin/marketplace.json` | The marketplace manifest. It lists the one plugin, `agrippa`. | Yes, as the marketplace a project adds. |
| `plugins/agrippa/` | The plugin and installable kit: templates, linter, install and upgrade prompts. Start with its `README.md`. | Yes, this folder is copied into a target repository. |
| `dev/` | The kit's self-check, `validate-kit.ps1`, and the smoke-test fixture in `fixtures/`. | No |
| `docs/design-notes.md` | Why the kit is shaped the way it is, and the linter rules that are easy to trip over. | No |
| `docs/research-2026-08.md` | The external research behind several rules, with sources. | No |
| `docs/plugin-conversion-plan.md` | The plan to turn Agrippa into a plugin marketplace. | No |
| `history/plans/` | Two plan workspaces from nuro-battler that built earlier versions of the methodology. They are read-only history. | No |

## Working on the kit

1. Change files under `plugins/agrippa/`.
2. Run the kit's self-check from this folder:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File dev/validate-kit.ps1
   ```

   It must print `PASS`. It checks file presence, required methodology
   clauses, leftover vocabulary from older toolchains, encoding, script
   parsing, and an end-to-end smoke test against a simulated install. It checks
   shape, never truth.
3. To check a repository that has the kit installed, add
   `-InstalledRepo <path>`. That repository's
   `tools/validate_plan_workspace.ps1` must match the kit's linter.
4. Upgrade each installed repository with the upgrade prompt in
   `plugins/agrippa/README.md`.

## Installed repositories

| Repository | Path from here | State on 2026-10-18 |
|---|---|---|
| nuro-battler | `../evolution-game/nuro-battler` | Installed. Runs the kit linter unchanged, with its Godot rules in `tools/validate_plan_workspace.local.ps1`; `validate-kit.ps1 -InstalledRepo` passes. |
