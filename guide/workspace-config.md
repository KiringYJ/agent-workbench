# Workspace Configuration Orphan Branch

Use a dedicated orphan Git branch named `workspace-config` for reproducible local workspace overlays such as agent instructions, editor settings, prompts, and local automation. This keeps product branches clean while still versioning the files an agent or developer needs to recreate the same workspace.

Recommended repository shape:

```text
same project repo
├─ main                # clean product branch
├─ dev                 # clean integration branch
├─ feature/*           # normal product work
└─ workspace-config    # orphan workspace overlay branch, never merged
```

## Core Invariant

`workspace-config` must never be merged, rebased, or cherry-picked wholesale into `main`, `dev`, or product feature branches.

Product branches must not track workspace-only files. Workspace files may physically exist in a normal product worktree, but they must stay ignored locally through `.git/info/exclude`, not through project `.gitignore`, unless the project explicitly decides those paths are project-wide policy.

## What Belongs in `workspace-config`

The branch is for reproducible local development setup, not product source code. Core agent-workbench overlay files include:

```text
AI_AGENT_GUIDE.md
AI_AGENT_PROJECT.md
AGENTS.md
CLAUDE.md
GEMINI.md
.agent-workbench.yaml
.agents/
.codex/
.claude/
opencode.json
```

Additional local workspace paths may also belong on `workspace-config` when they are not project-owned:

```text
.agent/
.cursor/
.vscode/
prompts/
scripts/
```

Exceptions are allowed only when a file is intentionally part of the project for all contributors. For example, a repository may choose to track `.vscode/extensions.json`, `prompts/`, or `scripts/` on `main`; if so, document that exception in `AI_AGENT_PROJECT.md`.

## What Belongs on Product Branches

`main`, `dev`, and `feature/*` should contain product source code, product documentation, tests, and configuration required by the actual application or library.

They should not track local workspace overlays such as agent prompts, editor workspaces, local automation, or vendor-specific AI-agent files unless the project explicitly promotes that file into project policy.

## Initial Setup

Create the orphan branch from the repository root:

```bash
git status --short
git switch --orphan workspace-config
git rm -rf .
```

Start only from a clean product worktree. If `git status --short` shows changes, preserve or commit them before switching branches.

Create or restore the workspace files, then commit them:

```bash
git add AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agents .codex .claude opencode.json
git commit -m "chore: add workspace config overlay"
git push -u origin workspace-config
```

Add optional workspace-only paths such as `.cursor/`, `.vscode/`, `prompts/`, or `scripts/` only after confirming they are not product-owned.

Return to product development:

```bash
git switch main
```

If the branch was previously named `agent-config`, rename it:

```bash
git switch agent-config
git branch -m workspace-config
git push origin :agent-config
git push -u origin workspace-config
```

## Local Excludes on Product Branches

In the normal product worktree, add workspace-overlay paths to `.git/info/exclude`. Use local excludes instead of `.gitignore` because this is local workspace policy, not necessarily product policy.

Bash:

```bash
cat >> .git/info/exclude <<'EOF'
AI_AGENT_GUIDE.md
AI_AGENT_PROJECT.md
AGENTS.md
CLAUDE.md
GEMINI.md
.agent-workbench.yaml
.agents/
.codex/
.claude/
opencode.json
EOF
```

Append optional paths such as `.agent/`, `.cursor/`, `.vscode/`, `prompts/`, or `scripts/` only when the project treats them as workspace-only.

PowerShell:

```powershell
@"
AI_AGENT_GUIDE.md
AI_AGENT_PROJECT.md
AGENTS.md
CLAUDE.md
GEMINI.md
.agent-workbench.yaml
.agents/
.codex/
.claude/
opencode.json
"@ | Add-Content .git/info/exclude
```

Append optional paths such as `.agent/`, `.cursor/`, `.vscode/`, `prompts/`, or `scripts/` only when the project treats them as workspace-only.

## Restore Workspace Files into a Product Worktree

On a new machine or fresh clone:

```bash
git clone <project-url> my-project
cd my-project
git restore --source=origin/workspace-config -- AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agents .codex .claude opencode.json
```

Then add the local excludes shown above. After this, the workspace files physically exist in the product worktree but are not tracked by product branches.

## Updating Workspace Config

Prefer a temporary worktree for updates so the orphan branch remains isolated:

```bash
git worktree add ../my-project-workspace-config workspace-config
```

Copy the updated workspace files from the product worktree into that temporary worktree:

```bash
cp -r AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agents .codex .claude opencode.json ../my-project-workspace-config/
```

PowerShell alternative:

```powershell
Copy-Item -Recurse -Force AI_AGENT_GUIDE.md, AI_AGENT_PROJECT.md, AGENTS.md, CLAUDE.md, GEMINI.md, .agent-workbench.yaml, .agents, .codex, .claude, opencode.json ..\my-project-workspace-config\
```

Commit from the temporary worktree:

```bash
cd ../my-project-workspace-config
git add -A
git commit -m "chore: update workspace config overlay"
git push
```

Refresh local workspace files in the product worktree:

```bash
git restore --source=origin/workspace-config -- AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agents .codex .claude opencode.json
```

## If Workspace Files Are Already Tracked on a Product Branch

Remove them from the product branch index while preserving the physical files:

```bash
git rm -r --cached AI_AGENT_GUIDE.md AI_AGENT_PROJECT.md AGENTS.md CLAUDE.md GEMINI.md .agent-workbench.yaml .agents .codex .claude opencode.json
git commit -m "chore: stop tracking local workspace config"
```

Then ensure `.git/info/exclude` contains those paths and commit the files on `workspace-config`.

## Agent Rules

When working in a repository that uses this design:

1. Treat `main`, `dev`, and `feature/*` as product-code branches.
2. Treat `workspace-config` as an orphan branch for local development overlay files.
3. Never merge `workspace-config` into a product branch.
4. Never add workspace-only files to product branches.
5. Restore workspace files from `workspace-config` when they are needed in a normal worktree.
6. Commit workspace-file updates on `workspace-config`, preferably through a temporary worktree.
7. Use `.git/info/exclude` to keep restored workspace files untracked on product branches.
8. Before committing on a product branch, run `git status --short` and confirm workspace files are not staged.

Git has no native rule that means "track these files on `dev`, but automatically omit them when merging into `main`." Therefore `dev` must remain clean, and `workspace-config` is the versioned storage location for local workspace configuration.
