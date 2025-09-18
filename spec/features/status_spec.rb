# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe 'worktrees status', type: :aruba do
  before do
    # Create git repository
    run_command('git init')
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
    write_file('README.md', '# Test Repository')
    run_command('git add README.md')
    run_command('git commit -m "Initial commit"')
  end

  it 'shows status when not in a worktree' do
    run_command('worktrees status')
    expect(last_command_started).to have_exit_status(4)
    expect(last_command_started).to have_output_on_stderr(/Not in a worktree/)
    expect(last_command_started).to have_output_on_stdout(/Repository:/)
    expect(last_command_started).to have_output_on_stdout(/Worktrees root:/)
  end

  it 'shows current worktree status' do
    run_command('worktrees create 001-status-test')
    expect(last_command_started).to have_exit_status(0)

    run_command('worktrees switch 001-status-test')
    expect(last_command_started).to have_exit_status(0)

    # Change to the worktree directory to test status command (global location)
    cd('.worktrees/001-status-test') do
      run_command('worktrees status')
      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output_on_stdout(/Current worktree: 001-status-test/)
      expect(last_command_started).to have_output_on_stdout(/Path:/)
      expect(last_command_started).to have_output_on_stdout(/Branch: 001-status-test/)
      expect(last_command_started).to have_output_on_stdout(/Status: active/)
    end
  end

  it 'shows dirty status when files are modified' do
    run_command('worktrees create 001-dirty-test')
    run_command('worktrees switch 001-dirty-test')

    # Change to the worktree directory to modify files and test status
    cd('.worktrees/001-dirty-test') do
      write_file('test.txt', 'initial content')
      run_command('git add test.txt')
      run_command('git commit -m "Add test file"')
      # Now modify the tracked file
      write_file('test.txt', 'modified content')
      run_command('worktrees status')
      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output_on_stdout(/Status: active/)
    end
  end

  it 'outputs JSON format when requested' do
    run_command('worktrees create 001-json-status')
    run_command('worktrees switch 001-json-status')

    # Change to the worktree directory to test JSON status output
    cd('.worktrees/001-json-status') do
      run_command('worktrees status --format json')
      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output_on_stdout(/"current_worktree":/)
      expect(last_command_started).to have_output_on_stdout(/"name": "001-json-status"/)
      expect(last_command_started).to have_output_on_stdout(/"status": "active"/)
    end
  end

  it 'shows repository and configuration information' do
    run_command('worktrees status')
    expect(last_command_started).to have_output_on_stdout(/Repository:/)
    expect(last_command_started).to have_output_on_stdout(/Worktrees root:/)
  end
end
