# frozen_string_literal: true

require 'English'
module Worktrees
  module GitOperations
    class << self
      def create_worktree(path, branch, base_ref)
        # Check if branch already exists
        if branch_exists?(branch)
          # Checkout existing branch
          system('git', 'worktree', 'add', path, branch)
        else
          # Create new branch from base_ref
          system('git', 'worktree', 'add', '-b', branch, path, base_ref)
        end
      end

      def list_worktrees
        output = `git worktree list --porcelain 2>&1`
        raise GitError, 'Failed to list worktrees: git command failed' unless $CHILD_STATUS.success?

        # Additional check - if not in a git repo, the output will contain error messages
        raise GitError, 'Failed to list worktrees: not in a git repository' if output.include?('not a git repository') || output.include?('fatal:')

        parse_worktree_list(output)
      rescue StandardError => e
        raise GitError, "Failed to list worktrees: #{e.message}"
      end

      def remove_worktree(path, force: false)
        args = %w[git worktree remove]
        args << '--force' if force
        args << path

        system(*args)
      end

      def branch_exists?(branch_name)
        system('git', 'show-ref', '--verify', '--quiet', "refs/heads/#{branch_name}")
      end

      def current_branch
        `git rev-parse --abbrev-ref HEAD`.strip
      end

      def is_clean?(worktree_path)
        # git diff-index --quiet returns 0 if clean, 1 if dirty
        # We want to return true if clean, false if dirty
        system('git', 'diff-index', '--quiet', 'HEAD', chdir: worktree_path)
      end

      def has_unpushed_commits?(_branch_name)
        output = `git rev-list @{u}..HEAD`
        $CHILD_STATUS.success? && !output.strip.empty?
      rescue StandardError
        # No upstream branch or other error - consider as no unpushed commits
        false
      end

      def fetch_ref(ref)
        system('git', 'fetch', 'origin', ref)
      end

      def delete_branch(branch_name, force: false)
        flag = force ? '-D' : '-d'
        system('git', 'branch', flag, branch_name)
      end

      def is_merged?(branch_name, base_branch = 'main')
        # Check if all commits in branch_name are reachable from base_branch
        system('git', 'merge-base', '--is-ancestor', branch_name, base_branch)
      end

      private

      def parse_worktree_list(output)
        worktrees = []
        current_worktree = {}

        output.each_line do |line|
          line.strip!
          next if line.empty?

          case line
          when /^worktree (.+)$/
            # Save previous worktree if exists
            worktrees << current_worktree unless current_worktree.empty?
            current_worktree = { path: ::Regexp.last_match(1) }
          when /^HEAD (.+)$/
            current_worktree[:commit] = ::Regexp.last_match(1)
          when /^branch (.+)$/
            current_worktree[:branch] = ::Regexp.last_match(1).sub('refs/heads/', '')
          when /^detached$/
            current_worktree[:detached] = true
          when /^bare$/
            current_worktree[:bare] = true
          end
        end

        # Add the last worktree
        worktrees << current_worktree unless current_worktree.empty?

        # Filter out bare and main repository worktrees
        worktrees.reject { |wt| wt[:bare] || wt[:path]&.end_with?('/.git') }
      end
    end
  end
end
