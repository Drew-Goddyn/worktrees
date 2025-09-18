# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::Commands::Create, type: :aruba do
  let(:command) { described_class.new }

  before do
    setup_test_repo
    create_directory('.worktrees')
  end

  describe '#call' do
    it 'creates worktree successfully' do
      expect { command.call(name: '001-test', base: 'main') }
        .to output(/Created worktree: 001-test/).to_stdout

      # Check that worktree is created in the global directory (HOME/.worktrees)
      global_worktrees_path = File.join(Dir.home, '.worktrees', '001-test')
      expect(Dir.exist?(global_worktrees_path)).to be true
    end

    it 'handles creation errors' do
      expect { command.call(name: 'bad-name', base: 'main') }
        .to raise_error(SystemExit)
    end
  end
end
