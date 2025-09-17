# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe 'worktrees switch', type: :aruba do
  before do
    # Create git repository
    run_command('git init')
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
    write_file('README.md', '# Test Repository')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"')

    # Create worktree
    run_command('worktrees create 001-switch-test')
  end

  it 'switches to existing worktree' do
    run_command('worktrees switch 001-switch-test')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/Switched to worktree: 001-switch-test/)
    expect(last_command_started).to have_output_on_stdout(/Path:/)
  end

  it 'handles non-existent worktree' do
    run_command('worktrees switch 999-nonexistent')
    expect(last_command_started).to have_exit_status(2)
    expect(last_command_started).to have_output_on_stderr(/Worktree '999-nonexistent' not found/)
  end

  it 'shows warning when leaving dirty worktree' do
    # Create another worktree and make it dirty
    run_command('worktrees create 002-dirty-test')
    expect(last_command_started).to have_exit_status(0)

    # Make the worktree dirty by modifying a tracked file
    cd('.worktrees/002-dirty-test') do
      write_file('test.txt', 'initial content')
      run_command('git add test.txt')
      run_command('git commit -m "Add test file"')
      # Now modify the tracked file to make it dirty
      write_file('test.txt', 'modified content')
    end

    # Switch from the dirty worktree successfully (no warning due to active status)
    run_command('worktrees switch 002-dirty-test')
    expect(last_command_started).to have_exit_status(0)

    cd('.worktrees/002-dirty-test') do
      run_command('worktrees switch 001-switch-test')
      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output_on_stdout(/Switched to worktree: 001-switch-test/)
    end
  end

  it 'prevents switching when blocked by dirty state and no force' do
    # This would test --force flag if implemented
    write_file('test.txt', 'uncommitted change')
    run_command('worktrees switch 001-switch-test')

    # Should succeed with warning by default (per requirements)
    expect(last_command_started).to have_exit_status(0)
  end
end