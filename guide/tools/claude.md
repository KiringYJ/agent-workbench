# Claude Code Notes

Claude Code can load files from `CLAUDE.md` with `@AI_AGENT_GUIDE.md` and `@AI_AGENT_PROJECT.md` references. In this workbench, `CLAUDE.md` is intentionally thin and should not duplicate the canonical guide.

Claude Code v2.1.277 and later can also read `AGENTS.md` directly, but by default only when no `CLAUDE.md` or `CLAUDE.local.md` exists, and the workbench `AGENTS.md` asks agents in prose to read the guide instead of importing it. Keep the generated `CLAUDE.md` so every Claude Code version and instruction-file setting loads the guide.

Claude Code discovers project skills under `.claude/skills/` and does not load instructions or discover skills from `.agents/`. When the Claude target is enabled, mirror each registered canonical skill directory into `.claude/skills/` without changing its contents. Treat the mirror as generated output.

The Claude routing binding is `.claude/rules/agent-routing.md`, which Claude Code loads at session start. It has one subagent per workload tier in `.claude/agents/`, because the Agent tool accepts a per-call model but not a per-call effort level.

Do not require Claude Marketplace, Claude plugins, or user-scope Claude settings for a consumer project to receive the guide. Those mechanisms may exist as optional legacy tooling, but they are not the primary distribution path.
