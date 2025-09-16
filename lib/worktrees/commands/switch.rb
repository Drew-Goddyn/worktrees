# frozen_string_literal: true

require 'dry/cli'

module Worktrees
  module Commands
    class Switch < Dry::CLI::Command
      desc 'Switch to a different worktree'

      argument :name, required: true, desc: 'Name of worktree to switch to'

      option :force, type: :boolean, default: false, desc: 'Switch even if current worktree is dirty'

      def call(name:, **options)
        begin
          manager = WorktreeManager.new

          # Check if target worktree exists
          target_worktree = manager.find_worktree(name)
          unless target_worktree
            raise ValidationError, "Worktree '#{name}' not found"
          end

          # Check current state for warnings/blocking
          current = manager.current_worktree
          if current && current.dirty? && !options[:force]
            # Per requirements: allow switch with warning (not blocking)
            warn "Warning: Previous worktree '#{current.name}' has uncommitted changes"
          end

          # Perform the switch
          switched_worktree = manager.switch_to_worktree(name)

          puts "Switched to worktree: #{switched_worktree.name}"
          puts "  Path: #{switched_worktree.path}"
          puts "  Branch: #{switched_worktree.branch}"
          puts "  Status: #{switched_worktree.status}"

          # Show previous worktree warning if applicable
          if current && current.dirty?
            puts "\nWarning: Previous worktree '#{current.name}' has uncommitted changes"
          end

        rescue ValidationError => e
          warn "ERROR: Validation: #{e.message}"
          exit(2)
        rescue StateError => e
          warn "ERROR: State: #{e.message}"
          exit(3)
        rescue StandardError => e
          warn "ERROR: #{e.message}"
          exit(1)
        end
      end
    end
  end
end