# frozen_string_literal: true

require 'yaml'
require 'pathname'

module Worktrees
  module Models
    class WorktreeConfig
      DEFAULT_ROOT = '~/.worktrees'
      NAME_PATTERN = /^[0-9]{3}-[a-z0-9-]{1,40}$/
      RESERVED_NAMES = %w[main master].freeze

      attr_reader :worktrees_root, :default_base, :force_cleanup, :name_pattern

      def initialize(worktrees_root: DEFAULT_ROOT, default_base: nil, force_cleanup: false, name_pattern: NAME_PATTERN)
        @worktrees_root = worktrees_root
        @default_base = default_base
        @force_cleanup = force_cleanup
        @name_pattern = name_pattern
      end

      def self.load(config_path = default_config_path)
        if File.exist?(config_path)
          begin
            config_data = YAML.load_file(config_path)
            new(
              worktrees_root: config_data['worktrees_root'] || DEFAULT_ROOT,
              default_base: config_data['default_base'],
              force_cleanup: config_data['force_cleanup'] || false,
              name_pattern: config_data['name_pattern'] ? Regexp.new(config_data['name_pattern']) : NAME_PATTERN
            )
          rescue Psych::SyntaxError => e
            raise Error, "Invalid configuration file #{config_path}: #{e.message}"
          end
        else
          new
        end
      end

      def self.default_config_path
        File.join(Dir.home, '.worktrees', 'config.yml')
      end

      def valid_name?(name)
        return false unless name.is_a?(String)
        return false unless name.match?(@name_pattern)

        # Extract feature part after NNN-
        feature_part = name.split('-', 2)[1]
        return false if feature_part.nil?

        # Check for reserved names
        !RESERVED_NAMES.include?(feature_part.downcase)
      end

      def expand_worktrees_root
        File.expand_path(@worktrees_root)
      end

      def to_h
        {
          worktrees_root: @worktrees_root,
          default_base: @default_base,
          force_cleanup: @force_cleanup,
          name_pattern: @name_pattern.source
        }
      end
    end
  end
end
