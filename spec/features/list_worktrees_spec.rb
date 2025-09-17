# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe 'worktrees list', type: :aruba do
  before do
    # Create a git repository
    run_command('git init')
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
    write_file('README.md', '# Test Repository')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"')
  end

  it 'lists empty worktrees when none exist' do
    run_command('worktrees list')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/No worktrees found/)
  end

  it 'lists existing worktrees in text format' do
    run_command('worktrees create 001-feature-a')
    run_command('worktrees create 002-feature-b')
    run_command('worktrees list')

    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/001-feature-a.*clean/)
    expect(last_command_started).to have_output_on_stdout(/002-feature-b.*clean/)
    expect(last_command_started).to have_output_on_stdout(/from main/)
  end

  it 'shows active worktree with asterisk' do
    run_command('worktrees create 001-active')
    run_command('worktrees switch 001-active')

    # Change to the worktree directory to test active worktree detection
    cd('.worktrees/001-active') do
      run_command('worktrees list')
      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output_on_stdout(/\* 001-active/)
    end
  end

  it 'outputs JSON format when requested' do
    run_command('worktrees create 001-json-test')
    run_command('worktrees list --format json')

    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/"worktrees":/)
    expect(last_command_started).to have_output_on_stdout(/"name": "001-json-test"/)
    expect(last_command_started).to have_output_on_stdout(/"status": "clean"/)
  end

  it 'filters by status when requested' do
    run_command('worktrees create 001-clean')
    # Create dirty worktree (would modify files)
    run_command('worktrees list --filter clean')

    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/001-clean/)
  end
end