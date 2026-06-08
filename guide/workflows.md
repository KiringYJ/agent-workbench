# Portable Agent Workflows

Every synchronized project should carry the same core agent workflows regardless of which vendor agent is active. Treat these as portable capabilities, not Claude plugins, Codex-only skills, or Gemini-only extensions.

Use a hybrid strategy:

```text
canonical neutral capability
        -> thin vendor adapter or generated vendor surface
        -> optional official implementation, when available
```

The canonical capability is the source of truth. Vendor-native skills, commands, hooks, extensions, or plugins are accelerators and adapters; they must not become independently maintained copies of the workflow.

## Canonical Project-Local Locations

- `.agents/prompts/` stores reusable prompt workflows that any capable coding agent can read and execute.
- `.agents/skills/` stores portable Agent Skills using `SKILL.md` folders.
- `.agents/guardrails/` stores vendor-neutral guardrail rule documents.
- `capabilities/<name>/capability.yaml` records the portability level, canonical skill/prompt files, vendor outputs, and official-preferred fallbacks.
- `.agent-workbench.lock.json` records agent-owned sync provenance: source commit, manifest digest, scoped baselines, installed artifacts, and retained removals. Keep `.agent-workbench.yaml` as human-owned desired configuration.

Vendor-native discovery paths such as `.codex/skills/`, `.gemini/skills/`, `.claude/commands/`, `.gemini/commands/`, or hook config files may be generated as optional mirrors only when the project explicitly wants them. The canonical source remains under `.agents/`.

Claude Code is the main exception for skill discovery: when the Claude target is enabled, sync may generate project skills under `.claude/skills/<name>/SKILL.md` from the same canonical capability so Claude can discover them natively. These generated files are adapter surfaces, not new sources of truth.

## Portability Levels

- `portable-guide`: guidance belongs in `AI_AGENT_GUIDE.md`; no separate skill is required.
- `portable-skill`: a neutral `SKILL.md` expresses the workflow well across vendors.
- `vendor-adapted`: the concept is shared, but execution needs vendor-specific config, hooks, permissions, or commands.
- `official-preferred`: a vendor has a native implementation that should be used first when present; keep the neutral skill as fallback.

## Required Portable Capabilities

Each project should have these workflows available after sync:

| Capability | Canonical artifact | Replaces or abstracts |
| --- | --- | --- |
| Workbench sync and audit | `.agents/prompts/sync-agent-workbench.md`, `.agents/prompts/audit-agent-workbench.md`, `.agents/prompts/repair-agent-workbench.md`, `.agents/skills/sync-agent-workbench/SKILL.md` | `claude-md-management`, `claude-code-setup` |
| Loop until done | `.agents/prompts/loop-until-done.md`, `.agents/skills/loop-until-done/SKILL.md` | `ralph-loop` |
| Guardrail authoring | `.agents/prompts/create-guardrail.md`, `.agents/skills/guardrail-authoring/SKILL.md` | `hookify` |
| Skill authoring | `.agents/prompts/create-agent-skill.md`, `.agents/skills/skill-authoring/SKILL.md` | `skill-creator` |
| Commit workflow | `.agents/prompts/commit-workflow.md`, `.agents/skills/commit-workflow/SKILL.md` | `commit-commands` |
| Linus-style review | `.agents/prompts/linus-review.md`, `.agents/skills/linus-review/SKILL.md` | strict maintainer review mode |

## Portability Rules

- Treat install as the first sync. The same sync workflow should detect new, legacy/no-lockfile, and already-managed repositories.
- Use `.agent-workbench.lock.json` as a provenance/baseline ledger, not a package-manager lockfile. Use it with the current desired set to detect removed or deselected managed artifacts.
- Classify sync drift with explicit statuses: confirmed upstream removal, confirmed removal with local edits, suspected legacy removal, deselected by local config, source changed / migration required, and local unmanaged.
- Never delete generated downstream artifacts without explicit user confirmation. If a user keeps a removed artifact, record that decision in `retainedRemovals` so future syncs preserve context.
- Do not make a consumer project depend on a marketplace, global extension, user-scope config, or machine-local absolute path to get these workflows.
- Prefer a prompt or portable skill first unless the capability is marked `official-preferred` for the active vendor.
- Use vendor-specific hooks, slash commands, plugins, or extensions as generated adapters only.
- Keep the vendor-specific adapter thin: it should point to the `.agents/` prompt, skill, or guardrail instead of duplicating the workflow.
- Do not symlink skills for portability; copy managed skill folders when a vendor-specific mirror is required.
- Keep generated project workflows in English and project-local.
- Do not manually maintain four full copies of the same skill. Maintain one canonical capability plus small vendor adapters.

## When a Vendor Has a Native Equivalent

Native equivalents are allowed as accelerators, not as the source of truth:

- Codex: built-in `$skill-creator` and project/user skills can help author or consume Agent Skills.
- Gemini: Agent Skills and extensions can load skills, hooks, and commands; Ralph-style looping can be implemented with `AfterAgent` hooks.
- Claude Code: `CLAUDE.md`, custom commands, hooks, and plugins can adapt the same workflows.

If a native feature is missing, unstable, or disabled, execute the `.agents/prompts/*.md` workflow directly.
