# frozen_string_literal: true

require 'English'
require 'fileutils'

module Worktrees
  class WorktreeManager
    attr_reader :repository, :config

    def initialize(repository = nil, config = nil)
      begin
        repo_root = find_git_repository_root
        @repository = repository || Models::Repository.new(repo_root)
      rescue GitError => e
        # Re-raise with more context if we're not in a git repo
        raise GitError, "Not in a git repository. #{e.message}"
      end
      @config = config || Models::WorktreeConfig.load
    end

    def create_worktree(name, base_ref = nil, _options = {})
      # Validate arguments
      raise ValidationError, 'Name is required' if name.nil?
      raise ValidationError, 'Name cannot be empty' if name.empty?

      # Use FeatureWorktree validation for better error messages
      unless Models::FeatureWorktree.validate_name(name)
        # Check what specific error to show
        unless name.match?(Models::FeatureWorktree::NAME_PATTERN)
          raise ValidationError,
                "Invalid name format '#{name}'. Names must match pattern: NNN-kebab-feature"
        end

        feature_part = name.split('-', 2)[1]
        if feature_part && Models::FeatureWorktree::RESERVED_NAMES.include?(feature_part.downcase)
          raise ValidationError, "Reserved name '#{feature_part}' not allowed in worktree names"
        end
      end

      # Use default base if none provided
      base_ref ||= @repository.default_branch

      # Check if base reference exists
      raise GitError, "Base reference '#{base_ref}' not found" unless @repository.branch_exists?(base_ref)

      # Check for duplicate worktree
      existing = find_worktree(name)
      raise ValidationError, "Worktree '#{name}' already exists" if existing

      # Create worktree path
      worktree_path = File.join(@config.expand_worktrees_root, name)

      # Create worktrees root directory if it doesn't exist
      FileUtils.mkdir_p(@config.expand_worktrees_root)

      # Create the worktree
      raise GitError, "Failed to create worktree '#{name}'" unless GitOperations.create_worktree(worktree_path, name,
                                                                                                 base_ref)

      # Verify worktree was created
      unless File.directory?(worktree_path)
        raise FileSystemError,
              "Worktree directory was not created: #{worktree_path}"
      end

      # Return the created worktree
      Models::FeatureWorktree.new(
        name: name,
        path: worktree_path,
        branch: name,
        base_ref: base_ref,
        status: :clean,
        created_at: Time.now,
        repository_path: @repository.root_path
      )
    end

    def list_worktrees(format: :objects, status: nil)
      git_worktrees = GitOperations.list_worktrees
      worktrees = []

      git_worktrees.each do |git_wt|
        next unless git_wt[:path] && File.directory?(git_wt[:path])

        # Extract name from path
        name = File.basename(git_wt[:path])
        next unless @config.valid_name?(name)

        # Determine status
        wt_status = determine_status(git_wt[:path])

        # Skip if status filter doesn't match
        next if status && wt_status != status

        worktree = Models::FeatureWorktree.new(
          name: name,
          path: git_wt[:path],
          branch: git_wt[:branch] || name,
          base_ref: detect_base_ref(git_wt[:branch] || name),
          status: wt_status,
          created_at: File.ctime(git_wt[:path]),
          repository_path: @repository.root_path
        )

        worktrees << worktree
      end

      worktrees.sort_by(&:name)
    end

    def find_worktree(name)
      worktrees = list_worktrees
      worktrees.find { |wt| wt.name == name }
    end

    def switch_to_worktree(name)
      worktree = find_worktree(name)
      raise ValidationError, "Worktree '#{name}' not found" unless worktree

      # Check current state for warnings
      current = current_worktree
      warn "Warning: Previous worktree '#{current.name}' has uncommitted changes" if current&.dirty?

      # Change to worktree directory
      Dir.chdir(worktree.path)
      worktree
    end

    def remove_worktree(name, options = {})
      worktree = find_worktree(name)
      raise NotFoundError, "Worktree '#{name}' not found" unless worktree

      # Safety checks
      if worktree.active?
        raise StateError,
              "Cannot remove active worktree '#{name}'. Switch to a different worktree first"
      end

      if worktree.dirty? && !options[:force_untracked]
        raise StateError,
              "Worktree '#{name}' has uncommitted changes. Commit or stash changes, or use --force-untracked for untracked files only"
      end

      # Check for unpushed commits
      if GitOperations.has_unpushed_commits?(worktree.branch)
        raise StateError,
              "Worktree '#{name}' has unpushed commits. Push commits first or use --force"
      end

      # Remove the worktree
      force = options[:force_untracked] || options[:force]
      raise GitError, "Failed to remove worktree '#{name}'" unless GitOperations.remove_worktree(worktree.path,
                                                                                                 force: force)

      # Optionally delete branch
      if options[:delete_branch]
        unless GitOperations.is_merged?(worktree.branch)
          raise StateError,
                "Branch '#{worktree.branch}' is not fully merged. Use merge-base check or --force"
        end

        GitOperations.delete_branch(worktree.branch)

      end

      true
    end

    def current_worktree
      current_path = Dir.pwd
      worktrees = list_worktrees

      worktrees.find do |worktree|
        current_path.start_with?(worktree.path)
      end
    end

    private

    def find_git_repository_root
      # Use git to find the main repository root (not worktree)
      result = `git rev-parse --git-common-dir 2>/dev/null`.strip
      if $CHILD_STATUS.success? && !result.empty?
        # git-common-dir returns the .git directory, we need its parent
        File.dirname(result)
      else
        # Fallback: try to find repository by walking up directories
        current_dir = Dir.pwd
        while current_dir != '/'
          return current_dir if File.exist?(File.join(current_dir, '.git'))

          current_dir = File.dirname(current_dir)
        end
        # Last fallback
        Dir.pwd
      end
    end

    def determine_status(worktree_path)
      # Check if this is the current worktree
      current_path = Dir.pwd
      is_current = current_path.start_with?(worktree_path)

      # Check if worktree is clean
      is_clean = GitOperations.is_clean?(worktree_path)

      if is_current
        :active
      elsif is_clean
        :clean
      else
        :dirty
      end
    rescue StandardError
      :unknown
    end

    def detect_base_ref(branch_name)
      # Try to determine base branch using git merge-base
      default_branch = @repository.default_branch

      # Use merge-base to find the best common ancestor
      result = `git merge-base #{branch_name} #{default_branch} 2>/dev/null`.strip
      return default_branch if $CHILD_STATUS.success? && !result.empty?

      # Fallback: if branch exists and default branch exists, assume default
      return default_branch if GitOperations.branch_exists?(branch_name) && GitOperations.branch_exists?(default_branch)

      'unknown'
    rescue StandardError
      'unknown'
    end
  end
end
