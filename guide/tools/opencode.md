# OpenCode Notes

OpenCode can explicitly load instruction files with `opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "instructions": [
    "AI_AGENT_GUIDE.md",
    "AI_AGENT_PROJECT.md"
  ]
}
```

If a project already has `opencode.json`, merge the two instruction paths into the existing configuration and preserve unrelated settings.

OpenCode discovers project Agent Skills under `.agents/skills/`. Do not create a separate `.opencode/skills/` mirror solely for discovery.
