# frozen_string_literal: true

module GitHelpers
  def default_branch
    # Get the current default branch (main or master)
    result = run_command_and_stop(
      'git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null || git branch --show-current 2>/dev/null || echo "main"', fail_on_error: false
    )
    branch = result.stdout.strip.gsub('refs/remotes/origin/', '')
    branch.empty? ? 'main' : branch
  end

  def setup_test_repo
    cleanup_git_worktrees

    # Only initialize git if not already in a git repository
    unless Dir.exist?('.git')
      run_command('git init')
      run_command('git config user.email "test@example.com"')
      run_command('git config user.name "Test User"')
      run_command('git config init.defaultBranch main')
    end

    # Set up initial content and commit (safe even if repo exists)
    write_file('README.md', '# Test Repository') unless File.exist?('README.md')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"', fail_on_error: false)
    # Ensure we're on main branch after first commit
    run_command('git branch -M main', fail_on_error: false)
  end

  def setup_test_repo_with_branch(branch_name)
    setup_test_repo
    run_command("git checkout -b #{branch_name}")
    write_file('feature.txt', 'Feature content')
    run_command('git add feature.txt')
    run_command("git commit -m 'Add #{branch_name} feature'")
    run_command('git checkout main')
  end

  def create_test_worktree(name, base_branch = 'main')
    create_directory('.worktrees')
    run_command("git worktree add .worktrees/#{name} -b #{name} #{base_branch}")
  end

  def create_test_worktree_from_existing(name, existing_branch)
    create_directory('.worktrees')
    run_command("git worktree add .worktrees/#{name} #{existing_branch}")
  end

  def setup_remote_repo
    # Create a bare repository to simulate remote
    create_directory('remote.git')
    cd('remote.git') do
      run_command('git init --bare')
    end

    # Add it as origin
    run_command('git remote add origin ./remote.git')
    run_command('git push -u origin main')
  end

  def make_dirty_worktree(worktree_name)
    cd(".worktrees/#{worktree_name}") do
      write_file('dirty.txt', 'Uncommitted changes')
    end
  end

  def commit_changes_in_worktree(worktree_name, message = 'Test commit')
    cd(".worktrees/#{worktree_name}") do
      run_command('git add .')
      run_command("git commit -m '#{message}'")
    end
  end

  def cleanup_git_worktrees
    safe_cleanup_git_worktrees
  end

  def safe_cleanup_git_worktrees
    # Store current directory to ensure we can return to it
    original_dir = Dir.pwd

    begin
      # Only attempt cleanup if we're in a git repository
      return unless Dir.exist?('.git') || ENV['GIT_DIR']

      # List and remove worktrees safely
      cleanup_worktree_references
      cleanup_worktree_directories
      prune_worktree_metadata
    rescue StandardError => e
      warn "Warning: Git cleanup failed: #{e.message}" if ENV['WORKTREES_VERBOSE']
    ensure
      # Always ensure we return to original directory if it still exists
      if Dir.exist?(original_dir)
        begin
          Dir.chdir(original_dir)
        rescue StandardError
          nil
        end
      else
        # If original directory was deleted, go to a safe fallback
        begin
          Dir.chdir(Dir.home || '/tmp')
        rescue StandardError
          nil
        end
      end
    end
  end

  private

  def cleanup_worktree_references
    # Get worktree list safely
    result = run_command_and_stop('git worktree list --porcelain 2>/dev/null || echo ""', fail_on_error: false)
    return unless result&.stdout && !result.stdout.empty?

    current_repo_path = expand_path('.')
    worktree_paths = []

    result.stdout.split("\n").each do |line|
      next unless line.start_with?('worktree ')

      path = line.sub('worktree ', '').strip
      # Skip main repository directory and non-existent paths
      next if path == current_repo_path
      next unless path.include?('.worktrees') || path.include?('worktree')

      worktree_paths << path
    end

    # Remove worktrees with safety checks
    worktree_paths.each do |path|
      cleanup_single_worktree(path)
    end
  end

  def cleanup_single_worktree(path)
    # Verify the path looks like a worktree before removal
    return unless path.include?('worktree') || path.include?('.worktrees')

    # Use git worktree remove first (safest)
    run_command("git worktree remove --force '#{path}' 2>/dev/null", fail_on_error: false)

    # If directory still exists, remove it manually
    if Dir.exist?(path)
      # Double-check we're not removing something important
      return if path == '/' || path == Dir.home || path.length < 5

      begin
        FileUtils.rm_rf(path)
      rescue StandardError
        nil
      end
    end
  rescue StandardError => e
    warn "Warning: Failed to cleanup worktree #{path}: #{e.message}" if ENV['WORKTREES_VERBOSE']
  end

  def cleanup_worktree_directories
    # Clean up .worktrees directories
    worktree_dirs = ['.worktrees']

    # Also check global worktree directory if it exists in test context
    worktree_dirs << File.join(Dir.home, '.worktrees') if Dir.home && Dir.exist?(File.join(Dir.home,
                                                                                           '.worktrees'))

    worktree_dirs.each do |dir|
      next unless Dir.exist?(dir)

      begin
        FileUtils.rm_rf(dir)
      rescue StandardError => e
        warn "Warning: Failed to remove #{dir}: #{e.message}" if ENV['WORKTREES_VERBOSE']
      end
    end
  end

  def prune_worktree_metadata
    # Prune git worktree metadata
    run_command('git worktree prune --verbose 2>/dev/null', fail_on_error: false)

    # Clean up git administrative files for worktrees
    git_worktrees_dir = '.git/worktrees'
    if Dir.exist?(git_worktrees_dir)
      begin
        FileUtils.rm_rf(git_worktrees_dir)
      rescue StandardError
        nil
      end
    end

    # Remove any git lock files that might prevent cleanup
    if Dir.exist?('.git')
      Dir.glob('.git/**/*.lock').each do |lock_file|
        File.unlink(lock_file)
      rescue StandardError
        nil
      end
    end
  rescue StandardError => e
    warn "Warning: Failed to prune worktree metadata: #{e.message}" if ENV['WORKTREES_VERBOSE']
  end
end
