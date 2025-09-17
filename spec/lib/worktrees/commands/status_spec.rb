# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::Commands::Status, type: :aruba do
  let(:command) { described_class.new }

  before do
    setup_test_repo
    create_directory('.worktrees')
  end

  describe '#call' do
    it 'shows current worktree status' do
      create_test_worktree('001-test')

      cd('.worktrees/001-test') do
        expect { command.call }
          .to output(/Current worktree: 001-test/).to_stdout
      end
    end

    it 'shows message when not in worktree' do
      expect { command.call }
        .to output(/Not currently in a worktree/).to_stdout
    end
  end
end