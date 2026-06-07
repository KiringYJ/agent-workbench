# Git and Change Management

## Safe Staging

- Stage only the files intentionally changed for the current task.
- Do not use broad staging commands such as `git add .` or `git add -A` unless the user explicitly asks and the diff has been reviewed.
- Inspect `git status` and relevant diffs before committing or summarizing work.

## Atomic Commit Discipline

- Make one logical change per commit. Split unrelated fixes, refactors, dependency updates, formatting-only changes, and documentation updates unless they are necessary parts of the same intent.
- Keep each commit atomic, reviewable, reversible, and bisectable.
- Do not hide speculative cleanup inside a feature or bug-fix commit.

## History Safety

- Do not run destructive history or working-tree commands (`git reset --hard`, `git clean`, force push, branch deletion, interactive rebase) unless explicitly authorized for the current task.
- Do not bypass hooks or checks with `--no-verify`. If a hook fails, fix or document the underlying cause.
- Keep commits focused and reversible.

## Pre-commit Enforcement

- Prefer project-scoped pre-commit hooks that enforce the project's formatter, linter, type checker, tests, and other required checks.
- Keep hook commands deterministic, documented, and fast enough for routine commits; move long-running checks to CI when necessary.
- Treat hook failures as evidence to investigate. Do not bypass them unless the user explicitly accepts the risk for that commit.

## Commit Messages

Every commit must use a Conventional Commit subject line and explain why the change exists, not just what files changed.

Subject format:

```text
<type>[optional scope]: <intent-oriented summary>
```

Use standard types such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, and `ci`. Choose the type that best describes the user-visible intent of the change.

For non-trivial commits, include useful Lore trailers when they clarify constraints, rejected alternatives, risk, or verification.

Example shape:

```text
refactor: make agent instructions portable across vendors

The repository now generates one canonical guide and keeps vendor
entrypoints thin so projects can use Claude Code, Codex, Gemini, or
OpenCode without duplicating policy.

Constraint: Sync must not require global configuration or marketplaces
Rejected: Git submodule distribution | too intrusive for consumer projects
Confidence: high
Scope-risk: moderate
Tested: Inspected generated files and sync prompt invariants
```

## Review Before Final Response

Before reporting completion:

- Confirm no unrelated files were modified.
- Confirm generated or managed files contain expected markers.
- Confirm project-specific files were preserved.
- Include verification commands and outcomes.
