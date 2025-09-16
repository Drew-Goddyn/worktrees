# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe 'worktrees help and version', type: :aruba do
  it 'shows help when --help is used' do
    run_command('worktrees --help')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/COMMANDS:/)
    expect(last_command_started).to have_output_on_stdout(/create/)
    expect(last_command_started).to have_output_on_stdout(/list/)
    expect(last_command_started).to have_output_on_stdout(/switch/)
    expect(last_command_started).to have_output_on_stdout(/remove/)
    expect(last_command_started).to have_output_on_stdout(/status/)
  end

  it 'shows version when --version is used' do
    run_command('worktrees --version')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/worktrees \d+\.\d+\.\d+/)
  end

  it 'shows help when no command is given' do
    run_command('worktrees')
    expect(last_command_started).to have_exit_status(0)
    expect(last_command_started).to have_output_on_stdout(/COMMANDS:/)
  end
end