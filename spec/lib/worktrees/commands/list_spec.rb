# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::Commands::List, type: :aruba do
  let(:command) { described_class.new }

  before do
    setup_test_repo
    create_directory('.worktrees')
  end

  describe '#call' do
    it 'lists worktrees in text format' do
      create_test_worktree('001-test')
      create_test_worktree('002-other')
      make_dirty_worktree('002-other')

      expect { command.call }.to output(/001-test.*002-other/m).to_stdout
    end

    it 'shows message when no worktrees exist' do
      expect { command.call }.to output(/No worktrees found/).to_stdout
    end

    it 'outputs JSON format when requested' do
      create_test_worktree('001-test')

      expect { command.call(format: 'json') }
        .to output(/"worktrees":/).to_stdout
    end
  end
end
