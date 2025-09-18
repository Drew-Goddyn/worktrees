# frozen_string_literal: true

require_relative 'isolated_test_environment'

# Provides hermetic test isolation using directory-based containers
# inspired by TestContainers principles but optimized for git CLI testing
module TestIsolation
  include IsolatedTestEnvironment

  class IsolationError < StandardError; end

  # Runs a test in complete isolation with automatic cleanup
  def with_isolated_test(&block)
    isolation_context = IsolationContext.new
    isolation_context.setup

    begin
      yield(isolation_context)
    ensure
      isolation_context.cleanup
    end
  end

  # Provides retry logic for flaky operations (inspired by TestContainers)
  def with_retry(attempts: 3, delay: 0.5, exceptions: [StandardError])
    attempt = 1

    begin
      yield
    rescue *exceptions => e
      if attempt < attempts
        sleep delay
        attempt += 1
        retry
      else
        raise e
      end
    end
  end

  class IsolationContext
    include IsolatedTestEnvironment

    attr_reader :workspace_path, :home_path, :git_path

    def initialize
      @setup_complete = false
      @cleanup_callbacks = []
    end

    def setup
      return if @setup_complete

      # Create isolated environment
      setup_isolated_environment

      # Create directory structure
      create_workspace_structure

      # Setup git configuration
      setup_git_environment

      # Initialize the workspace as a git repository for tests that need it
      initialize_workspace_git_repository

      @setup_complete = true
    end

    def cleanup
      return unless @setup_complete

      # Execute cleanup callbacks in reverse order
      @cleanup_callbacks.reverse.each do |callback|
        begin
          callback.call
        rescue => e
          warn "Warning: Cleanup callback failed: #{e.message}"
        end
      end

      # Clean up isolated environment
      cleanup_isolated_environment

      @setup_complete = false
    end

    # Add a cleanup callback to be executed during teardown
    def add_cleanup_callback(&block)
      @cleanup_callbacks << block
    end

    # Create a git repository in the workspace
    def create_git_repository(name = 'main')
      repo_path = File.join(@workspace_path, name)
      Dir.mkdir(repo_path)

      Dir.chdir(repo_path) do
        setup_isolated_git_repository
      end

      add_cleanup_callback { cleanup_git_repository(repo_path) }
      repo_path
    end

    # Create worktrees directory structure
    def create_worktrees_structure
      worktrees_path = File.join(@workspace_path, '.worktrees')
      Dir.mkdir(worktrees_path) unless Dir.exist?(worktrees_path)

      # Set up global worktrees directory in home
      global_worktrees = File.join(@home_path, '.worktrees')
      Dir.mkdir(global_worktrees) unless Dir.exist?(global_worktrees)

      add_cleanup_callback { cleanup_worktrees_structure(worktrees_path, global_worktrees) }

      { local: worktrees_path, global: global_worktrees }
    end

    # Execute a command safely within the isolation context
    def run_command_safely(command, working_dir: nil)
      original_dir = Dir.pwd

      begin
        Dir.chdir(working_dir) if working_dir

        if command.is_a?(Array)
          system(*command)
        else
          system(command)
        end

        $?.exitstatus
      ensure
        Dir.chdir(original_dir) if Dir.exist?(original_dir)
      end
    end

    # Get environment variables for this isolation context
    def environment_variables
      {
        'HOME' => @home_path,
        'WORKTREES_TEST_MODE' => 'isolated',
        'WORKTREES_TEST_ID' => @test_id,
        'GIT_CONFIG_GLOBAL' => File.join(@home_path, '.gitconfig')
      }
    end

    # Check if we're currently in the isolated environment
    def in_isolated_environment?
      @setup_complete && Dir.pwd.start_with?(@test_root.to_s)
    end

    # Provide a safe directory to return to
    def safe_directory
      @setup_complete ? @workspace_path : safe_working_directory
    end

    private

    def initialize_workspace_git_repository
      # Initialize the workspace itself as a git repository
      Dir.chdir(@workspace_path) do
        # Initialize git with consistent configuration
        system('git', 'init')
        system('git', 'config', 'user.email', 'test@example.com')
        system('git', 'config', 'user.name', 'Test User')
        system('git', 'config', 'init.defaultBranch', 'main')

        # Create initial commit to establish main branch
        File.write('README.md', "# Test Repository #{@test_id}")
        system('git', 'add', 'README.md')
        system('git', 'commit', '-m', 'Initial commit')

        # Ensure we're on main branch
        system('git', 'checkout', '-B', 'main')
      end

      add_cleanup_callback { cleanup_git_repository(@workspace_path) }
    end

    def create_workspace_structure
      @workspace_path = File.join(@test_root, 'workspace')
      @home_path = File.join(@test_root, 'home')
      @git_path = File.join(@home_path, '.git')

      Dir.mkdir(@workspace_path)
      Dir.mkdir(@home_path)

      # Change to workspace by default
      Dir.chdir(@workspace_path)
    end

    def setup_git_environment
      # Create global git configuration in isolated home
      global_gitconfig = File.join(@home_path, '.gitconfig')
      File.write(global_gitconfig, <<~GITCONFIG)
        [user]
        	name = Test User
        	email = test@example.com
        [init]
        	defaultBranch = main
        [core]
        	autocrlf = false
      GITCONFIG
    end

    def cleanup_git_repository(repo_path)
      return unless Dir.exist?(repo_path)

      # Safely clean up git worktrees
      Dir.chdir(repo_path) do
        # Remove all worktrees
        system('git worktree prune --verbose 2>/dev/null')

        # Clean up worktree administrative files
        FileUtils.rm_rf('.git/worktrees') if Dir.exist?('.git/worktrees')
      end
    rescue => e
      warn "Warning: Git repository cleanup failed for #{repo_path}: #{e.message}"
    end

    def cleanup_worktrees_structure(local_path, global_path)
      [local_path, global_path].each do |path|
        next unless Dir.exist?(path)

        begin
          FileUtils.rm_rf(path)
        rescue => e
          warn "Warning: Worktrees cleanup failed for #{path}: #{e.message}"
        end
      end
    end
  end
end