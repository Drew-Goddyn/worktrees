# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe 'worktrees create', type: :aruba do
  before do
    # Create a git repository in the current directory
    run_command('git init')
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
    write_file('README.md', '# Test Repository')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"')
  end

  it 'creates a new worktree with valid name' do
    run_command('worktrees create 001-test-feature')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/Created worktree: 001-test-feature/)
    expect(last_command_started).to have_output_on_stdout(/Path:/)
    expect(last_command_started).to have_output_on_stdout(/Branch: 001-test-feature/)
    expect(last_command_started).to have_output_on_stdout(/Status: clean/)
  end

  it 'creates worktree from specified base branch' do
    run_command('git checkout -b develop')
    run_command('git checkout main')
    run_command('worktrees create 002-from-develop develop')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/Base: develop/)
  end

  it 'rejects invalid name format' do
    run_command('worktrees create bad_name')
    expect(last_command_started).to have_exit_status(2)
    expect(last_command_started).to have_output_on_stderr(/Invalid name format/)
    expect(last_command_started).to have_output_on_stderr(/Names must match pattern: NNN-kebab-feature/)
  end

  it 'rejects reserved names' do
    run_command('worktrees create 001-main')
    expect(last_command_started).to have_exit_status(2)
    expect(last_command_started).to have_output_on_stderr(/Reserved name 'main' not allowed/)
  end

  it 'rejects duplicate names' do
    run_command('worktrees create 001-duplicate')
    expect(last_command_started).to have_exit_status(0)

    run_command('worktrees create 001-duplicate')
    expect(last_command_started).to have_exit_status(2)
    expect(last_command_started).to have_output_on_stderr(/Worktree '001-duplicate' already exists/)
  end

  it 'handles non-existent base reference' do
    run_command('worktrees create 001-test nonexistent-branch')
    expect(last_command_started).to have_exit_status(3)
    expect(last_command_started).to have_output_on_stderr(/Base reference 'nonexistent-branch' not found/)
  end
end
