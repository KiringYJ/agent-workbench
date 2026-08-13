# Codex and General Agent Notes

Codex and many general agents read `AGENTS.md`. Do not rely on `@` imports in `AGENTS.md`; instead, instruct the agent to read `AI_AGENT_GUIDE.md` and `AI_AGENT_PROJECT.md` directly.

Codex discovers project Agent Skills under `.agents/skills/`. Keep optional Codex skill metadata inside the canonical skill directory instead of creating a duplicate `.codex/skills/` tree.

Optional Codex configuration belongs in project-scoped `.codex/config.toml`. Do not depend on user-scope Codex configuration or machine-local paths.

Keep `AGENTS.md` thin. The canonical policy belongs in `AI_AGENT_GUIDE.md`.
