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
    run_command('worktrees remove 001-remove-test')

    expect(last_command_started).to have_exit_status(2)
    expect(last_command_started).to have_output_on_stderr(/Cannot remove active worktree/)
  end

  it 'prevents removing dirty worktree' do
    # Switch to worktree and make it dirty
    run_command('worktrees switch 001-remove-test')
    write_file('dirty.txt', 'uncommitted change')
    run_command('cd ..')  # Switch back to main repo
    run_command('worktrees remove 001-remove-test')

    expect(last_command_started).to have_exit_status(3)
    expect(last_command_started).to have_output_on_stderr(/has uncommitted changes/)
  end

  it 'allows force removal of worktree with untracked files' do
    run_command('worktrees switch 001-remove-test')
    write_file('untracked.txt', 'untracked file')
    run_command('cd ..')
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