# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Commands::Remove do
  let(:manager) { instance_double('Worktrees::WorktreeManager') }
  let(:command) { described_class.new(manager) }

  describe '#call' do
    it 'removes worktree successfully' do
      allow(manager).to receive(:remove_worktree).with('001-test', {}).and_return(true)

      expect { command.call(name: '001-test') }
        .to output(/Removed worktree: 001-test/).to_stdout
    end

    it 'handles removal errors' do
      allow(manager).to receive(:remove_worktree)
        .and_raise(Worktrees::StateError.new('Cannot remove active worktree'))

      expect { command.call(name: '001-test') }
        .to raise_error(SystemExit) { |error| expect(error.status).to eq(3) }
    end
  end
end