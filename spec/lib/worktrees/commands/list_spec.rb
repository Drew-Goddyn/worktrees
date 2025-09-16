# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Commands::List do
  let(:manager) { instance_double('Worktrees::WorktreeManager') }
  let(:command) { described_class.new(manager) }

  describe '#call' do
    it 'lists worktrees in text format' do
      worktrees = [
        double(name: '001-test', status: :clean, path: '/tmp/.worktrees/001-test', base_ref: 'main', active?: false),
        double(name: '002-other', status: :dirty, path: '/tmp/.worktrees/002-other', base_ref: 'develop', active?: true)
      ]
      allow(manager).to receive(:list_worktrees).and_return(worktrees)

      expect { command.call }.to output(/001-test.*clean.*002-other.*dirty/).to_stdout
    end

    it 'shows message when no worktrees exist' do
      allow(manager).to receive(:list_worktrees).and_return([])

      expect { command.call }.to output(/No worktrees found/).to_stdout
    end

    it 'outputs JSON format when requested' do
      worktrees = [double(name: '001-test', to_h: { name: '001-test', status: :clean })]
      allow(manager).to receive(:list_worktrees).and_return(worktrees)

      expect { command.call(format: 'json') }
        .to output(/"worktrees":/).to_stdout
    end
  end
end