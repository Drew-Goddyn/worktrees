# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::Commands::Switch, type: :aruba do
  let(:command) { described_class.new }

  before do
    setup_test_repo
    create_directory('.worktrees')
  end

  describe '#call' do
    it 'switches to existing worktree' do
      create_test_worktree('001-test')

      expect { command.call(name: '001-test') }
        .to output(/Switched to worktree: 001-test/).to_stdout
    end

    it 'handles non-existent worktree' do
      expect { command.call(name: 'nonexistent') }
        .to raise_error(SystemExit)
    end
  end
end
