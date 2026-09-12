# Portable Agent Workflows

Every synchronized project should carry the same core workflows regardless of which coding agent is active. Use the Agent Skills standard directly instead of describing each workflow again through a capability registry or per-vendor adapter files.

## Canonical Project-Local Locations

- `.agents/prompts/` stores supporting prompt workflows that any capable coding agent can read and execute.
- `.agents/skills/` stores the canonical project copies of portable Agent Skills, including optional `scripts/`, `references/`, and `assets/` resources.
- `.agents/guardrails/` stores vendor-neutral guardrail documents.
- `.agent-workbench.lock.json` records sync provenance, scoped baselines, installed artifacts, and retained removals. Keep `.agent-workbench.yaml` as human-owned desired configuration.

`manifest.yaml` registers prompts and skills directly. Do not introduce a second registry that repeats their paths, portability labels, vendor targets, or fallback behavior.

## Vendor Discovery Boundary

Codex, Gemini CLI, OpenCode, and other compatible agents should discover the shared `.agents/skills/` tree directly.

Claude Code uses `.claude/skills/` for project skill discovery. When the Claude target is enabled, sync should copy the registered managed source/resource set for each canonical skill from `.agents/skills/<name>/` to `.claude/skills/<name>/` without appending adapter prose or changing its resources. Corresponding managed files must be byte-identical; unregistered local files remain preserved only in `.agents/skills/`. The Claude copy is a generated discovery mirror, not another source of truth. Use real copied files rather than symlinks so synchronized repositories behave consistently on Windows and other environments.

Do not generate `.codex/skills/`, `.gemini/skills/`, or `.opencode/skills/` mirrors by default. Create a vendor-specific file only when it encodes actual runtime behavior that the shared standard cannot express, such as loader configuration, permissions, hooks, invocation controls, or vendor metadata.

## Required Portable Workflows

| Workflow | Canonical artifacts |
| --- | --- |
| Workbench sync and audit | `.agents/prompts/sync-agent-workbench.md`, `.agents/prompts/audit-agent-workbench.md`, `.agents/prompts/repair-agent-workbench.md`, `.agents/skills/sync-agent-workbench/SKILL.md` |
| Loop until done | `.agents/prompts/loop-until-done.md`, `.agents/skills/loop-until-done/SKILL.md` |
| Guardrail authoring | `.agents/prompts/create-guardrail.md`, `.agents/skills/guardrail-authoring/SKILL.md` |
| Skill authoring | `.agents/prompts/create-agent-skill.md`, `.agents/skills/skill-authoring/SKILL.md` |
| Commit workflow | `.agents/prompts/commit-workflow.md`, `.agents/skills/commit-workflow/SKILL.md` |
| Linus-style review | `.agents/prompts/linus-review.md`, `.agents/skills/linus-review/SKILL.md` |
| Integrate a linked ChatGPT conversation | `.agents/skills/integrate-chatgpt-conversation/SKILL.md` |
| Mathematical PDF reading | `.agents/skills/math-pdf-reader/SKILL.md` |

## Portability Rules

- Treat install as the first sync. The same workflow should detect new, legacy/no-lockfile, and already-managed repositories.
- Use `.agent-workbench.lock.json` as a provenance/baseline ledger, not a package-manager lockfile.
- Classify sync drift as confirmed upstream removal, confirmed removal with local edits, suspected legacy removal, deselected by local config, source changed / migration required, or local unmanaged.
- Never delete downstream artifacts without explicit user confirmation. Record a decision to retain an obsolete managed artifact in `retainedRemovals`.
- Keep skills within the standard `SKILL.md` format unless an explicit target requires an extension.
- Prefer a compatible built-in or installed implementation when the active environment provides one, but keep the portable skill available as the project-owned fallback.
- Store any vendor preference or fallback rule once in the canonical skill or supporting prompt, not in four parallel adapter notes.
- Do not make a consumer project depend on a marketplace, plugin, extension, global configuration, submodule, or machine-local path.
- Keep generated workflows in English and project-local.

If a native feature is missing, unstable, or disabled, execute the canonical `.agents/skills/` or `.agents/prompts/` workflow directly.

## Skill Model and Reasoning Routing

### Workload selection

User-selected operating policy, adopted on 2026-09-07: optimize Codex allowance
per successfully completed, verified unit of work while accounting for both
engineering and research-level mathematics. These are working allocations,
not a measured universal Pareto frontier. Do not turn general intelligence
scores or coding benchmark dollars into research-math capability rankings or
weekly allowance percentages.

