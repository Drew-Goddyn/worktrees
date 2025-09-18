# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::Commands::Remove, type: :aruba do
  let(:command) { described_class.new }

  before do
    setup_test_repo
    create_directory('.worktrees')
  end

  describe '#call' do
    it 'removes worktree successfully' do
      create_test_worktree('001-test')

      expect { command.call(name: '001-test') }
        .to output(/Removed worktree: 001-test/).to_stdout

      expect(Dir.exist?(expand_path('.worktrees/001-test'))).to be false
    end

    it 'handles removal errors' do
      expect { command.call(name: 'nonexistent') }
        .to raise_error(SystemExit) do |error|
          expect(error.status).to eq(2)
        end
    end
  end
end
