# Claude Code Notes

Claude Code can load files from `CLAUDE.md` with `@AI_AGENT_GUIDE.md` and `@AI_AGENT_PROJECT.md` references. In this workbench, `CLAUDE.md` is intentionally thin and should not duplicate the canonical guide.

Claude Code discovers project skills under `.claude/skills/`, not the shared `.agents/skills/` path. When the Claude target is enabled, mirror each registered canonical skill directory into `.claude/skills/` without changing its contents. Treat the mirror as generated output.

Do not require Claude Marketplace, Claude plugins, or user-scope Claude settings for a consumer project to receive the guide. Those mechanisms may exist as optional legacy tooling, but they are not the primary distribution path.
