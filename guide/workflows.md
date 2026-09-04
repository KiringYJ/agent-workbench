# Portable Agent Workflows

Every synchronized project should carry the same core workflows regardless of which coding agent is active. Use the Agent Skills standard directly instead of describing each workflow again through a capability registry or per-vendor adapter files.

## Canonical Project-Local Locations

- `.agents/prompts/` stores supporting prompt workflows that any capable coding agent can read and execute.
- `.agents/skills/` stores the canonical project copies of portable Agent Skills, including optional `scripts/`, `references/`, and `assets/` resources.
- `.agents/guardrails/` stores vendor-neutral guardrail documents.
- `.agent-workbench.lock.json` records sync provenance, scoped baselines, installed artifacts, and retained removals. Keep `.agent-workbench.yaml` as human-owned desired configuration.

`manifest.yaml` registers prompts and skills directly. Do not introduce a second registry that repeats their paths, portability labels, vendor targets, or fallback behavior.

## Vendor Discovery Boundary

Codex, Gemini CLI, OpenCode, and other compatible agents should discover the shared `.agents/skills/` tree directly.

Claude Code uses `.claude/skills/` for project skill discovery. When the Claude target is enabled, sync should copy the registered managed source/resource set for each canonical skill from `.agents/skills/<name>/` to `.claude/skills/<name>/` without appending adapter prose or changing its resources. Corresponding managed files must be byte-identical; unregistered local files remain preserved only in `.agents/skills/`. The Claude copy is a generated discovery mirror, not another source of truth. Use real copied files rather than symlinks so synchronized repositories behave consistently on Windows and other environments.

Do not generate `.codex/skills/`, `.gemini/skills/`, or `.opencode/skills/` mirrors by default. Create a vendor-specific file only when it encodes actual runtime behavior that the shared standard cannot express, such as loader configuration, permissions, hooks, invocation controls, or vendor metadata.

## Required Portable Workflows

| Workflow | Canonical artifacts |
| --- | --- |
| Workbench sync and audit | `.agents/prompts/sync-agent-workbench.md`, `.agents/prompts/audit-agent-workbench.md`, `.agents/prompts/repair-agent-workbench.md`, `.agents/skills/sync-agent-workbench/SKILL.md` |
| Loop until done | `.agents/prompts/loop-until-done.md`, `.agents/skills/loop-until-done/SKILL.md` |
| Guardrail authoring | `.agents/prompts/create-guardrail.md`, `.agents/skills/guardrail-authoring/SKILL.md` |
| Skill authoring | `.agents/prompts/create-agent-skill.md`, `.agents/skills/skill-authoring/SKILL.md` |
| Commit workflow | `.agents/prompts/commit-workflow.md`, `.agents/skills/commit-workflow/SKILL.md` |
| Linus-style review | `.agents/prompts/linus-review.md`, `.agents/skills/linus-review/SKILL.md` |
| Read a linked ChatGPT conversation | `.agents/skills/read-chatgpt-conversation/SKILL.md` |

## Portability Rules

- Treat install as the first sync. The same workflow should detect new, legacy/no-lockfile, and already-managed repositories.
- Use `.agent-workbench.lock.json` as a provenance/baseline ledger, not a package-manager lockfile.
- Classify sync drift as confirmed upstream removal, confirmed removal with local edits, suspected legacy removal, deselected by local config, source changed / migration required, or local unmanaged.
- Never delete downstream artifacts without explicit user confirmation. Record a decision to retain an obsolete managed artifact in `retainedRemovals`.
- Keep skills within the standard `SKILL.md` format unless an explicit target requires an extension.
- Prefer a compatible built-in or installed implementation when the active environment provides one, but keep the portable skill available as the project-owned fallback.
- Store any vendor preference or fallback rule once in the canonical skill or supporting prompt, not in four parallel adapter notes.
- Do not make a consumer project depend on a marketplace, plugin, extension, global configuration, submodule, or machine-local path.
- Keep generated workflows in English and project-local.

If a native feature is missing, unstable, or disabled, execute the canonical `.agents/skills/` or `.agents/prompts/` workflow directly.
