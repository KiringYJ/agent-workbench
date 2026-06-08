# Project-Specific Agent Context

## Architecture

This repository is the source workbench for vendor-neutral AI-agent instructions. Shared guidance lives in `guide/`, profile composition lives in `profiles/`, consumer-facing templates live in `templates/`, prompt-driven workflows live in `prompts/`, portable Agent Skills live in `skills/`, and capability metadata plus vendor adapters live in `capabilities/`.

## Build Commands

No build step is required for the prompt/template repository.

## Test Commands

No automated test suite is currently required. For changes, verify by inspecting:

```bash
git status --short
git diff --stat
```

For prompt/template edits, also verify that `manifest.yaml` references existing files and that generated entrypoints remain thin.

## Important Files and Directories

- `manifest.yaml` — module, profile, and template registry.
- `guide/` — source modules for generated guides.
- `profiles/` — module selection profiles.
- `templates/` — files created in consumer projects.
- `prompts/` — LLM-executed sync, audit, repair, loop, guardrail, skill-authoring, and commit workflows.
- `skills/` — portable Agent Skills copied to consumer projects under `.agents/skills/`.
- `capabilities/` — canonical capability metadata, portability level, official-preferred notes, and thin vendor adapters.

## Domain Terms

- **Canonical guide**: `AI_AGENT_GUIDE.md`, generated from selected modules.
- **Project guide**: `AI_AGENT_PROJECT.md`, manually maintained by each project.
- **Thin entrypoint**: vendor-specific file that points to the canonical guides without duplicating them.
- **Profile**: YAML selection of modules for a language or project type.

## Workspace Configuration

This repository is the source workbench whose product is reusable agent guidance, templates, prompts, skills, and capability metadata. It intentionally tracks those source artifacts on `main`.

Consumer projects should use the `workspace-config` orphan branch design for local agent/editor workspace overlays unless they document a project-wide exception.

## Commit Message Requirements

All commits in this repository must use a Conventional Commit subject line and preserve the Lore trailer format for decision context.

Subject format:

```text
<type>[optional scope]: <intent-oriented summary>
```

Examples:

- `refactor: support vendor-neutral agent workbench`
- `docs: clarify prompt-driven sync workflow`
- `fix: preserve manual guide blocks during repair`

Use standard types such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, and `ci`. The subject should still explain the intent of the change, not just list touched files. For non-trivial commits, include useful Lore trailers such as `Constraint:`, `Rejected:`, `Confidence:`, `Scope-risk:`, `Directive:`, `Tested:`, and `Not-tested:`.

## Project-Specific Constraints

- Keep the architecture vendor-neutral.
- Do not make Claude Marketplace or plugins the primary distribution mechanism.
- Do not require global/user-scope configuration, git submodules, or machine-local paths.
- Preserve project-specific manual content during sync.
- Do not create `AGENT.md`; use `AGENTS.md`.
