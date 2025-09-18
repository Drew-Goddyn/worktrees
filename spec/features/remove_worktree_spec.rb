# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe 'worktrees remove', type: :aruba do
  before do
    # Create git repository
    run_command('git init')
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
    write_file('README.md', '# Test Repository')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"')

    # Create worktree
    run_command('worktrees create 001-remove-test')
  end

  it 'removes clean worktree successfully' do
    run_command('worktrees remove 001-remove-test')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/Removed worktree: 001-remove-test/)
    expect(last_command_started).to have_output_on_stdout(/Branch: 001-remove-test \(kept\)/)
  end

  it 'prevents removing active worktree' do
    run_command('worktrees switch 001-remove-test')

    # Try to remove the worktree from within it (should fail)
    cd('.worktrees/001-remove-test') do
      run_command('worktrees remove 001-remove-test')
      expect(last_command_started).to have_exit_status(3)
      expect(last_command_started).to have_output_on_stderr(/Cannot remove active worktree/)
    end
  end

  it 'prevents removing dirty worktree' do
    run_command('worktrees switch 001-remove-test')

    # Make the worktree dirty by adding and modifying a tracked file
    cd('.worktrees/001-remove-test') do
      write_file('test.txt', 'initial content')
      run_command('git add test.txt')
      run_command('git commit -m "Add test file"')
      # Now modify the tracked file to make it dirty
      write_file('test.txt', 'modified content')
    end

    # Try to remove the dirty worktree from outside (should fail)
    run_command('worktrees remove 001-remove-test')
    expect(last_command_started).to have_exit_status(3)
    expect(last_command_started).to have_output_on_stderr(/has uncommitted changes/)
  end

  it 'allows force removal of worktree with untracked files' do
    run_command('worktrees switch 001-remove-test')
    write_file('untracked.txt', 'untracked file')
    cd('..')
    run_command('worktrees remove 001-remove-test --force-untracked')

    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/Removed worktree/)
  end

  it 'deletes branch when requested and safe' do
    run_command('worktrees remove 001-remove-test --delete-branch')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/Branch: 001-remove-test \(deleted\)/)
  end

  it 'handles non-existent worktree' do
    run_command('worktrees remove 999-nonexistent')
    expect(last_command_started).to have_exit_status(2)
    expect(last_command_started).to have_output_on_stderr(/Worktree '999-nonexistent' not found/)
  end
end
