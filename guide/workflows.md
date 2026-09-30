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

Do not generate `.codex/skills/`, `.gemini/skills/`, or `.opencode/skills/` mirrors by default. Create a vendor-specific file only when it encodes actual runtime behavior that the shared standard cannot express, such as loader configuration, model and effort bindings, permissions, hooks, invocation controls, or vendor metadata.

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

### Workload tiers

Route each stage by the work it actually performs. The five tier names are the
portable contract; platform bindings map them to concrete models, effort levels,
and child mechanisms.

| Tier | Selection rule |
| --- | --- |
| `peripheral` | Repository search, metadata, bulk reading, notation/LaTeX formatting, routine refactoring with established semantics, Lean boilerplate, and running existing proofs/tests. |
| `technical` | Nontrivial implementation, large-codebase understanding, technical debugging, and translating an established argument into code. |
| `mixed` | Difficult engineering or math/code integration that consumes established mathematical facts and does not decide a new mathematical claim. |
| `research-math` | Theorem truth, sufficient hypotheses, well-defined maps, generalizations, obstructions, proof gaps, counterexamples, and theorem-statement faithfulness. |
| `critical-proof` | Important main theorems, fatal gaps, long cross-lemma arguments, new formal proof search, adversarial proof audits, or unusually high failure-cost obligations. |

Classify the substance of each stage before selecting a skill's ordinary
default. Apply the critical-proof criterion first, then research-math, then
mixed/technical/peripheral. Mathematical substance goes directly to
`research-math`; qualifying critical proof work goes directly to
`critical-proof`. Neither requires first failing at a lower tier. Use
`critical-proof` also when an adequate `research-math` attempt exposes a genuine
remaining mathematical impasse.

The `technical` and `mixed` tiers are intermediate options for engineering work,
not mandatory stops on the way to mathematical research. A math repository or a
.tex/.lean extension alone does not select `research-math` or `critical-proof`:
changing notation or executing an existing proof stays peripheral. Conversely,
a "formatting", "review", or "debugging" label must not downgrade a stage that
is actually deciding mathematical correctness. If a Lean failure could reflect
either a library/API issue or false mathematics, separate the mechanical
diagnosis from the mathematical obligation and route the latter to
research-math or critical-proof.

Retain the five tiers as the ordinary operating set. Other model or effort
choices remain available under an explicit user override or a separately
evidenced binding revision. Do not create per-skill agents for routing; a
binding may define one child per tier only when its runtime cannot set effort
per dispatch. Do not change the active main model merely because a new skill is
invoked. Maintain proof/heuristic/open-obligation distinctions; a higher tier
does not justify claiming theorem closure. Diagnose missing
tools/data/environment failures before changing the tier.

### Platform bindings

Each platform binding resolves the tiers to its runtime's models, effort levels,
and child mechanisms, and assigns tiers to the skills of its own environment.
Only the matching runtime loads it:

| Runtime | Binding | Loading |
| --- | --- | --- |
| Claude Code | `.claude/rules/agent-routing.md`, with tier subagents in `.claude/agents/` | Loaded automatically at session start. |
| Codex | `.codex/agent-routing.md` | Read it before selecting a model or effort or dispatching a child. |

Follow only the binding for the runtime that is executing. If it is missing or
cannot express a tier, keep the stage with the parent at its current settings
and report the recommended tier and the actual settings separately. Model
identifiers, effort values, and allowance rationale belong in bindings, not in
this guide. Record project-specific routing deviations in `AI_AGENT_PROJECT.md`
instead of editing a generated binding.

### Dispatch rules

The skill assignment tables choose a default tier for the *skill's first
eligible stage*, not a new fixed agent role or a promise that a runtime will
honour an override. The table below covers the portable workbench skills; each
platform binding covers the skills of its own environment. An explicit
user-selected model or effort wins. Before invoking a skill, look up its exact
full name, then its explicit aliases, in these tables. The workload tiers above
override a skill's ordinary default for mathematical or critical-proof
substance. If a skill is not listed, classify the stage, use that tier, and
report that the skill was unmapped. Load that skill's original `SKILL.md` before
work. For independent work, pass the path and a bounded scope to an eligible
child; do not auto-create a new task or launch a CLI workflow.

Resolve the tier through the active platform binding. For a skill whose named
specialist is fixed at incompatible settings, use a generic child only when the
runtime permits it; otherwise keep the current parent settings and report the
recommended tier and actual settings separately.

`Bounded child` means a separately reviewable read, implementation, or review
slice. `Leader workflow` remains in the parent, which owns its state,
orchestration, and final decision. `Parent-bound tool` remains in the parent
because it needs the current browser, UI, authenticated connector, live
application, or artifact session. Typed roles or a runtime may fix a model and
reject an override; choose an unconfigured eligible child only when the active
runtime supports the requested tier settings, otherwise keep the stage with the
parent and state that limitation. Image-generation models are selected by their
tool, not by these routing tables.

Keep every required specialist lane and its evidence contract. For a dynamic
generic child, include the original specialist instructions as well as the skill
and bounded assignment. A missing required independent review is a blocker,
not permission for the author to self-review. A workflow that requires an
unavailable runtime remains unavailable; these tables do not substitute a
different execution engine. Source-order rules apply to the skill handler's
own work; unrelated parent work may continue independently.

Use the enabled skill catalog as the availability source. Removed workflow
names are not executable aliases: select a current workflow from the requested
outcome and retain any explicit user workflow boundary.

### Skill assignments

| Exact skill or explicit alias group | Tier | Delivery | Stage or escalation |
| --- | --- | --- | --- |
| `commit-workflow` | `peripheral` | Parent-bound tool | Routine reviewed staging, commit, and requested push. Ambiguous scope/divergence: `technical`; difficult technical conflict analysis: `mixed`. Parent retains Git ownership. |
| `guardrail-authoring` | `mixed` | Leader workflow | Established rule edits: `peripheral`; new enforcement/authority design: `mixed`. Research-math proof/status obligations use `research-math`. |
| `linus-review` | `mixed` | Bounded child | Independent technical correctness/maintainability review: `mixed`; mathematical correctness: `research-math`; adversarial proof audit or main-theorem validation: `critical-proof`. |
| `loop-until-done` | `technical` | Leader workflow | Peripheral work: `peripheral`; technical implementation: `technical`; difficult debugging: `mixed`. Mathematical substance uses `research-math`; critical proof or genuine mathematical impasse uses `critical-proof`. |
| `integrate-chatgpt-conversation` | `mixed` | Parent-bound tool | Mixed-tier controller for retrieval followed by synthesis, project updates, and validation. An explicitly retrieval-only task may use `peripheral`. Mathematical changes fail closed to a bounded independent `research-math` pre-edit audit and fresh post-edit audit; critical-proof escalation alone uses `critical-proof`. |
| `math-pdf-reader` | `research-math` | Bounded child | Theorem, proof, formula, or notation verification. Literal page navigation, rendering, and metadata extraction: `peripheral`; non-mathematical artifact handling: `technical`; main-theorem or adversarial proof audit: `critical-proof`. Preserve the PDF evidence boundary and fail closed on unreadable content. |
| `skill-authoring` | `technical` | Bounded child | Routine entrypoint edits: `peripheral`; workflow design: `technical`; difficult runtime/safety-policy decisions: `mixed`. |
| `sync-agent-workbench` | `peripheral` | Leader workflow | Routine inventory and prescribed sync: `peripheral`; nontrivial reconciliation: `technical`; complex provenance or local-edit conflicts: `mixed`. Preserve sync scope and project-owned files. |
