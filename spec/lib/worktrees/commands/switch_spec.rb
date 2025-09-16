# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Commands::Switch do
  let(:manager) { instance_double('Worktrees::WorktreeManager') }
  let(:command) { described_class.new(manager) }

  describe '#call' do
    it 'switches to existing worktree' do
      worktree = double(name: '001-test', path: '/tmp/.worktrees/001-test')
      allow(manager).to receive(:switch_to_worktree).with('001-test').and_return(worktree)

      expect { command.call(name: '001-test') }
        .to output(/Switched to worktree: 001-test/).to_stdout
    end

    it 'handles non-existent worktree' do
      allow(manager).to receive(:switch_to_worktree)
        .and_raise(Worktrees::ValidationError.new('Worktree not found'))

      expect { command.call(name: 'nonexistent') }
        .to raise_error(SystemExit) { |error| expect(error.status).to eq(2) }
    end
  end
end