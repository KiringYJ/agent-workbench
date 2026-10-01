# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "minitest/autorun"
require "open3"
require "pathname"
require "tmpdir"
require "yaml"

require_relative "../skills/sync-agent-workbench/scripts/migrate_lockfile"
require_relative "../skills/sync-agent-workbench/scripts/verify_skill_mirror"

class WorkbenchContractsTest < Minitest::Test
  ROOT = Pathname(__dir__).parent
  FIXTURES = ROOT / "test/fixtures"
  FIXTURE_WORKBENCH = FIXTURES / "workbench"
  FIXTURE_REPO = "KiringYJ/agent-workbench"
  FIXTURE_BRANCH = "main"
  FIXTURE_REQUESTED_REF = "main"
  MANIFEST = YAML.safe_load_file(ROOT / "manifest.yaml")
  MANAGED_HEADER = <<~HEADER.chomp
    <!--
    agent-workbench: managed
    source: KiringYJ/agent-workbench
    profile: base
    manual-edits: preserve-marked-sections-only
    -->

    # AI Agent Guide

    This file is generated from `agent-workbench` modules. Re-run the sync prompt to update it. Keep project-specific details in `AI_AGENT_PROJECT.md`.
  HEADER
  MODULE_SEPARATOR = "\n\n---\n\n"
  MANUAL_NOTES_HEADING = "## Preserved Manual Notes\n\n"
  MANUAL_BLOCK_TERMINATOR = "\n\n"
  MANUAL_BLOCK = /<!-- agent-workbench:manual-begin -->.*?<!-- agent-workbench:manual-end -->/m
  LEDGER_TABLE_HEADER = "| Kind | Scope | `id` | `name` | `sourcePath` | `markerVersion` |"
  LEDGER_TOP_LEVEL_FIELDS = %w[
    schemaVersion generatedAt source manifestDigest profile syncMode targets scopes installedArtifacts retainedRemovals
  ].freeze
  LEDGER_RECORD_FIELDS = %w[
    id kind scope name sourcePath outputPath sourceChecksum lastAppliedOutputChecksum resourceManifest markerVersion profile managed
  ].freeze
  LEDGER_SCOPES = %w[guide entrypoints portable_prompts portable_skills].freeze
  LEDGER_KIND_SCOPES = {
    "guide" => "guide",
    "entrypoint" => "entrypoints",
    "vendor_config" => "entrypoints",
    "platform_binding" => "entrypoints",
    "portable_prompt" => "portable_prompts",
    "portable_skill" => "portable_skills"
  }.freeze
  LEDGER_ID_PATTERNS = {
    "guide" => "guide:AI_AGENT_GUIDE.md",
    "entrypoint" => "entrypoint:<output path>",
    "vendor_config" => "vendor_config:<output path>",
    "platform_binding" => "platform_binding:<output path>",
    "portable_prompt" => "portable_prompt:<name>",
    "portable_skill" => "portable_skill:<name>"
  }.freeze

  PROFILE_MODULES = {
    "base" => %w[base prompting git repository-workspace security testing review workflows],
    "rust" => %w[base prompting git repository-workspace security testing review workflows languages/rust],
    "python" => %w[base prompting git repository-workspace security testing review workflows languages/python],
    "typescript" => %w[base prompting git repository-workspace security testing review workflows languages/typescript],
    "frontend" => %w[base prompting git repository-workspace security testing review workflows languages/typescript domains/frontend],
    "vue" => %w[base prompting git repository-workspace security testing review workflows languages/typescript domains/frontend frameworks/vue],
    "vue-vuetify" => %w[base prompting git repository-workspace security testing review workflows languages/typescript domains/frontend frameworks/vue frameworks/vuetify],
    "research" => %w[base prompting git repository-workspace security testing review workflows domains/research],
    "tex" => %w[base prompting git repository-workspace security testing review workflows domains/research languages/tex]
  }.freeze

  TIERS = %w[peripheral technical mixed research-math critical-proof].freeze
  DELIVERY_MODES = ["Bounded child", "Leader workflow", "Parent-bound tool"].freeze
  SKILL_TABLE_HEADER = "| Exact skill or explicit alias group | Tier | Delivery | Stage or escalation |"
  CODEX_BINDING = "templates/codex.agent-routing.md.tpl"
  CLAUDE_BINDING = "templates/claude.agent-routing.md.tpl"
  CLAUDE_TIER_AGENTS = "templates/claude-agents"
  PLATFORM_BINDINGS = {
    ".claude/rules/agent-routing.md" => CLAUDE_BINDING,
    ".codex/agent-routing.md" => CODEX_BINDING
  }.freeze
  CODEX_TIER_BINDING = {
    "peripheral" => ["gpt-5.6-luna", "max"],
    "technical" => ["gpt-5.6-sol", "medium"],
    "mixed" => ["gpt-5.6-sol", "high"],
    "research-math" => ["gpt-6-astra", "medium"],
    "critical-proof" => ["gpt-6-astra", "max"]
  }.freeze
  CLAUDE_TIER_BINDING = {
    "peripheral" => ["haiku", nil],
    "technical" => ["sonnet", "medium"],
    "mixed" => ["sonnet", "high"],
    "research-math" => ["opus", "high"],
    "critical-proof" => ["fable", "max"]
  }.freeze
  CODEX_SKILL_ROUTES = %w[
    imagegen openai-docs plugin-creator skill-creator skill-creator:skill-creator
    skill-installer plugin-management:plugin-management ai-slop-cleaner
    oh-my-codex:ai-slop-cleaner analyze oh-my-codex:analyze autopilot
    oh-my-codex:autopilot claude-code-setup:claude-automation-recommender
    claude-md-management:claude-md-improver
    claude-md-management:source-command-revise-claude-md code-review
    oh-my-codex:code-review computer-use:computer-use deep-interview
    oh-my-codex:deep-interview deep-research-work:deep-research doctor
    oh-my-codex:doctor documents:documents pdf:pdf presentations:Presentations
    spreadsheets:Spreadsheets help oh-my-codex:hud
    oh-my-codex:cancel ralph-loop:source-command-help
    ralph-loop:source-command-cancel-ralph hookify:source-command-configure
    hookify:writing-hookify-rules hookify:source-command-list oh-my-codex:ask
    oh-my-codex:autoresearch
    oh-my-codex:best-practice-research oh-my-codex:configure-notifications
    oh-my-codex:design oh-my-codex:omx-setup omx-setup
    oh-my-codex:performance-goal
    oh-my-codex:ultragoal
    oh-my-codex:ultraqa ultraqa
    oh-my-codex:plan plan oh-my-codex:ralplan ralplan
    oh-my-codex:skill oh-my-codex:team team oh-my-codex:visual-ralph oh-my-codex:wiki
    oh-my-codex:worker security-review sites:sites-building sites:sites-hosting
    spreadsheets:excel-live-control template-creator:template-creator
    visualize:visualize web-clone
  ].freeze
  PLATFORM_SETTING_PATTERN = /
    \bgpt-|\b(?:haiku|sonnet|opus|fable)\b|reasoning_effort|fork_turns|`(?:low|medium|high|xhigh|max)`|
    oh-my-(?:codex|claudecode)|\b(?:OMX|OMC)\b|Ultragoal
  /xi

  def test_every_manifest_path_exists
    registered_paths.each do |path|
      assert_path_exists ROOT / path, "manifest path does not exist: #{path}"
    end
  end

  def test_every_profile_resolves_in_parent_first_order
    PROFILE_MODULES.each do |profile, expected|
      assert_equal expected, resolve_profile(profile), "unexpected module order for #{profile}"
    end
  end

  def test_profiles_reference_registered_modules
    PROFILE_MODULES.each_value do |modules|
      modules.each { |name| assert MANIFEST.fetch("modules").key?(name), "unregistered module: #{name}" }
    end
  end

  def test_base_guide_matches_canonical_modules
    assert_equal "#{MANAGED_HEADER}\n\n#{module_body("base")}\n", (ROOT / "AI_AGENT_GUIDE.md").read
  end

  def test_guide_template_renders_the_canonical_guide
    assert_equal (ROOT / "AI_AGENT_GUIDE.md").read, render_guide("base", [])
  end

  def test_sync_prompt_pins_the_guide_layout
    generation = markdown_section((ROOT / "prompts/sync-agent-workbench.md").read, "## AI_AGENT_GUIDE.md generation")
    [MODULE_SEPARATOR, MANUAL_NOTES_HEADING, MANUAL_BLOCK_TERMINATOR].each do |literal|
      escaped = literal.gsub("\n", '\n') # the prompt spells newlines as \n
      assert_includes generation, "`#{escaped}`"
    end
  end

  def test_manual_blocks_regenerate_idempotently
    blocks = [
      "<!-- agent-workbench:manual-begin -->\nKeep this local note.\n<!-- agent-workbench:manual-end -->",
      "<!-- agent-workbench:manual-begin -->\n## Local Terms\n\n- `{{modules}}` stays literal here.\n<!-- agent-workbench:manual-end -->"
    ]
    rendered = render_guide("base", blocks)

    assert_equal blocks, rendered.scan(MANUAL_BLOCK)
    assert_equal rendered, render_guide("base", rendered.scan(MANUAL_BLOCK))
  end

  def test_entrypoints_remain_thin_and_match_templates
    {
      "AGENTS.md" => "templates/AGENTS.md.tpl",
      "CLAUDE.md" => "templates/CLAUDE.md.tpl",
      "GEMINI.md" => "templates/GEMINI.md.tpl",
      "opencode.json" => "templates/opencode.json.tpl"
    }.each do |output, template|
      content = (ROOT / output).read
      assert_equal (ROOT / template).read, content
      assert_operator content.lines.length, :<=, 16, "#{output} is no longer a thin entrypoint"
      assert_includes content, "AI_AGENT_GUIDE.md"
      assert_includes content, "AI_AGENT_PROJECT.md"
    end
  end

  def test_core_execution_and_reporting_contracts_remain_canonical
    guide = (ROOT / "AI_AGENT_GUIDE.md").read
    assert_match(/non-trivial work, state or internally maintain a short plan/i, guide)
    assert_match(/final summaries.*changed files.*verification commands.*preserved manual content.*remaining risks/im, guide)
    assert_match(/working-tree changes as user-owned/i, guide)
    assert_match(/never bypass hooks/i, guide)
  end

  def test_root_configuration_matches_registered_templates
    assert_equal (ROOT / "templates/agent-workbench.yaml.tpl").read, (ROOT / ".agent-workbench.yaml").read
    assert_equal (ROOT / "templates/codex.config.toml.tpl").read, (ROOT / ".codex/config.toml").read

    config = YAML.safe_load_file(ROOT / ".agent-workbench.yaml")
    assert_equal "base", config.fetch("profile")
    assert_equal PROFILE_MODULES.fetch("base"), config.fetch("modules")
  end

  def test_json_and_toml_templates_parse
    JSON.parse((ROOT / "templates/opencode.json.tpl").read)

    _output, error, status = Open3.capture3(
      "python",
      "-c",
      "import sys, tomllib; tomllib.load(open(sys.argv[1], 'rb'))",
      (ROOT / "templates/codex.config.toml.tpl").to_s
    )
    assert status.success?, "invalid Codex TOML template: #{error}"
  end

  def test_portable_skills_have_canonical_frontmatter
    MANIFEST.fetch("portable_skills").each do |name, registration|
      path = ROOT / registration.fetch("path")
      frontmatter = YAML.safe_load(path.read.match(/\A---\s*\n(.*?)\n---/m)[1])

      assert_equal name, frontmatter.fetch("name")
      refute_empty frontmatter.fetch("description")
      assert_equal %w[description name], frontmatter.keys.sort
      assert_includes path.read, "agent-workbench: managed portable-skill"
    end
  end

  def test_shared_routing_names_tiers_without_platform_settings
    routing = shared_routing_text
    tiers = markdown_table(routing, "| Tier | Selection rule |").map(&:first)
    bindings = markdown_table(routing, "| Runtime | Binding | Loading |").to_h { |cells| cells.first(2) }

    assert_equal TIERS.map { |tier| "`#{tier}`" }, tiers
    refute_match PLATFORM_SETTING_PATTERN, routing
    assert_includes bindings.fetch("Claude Code"), "`.claude/rules/agent-routing.md`"
    assert_includes bindings.fetch("Claude Code"), "`.claude/agents/`"
    assert_includes bindings.fetch("Codex"), "`.codex/agent-routing.md`"
  end

  def test_shared_skill_assignments_cover_exactly_the_portable_skills
    rows = skill_assignments(shared_routing_text)
    routes = rows.flat_map { |row| row.fetch(:routes) }

    assert_equal MANIFEST.fetch("portable_skills").keys.sort, routes.sort
    assert_equal routes.uniq, routes, "each skill must resolve to exactly one row"
    assert_valid_assignments rows
  end

  def test_codex_binding_maps_every_tier_and_owns_the_codex_skill_catalog
    binding = (ROOT / CODEX_BINDING).read
    mapping = markdown_table(binding, "| Tier | Model | Effort |").to_h do |cells|
      [cells.fetch(0).delete("`"), [cells.fetch(1).delete("`"), cells.fetch(2).delete("`")]]
    end
    rows = skill_assignments(binding)
    routes = rows.flat_map { |row| row.fetch(:routes) }

    assert_equal TIERS, mapping.keys
    assert_equal CODEX_TIER_BINDING, mapping
    assert_equal CODEX_SKILL_ROUTES.sort, routes.sort, "routing must match the supported Codex skill catalog exactly"
    assert_equal routes.uniq, routes, "each skill must resolve to exactly one row"
    assert_empty routes & MANIFEST.fetch("portable_skills").keys, "portable skills belong in the shared guide"
    assert_valid_assignments rows
    %w[reasoning_effort fork_turns].each { |field| assert_includes binding, "`#{field}`" }
    assert_includes binding, "agent-workbench: managed platform-binding"
  end

  def test_claude_binding_maps_every_tier_to_a_matching_subagent
    binding = (ROOT / CLAUDE_BINDING).read
    rows = markdown_table(binding, "| Tier | Model | Effort | Subagent |")
    mapping = rows.to_h do |cells|
      effort = cells.fetch(2) == "none" ? nil : cells.fetch(2).delete("`")
      [cells.fetch(0).delete("`"), [cells.fetch(1).delete("`"), effort]]
    end

    assert_equal TIERS, mapping.keys
    assert_equal CLAUDE_TIER_BINDING, mapping
    assert_equal TIERS.map { |tier| "`tier-#{tier}`" }, rows.map { |cells| cells.fetch(3) }
    assert_includes binding, "agent-workbench: managed platform-binding"

    templates = Dir[ROOT / CLAUDE_TIER_AGENTS / "*.md.tpl"].map { |path| File.basename(path, ".md.tpl") }
    assert_equal TIERS.map { |tier| "tier-#{tier}" }.sort, templates.sort
    CLAUDE_TIER_BINDING.each do |tier, (model, effort)|
      content = (ROOT / CLAUDE_TIER_AGENTS / "tier-#{tier}.md.tpl").read
      frontmatter = YAML.safe_load(content.match(/\A---\n(.*?)\n---\n/m)[1])

      assert_equal "tier-#{tier}", frontmatter.fetch("name")
      refute_empty frontmatter.fetch("description")
      assert_equal model, frontmatter.fetch("model")
      effort ? assert_equal(effort, frontmatter.fetch("effort")) : refute(frontmatter.key?("effort"))
      assert_equal "Agent", frontmatter.fetch("disallowedTools"), "tier workers must not delegate further"
      expected_keys = %w[description disallowedTools model name] + (effort ? %w[effort] : [])
      assert_equal expected_keys.sort, frontmatter.keys.sort
      assert_includes content, "agent-workbench: managed platform-binding"
      assert_includes content, "the `#{tier}` tier"
    end
  end

  def test_stage_escalations_name_only_tiers
    rows = skill_assignments(shared_routing_text) + skill_assignments((ROOT / CODEX_BINDING).read)

    rows.each do |row|
      references = row.fetch(:stage).scan(/`([^`]+)`/).flatten
      assert_empty references - TIERS, "#{row.fetch(:routes).first} escalates to something other than a tier"
    end
  end

  def test_portable_skills_route_through_bindings_without_platform_settings
    MANIFEST.fetch("portable_skills").each do |name, registration|
      skill = (ROOT / registration.fetch("path")).read
      assert_includes skill.gsub(/\s+/, " "), "platform binding", "#{name} must resolve tiers through a binding"
      refute_match PLATFORM_SETTING_PATTERN, skill, "#{name} carries platform-specific routing"
    end
  end

  def test_managed_path_allowlists_name_every_platform_binding
    sync = (ROOT / "prompts/sync-agent-workbench.md").read
    allowlists = {
      "sync write allowlist" => markdown_section(sync, "## Hard safety rules"),
      "sync deletion scope" => markdown_section(sync, "### Generated artifact deletion scope"),
      "repair allowlist" => markdown_section((ROOT / "prompts/repair-agent-workbench.md").read, "## Allowed repairs"),
      "guide allowlist" => markdown_section((ROOT / "guide/security.md").read, "## Generated Instruction Files"),
      "audit checks" => markdown_section((ROOT / "prompts/audit-agent-workbench.md").read, "## Checks")
    }

    allowlists.each do |name, section|
      [".codex/agent-routing.md", ".claude/rules/agent-routing.md", ".claude/agents/"].each do |path|
        assert_includes section, path, "#{name} omits #{path}"
      end
    end
    bindings = markdown_section(sync, "## Platform routing bindings")
    %w[targets.claude targets.codex].each { |target| assert_includes bindings, "`#{target}: true`" }
  end

  def test_platform_bindings_at_the_root_match_their_templates
    PLATFORM_BINDINGS.each do |output, template|
      assert_equal (ROOT / template).read, (ROOT / output).read, "#{output} differs from #{template}"
    end

    templates = Dir[ROOT / CLAUDE_TIER_AGENTS / "*.md.tpl"].map { |path| File.basename(path, ".tpl") }
    outputs = Dir[ROOT / ".claude/agents/*.md"].map { |path| File.basename(path) }
    assert_equal templates.sort, outputs.sort
    templates.each do |name|
      assert_equal (ROOT / CLAUDE_TIER_AGENTS / "#{name}.tpl").read, (ROOT / ".claude/agents" / name).read
    end
  end

  def test_sync_distributes_platform_bindings_by_target
    sync = (ROOT / "prompts/sync-agent-workbench.md").read
    [
      "`templates/claude.agent-routing.md.tpl` -> `.claude/rules/agent-routing.md`",
      "`templates/claude-agents/<name>.md.tpl` -> `.claude/agents/<name>.md`",
      "`templates/codex.agent-routing.md.tpl` -> `.codex/agent-routing.md`",
      "agent-workbench: managed platform-binding",
      "`platform_binding`"
    ].each { |fragment| assert_includes sync, fragment }

    registered = MANIFEST.fetch("templates").transform_values { |entry| entry.fetch("path") }
    assert_equal CLAUDE_BINDING, registered.fetch("claude_routing")
    assert_equal CLAUDE_TIER_AGENTS, registered.fetch("claude_tier_agents")
    assert_equal CODEX_BINDING, registered.fetch("codex_routing")
  end

  def test_sync_prompt_pins_ledger_record_conventions
    conventions, rows = ledger_conventions
    provenance = markdown_section((ROOT / "prompts/sync-agent-workbench.md").read, "## Provenance ledger and removal detection")
    example = JSON.parse(provenance[/```json\n(.*?)\n```/m, 1])
    record = example.fetch("installedArtifacts").first
    field_order = conventions[/^- Give every managed record these fields in this order: (.*)$/, 1].scan(/`([^`]+)`/).flatten - ["true"]

    assert_equal LEDGER_TOP_LEVEL_FIELDS, example.keys
    assert_equal LEDGER_SCOPES, example.fetch("scopes").keys
    assert_equal LEDGER_RECORD_FIELDS, field_order
    assert_equal LEDGER_RECORD_FIELDS, record.keys
    assert_equal ledger_id(record), record.fetch("id")
    record.fetch("resourceManifest").each { |entry| assert_equal %w[path sourceChecksum lastAppliedOutputChecksum], entry.keys }

    assert_equal LEDGER_ID_PATTERNS.keys.sort, rows.keys.sort
    LEDGER_KIND_SCOPES.each { |kind, scope| assert_equal "`#{scope}`", rows.fetch(kind).fetch(1) }
    assert_equal "`AI_AGENT_GUIDE.md`", rows.fetch("guide").fetch(3)
    assert_equal "`#{MANIFEST.dig("templates", "guide", "path")}`", rows.fetch("guide").fetch(4)
    entrypoints, vendor_configs = conventions[/^- `entrypoint` records cover (.*)$/, 1].split("`vendor_config` records cover")
    %w[CLAUDE.md AGENTS.md GEMINI.md].each { |path| assert_includes entrypoints, "`#{path}`" }
    %w[opencode.json .codex/config.toml].each { |path| assert_includes vendor_configs, "`#{path}`" }
    removal_fields = conventions[/^- A new `retainedRemovals` entry has (.*)$/, 1].scan(/`([^`]+)`/).flatten
    assert_equal %w[id outputPath status recordedAt reason], removal_fields
    LEDGER_ID_PATTERNS.each { |kind, pattern| assert_includes rows.fetch(kind).fetch(2), "`#{pattern}`" }
    assert_includes rows.fetch("portable_skill").fetch(2), "`#{LEDGER_ID_PATTERNS.fetch("portable_skill")}:claude`"

    sources = {
      "guide" => [MANIFEST.dig("templates", "guide", "path")],
      "entrypoint" => %w[claude agents gemini].map { |key| MANIFEST.dig("templates", key, "path") },
      "vendor_config" => %w[opencode codex].map { |key| MANIFEST.dig("templates", key, "path") },
      "platform_binding" => [CLAUDE_BINDING, CODEX_BINDING] +
        Dir[ROOT / CLAUDE_TIER_AGENTS / "*.md.tpl"].map { |path| "#{CLAUDE_TIER_AGENTS}/#{File.basename(path)}" },
      "portable_prompt" => MANIFEST.fetch("portable_prompts").values.map { |entry| entry.fetch("path") },
      "portable_skill" => MANIFEST.fetch("portable_skills").values.map { |entry| entry.fetch("path") }
    }
    sources.each do |kind, paths|
      marker = rows.fetch(kind).fetch(5).delete("`")
      paths.each do |path|
        text = (ROOT / path).read
        if marker == "none"
          refute_includes text, "agent-workbench: managed", "#{path} carries a marker its ledger kind does not record"
        else
          assert_includes text, marker, "#{path} lacks the #{kind} marker"
        end
      end
    end
  end

  def test_conversation_integration_uses_a_mixed_leader_and_fail_closed_math_gate
    row = skill_assignments(shared_routing_text).find do |entry|
      entry.fetch(:routes) == ["integrate-chatgpt-conversation"]
    end
    refute_nil row
    assert_equal "`mixed`", row.fetch(:tier)
    assert_equal "Parent-bound tool", row.fetch(:delivery)

    skill = (ROOT / "skills/integrate-chatgpt-conversation/SKILL.md").read.gsub(/\s+/, " ")
    required_contracts = [
      "active host policy named by the project guide and its model-routing guidance",
      "mixed technical/editorial tier as the controller default",
      "explicitly limited to retrieval or literal extraction",
      "retrieval, literal-extraction, synthesis, or review-only endpoint",
      "file-update endpoint",
      "separately requested repair endpoint",
      "Unless the user excludes repair, that authority includes the one bounded local repair",
      "does not authorize unrelated mathematical development",
      "substantive mathematical assertion or verdict from a synthesis or review-only endpoint",
      "Fail-Closed Mathematical Integration",
      "must not certify the conversation's mathematics",
      "If classification is uncertain, trigger the audit",
      "source-bound pre-audit packet",
      "complete source-bound packet",
      "Reuse the original adversarial reviewer for this ordinary recheck by default",
      "fresh reviewer only for a main theorem, a possible fatal gap",
      "exact claim, source proof and support, source locators, dependencies, and downstream uses remain unchanged",
      "authorized file-update or repair endpoint",
      "active normal research-mathematics tier",
      "Do not commission this repair pass for a retrieval, synthesis, or review-only endpoint",
      "do not establish an essential gap and do not bar feasible authorized reconstruction",
      "read-only endpoint instead returns the reviewed disposition and task in its response",
      "read-only response disposition records the same fields without writing them",
      "read-only endpoints make no project changes"
    ]
    required_contracts.each { |contract| assert_includes skill, contract }
    refute_match(/AI_AGENT_GUIDE\.md.*Skill Model and Reasoning Routing.*table/, skill)
    refute_includes skill, "exactly one bounded local repair attempt used for each consolidated packet"
  end

  def test_portable_skill_distribution_keeps_one_shared_core_and_a_claude_mirror
    assert_equal %w[
      commit-workflow
      guardrail-authoring
      integrate-chatgpt-conversation
      linus-review
      loop-until-done
      math-pdf-reader
      skill-authoring
      sync-agent-workbench
    ], MANIFEST.fetch("portable_skills").keys.sort
    refute MANIFEST.key?("capabilities")
    assert_empty Dir[ROOT / "capabilities/**/*"].select { |path| File.file?(path) }

    sync = (ROOT / "prompts/sync-agent-workbench.md").read
    assert_includes sync, "`.agents/skills/<name>/SKILL.md`"
    assert_includes sync, "`.claude/skills/<name>/SKILL.md`"
    assert_includes sync, "targets.claude"
    assert_includes sync, "Do not create vendor-specific mirrors"
    assert_includes sync, "neutral fallback skill"
    assert_includes sync, "registered managed source/resource set"
    assert_includes sync, "must be byte-identical"
    assert_includes sync, "selected `.claude/skills/` discovery-mirror artifacts"
    refute_includes sync, "capabilities/<name>/vendors"
  end

  def test_v1_lockfile_migration_reconciles_portable_records_and_preserves_other_evidence
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
      input = JSON.parse((FIXTURES / "lockfile-v1.json").read)
      original = JSON.parse(JSON.generate(input))
      digest = "sha256:#{'2' * 64}"
      commit = "3" * 40
      reconciled_at = "2026-08-13T12:00:00Z"

      migrated = AgentWorkbench::LockfileMigration.migrate(
        input,
        manifest,
        workbench_root: FIXTURE_WORKBENCH,
        consumer_root: consumer,
        expected_repo: FIXTURE_REPO,
        expected_branch: FIXTURE_BRANCH,
        expected_requested_ref: FIXTURE_REQUESTED_REF,
        manifest_digest: digest,
        resolved_commit: commit,
        reconciled_at: reconciled_at
      )

      assert_equal original, input, "migration mutated the v1 input"
      assert_equal 2, migrated.fetch("schemaVersion")
      assert_equal digest, migrated.fetch("manifestDigest")
      assert_equal commit, migrated.dig("source", "resolvedCommit")
      assert_equal reconciled_at, migrated.fetch("generatedAt")
      assert_equal original.fetch("retainedRemovals"), migrated.fetch("retainedRemovals")
      refute migrated.fetch("scopes").key?("vendor_adapters")
      assert_equal original.dig("scopes", "entrypoints"), migrated.dig("scopes", "entrypoints")
      %w[portable_prompts portable_skills].each do |scope|
        assert_equal({
          "resolvedCommit" => commit,
          "manifestDigest" => digest,
          "lastReconciledAt" => reconciled_at
        }, migrated.dig("scopes", scope))
      end

      artifacts = migrated.fetch("installedArtifacts").to_h { |artifact| [artifact.fetch("id"), artifact] }
      entrypoint = artifacts.fetch("entrypoint:AGENTS.md")
      assert_equal "entrypoints", entrypoint.fetch("scope")
      assert_equal "sha256:#{'a' * 64}", entrypoint.fetch("sourceChecksum")

      prompt = artifacts.fetch("portable_prompt:create-agent-skill")
      prompt_checksum = sha256(FIXTURE_WORKBENCH / "prompts/create-agent-skill.md")
      assert_equal prompt_checksum, prompt.fetch("sourceChecksum")
      assert_equal prompt_checksum, prompt.fetch("lastAppliedOutputChecksum")

      agent_skill = artifacts.fetch("portable_skill:sync-agent-workbench")
      claude_skill = artifacts.fetch("portable_skill:sync-agent-workbench:claude")
      skill_checksum = sha256(FIXTURE_WORKBENCH / "skills/sync-agent-workbench/SKILL.md")
      [agent_skill, claude_skill].each do |artifact|
        assert_equal "portable_skills", artifact.fetch("scope")
        assert_equal "skills/sync-agent-workbench/SKILL.md", artifact.fetch("sourcePath")
        assert_equal skill_checksum, artifact.fetch("sourceChecksum")
        assert_equal skill_checksum, artifact.fetch("lastAppliedOutputChecksum")
        assert_equal expected_fixture_resources, artifact.fetch("resourceManifest")
      end
      assert_equal original.fetch("installedArtifacts").last.fetch("localEditEvidence"),
                   claude_skill.fetch("localEditEvidence")

      rows = ledger_conventions.last
      migrated.fetch("installedArtifacts").each do |artifact|
        refute artifact.key?("capability")
        refute artifact.key?("vendor")
        next unless rows.key?(artifact.fetch("kind"))

        assert_equal ledger_id(artifact), artifact.fetch("id")
        assert_equal "`#{artifact.fetch("scope")}`", rows.fetch(artifact.fetch("kind")).fetch(1)
      end
    end
  end

  def test_v1_lockfile_migration_rejects_non_managed_output_paths
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
      input = JSON.parse((FIXTURES / "lockfile-v1.json").read)
      prompt = input.fetch("installedArtifacts").find { |artifact| artifact["kind"] == "portable_prompt" }
      prompt["outputPath"] = "src/application.rb"

      error = assert_raises(AgentWorkbench::LockfileMigrationError) do
        migrate_fixture(input, manifest, consumer)
      end
      assert_includes error.message, "no registered destination"
    end
  end

  def test_v1_lockfile_migration_rejects_non_managed_output_on_non_workflow_record
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
      input = JSON.parse((FIXTURES / "lockfile-v1.json").read)
      entrypoint = input.fetch("installedArtifacts").find { |artifact| artifact["kind"] == "entrypoint" }
      entrypoint["outputPath"] = "src/application.rb"

      error = assert_raises(AgentWorkbench::LockfileMigrationError) do
        migrate_fixture(input, manifest, consumer)
      end
      assert_includes error.message, "non-managed output path"
    end
  end

  def test_v1_lockfile_migration_rejects_incomplete_ledger_envelope
    manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
    error = assert_raises(AgentWorkbench::LockfileMigrationError) do
      AgentWorkbench::LockfileMigration.migrate(
        { "schemaVersion" => 1 },
        manifest,
        workbench_root: FIXTURE_WORKBENCH,
        consumer_root: FIXTURES,
        expected_repo: FIXTURE_REPO,
        expected_branch: FIXTURE_BRANCH,
        expected_requested_ref: FIXTURE_REQUESTED_REF,
        manifest_digest: "sha256:#{'2' * 64}",
        resolved_commit: "3" * 40,
        reconciled_at: "2026-08-13T12:00:00Z"
      )
    end
    assert_includes error.message, "v1 ledger missing required fields"
    assert_includes error.message, "installedArtifacts"
    assert_includes error.message, "scopes"
    assert_includes error.message, "targets"
    assert_includes error.message, "syncMode"
  end

  def test_v1_lockfile_migration_rejects_cross_source_provenance
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
      input = JSON.parse((FIXTURES / "lockfile-v1.json").read)
      input.fetch("source")["repo"] = "Other/unrelated-repository"

      error = assert_raises(AgentWorkbench::LockfileMigrationError) do
        migrate_fixture(input, manifest, consumer)
      end
      assert_includes error.message, "source.repo mismatch"
    end
  end

  def test_v1_lockfile_migration_rejects_duplicate_ids_and_outputs
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
      original = JSON.parse((FIXTURES / "lockfile-v1.json").read)
      entrypoint = original.fetch("installedArtifacts").first

      duplicate_output = JSON.parse(JSON.generate(original))
      duplicate_output.fetch("installedArtifacts") << entrypoint.merge("id" => "entrypoint:AGENTS.md:duplicate")
      error = assert_raises(AgentWorkbench::LockfileMigrationError) do
        migrate_fixture(duplicate_output, manifest, consumer)
      end
      assert_includes error.message, "duplicate v1 artifact output AGENTS.md"

      duplicate_id = JSON.parse(JSON.generate(original))
      duplicate_id.fetch("installedArtifacts") << entrypoint.merge(
        "sourcePath" => "templates/CLAUDE.md.tpl",
        "outputPath" => "CLAUDE.md"
      )
      error = assert_raises(AgentWorkbench::LockfileMigrationError) do
        migrate_fixture(duplicate_id, manifest, consumer)
      end
      assert_includes error.message, "duplicate v1 artifact id entrypoint:AGENTS.md"
    end
  end

  def test_v1_lockfile_migration_requires_reconciled_skill_bytes
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      (consumer / ".claude/skills/sync-agent-workbench/SKILL.md").write("legacy adapter prose\n")
      manifest = YAML.safe_load_file(FIXTURE_WORKBENCH / "manifest.yaml")
      input = JSON.parse((FIXTURES / "lockfile-v1.json").read)

      error = assert_raises(AgentWorkbench::LockfileMigrationError) do
        migrate_fixture(input, manifest, consumer)
      end
      assert_includes error.message, "differs from registered source"
    end
  end

  def test_v1_lockfile_migration_cli_writes_a_new_candidate_without_overwriting
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      input_path = consumer / "lockfile-v1.json"
      output_path = consumer / "lockfile-v2.candidate.json"
      FileUtils.cp(FIXTURES / "lockfile-v1.json", input_path)
      command = [
        "ruby",
        (ROOT / "skills/sync-agent-workbench/scripts/migrate_lockfile.rb").to_s,
        (FIXTURE_WORKBENCH / "manifest.yaml").to_s,
        consumer.to_s,
        input_path.to_s,
        output_path.to_s,
        FIXTURE_REPO,
        FIXTURE_BRANCH,
        FIXTURE_REQUESTED_REF,
        "sha256:#{'2' * 64}",
        "3" * 40,
        "2026-08-13T12:00:00Z"
      ]

      _output, error, status = Open3.capture3(*command)
      assert status.success?, error
      assert_equal 2, JSON.parse(output_path.read).fetch("schemaVersion")
      refute_includes output_path.binread, "\r", "the ledger candidate must use LF line endings on every platform"

      _output, error, status = Open3.capture3(*command)
      refute status.success?
      assert_includes error, "refusing to overwrite migration output"
    end
  end

  def test_skill_mirror_verifier_checks_registered_resources_but_allows_local_agent_files
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      (consumer / ".agents/skills/sync-agent-workbench/LOCAL.md").write("project-owned\n")

      assert_empty AgentWorkbench::SkillMirror.verify(FIXTURE_WORKBENCH, consumer, claude: true)

      claude_local = consumer / ".claude/skills/sync-agent-workbench/LOCAL.md"
      claude_local.write("not registered\n")
      errors = AgentWorkbench::SkillMirror.verify(FIXTURE_WORKBENCH, consumer, claude: true)
      assert_includes errors, ".claude/skills/sync-agent-workbench/LOCAL.md: unregistered mirror file"

      claude_local.delete
      (consumer / ".claude/skills/sync-agent-workbench/scripts/check.rb").write("changed\n")
      errors = AgentWorkbench::SkillMirror.verify(FIXTURE_WORKBENCH, consumer, claude: true)
      assert_includes errors,
                      ".claude/skills/sync-agent-workbench/scripts/check.rb: content differs from registered source"
    end
  end

  def test_skill_mirror_verifier_accepts_every_registered_workbench_skill
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      MANIFEST.fetch("portable_skills").each do |name, registration|
        source_directory = (ROOT / registration.fetch("path")).dirname
        %w[.agents .claude].each do |surface|
          destination = consumer / surface / "skills" / name
          FileUtils.mkdir_p(destination.parent)
          FileUtils.cp_r(source_directory, destination)
        end
      end

      assert_empty AgentWorkbench::SkillMirror.verify(ROOT, consumer, claude: true)
    end
  end

  def test_skill_mirror_verifier_rejects_symlinked_managed_files
    Dir.mktmpdir("agent-workbench-contract") do |directory|
      consumer = Pathname(directory)
      install_fixture_workflows(consumer)
      target = consumer / "outside-check.rb"
      target.write((FIXTURE_WORKBENCH / "skills/sync-agent-workbench/scripts/check.rb").read)
      link = consumer / ".claude/skills/sync-agent-workbench/scripts/check.rb"
      link.delete

      begin
        File.symlink(target, link)
      rescue Errno::EACCES, Errno::EPERM, NotImplementedError
        skip "symbolic links are unavailable in this environment"
      end

      errors = AgentWorkbench::SkillMirror.verify(FIXTURE_WORKBENCH, consumer, claude: true)
      assert_includes errors,
                      ".claude/skills/sync-agent-workbench/scripts/check.rb: managed path is a symlink"
    end
  end

  def test_real_vendor_loader_templates_remain_registered
    expected = %w[agents claude codex gemini opencode]
    assert expected.all? { |name| MANIFEST.fetch("templates").key?(name) }
  end

  def test_sync_contract_preserves_safety_and_state_boundaries
    sync = (ROOT / "prompts/sync-agent-workbench.md").read
    required_fragments = [
      "parent profile modules",
      "child profile modules",
      "explicit `modules:`",
      "agent-workbench:manual-begin",
      "agent-workbench:manual-end",
      "Do not modify application source code.",
      "Do not install dependencies.",
      "Never delete",
      "confirmed upstream removal",
      "confirmed removal with local edits",
      "suspected legacy removal",
      "deselected by local config",
      "source changed / migration required",
      "local unmanaged",
      "resourceManifest",
      "scripts/migrate_lockfile.rb",
      "scripts/verify_skill_mirror.rb",
      '"schemaVersion": 2',
      "Legacy capability metadata migration",
      "Match legacy records",
      "retainedRemovals",
      "repository-workspace",
      "Do not accept or synthesize an alias",
      "idempotence"
    ]

    required_fragments.each { |fragment| assert_includes sync, fragment }
  end

  def test_retired_workspace_module_is_not_registered_or_selected
    refute MANIFEST.fetch("modules").key?("workspace-config")
    Dir[ROOT / "profiles/*.yaml"].each do |path|
      refute_includes YAML.safe_load_file(path).fetch("modules", []), "workspace-config"
    end
  end

  private

  def shared_routing_text
    (ROOT / "guide/workflows.md").read.split("## Skill Model and Reasoning Routing", 2).fetch(1)
  end

  def module_body(profile)
    resolve_profile(profile).map do |name|
      (ROOT / MANIFEST.fetch("modules").fetch(name).fetch("path")).read.strip
    end.join(MODULE_SEPARATOR)
  end

  def render_guide(profile, manual_blocks)
    notes = manual_blocks.empty? ? "" : MANUAL_NOTES_HEADING + manual_blocks.map { |block| block + MANUAL_BLOCK_TERMINATOR }.join
    values = {
      "source" => "KiringYJ/agent-workbench",
      "profile" => profile,
      "manual_blocks" => notes,
      "modules" => module_body(profile)
    }
    (ROOT / "templates/AI_AGENT_GUIDE.md.tpl").read.gsub(/\{\{(\w+)\}\}/) { values.fetch(Regexp.last_match(1)) }
  end

  def ledger_conventions
    conventions = markdown_section((ROOT / "prompts/sync-agent-workbench.md").read, "### Ledger record conventions")
    [conventions, markdown_table(conventions, LEDGER_TABLE_HEADER).to_h { |cells| [cells.first.delete("`"), cells] }]
  end

  def ledger_id(artifact)
    id = LEDGER_ID_PATTERNS.fetch(artifact.fetch("kind"))
                           .sub("<output path>", artifact.fetch("outputPath")).sub("<name>", artifact.fetch("name"))
    artifact.fetch("outputPath").start_with?(".claude/skills/") ? "#{id}:claude" : id
  end

  def markdown_section(text, heading)
    level = heading[/\A#+/].length
    body = text.split("#{heading}\n", 2)
    assert_equal 2, body.length, "missing section: #{heading}"
    body.fetch(1).lines.take_while { |line| !line.match?(/\A\#{1,#{level}} /) }.join
  end

  def markdown_table(text, header)
    lines = text.lines.map(&:strip)
    start = lines.index(header)
    refute_nil start, "missing table: #{header}"
    lines.drop(start + 2).take_while { |line| line.start_with?("|") }.map do |line|
      line.split("|").map(&:strip).drop(1)
    end
  end

  def skill_assignments(text)
    markdown_table(text, SKILL_TABLE_HEADER).map do |cells|
      {
        routes: cells.fetch(0).scan(/`([^`]+)`/).flatten,
        tier: cells.fetch(1),
        delivery: cells.fetch(2),
        stage: cells.fetch(3)
      }
    end
  end

  def assert_valid_assignments(rows)
    refute_empty rows
    rows.each do |row|
      assert_includes TIERS.map { |tier| "`#{tier}`" }, row.fetch(:tier), "#{row.fetch(:routes).first} has no known tier"
      assert_includes DELIVERY_MODES, row.fetch(:delivery), "#{row.fetch(:routes).first} has no known delivery"
    end
  end

  def install_fixture_workflows(consumer)
    prompt_directory = consumer / ".agents/prompts"
    FileUtils.mkdir_p(prompt_directory)
    FileUtils.cp(FIXTURE_WORKBENCH / "prompts/create-agent-skill.md", prompt_directory / "create-agent-skill.md")

    %w[.agents .claude].each do |surface|
      destination = consumer / surface / "skills/sync-agent-workbench"
      FileUtils.mkdir_p(destination.parent)
      FileUtils.cp_r(FIXTURE_WORKBENCH / "skills/sync-agent-workbench", destination)
    end
  end

  def migrate_fixture(input, manifest, consumer)
    AgentWorkbench::LockfileMigration.migrate(
      input,
      manifest,
      workbench_root: FIXTURE_WORKBENCH,
      consumer_root: consumer,
      expected_repo: FIXTURE_REPO,
      expected_branch: FIXTURE_BRANCH,
      expected_requested_ref: FIXTURE_REQUESTED_REF,
      manifest_digest: "sha256:#{'2' * 64}",
      resolved_commit: "3" * 40,
      reconciled_at: "2026-08-13T12:00:00Z"
    )
  end

  def expected_fixture_resources
    %w[references/policy.md scripts/check.rb].map do |path|
      checksum = sha256(FIXTURE_WORKBENCH / "skills/sync-agent-workbench" / path)
      {
        "path" => path,
        "sourceChecksum" => checksum,
        "lastAppliedOutputChecksum" => checksum
      }
    end
  end

  def sha256(path)
    "sha256:#{Digest::SHA256.file(path).hexdigest}"
  end

  def registered_paths
    MANIFEST.flat_map do |section, entries|
      next [] unless entries.is_a?(Hash)

      entries.values.filter_map { |entry| entry["path"] if entry.is_a?(Hash) }
    end
  end

  def resolve_profile(name, stack = [])
    raise "profile cycle: #{(stack + [name]).join(' -> ')}" if stack.include?(name)

    registration = MANIFEST.fetch("profiles").fetch(name)
    profile = YAML.safe_load_file(ROOT / registration.fetch("path"))
    parent = profile["extends"]
    inherited = parent ? resolve_profile(parent, stack + [name]) : []
    inherited + profile.fetch("modules", []).reject { |module_name| inherited.include?(module_name) }
  end
end
