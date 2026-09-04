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
    module_body = resolve_profile("base").map do |name|
      (ROOT / MANIFEST.fetch("modules").fetch(name).fetch("path")).read.strip
    end.join("\n\n---\n\n")

    assert_equal "#{MANAGED_HEADER}\n\n#{module_body}\n", (ROOT / "AI_AGENT_GUIDE.md").read
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

  def test_removed_entrypoint_notes_remain_canonical_policy
    guide = (ROOT / "AI_AGENT_GUIDE.md").read
    assert_includes guide, "For non-trivial work, state or internally maintain a short plan"
    assert_includes guide, "Changed files grouped by purpose."
    assert_includes guide, "Verification commands and results."
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

  def test_portable_skill_distribution_keeps_one_shared_core_and_a_claude_mirror
    assert_equal %w[
      commit-workflow
      guardrail-authoring
      linus-review
      loop-until-done
      read-chatgpt-conversation
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

      migrated.fetch("installedArtifacts").each do |artifact|
        refute artifact.key?("capability")
        refute artifact.key?("vendor")
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
