# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Commands::Status do
  let(:manager) { instance_double('Worktrees::WorktreeManager') }
  let(:command) { described_class.new(manager) }

  describe '#call' do
    it 'shows current worktree status' do
      worktree = double(name: '001-test', path: '/tmp/.worktrees/001-test', status: :clean, branch: '001-test')
      allow(manager).to receive(:current_worktree).and_return(worktree)

      expect { command.call }
        .to output(/Current worktree: 001-test/).to_stdout
    end

    it 'shows message when not in worktree' do
      allow(manager).to receive(:current_worktree).and_return(nil)

      expect { command.call }
        .to output(/Not in a worktree/).to_stderr
        .and raise_error(SystemExit) { |error| expect(error.status).to eq(4) }
    end
  end
end