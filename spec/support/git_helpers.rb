# frozen_string_literal: true

module GitHelpers
  def setup_test_repo
    cleanup_git_worktrees
    run_command('git init')
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
    write_file('README.md', '# Test Repository')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"')
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
    # List and properly remove all worktrees except main repository
    begin
      result = run_command_and_stop('git worktree list --porcelain 2>/dev/null || true', fail_on_error: false)
      if result.stdout && !result.stdout.empty?
        worktree_paths = []
        result.stdout.split("\n").each do |line|
          if line.start_with?('worktree ')
            path = line.sub('worktree ', '')
            # Skip main repository directory
            unless path == expand_path('.')
              worktree_paths << path
            end
          end
        end

        # Remove each worktree properly
        worktree_paths.each do |path|
          run_command("git worktree remove --force '#{path}' 2>/dev/null || true", fail_on_error: false)
        end
      end
    rescue
      # If git commands fail, fall back to directory cleanup
    end

    # Clean up any remaining directory and prune
    run_command('rm -rf .worktrees 2>/dev/null || true')
    run_command('git worktree prune 2>/dev/null || true')
  end
end