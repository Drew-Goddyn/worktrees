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

      expect(Dir.exist?(expand_path('.worktrees/001-test'))).to be true
    end

    it 'handles creation errors' do
      expect { command.call(name: 'bad-name', base: 'main') }
        .to raise_error(Worktrees::ValidationError, /Invalid name/)
    end
  end
end