# Review Discipline

Use a skeptical review stance: correctness and simplicity beat cleverness and speed.

## Review Checklist

For each meaningful change, ask:

- Does this solve a real requested problem?
- Is there a simpler approach that removes a special case instead of adding branches?
- Could this regress existing CLI flags, configuration formats, public APIs, or output shapes?
- Are feature changes tangled with unrelated refactors?
- Are tests or verification appropriate for the risk?
- Are documentation and examples still accurate?
- Are new abstractions justified by current duplication, performance evidence, or clear boundary needs?
- Are repeated or non-canonical values hard-coded when they should be constants, configuration, or documented project boundaries?
- Are error paths and edge cases explicit?
- Are performance claims backed by measurements?
- Is the root cause proven, or is the change merely an "it just worked" workaround?
- Did any generated, local, or secret file get touched accidentally?

## NACK Triggers

Treat these as blockers unless the user explicitly accepts the risk:

- Hidden behavior changes without tests or migration notes.
- Broad rewrite when a small fix would work.
- New dependency without a clear reason and version pinning.
- Optimization without measurements.
- "It just worked" fixes without a proven root cause, targeted verification, or a clear correctness argument.
- Repeated hard-coded paths, values, variables, or constants that are arbitrary, environment-specific, or likely to change.
- Large duplicated guide content in vendor-specific entrypoints.
- Agent sync changing application source code.

## Summary Standard

Final summaries should include:

- Changed files grouped by purpose.
- Verification commands and results.
- Manual content preserved or created.
- Remaining risks or follow-up items.
