# frozen_string_literal: true

require 'dry/cli'

module Worktrees
  module Commands
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
          # Create manager with options
          config = Models::WorktreeConfig.load
          if options[:'worktrees-root']
            config = Models::WorktreeConfig.new(
              worktrees_root: options[:'worktrees-root'],
              default_base: config.default_base,
              force_cleanup: config.force_cleanup
            )
          end

          manager = WorktreeManager.new(nil, config)
          create_options = options.select { |k, _| %i[force].include?(k) }

          worktree = manager.create_worktree(name, base_ref, create_options)

          # Display success message
          puts "Created worktree: #{worktree.name}"
          puts "  Path: #{worktree.path}"
          puts "  Branch: #{worktree.branch}"
          puts "  Base: #{worktree.base_ref}"
          puts "  Status: #{worktree.status}"

          # Switch to worktree if requested
          if options[:switch]
            manager.switch_to_worktree(name)
            puts "\nSwitched to worktree: #{name}"
          end

        rescue ValidationError => e
          warn "ERROR: Validation: #{e.message}"
          exit(2)
        rescue GitError => e
          warn "ERROR: Git: #{e.message}"
          exit(3)
        rescue StateError => e
          warn "ERROR: State: #{e.message}"
          exit(3)
        rescue StandardError => e
          warn "ERROR: #{e.message}"
          exit(1)
        end
      end

      private

      def validate_arguments(name, base_ref)
        raise ValidationError, 'Name is required' if name.nil?
        raise ValidationError, 'Name cannot be empty' if name.empty?

        # Additional argument validation could go here
      end
    end
  end
end