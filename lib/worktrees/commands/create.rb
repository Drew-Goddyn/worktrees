# frozen_string_literal: true

require 'dry/cli'

module Worktrees
  module Commands
    # Creates new feature worktrees with validation and git integration
    class Create < Dry::CLI::Command
      desc 'Create a new feature worktree'

      argument :name, required: true, desc: 'Feature name (NNN-kebab-feature format)'
      argument :base_ref, required: false, desc: 'Base branch/commit (defaults to repository default)'

      option :worktrees_root, type: :string, desc: 'Override worktrees root directory'
      option :force, type: :boolean, default: false, desc: 'Create even if validation warnings exist'
      option :switch, type: :boolean, default: false, desc: 'Switch to new worktree after creation'

      def call(name:, base_ref: nil, **options)
        validate_arguments(name, base_ref)

        begin
          manager = build_manager(options)
          worktree = create_worktree(manager, name, base_ref, options)
          display_success(worktree)
          handle_switch(manager, name, options)
        rescue ValidationError => e
          handle_error('Validation', e.message, 2)
        rescue GitError => e
          handle_error('Git', e.message, 3)
        rescue StateError => e
          handle_error('State', e.message, 3)
        rescue StandardError => e
          handle_error('', e.message, 1)
        end
      end

      private

      def validate_arguments(name, _base_ref)
        raise ValidationError, 'Name is required' if name.nil?
        raise ValidationError, 'Name cannot be empty' if name.empty?
      end

      def build_manager(options)
        config = Models::WorktreeConfig.load
        config = override_config(config, options) if options[:'worktrees-root']
        WorktreeManager.new(nil, config)
      end

      def override_config(config, options)
        Models::WorktreeConfig.new(
          worktrees_root: options[:'worktrees-root'],
          default_base: config.default_base,
          force_cleanup: config.force_cleanup
        )
      end

      def create_worktree(manager, name, base_ref, options)
        create_options = options.slice(:force)
        manager.create_worktree(name, base_ref, create_options)
      end

      def display_success(worktree)
        puts "Created worktree: #{worktree.name}"
        puts "  Path: #{worktree.path}"
        puts "  Branch: #{worktree.branch}"
        puts "  Base: #{worktree.base_ref}"
        puts "  Status: #{worktree.status}"
      end

      def handle_switch(manager, name, options)
        return unless options[:switch]

        manager.switch_to_worktree(name)
        puts "\nSwitched to worktree: #{name}"
      end

      def handle_error(type, message, exit_code)
        prefix = type.empty? ? 'ERROR:' : "ERROR: #{type}:"
        warn "#{prefix} #{message}"
        exit(exit_code)
      end
    end
  end
end