[Official OpenAI usage guidance](https://learn.chatgpt.com/docs/pricing)
distinguishes included ChatGPT-plan allowance from API-key billing and explains
that usage varies with the model and actual task. API benchmark cost is not a
direct conversion to the user's five-hour or weekly usage percentage. Keep
uncertainty explicit; validate allocation choices with attributable task-level
outcomes and host-reported usage when available.

| Work class | Model | Effort | Selection rule |
| --- | --- | --- | --- |
| peripheral | `gpt-5.6-luna` | `max` | Repository search, metadata, bulk reading, notation/LaTeX formatting, routine refactoring with established semantics, Lean boilerplate, and running existing proofs/tests. |
| technical | `gpt-5.6-sol` | `medium` | Nontrivial implementation, large-codebase understanding, technical debugging, and translating an established argument into code. |
| mixed | `gpt-5.6-sol` | `high` | Difficult engineering or math/code integration that consumes established mathematical facts and does not decide a new mathematical claim. |
| research-math | `gpt-6-astra` | `medium` | Theorem truth, sufficient hypotheses, well-defined maps, generalizations, obstructions, proof gaps, counterexamples, and theorem-statement faithfulness. |
| critical-proof | `gpt-6-astra` | `max` | Important main theorems, fatal gaps, long cross-lemma arguments, new formal proof search, adversarial proof audits, or unusually high failure-cost obligations. |

Classify the substance of each stage before selecting a skill's ordinary
default. Apply the critical-proof criterion first, then research-math, then
mixed/technical/peripheral. Mathematical substance goes directly to
`gpt-6-astra` / `medium`; qualifying critical proof work goes directly to `gpt-6-astra` / `max`.
Neither requires first failing on Luna or Sol. Use `gpt-6-astra` / `max` also when an
adequate `gpt-6-astra` / `medium` attempt exposes a genuine remaining mathematical impasse.

Sol is an intermediate option for technical work, not a mandatory stop on the
way to mathematical research. A math repository or a .tex/.lean extension alone
does not select Astra: changing notation or executing an existing proof stays
peripheral. Conversely, a "formatting", "review", or "debugging" label must not
downgrade a stage that is actually deciding mathematical correctness. If a Lean
failure could reflect either a library/API issue or false mathematics, separate
the mechanical diagnosis from the mathematical obligation and route the latter
to research-math or critical-proof.

Retain the five listed combinations as the ordinary operating set without
creating fixed-combination agents. Other combinations remain available under
an explicit user override or a separately evidenced policy revision. Do not
change the active main model merely because a new skill is invoked.
Maintain proof/heuristic/open-obligation distinctions; higher effort does not
justify claiming theorem closure. Diagnose missing tools/data/environment
failures before changing the reasoning allocation.

### Dispatch rules

This is the canonical dispatch table for installed skills. It chooses a default
combination for the *skill's first eligible stage*, not a new fixed agent role
or a promise that a runtime will honour an override. An explicit user-selected
model or effort wins. Before invoking a skill, look up its exact full name,
then its explicit aliases in this table. The workload selection above overrides
a skill's ordinary default for mathematical or critical-proof substance. If a
skill is not listed, use its work-class pair and report that it was unmapped. Load that skill's
original `SKILL.md` before work. For independent work, pass the path and a
bounded scope to an eligible child; do not auto-create a new task or launch a
CLI workflow.

When the native generic child surface supports overrides, dispatch its explicit
`model` and `reasoning_effort` fields separately, with `fork_turns` set to
`none` or a bounded recent history as the task needs. Keep model and effort
independent; do not create an agent definition for each pair. For a skill whose named
specialist is fixed at an incompatible pair, use that generic child only when
the runtime permits it; otherwise keep the current parent settings and report
the recommended pair and actual settings separately.

`Bounded child` means a separately reviewable read, implementation, or review
slice. `Leader workflow` remains in the parent, which owns its state,
orchestration, and final decision. `Parent-bound tool` remains in the parent
because it needs the current browser, UI, authenticated connector, live Excel,
or artifact session. Typed roles or a runtime may fix a model and reject an
override; choose an unconfigured eligible child only when the active runtime
supports the requested pair, otherwise keep the stage with the parent and
state that limitation. Image-generation models are selected by their tool, not
by this reasoning table.

Keep every required specialist lane and its evidence contract. For a dynamic
generic child, include the original specialist instructions as well as the skill
and bounded assignment. A missing required independent review is a blocker,
not permission for the author to self-review. A workflow that requires an
unavailable runtime remains unavailable; this table does not substitute a
different execution engine. Source-order rules apply to the skill handler's
own work; unrelated parent work may continue independently.

### OMX workflow compatibility

Use the enabled skill catalog as the availability source. Removed workflow
names are not executable aliases: select a current workflow from the requested
outcome and retain any explicit user workflow boundary. Ordinary scoped work
stays direct; durable multi-goal execution uses Ultragoal. Team is optional
coordinated parallel work, not an automatic extra stage.

Explicit Autopilot preserves `deep-interview -> ralplan -> ultragoal`, durable
planning artifacts, sequential Architect/Critic reviews, and the session-bound
execution handoff. Ordinary progression does not require a host-issued consensus
receipt. Conductor-specific caller/parent/target proof applies only to an actual
Conductor operation; it must not become a blanket Autopilot prerequisite.

For Ultragoal finalization, the cleaner and independent code-reviewer/architect
lanes remain mandatory. Run the cleaner on the changed files and inspect its
result and diff. Reuse an accepted successful verification only when it covers
the current goal and final behavior, and its relevant source, tests,
configuration, dependencies, execution environment, and evidence validity are
unchanged. A no-change cleaner result alone does not establish that coverage.
Rerun affected checks for changed, uncovered, uncertain or time-sensitive inputs.
Record the actual verification run and validity basis in the required quality
gate evidence; do not fabricate a newer run. Complete the independent final
reviews after cleanup, and repeat affected review if later edits invalidate a
verdict. Preserve fresh goal snapshots, checkpoint receipts and all final gates.
This reuse rule never substitutes for the journal pipeline's source-bound
whole-manuscript final reviews.

### Skill assignments

| Exact skill or explicit alias group | Model | Effort | Delivery | Stage or escalation |
| --- | --- | --- | --- | --- |
| `imagegen` | `gpt-5.6-luna` | `max` | Parent-bound tool | Prompt/edit planning only; the image tool controls its model. Complex implementation: `gpt-5.6-sol` / `medium`; mathematical validity in a diagram: `gpt-6-astra` / `medium`. |
| `openai-docs` | `gpt-5.6-luna` | `max` | Bounded child | Source lookup and extraction. Nontrivial API implementation: `gpt-5.6-sol` / `medium`; difficult integration or compatibility analysis: `gpt-5.6-sol` / `high`. |
| `plugin-creator` | `gpt-5.6-luna` | `max` | Bounded child | Routine scaffolding and manifest updates. Nontrivial implementation: `gpt-5.6-sol` / `medium`; cross-runtime architecture: `gpt-5.6-sol` / `high`. |
| `skill-creator`, `skill-creator:skill-creator` | `gpt-5.6-sol` | `medium` | Bounded child | Routine wording/metadata edits: `gpt-5.6-luna` / `max`; workflow design: `gpt-5.6-sol` / `medium`; conflicting policies or specialist boundaries: `gpt-5.6-sol` / `high`. |
| `skill-installer`, `plugin-management:plugin-management` | `gpt-5.6-luna` | `max` | Parent-bound tool | Known-source installation and listing. Substantive failure diagnosis: `gpt-5.6-sol` / `medium`; complex reconciliation: `gpt-5.6-sol` / `high`. Preserve action authorization. |
| `ai-slop-cleaner`, `oh-my-codex:ai-slop-cleaner` | `gpt-5.6-luna` | `max` | Leader workflow | Behaviour-preserving cleanup with established tests: `gpt-5.6-luna` / `max`; nontrivial refactor: `gpt-5.6-sol` / `medium`; contract/architecture decisions: `gpt-5.6-sol` / `high`. Mathematical semantics use the workload override. |
| `analyze`, `oh-my-codex:analyze` | `gpt-5.6-sol` | `medium` | Bounded child | Gather repository evidence with `gpt-5.6-luna` / `max`; complex causal analysis: `gpt-5.6-sol` / `high`. Theorem validity or proof-gap analysis goes directly to `gpt-6-astra` / `medium`. |
| `autopilot`, `oh-my-codex:autopilot` | `gpt-5.6-sol` | `medium` | Leader workflow | Parent coordinates. Peripheral work: `gpt-5.6-luna` / `max`; implementation: `gpt-5.6-sol` / `medium`; difficult technical review: `gpt-5.6-sol` / `high`. Classify each child stage; mathematical content uses `gpt-6-astra` / `medium` or `gpt-6-astra` / `max` directly. |
| `claude-code-setup:claude-automation-recommender` | `gpt-5.6-sol` | `medium` | Bounded child | Inventory: `gpt-5.6-luna` / `max`; capability recommendations: `gpt-5.6-sol` / `medium`; cross-project architecture: `gpt-5.6-sol` / `high`. |
| `claude-md-management:claude-md-improver`, `claude-md-management:source-command-revise-claude-md` | `gpt-5.6-luna` | `max` | Bounded child | Grounded documentation updates. Conflicting project policies: `gpt-5.6-sol` / `medium`; complex authority or architectural decisions: `gpt-5.6-sol` / `high`. |
| `code-review`, `oh-my-codex:code-review` | `gpt-5.6-sol` | `high` | Leader workflow | Independent code/spec and architect lanes: `gpt-5.6-sol` / `high`. Mathematical claims: `gpt-6-astra` / `medium`; main-theorem, formal-proof, or adversarial proof audit: `gpt-6-astra` / `max`. Preserve both independent outputs and the unavailable-review gate. |
| `computer-use:computer-use` | `gpt-5.6-luna` | `max` | Parent-bound tool | Routine UI operations and extraction. Multi-system technical troubleshooting: `gpt-5.6-sol` / `medium`. Preserve the active session; interpret mathematical content using the workload override. |
| `deep-interview`, `oh-my-codex:deep-interview` | `gpt-5.6-sol` | `high` | Leader workflow | Parent owns questions and answers. Ordinary requirements use `gpt-5.6-sol` / `high`; resolving mathematical hypotheses or problem formulation uses `gpt-6-astra` / `medium`, without a cheap-first requirement. |
| `deep-research-work:deep-research` | `gpt-5.6-sol` | `high` | Bounded child | Literature retrieval/metadata: `gpt-5.6-luna` / `max`; non-mathematical synthesis: `gpt-5.6-sol` / `high`; mathematical substance: `gpt-6-astra` / `medium`; main-theorem, proof search, or adversarial proof audit: `gpt-6-astra` / `max`. |
| `doctor`, `oh-my-codex:doctor` | `gpt-5.6-sol` | `medium` | Parent-bound tool | Routine inspection: `gpt-5.6-luna` / `max`; technical diagnosis: `gpt-5.6-sol` / `medium`; complex runtime interactions: `gpt-5.6-sol` / `high`. If a formalization failure may be mathematical, classify that question as `gpt-6-astra` / `medium`. |
| `documents:documents`, `pdf:pdf`, `presentations:Presentations`, `spreadsheets:Spreadsheets` | `gpt-5.6-luna` | `max` | Parent-bound tool | Formatting, extraction, and writing an already-established argument: `gpt-5.6-luna` / `max`; nontrivial artifact code: `gpt-5.6-sol` / `medium`. Evaluating the mathematical argument itself uses `gpt-6-astra` / `medium` or `gpt-6-astra` / `max`. Preserve visual QA. |
| `help`, `oh-my-codex:hud`, `oh-my-codex:cancel`, `ralph-loop:source-command-help`, `ralph-loop:source-command-cancel-ralph` | `gpt-5.6-luna` | `max` | Parent-bound tool | Status, help, and requested control operations. Substantive diagnosis follows its own skill row. |
| `hookify:source-command-configure`, `hookify:writing-hookify-rules` | `gpt-5.6-luna` | `max` | Parent-bound tool | Routine rule/configuration edits. Enforcement logic: `gpt-5.6-sol` / `medium`; difficult trust-boundary interactions: `gpt-5.6-sol` / `high`. |
| `hookify:source-command-list` | `gpt-5.6-luna` | `max` | Parent-bound tool | Read-only listing and concise explanation. |
| `oh-my-codex:ask` | `gpt-5.6-luna` | `max` | Parent-bound tool | Prepare the grounded advisor question; the external advisor has its own configuration. Evaluate technical claims with `gpt-5.6-sol` / `high`, mathematical claims with `gpt-6-astra` / `medium`, and critical proofs with `gpt-6-astra` / `max`. |
| `oh-my-codex:autoresearch` | `gpt-5.6-sol` | `high` | Leader workflow | Parent owns evaluator gates. Routine experiments: `gpt-5.6-sol` / `medium`; mathematical research: `gpt-6-astra` / `medium`; new formal proof search or high-failure-cost proof obligations: `gpt-6-astra` / `max`. |
| `oh-my-codex:best-practice-research` | `gpt-5.6-luna` | `max` | Bounded child | Official-source retrieval and comparison. Implementation implications: `gpt-5.6-sol` / `medium`; material technical tradeoffs: `gpt-5.6-sol` / `high`; mathematical validity: `gpt-6-astra` / `medium`. |
| `oh-my-codex:configure-notifications` | `gpt-5.6-luna` | `max` | Parent-bound tool | Requested configuration/status. Nontrivial provider failures: `gpt-5.6-sol` / `medium`. |
| `oh-my-codex:design` | `gpt-5.6-sol` | `medium` | Leader workflow | Product/UI design: `gpt-5.6-sol` / `medium`; complex engineering tradeoffs: `gpt-5.6-sol` / `high`. Mathematical modeling decisions use `gpt-6-astra` / `medium`. |
| `oh-my-codex:omx-setup`, `omx-setup` | `gpt-5.6-luna` | `max` | Parent-bound tool | Routine setup and configuration inspection. Technical diagnosis: `gpt-5.6-sol` / `medium`; difficult cross-runtime interactions: `gpt-5.6-sol` / `high`. |
| `oh-my-codex:performance-goal` | `gpt-5.6-sol` | `high` | Leader workflow | Parent owns measurements and evaluator gates. Bounded implementation: `gpt-5.6-sol` / `medium`; difficult engineering: `gpt-5.6-sol` / `high`; mathematical correctness of an algorithm/model: `gpt-6-astra` / `medium`. Preserve measured acceptance criteria. |
| `oh-my-codex:ultragoal`, `oh-my-codex:ultraqa`, `ultraqa` | `gpt-5.6-sol` | `medium` | Leader workflow | Parent owns lifecycle state. Peripheral tasks: `gpt-5.6-luna` / `max`; nontrivial implementation: `gpt-5.6-sol` / `medium`; difficult integration: `gpt-5.6-sol` / `high`. Mathematical or critical-proof stages use `gpt-6-astra` / `medium` or `gpt-6-astra` / `max` directly. |
| `oh-my-codex:plan`, `plan`, `oh-my-codex:ralplan`, `ralplan` | `gpt-5.6-sol` | `medium` | Leader workflow | Technical planning: `gpt-5.6-sol` / `medium`; difficult engineering criticism: `gpt-5.6-sol` / `high`. Research-math planning: `gpt-6-astra` / `medium`; critical proof strategy or a long lemma chain: `gpt-6-astra` / `max`. |
| `oh-my-codex:skill` | `gpt-5.6-luna` | `max` | Parent-bound tool | Inspect/manage skills; installation and authoring use their respective rows. |
| `oh-my-codex:team`, `team` | `gpt-5.6-sol` | `medium` | Leader workflow | Parent coordinates; classify worker stages separately. Peripheral: `gpt-5.6-luna` / `max`; technical: `gpt-5.6-sol` / `medium`; difficult integration: `gpt-5.6-sol` / `high`; mathematics: `gpt-6-astra` / `medium`; critical proof: `gpt-6-astra` / `max`. Host settings govern actual workers. |
| `oh-my-codex:visual-ralph` | `gpt-5.6-sol` | `high` | Leader workflow | Visual iteration and nontrivial technical comparison: `gpt-5.6-sol` / `high`; routine visual fixes: `gpt-5.6-luna` / `max`. Preserve evidence and state; mathematical semantics follow the workload override. |
| `oh-my-codex:wiki` | `gpt-5.6-luna` | `max` | Parent-bound tool | Grounded summaries and updates. Taxonomy design: `gpt-5.6-sol` / `medium`; validation of new mathematical connections: `gpt-6-astra` / `medium`. |
| `oh-my-codex:worker` | `gpt-5.6-luna` | `max` | Bounded child | Peripheral worker default. Technical implementation: `gpt-5.6-sol` / `medium`; difficult math/code integration using established results: `gpt-5.6-sol` / `high`; mathematical substance: `gpt-6-astra` / `medium`; critical proof: `gpt-6-astra` / `max`. The Team host assigns actual settings. |
| `security-review` | `gpt-5.6-sol` | `high` | Bounded child | Independent technical security review: `gpt-5.6-sol` / `high`. A critical adversarial audit with unusually high failure cost may start directly at `gpt-6-astra` / `max`. |
| `sites:sites-building` | `gpt-5.6-sol` | `medium` | Parent-bound tool | Routine scaffolding/content: `gpt-5.6-luna` / `max`; nontrivial site implementation: `gpt-5.6-sol` / `medium`; complex architecture: `gpt-5.6-sol` / `high`. Preserve the Sites session. |
| `sites:sites-hosting` | `gpt-5.6-luna` | `max` | Parent-bound tool | Routine authorized deployment/status. Technical failure diagnosis: `gpt-5.6-sol` / `medium`; complex infrastructure interactions: `gpt-5.6-sol` / `high`. |
| `spreadsheets:excel-live-control` | `gpt-5.6-luna` | `max` | Parent-bound tool | Routine edits and established formulas: `gpt-5.6-luna` / `max`; complex workbook code/integration: `gpt-5.6-sol` / `medium`. Mathematical model validity: `gpt-6-astra` / `medium`. Preserve the live Excel session. |
| `template-creator:template-creator` | `gpt-5.6-luna` | `max` | Bounded child | Routine reusable artifact production and QA. Nontrivial generation logic: `gpt-5.6-sol` / `medium`; difficult technical integration: `gpt-5.6-sol` / `high`. |
| `visualize:visualize` | `gpt-5.6-luna` | `max` | Parent-bound tool | Explanatory visuals for established content: `gpt-5.6-luna` / `max`; simulation implementation: `gpt-5.6-sol` / `medium`; validity of the mathematical model or argument: `gpt-6-astra` / `medium`. |
| `web-clone` | `gpt-5.6-sol` | `medium` | Leader workflow | Parent owns browser evidence. Routine markup/styles: `gpt-5.6-luna` / `max`; nontrivial behaviour: `gpt-5.6-sol` / `medium`; difficult cross-system debugging: `gpt-5.6-sol` / `high`. |
| `commit-workflow` | `gpt-5.6-luna` | `max` | Parent-bound tool | Routine reviewed staging, commit, and requested push. Ambiguous scope/divergence: `gpt-5.6-sol` / `medium`; difficult technical conflict analysis: `gpt-5.6-sol` / `high`. Parent retains Git ownership. |
| `guardrail-authoring` | `gpt-5.6-sol` | `high` | Leader workflow | Established rule edits: `gpt-5.6-luna` / `max`; new enforcement/authority design: `gpt-5.6-sol` / `high`. Research-math proof/status obligations use `gpt-6-astra` / `medium`. |
| `linus-review` | `gpt-5.6-sol` | `high` | Bounded child | Independent technical correctness/maintainability review: `gpt-5.6-sol` / `high`; mathematical correctness: `gpt-6-astra` / `medium`; adversarial proof audit or main-theorem validation: `gpt-6-astra` / `max`. |
| `loop-until-done` | `gpt-5.6-sol` | `medium` | Leader workflow | Peripheral work: `gpt-5.6-luna` / `max`; technical implementation: `gpt-5.6-sol` / `medium`; difficult debugging: `gpt-5.6-sol` / `high`. Mathematical substance uses `gpt-6-astra` / `medium`; critical proof or genuine mathematical impasse uses `gpt-6-astra` / `max`. |
| `integrate-chatgpt-conversation` | `gpt-5.6-sol` | `high` | Parent-bound tool | Mixed-tier controller for retrieval followed by synthesis, project updates, and validation. An explicitly retrieval-only task may use `gpt-5.6-luna` / `max`. Mathematical changes fail closed to a bounded independent `gpt-6-astra` / `medium` pre-edit audit and fresh post-edit audit; critical-proof escalation alone uses `gpt-6-astra` / `max`. |
| `math-pdf-reader` | `gpt-6-astra` | `medium` | Bounded child | Theorem, proof, formula, or notation verification. Literal page navigation, rendering, and metadata extraction: `gpt-5.6-luna` / `max`; non-mathematical artifact handling: `gpt-5.6-sol` / `medium`; main-theorem or adversarial proof audit: `gpt-6-astra` / `max`. Preserve the PDF evidence boundary and fail closed on unreadable content. |
| `skill-authoring` | `gpt-5.6-sol` | `medium` | Bounded child | Routine entrypoint edits: `gpt-5.6-luna` / `max`; workflow design: `gpt-5.6-sol` / `medium`; difficult runtime/safety-policy decisions: `gpt-5.6-sol` / `high`. |
| `sync-agent-workbench` | `gpt-5.6-luna` | `max` | Leader workflow | Routine inventory and prescribed sync: `gpt-5.6-luna` / `max`; nontrivial reconciliation: `gpt-5.6-sol` / `medium`; complex provenance or local-edit conflicts: `gpt-5.6-sol` / `high`. Preserve sync scope and project-owned files. |
