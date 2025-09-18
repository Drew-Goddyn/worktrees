# frozen_string_literal: true

require 'dry/cli'

module Worktrees
  module Commands
    class Remove < Dry::CLI::Command
      desc 'Remove a worktree safely'

      argument :name, required: true, desc: 'Name of worktree to remove'

      option :delete_branch, type: :boolean, default: false, desc: 'Also delete the associated branch (only if fully merged)'
      option :force_untracked, type: :boolean, default: false, desc: 'Force removal even if untracked files exist'
      option :merge_base, type: :string, desc: 'Specify merge base for branch deletion safety check'
      option :force, type: :boolean, default: false, desc: 'Force removal (dangerous)'

      def call(name:, **options)
        begin
          manager = WorktreeManager.new

          # Build options hash
          remove_options = {
            delete_branch: options[:delete_branch],
            force_untracked: options[:force_untracked],
            force: options[:force]
          }
          remove_options[:merge_base] = options[:merge_base] if options[:merge_base]

          # Remove the worktree
          result = manager.remove_worktree(name, remove_options)

          if result
            puts "Removed worktree: #{name}"
            puts "  Path: (deleted)"

            if options[:delete_branch]
              puts "  Branch: #{name} (deleted)"
            else
              puts "  Branch: #{name} (kept)"
              puts ''
              puts 'Note: Use --delete-branch to also remove the branch if fully merged'
            end
          end

        rescue ValidationError => e
          warn "ERROR: Validation: #{e.message}"
          warn 'Use \'worktrees list\' to see existing worktrees'
          exit(2)
        rescue NotFoundError => e
          warn "ERROR: #{e.message}"
          exit(2)
        rescue StateError => e
          warn "ERROR: Precondition: #{e.message}"
          exit(3)
        rescue GitError => e
          warn "ERROR: Git: #{e.message}"
          exit(3)
        rescue StandardError => e
          warn "ERROR: #{e.message}"
          exit(1)
        end
      end
    end
  end
end