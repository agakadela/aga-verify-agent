#!/usr/bin/env ruby
# frozen_string_literal: true

require "pathname"
require "yaml"

ROOT = Pathname.new(__dir__).join("..").realpath
ERRORS = []

CASE_FILES = %w[
  tests/correct-small-change.md
  tests/misaligned-task.md
  tests/stale-or-dirty-evidence.md
  tests/high-risk-insufficient-proof.md
].freeze

CASE_HEADINGS = [
  "## Input",
  "## Authoritative Task",
  "## Agent Claims",
  "## Evidence Identity",
  "## Expected Verdict",
  "## Expected Workflow Action",
  "## Last Actual Result"
].freeze

VERDICTS = %w[
  VERIFIED
  PARTIALLY_VERIFIED
  NOT_VERIFIED
  MISALIGNED
  UNSAFE_TO_MERGE
].freeze

WORKFLOW_ACTIONS = [
  "PROCEED TO CODE REVIEW",
  "PROCEED TO TEST",
  "HOLD",
  "SPLIT / ISOLATE",
  "DO NOT MERGE",
  "REVERT CANDIDATE",
  "MERGE CANDIDATE"
].freeze

def parse_yaml(content, label)
  YAML.safe_load(content, permitted_classes: [], permitted_symbols: [], aliases: false)
rescue Psych::Exception => e
  ERRORS << "#{label}: invalid YAML (#{e.message.lines.first.strip})"
  nil
end

def frontmatter(path)
  content = path.read
  match = content.match(/\A---\s*\n(.*?)\n---\s*\n/m)
  unless match
    ERRORS << "#{path.relative_path_from(ROOT)}: missing YAML frontmatter"
    return nil
  end

  parse_yaml(match[1], path.relative_path_from(ROOT).to_s)
end

skill_path = ROOT.join("SKILL.md")
skill_metadata = frontmatter(skill_path)

if skill_metadata
  keys = skill_metadata.keys.map(&:to_s).sort
  ERRORS << "SKILL.md: frontmatter must contain only name and description" unless keys == %w[description name]
  ERRORS << "SKILL.md: name must be aga-verify-agent" unless skill_metadata["name"] == "aga-verify-agent"
  description = skill_metadata["description"]
  ERRORS << "SKILL.md: description must be a non-empty string" unless description.is_a?(String) && !description.strip.empty?
end

Dir.glob(ROOT.join("**", "*.{yaml,yml}"), File::FNM_DOTMATCH).sort.each do |filename|
  path = Pathname.new(filename)
  next if path.each_filename.include?(".git")

  parse_yaml(path.read, path.relative_path_from(ROOT).to_s)
end

skill_path.read.scan(/`((?:references|scripts|tests)\/[^`\s]+)`/).flatten.each do |relative|
  ERRORS << "SKILL.md: missing referenced path #{relative}" unless ROOT.join(relative).exist?
end

Dir.glob(ROOT.join("**", "*.md"), File::FNM_DOTMATCH).sort.each do |filename|
  path = Pathname.new(filename)
  next if path.each_filename.include?(".git")

  path.read.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |target|
    clean_target = target.strip.delete_prefix("<").delete_suffix(">")
    next if clean_target.empty? || clean_target.start_with?("#")
    next if clean_target.match?(%r{\A(?:https?://|mailto:)})

    relative_target = clean_target.split("#", 2).first
    resolved = path.dirname.join(relative_target).cleanpath
    unless resolved.exist?
      ERRORS << "#{path.relative_path_from(ROOT)}: broken internal link #{target}"
    end
  end
end

CASE_FILES.each do |relative|
  path = ROOT.join(relative)
  unless path.file?
    ERRORS << "missing behavioral case #{relative}"
    next
  end

  content = path.read
  CASE_HEADINGS.each do |heading|
    ERRORS << "#{relative}: missing heading #{heading}" unless content.include?(heading)
  end

  verdict = content[/## Expected Verdict\s+`([^`]+)`/m, 1]
  action = content[/## Expected Workflow Action\s+`([^`]+)`/m, 1]
  ERRORS << "#{relative}: invalid or missing expected verdict" unless VERDICTS.include?(verdict)
  ERRORS << "#{relative}: invalid or missing expected workflow action" unless WORKFLOW_ACTIONS.include?(action)

  %w[Date Runner Model Result].each do |field|
    ERRORS << "#{relative}: Last Actual Result is missing #{field}" unless content.match?(/^- #{field}:\s+\S+/)
  end

  if content.match?(/^- Result:\s+PENDING\b/)
    ERRORS << "#{relative}: behavioral case has not been run"
  end
end

if ERRORS.empty?
  puts "PASS: skill structure, YAML, internal links, reference paths, and #{CASE_FILES.length} behavioral cases"
  exit 0
end

warn "FAIL: #{ERRORS.length} validation error(s)"
ERRORS.each { |error| warn "- #{error}" }
exit 1
