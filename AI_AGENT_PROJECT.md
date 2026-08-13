# Project-Specific Agent Context

## Architecture

This repository is the source workbench for composable, vendor-neutral AI-agent policy. Shared guidance lives in `guide/`, profile composition lives in `profiles/`, consumer-facing loader templates live in `templates/`, supporting workflows live in `prompts/`, and canonical portable Agent Skills live in `skills/`. Standard skills are registered directly in `manifest.yaml`; only real vendor discovery or configuration boundaries receive a shim.

## Build Commands

No build step is required for the prompt/template repository.

## Test Commands

Run the contract suite with Ruby and Python 3.11 or newer; it uses only their standard libraries:

```bash
ruby -Itest test/contracts_test.rb
git diff --check
git status --short
git diff --stat
```

The suite verifies manifest paths, profile inheritance, generated-guide parity, thin entrypoints, portable skill frontmatter, executable v1 lockfile migration, exact managed-resource mirrors, and core sync safety contracts.

## Important Files and Directories

- `manifest.yaml` — direct registry for modules, profiles, templates, prompts, and skills.
- `guide/` — source modules for generated guides.
- `profiles/` — module selection profiles.
- `templates/` — files created in consumer projects.
- `prompts/` — LLM-executed sync, audit, repair, loop, guardrail, skill-authoring, and commit workflows.
- `skills/` — portable Agent Skills copied to consumer projects under `.agents/skills/`.
- `skills/sync-agent-workbench/scripts/` — dependency-free migration and managed-skill mirror verification helpers distributed with the sync skill.
- `test/contracts_test.rb` — dependency-free structural and behavior contracts for profiles, generated artifacts, skills, and sync policy.

## Domain Terms

- **Canonical guide**: `AI_AGENT_GUIDE.md`, generated from selected modules.
- **Project guide**: `AI_AGENT_PROJECT.md`, manually maintained by each project.
- **Thin entrypoint**: vendor-specific file that points to the canonical guides without duplicating them.
- **Discovery mirror**: byte-identical generated copies of a standard skill's registered managed files placed in a vendor-required discovery path.
- **Profile**: YAML selection of modules for a language or project type.

## Workspace Configuration

This repository is the source workbench whose product is reusable agent guidance, profiles, templates, prompts, and standard Agent Skills. It tracks source artifacts and shared agent/editor workspace configuration in normal branch history.

Consumer projects should also track agent-workbench managed files on their ordinary development branches so `main` is the single source of truth. Personal settings, caches, secrets, and machine-local state remain untracked.

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
