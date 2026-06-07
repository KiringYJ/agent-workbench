# Base Agent Guide

## Purpose

This guide is the vendor-neutral baseline for AI agents working in a project. It applies to Claude Code, Codex, Gemini, OpenCode, and any other agent that can read repository files.

The canonical generated file in a consumer project is `AI_AGENT_GUIDE.md`. Vendor files such as `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` should only load or point to that guide and to `AI_AGENT_PROJECT.md`.

## Language Policy

All artifacts committed to a repository must be written in English: code, comments, documentation, commit messages, configuration, and generated examples. Conversation with a user may use any language, but repository content should stay in English unless the project explicitly documents a different policy in `AI_AGENT_PROJECT.md`.

## Operating Principles

- Prefer evidence over assumption; inspect files and run verification before claiming completion.
- Use the smallest reversible change that solves the real problem.
- Prefer current stable stacks, toolchains, runtimes, language standards, and project scaffolding for new work or upgrades unless project constraints require an older version.
- Preserve existing user behavior, public APIs, CLI flags, configuration formats, and machine-readable output unless the user explicitly requests a breaking change.
- Keep diffs focused and bisectable.
- Reuse existing project patterns before adding new abstractions.
- Prefer pragmatic, justified correctness over "it just worked" fixes; every solution should have a clear causal explanation and verification evidence.
- Do not add dependencies, services, code generators, plugins, marketplace entries, or global configuration without an explicit project decision.
- Treat project-local instructions as authoritative over generic guidance when they conflict.

## Standard Work Loop

1. Read the relevant instructions: `AI_AGENT_GUIDE.md` and `AI_AGENT_PROJECT.md` if present.
2. Understand the task and inspect the current implementation before editing.
3. For bug fixes or incident-style problems, identify the root cause with evidence before designing the solution. Test or justify the observation, rule out plausible alternatives, and do not present a root-cause fix unless confidence is complete; otherwise keep diagnosing or label the remaining uncertainty.
4. For non-trivial work, state or internally maintain a short plan: files to change, verification to run, and risks.
5. Make the minimal change.
6. Run the documented verification commands from `AI_AGENT_PROJECT.md` when available.
7. Review the diff for accidental edits, secrets, generated noise, and stale documentation.
8. Report changed files, verification evidence, and any remaining risks.

## Naming and Structure

- Use domain-specific names. Avoid vague containers such as `utils`, `helpers`, `common`, or `shared` unless the project already uses them intentionally.
- Spell names out. Avoid abbreviations unless they are standard in the language or domain.
- Source modules represent concepts and should usually use singular names.
- Data or collection directories that hold many peer files may use plural names.
- Prefer simple, explicit control flow and early returns over deeply nested conditions.
- Avoid hard-coded paths, variables, and constants. If a value appears repeatedly, is environment-specific, is arbitrary rather than canonical, or may change later, promote it to a named constant, configuration value, or documented boundary owned by the project.

## Output and Logging

Keep machine output and human diagnostics separate.

- Standard output is for command results or generated data.
- Standard error or the language logging framework is for progress, diagnostics, warnings, and errors.
- Library or domain code should not use raw print statements for status messages.
- Performance claims require measurements or profiling evidence.

## Dependency and External API Discipline

Before adopting or changing a dependency or SDK:

- Consult version-specific official documentation when possible.
- Prefer the latest stable supported release and toolchain compatible with the project; avoid obsolete stacks unless a documented constraint requires them.
- Confirm return values, error behavior, and edge cases with a minimal reproduction or test.
- Pin versions according to the project language ecosystem.
- Add or update integration tests when behavior crosses a boundary.
- Document the reason for the dependency if it is not obvious.

## Documentation Discipline

Update documentation when behavior, commands, configuration, public APIs, file layout, or onboarding instructions change. Stale documentation is a defect.

Treat `README.md` as user-facing product documentation. Keep it focused on what the project does, who it is for, how to install or use it, common workflows, troubleshooting, and support. Move maintainer-only architecture, exhaustive file trees, internal sync mechanics, and implementation notes into dedicated maintainer docs such as `CONTRIBUTING.md`, `ARCHITECTURE.md`, or `AI_AGENT_PROJECT.md` unless a README reader explicitly needs them.
