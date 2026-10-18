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
| `LICENSE`, `NOTICE` | The Apache-2.0 license and the attribution notice. Copies of both are inside `plugins/agrippa/`, so they travel with the plugin. | Yes, the copies in the plugin folder |

## Working on the kit

1. Change files under `plugins/agrippa/`.
2. Run the kit's self-check from this folder:

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File dev/validate-kit.ps1
   ```

   It must print `PASS`. It checks the plugin layout, that `plugin.json` and
   `marketplace.json` carry the same version, agent and skill frontmatter and
   their `agrippa:` names, that no `[PROJECT: ...]` slot appears outside the
   project-side templates, the size of the core rules, required methodology
   clauses, leftover vocabulary from older toolchains, encoding, script
   parsing, that the two copies of `LICENSE` and of `NOTICE` are identical,
   and an end-to-end smoke test against a simulated project that has no copy
   of the linter. It checks shape, never truth.
3. To check a project that uses the plugin, add `-InstalledRepo <path>`. The
   project's committed `.claude/settings.json` must declare the `agrippa`
   marketplace and enable `agrippa@agrippa`. It must have
   `docs/agent_memory/project-contracts.md` and
   `docs/agent_memory/validation-commands.md`. It must keep no local copy of
   the plugin's agents, its skills, the shared linter
   (`tools/validate_plan_workspace.ps1`), or the spawn-logger scripts. Each
   failure is printed as an `INSTALLED REPO:` line that names the file or
   setting and says what to do.
4. Upgrade each installed repository with the upgrade prompt in
   `plugins/agrippa/README.md`.

## Installed repositories

| Repository | Path from here | State on 2026-10-18 |
|---|---|---|
| nuro-battler | `../evolution-game/nuro-battler` | Installed from the G3 kit, with its Godot rules in `tools/validate_plan_workspace.local.ps1`. It still has local copies of the agents, kit skills, `/handoff`, linter, and spawn logger, and does not yet enable the plugin, so `validate-kit.ps1 -InstalledRepo` fails with 17 migration items until Phase 8 of the plugin plan migrates it. The plugin linter gives the same results on its plans. |

## License

Agrippa is licensed under the Apache License, Version 2.0. See `LICENSE`.

Anyone may use, modify, and redistribute it, including commercially. A
redistributed copy must include the license and the attribution in `NOTICE`.
Any file someone modifies must say that it was changed. Section 6 of the
license gives no permission to use the name Agrippa, except to describe
where the work came from. So a modified version may say that it is based on
Agrippa, but the license does not let it call itself Agrippa.

The two copies of `LICENSE` and of `NOTICE`, at the repository root and in
`plugins/agrippa/`, must stay identical.
