# frozen_string_literal: true

require 'tmpdir'
require 'pathname'

# Provides completely isolated test environments to prevent working directory corruption
# and ensure clean test separation. Each test gets its own temporary directory tree.
module IsolatedTestEnvironment
  class EnvironmentError < StandardError; end

  attr_reader :test_root, :original_directory, :test_id

  def setup_isolated_environment
    @original_directory = Dir.pwd
    @test_id = generate_test_id
    @test_root = create_isolated_directory

    # Ensure we can always return to a safe directory
    ensure_safe_return_path

    # Switch to isolated environment
    Dir.chdir(@test_root)

    # Set environment variables for the isolated context
    setup_isolated_environment_variables

    @test_root
  end

  def cleanup_isolated_environment
    return unless @test_root && @original_directory

    begin
      # Always return to original directory first to avoid ENOENT errors
      Dir.chdir(@original_directory) if Dir.exist?(@original_directory)

      # Only clean up if the test directory still exists
      if Dir.exist?(@test_root)
        # Force removal of the isolated directory tree
        FileUtils.remove_entry_secure(@test_root)
      end

    rescue => e
      # Log cleanup failures but don't fail tests
      warn "Warning: Failed to cleanup isolated environment #{@test_root}: #{e.message}"

      # Attempt forced cleanup as fallback
      system("rm -rf '#{@test_root}' 2>/dev/null") if @test_root

    ensure
      # Reset instance variables
      @test_root = nil
      @test_id = nil
    end
  end

  def in_isolated_environment(&block)
    setup_isolated_environment
    yield(@test_root)
  ensure
    cleanup_isolated_environment
  end

  # Provides a safe working directory that won't be deleted during test execution
  def safe_working_directory
    @original_directory || Dir.pwd
  end

  # Create a git repository within the isolated environment
  def setup_isolated_git_repository
    ensure_in_isolated_environment!

    # Initialize git with consistent configuration
    system('git', 'init', out: File::NULL, err: File::NULL)
    system('git', 'config', 'user.email', 'test@example.com')
    system('git', 'config', 'user.name', 'Test User')
    system('git', 'config', 'init.defaultBranch', 'main')

    # Create initial commit to establish main branch
    File.write('README.md', "# Test Repository #{@test_id}")
    system('git', 'add', 'README.md')
    system('git', 'commit', '-m', 'Initial commit', out: File::NULL, err: File::NULL)

    # Ensure we're on main branch
    system('git', 'checkout', '-B', 'main', out: File::NULL, err: File::NULL)
  end

  private

  def generate_test_id
    "test_#{Time.now.to_f.to_s.gsub('.', '_')}_#{Process.pid}"
  end

  def create_isolated_directory
    # Create unique temporary directory for this test
    Dir.mktmpdir("worktrees_test_#{@test_id}_", Dir.tmpdir)
  end

  def ensure_safe_return_path
    # Ensure original directory exists and is accessible
    unless Dir.exist?(@original_directory)
      @original_directory = Dir.tmpdir
    end
  end

  def setup_isolated_environment_variables
    # Set up environment for isolated testing
    ENV['WORKTREES_TEST_MODE'] = 'isolated'
    ENV['WORKTREES_TEST_ID'] = @test_id
    ENV['HOME'] = @test_root
  end

  def ensure_in_isolated_environment!
    unless @test_root && Dir.pwd == @test_root
      raise EnvironmentError, "Not in isolated environment. Call setup_isolated_environment first."
    end
  end
end