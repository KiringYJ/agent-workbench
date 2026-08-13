# Repository-Tracked Workspace Configuration

Track reusable agent instructions, editor settings, prompts, and local automation in the repository's normal branch history. This is the required layout for agent-workbench managed artifacts: contributors should receive them with a normal clone, and `main` should contain the authoritative version.

Feature branches may update workspace configuration like any other project file. Review and merge those changes through the repository's normal workflow; do not maintain a separate configuration branch or worktree.

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

Additional workspace paths may also be tracked when they are useful to every contributor:

```text
.agent/
.cursor/
.vscode/
prompts/
scripts/
```

Classify optional paths before adding them. Shared extensions, tasks, prompts, and deterministic automation belong in the repository; personal UI preferences, caches, credentials, absolute machine paths, and local runtime state do not.

## Initial Setup

Create or synchronize the workspace files on the current normal development branch. Inspect the result before staging:

```bash
git status --short
git diff -- AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agent-workbench.lock.json .agents .codex .claude opencode.json
```

When the user requests a commit, stage only the reviewed project-wide paths:

```bash
git add AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agent-workbench.lock.json .agents .codex .claude opencode.json
git commit -m "chore: synchronize workspace configuration"
```

Do not stage optional editor or automation directories until they have been classified as project-wide and reviewed for secrets or machine-local state.

## Updating Workspace Configuration

Update managed files in the current working tree and review them alongside the project changes that require them. A normal clone, branch switch, merge, or rebase carries the configuration without a restore step or auxiliary worktree.

Before committing:

1. Inspect `git status --short` and the relevant diff.
2. Confirm managed files are not hidden by `.git/info/exclude` or `.gitignore`.
3. Preserve `AI_AGENT_PROJECT.md`, explicit manual blocks, and unregistered local workflows according to the sync contract.
4. Stage only the intended files.
5. Run the repository's documented validation.

## Forced Migration from the Retired Layout

The former `workspace-config` module identifier and orphan branch layout are not supported. Replace the module identifier with `repository-workspace`, then migrate any files held on a legacy branch by comparing and copying them into a clean normal branch. Do not merge unrelated branch histories wholesale.

```bash
git status --short
git fetch origin
git branch --all --list "*workspace-config*"
legacy_ref=origin/workspace-config
git ls-tree -r --name-only "$legacy_ref"
git restore --source="$legacy_ref" -- AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agent-workbench.lock.json .agents .codex .claude opencode.json
```

Update `.agent-workbench.yaml` so it selects `repository-workspace` and contains no `workspace-config` alias. Remove only the exact legacy entries that hide managed paths from `.git/info/exclude` or `.gitignore`, then inspect and stage the migrated files on the normal branch. Preserve any newer project-owned version after resolving differences file by file.

The old branch is no longer authoritative once the normal branch contains and verifies every intended file. Deleting local or remote legacy branches is a separate destructive cleanup and requires explicit authorization.

## Agent Rules

1. Treat shared workspace configuration as project-owned content in normal branch history.
2. Keep `main` authoritative; do not create or refresh a separate workspace configuration branch.
3. Do not hide managed project-wide paths in `.git/info/exclude` or `.gitignore`.
4. Preserve genuinely local files and never commit secrets, credentials, caches, or machine-specific state.
5. Show workspace changes in normal Git status and diff output.
6. Stage, commit, push, or delete a legacy branch only when the user requests the corresponding Git action.
7. When migrating legacy branch content, compare and copy intended paths rather than merging unrelated histories wholesale.
