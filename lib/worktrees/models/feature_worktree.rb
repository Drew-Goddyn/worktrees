# frozen_string_literal: true

require 'time'

module Worktrees
  module Models
    class FeatureWorktree
      NAME_PATTERN = /^[0-9]{3}-[a-z0-9-]{1,40}$/
      RESERVED_NAMES = %w[main master].freeze

      attr_reader :name, :path, :branch, :base_ref, :status, :created_at, :repository_path

      def initialize(name:, path:, branch:, base_ref:, status:, created_at:, repository_path:)
        @name = name
        @path = path
        @branch = branch
        @base_ref = base_ref
        @status = status
        @created_at = created_at
        @repository_path = repository_path

        validate!
      end

      def valid?
        return false unless @name.is_a?(String) && @name.match?(NAME_PATTERN)

        feature_part = @name.split('-', 2)[1]
        return false if feature_part.nil?
        return false if RESERVED_NAMES.include?(feature_part.downcase)

        return false if @path.nil? || @path.empty?
        return false if @branch.nil? || @branch.empty?
        return false if @base_ref.nil? || @base_ref.empty?

        true
      end

      def active?
        @status == :active
      end

      def dirty?
        @status == :dirty
      end

      def to_h
        {
          name: @name,
          path: @path,
          branch: @branch,
          base_ref: @base_ref,
          status: @status,
          created_at: @created_at,
          repository_path: @repository_path,
          active: active?
        }
      end

      def self.validate_name(name)
        return false unless name.is_a?(String)
        return false unless name.match?(NAME_PATTERN)

        # Extract feature part after NNN-
        feature_part = name.split('-', 2)[1]
        return false if feature_part.nil?

        # Check for reserved names
        !RESERVED_NAMES.include?(feature_part.downcase)
      end

      private

      def validate!
        # First check basic format
        unless @name.is_a?(String) && @name.match?(NAME_PATTERN)
          raise ValidationError,
                "Invalid name format '#{@name}'. Names must match pattern: NNN-kebab-feature"
        end

        # Check for reserved names
        feature_part = @name.split('-', 2)[1]
        if feature_part && RESERVED_NAMES.include?(feature_part.downcase)
          raise ValidationError,
                "Reserved name '#{feature_part}' not allowed in worktree names"
        end

        raise ValidationError, 'Path cannot be empty' if @path.nil? || @path.empty?
        raise ValidationError, 'Branch cannot be empty' if @branch.nil? || @branch.empty?
        raise ValidationError, 'Base reference cannot be empty' if @base_ref.nil? || @base_ref.empty?
      end
    end
  end
end
