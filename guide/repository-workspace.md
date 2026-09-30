# Repository-Tracked Workspace Configuration

Track shared agent instructions, editor settings, prompts, and automation in normal repository history so a normal clone receives them. Update them like other project files; do not maintain a separate configuration branch or worktree.

## Core Invariant

`main` is the source of truth for shared workspace configuration.

Project-wide workspace files must not be hidden through `.git/info/exclude` or broad project `.gitignore` rules. Keep only genuinely personal, machine-local, generated, cached, or secret-bearing files untracked.

## What Belongs in the Repository

Core agent-workbench files are shared project policy and should be tracked:

```text
AI_AGENT_GUIDE.md
AI_AGENT_PROJECT.md
AGENTS.md
CLAUDE.md
GEMINI.md
.agent-workbench.yaml
.agent-workbench.lock.json
.agents/
.codex/
.claude/
opencode.json
```

Other workspace paths may be tracked when useful to every contributor:

```text
.agent/
.cursor/
.vscode/
prompts/
scripts/
```

Classify optional paths before adding them. Keep personal preferences, caches, credentials, absolute machine paths, and local runtime state untracked. For Claude Code, that includes `CLAUDE.local.md`, `.claude/settings.local.json`, and `.claude/worktrees/`.

## Initial Setup

Create or synchronize workspace files on the current development branch. Inspect the managed diff before any requested Git action:

```bash
git status --short
git diff -- AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agent-workbench.lock.json .agents .codex .claude opencode.json
```

Follow `Git and Change Management` for staging and commits. Do not stage optional editor or automation paths until they are classified as project-wide and reviewed for secrets or machine-local state.

## Updating Workspace Configuration

Update managed files in the current working tree. Preserve `AI_AGENT_PROJECT.md`, explicit manual blocks, and unregistered local workflows; confirm managed paths remain visible to Git, then use the canonical Git and validation rules.

## Forced Migration from the Retired Layout

The retired `workspace-config` identifier and orphan branch layout are unsupported. Follow `.agents/prompts/sync-agent-workbench.md` for the evidence-driven migration when that distributed prompt is present; otherwise use the upstream sync prompt. Select `repository-workspace`, compare intended paths file by file, preserve newer project-owned content, and never merge unrelated histories wholesale.

The old branch ceases to be authoritative only after every intended file is present and verified on the normal branch. Stage, commit, push, or delete a legacy branch only when the user requests that exact Git action; branch deletion remains a separate destructive cleanup.
