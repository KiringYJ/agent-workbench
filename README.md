# agent-workbench

`agent-workbench` reproducibly assembles AI coding-agent policy for different kinds of projects from reusable modules and composable profiles.

It publishes one shared guide and standard Agent Skills for Claude Code, Codex, Gemini, OpenCode, and other agents, with only the small loader or discovery shims each runtime actually needs.

> Historical note: this repository may still appear as `claude-workbench` in some checkouts, but the project is now vendor-neutral.

## What it gives your project

A sync creates a small set of agent instruction files in your project:

- `AI_AGENT_GUIDE.md` — shared generated guidance for agents.
- `AI_AGENT_PROJECT.md` — your manually maintained project-specific notes.
- `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` — thin entrypoints for vendor tools.
- Project-scoped prompts and canonical Agent Skills under `.agents/`.
- Generated `.claude/skills/` discovery mirrors when the Claude target is enabled; Codex, Gemini, and OpenCode use `.agents/skills/` directly.
- `.agent-workbench.lock.json` — an agent-owned provenance ledger that records the last successful sync baseline.

By default, those files are repository-tracked project configuration. Keep them in normal branch history so a clone receives the complete workspace and `main` remains the single source of truth for both product code and shared agent/editor setup.

It does **not** require marketplace installs, global configuration, git submodules, plugins, or machine-local paths.

The base profile incorporates OpenAI's [GPT-6 Astra prompting guidance](https://developers.openai.com/api/docs/guides/latest-model/gpt-6-astra.md#prompting-best-practices), checked on 2026-09-05: complete authorized work, resolve instruction conflicts, communicate clearly, delegate useful independent work, and calibrate verification to the change. The canonical guidance remains vendor-neutral; model-specific settings stay in vendor configuration.

## Quick start

Open your target project in an AI coding agent, then ask it to run the sync prompt:

```text
Follow the agent-workbench sync prompt at:
https://raw.githubusercontent.com/KiringYJ/agent-workbench/main/prompts/sync-agent-workbench.md

Run a full sync. Inspect the project and choose the most appropriate available profile.
If .agent-workbench.yaml already specifies a profile, keep using it.
Track agent/editor workspace files in normal branch history so they are included on `main`.
Do not modify application source code.
Do not install dependencies, plugins, marketplaces, global config, or submodules.
```

The agent will choose from these profiles based on the project:

| Profile | Use when |
| --- | --- |
| `base` | You want general agent guidance without language-specific rules. |
| `research` | You need rigorous, source-backed research with explicit evidence, citation, uncertainty, and reproducibility standards. |
| `tex` | You work on TeX/LaTeX manuscripts and want the `research` profile plus source, bibliography, compile, log, and render checks. |
| `rust` | The project is primarily Rust. |
| `python` | The project is primarily Python. |
| `typescript` | The project is primarily TypeScript or JavaScript. |
| `frontend` | The project is a TypeScript/JavaScript browser UI and needs component, accessibility, responsive-input, service, and visual-verification guidance. |
| `vue` | The frontend uses Vue 3 and needs Vue-specific component, reactivity, lifecycle, and verification guidance without assuming a UI library. |
| `vue-vuetify` | The project uses Vue 3 and Vuetify and needs Vuetify-first, theme-aware, exact-version component guidance, including active use of `vuetify-mcp` when available. |

`research` extends `base`, and `tex` extends `research`. The language profiles extend `base`; `frontend` extends `typescript`, `vue` extends `frontend`, and `vue-vuetify` extends `vue`.

Profiles are convenience compositions of independently registered modules. A non-Vue browser UI can select `frontend`, a Vue project without Vuetify can select `vue`, and only a project that actually uses Vuetify should select `vue-vuetify` or explicitly add the `frameworks/vuetify` module in `.agent-workbench.yaml`.

Install is the first sync: the same workflow creates missing files, writes `.agent-workbench.yaml` as human-owned desired configuration, and writes `.agent-workbench.lock.json` as the agent-owned sync baseline. After the first sync, fill in `AI_AGENT_PROJECT.md` with your project's architecture, build commands, test commands, important files, domain terms, and project-specific constraints.

## Common tasks

### Update an already-synced project

```text
Follow the agent-workbench sync prompt at:
https://raw.githubusercontent.com/KiringYJ/agent-workbench/main/prompts/sync-agent-workbench.md

Run a full sync using the existing .agent-workbench.yaml profile.
Preserve AI_AGENT_PROJECT.md and marked manual blocks.
Use .agent-workbench.lock.json to detect upstream-removed managed artifacts and ask before deleting anything.
Do not modify application source code.
```

### Audit without changing files

```text
Follow the agent-workbench audit prompt at:
https://raw.githubusercontent.com/KiringYJ/agent-workbench/main/prompts/audit-agent-workbench.md

Audit this repository for agent-workbench compliance.
Do not modify files.
```

### Repair missing or malformed instruction files

```text
Follow the agent-workbench repair prompt at:
https://raw.githubusercontent.com/KiringYJ/agent-workbench/main/prompts/repair-agent-workbench.md

Repair missing or malformed agent instruction files.
Preserve project-specific content.
Do not modify application source code.
```

## What sync is allowed to change

Sync is intentionally narrow. It may update agent instruction files, project-scoped agent configuration, `.agent-workbench.lock.json`, and registered portable workflows. It must not change application source code, dependencies, global/user configuration, marketplace/plugin installation state, or git submodules.

In Git repositories, sync should keep managed workspace paths visible to normal Git status and version them, including `.agent-workbench.lock.json`, in the repository's ordinary branch history. It should remove exact stale ignore entries left by the retired orphan-branch workflow, especially entries in `.git/info/exclude`, but it must not stage, commit, or push unless the user requested that Git action.

`AI_AGENT_PROJECT.md` is created if missing, but after that it belongs to your project and should be edited by hand. Sync may report **confirmed upstream removal**, **confirmed removal with local edits**, **suspected legacy removal**, **deselected by local config**, **source changed / migration required**, or **local unmanaged** findings. It must ask before deleting downstream artifacts and should record kept obsolete artifacts in `retainedRemovals`.

## For maintainers of this repository

Most users do not need the repository internals. If you are changing the workbench itself, start with:

- `AI_AGENT_PROJECT.md` for project architecture and verification expectations.
- `manifest.yaml` for registered modules, profiles, templates, prompts, and skills.
- `guide/`, `profiles/`, `templates/`, `prompts/`, and `skills/` for the source content used by sync.

Verify changes with Ruby and Python 3.11 or newer; no third-party packages are required. The contract suite includes fixture-driven v1 ledger migration and managed-skill mirror checks:

```bash
ruby -Itest test/contracts_test.rb
git diff --check
git status --short
git diff --stat
```

## License

MIT
