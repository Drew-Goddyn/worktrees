# frozen_string_literal: true

module Worktrees
  module Models
    class Repository
      attr_reader :root_path

      def initialize(root_path)
        @root_path = File.expand_path(root_path)
        validate_git_repository!
      end

      def default_branch
        git_default_branch
      end

      def branch_exists?(branch_name)
        git_branch_exists?(branch_name)
      end

      def remote_url
        git_remote_url
      end

      def worktrees_path
        config.expand_worktrees_root
      end

      def config
        @config ||= WorktreeConfig.load
      end

      private

      def validate_git_repository!
        git_dir = File.join(@root_path, '.git')
        # .git can be either a directory (main repo) or a file (worktree)
        unless File.exist?(git_dir)
          raise GitError, "Not a git repository: #{@root_path}"
        end
      end

      def git_default_branch
        # Try to get default branch from remote HEAD
        result = `cd "#{@root_path}" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null`.strip
        if $?.success? && !result.empty?
          return result.split('/').last
        end

        # Fallback: check if main exists, then master
        if git_branch_exists?('main')
          'main'
        elsif git_branch_exists?('master')
          'master'
        else
          # Use current branch as last resort
          git_current_branch
        end
      end

      def git_branch_exists?(branch_name)
        system('git', 'show-ref', '--verify', '--quiet', "refs/heads/#{branch_name}", chdir: @root_path)
      end

      def git_current_branch
        `cd "#{@root_path}" && git rev-parse --abbrev-ref HEAD`.strip
      end

      def git_remote_url
        result = `cd "#{@root_path}" && git remote get-url origin 2>/dev/null`.strip
        $?.success? && !result.empty? ? result : nil
      end
    end
  end
end