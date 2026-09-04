# Testing and Verification

## Test-First Bias

For feature work and bug fixes, prefer this loop:

1. Add or extend a test that proves the expected behavior.
2. Run it and confirm it fails for the expected reason when practical.
3. Implement the minimal fix.
4. Run the targeted test and the broader project checks documented in `AI_AGENT_PROJECT.md`.
5. Refactor only while tests stay green.

If the project lacks tests, use the lightest reliable verification available and state the gap.

For reversible, low-impact changes, avoid adding tests that merely repeat implementation details or match documentation wording. Add tests when they establish meaningful behavior or protect a real boundary.

## Root Cause and Proof Discipline

- For bug fixes, first reproduce or precisely characterize the failure, then identify the causal mechanism before changing behavior.
- Test or justify each root-cause observation and rule out plausible alternatives. Do not accept "it just worked" as evidence of correctness.
- Begin solution work only after the root cause is proven with complete confidence. If complete confidence is not currently possible, keep the change experimental, state the uncertainty, and avoid broad or irreversible edits.

## Verification Selection

Choose verification proportional to risk:

- Documentation-only change: render or inspect relevant Markdown/configuration and check links or examples when practical.
- Small code change: targeted tests plus formatter/linter if available.
- Multi-file or behavior change: targeted tests, broader suite, type checks, lint, and documentation review.
- Security or data-mutation change: add negative tests, boundary tests, and explicit rollback or recovery notes.

Complete the project's required checks. Once they pass, broaden or repeat verification only when further changes, failures, or unresolved concerns justify it. Stop when the completion criteria are supported by fresh evidence.

## Clean Output

A successful verification run should have no unexplained warnings, formatter diffs, or stale generated output. If checks fail for pre-existing reasons, document the exact command and failure summary.

## Project Commands

Use `AI_AGENT_PROJECT.md` as the source of truth for build and test commands. If commands are missing, infer conservatively from standard manifests and report the assumption.
