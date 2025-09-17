# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::WorktreeManager, type: :aruba do
  let(:repository) { Worktrees::Models::Repository.new(expand_path('.')) }
  let(:config) { Worktrees::Models::WorktreeConfig.new }
  let(:manager) { described_class.new(repository, config) }

  before do
    setup_test_repo
    create_directory('.worktrees')
  end

  describe '#create_worktree' do
    it 'creates worktree with valid name and base' do
      worktree = manager.create_worktree('001-test', 'main')

      expect(worktree).to be_a(Worktrees::Models::FeatureWorktree)
      expect(worktree.name).to eq('001-test')
      expect(worktree.base_ref).to eq('main')
      expect(Dir.exist?(expand_path('.worktrees/001-test'))).to be true
    end

    it 'raises validation error for invalid name' do
      expect { manager.create_worktree('bad-name', 'main') }
        .to raise_error(Worktrees::ValidationError, /Invalid name/)
    end

    it 'raises error for non-existent base reference' do
      expect { manager.create_worktree('001-test', 'nonexistent') }
        .to raise_error(Worktrees::GitError, /Base reference.*not found/)
    end

    it 'uses default base when none provided' do
      worktree = manager.create_worktree('001-test')

      expect(worktree.base_ref).to eq('main')
      expect(Dir.exist?(expand_path('.worktrees/001-test'))).to be true
    end

    it 'raises error when worktree creation fails' do
      # Try to create worktree with invalid base branch to cause failure
      expect { manager.create_worktree('001-test', 'nonexistent-base') }
        .to raise_error(Worktrees::GitError, /Base reference.*not found/)
    end
  end

  describe '#list_worktrees' do
    it 'returns list of worktrees' do
      create_test_worktree('001-test')
      create_test_worktree('002-test')

      worktrees = manager.list_worktrees

      expect(worktrees).to be_an(Array)
      expect(worktrees.length).to eq(2)
      expect(worktrees.first).to be_a(Worktrees::Models::FeatureWorktree)
      worktree_names = worktrees.map(&:name)
      expect(worktree_names).to include('001-test', '002-test')
    end

    it 'returns empty array when no worktrees exist' do
      worktrees = manager.list_worktrees
      expect(worktrees).to eq([])
    end

    it 'filters worktrees by status' do
      create_test_worktree('001-clean')
      create_test_worktree('002-dirty')
      make_dirty_worktree('002-dirty')

      clean_worktrees = manager.list_worktrees(status: :clean)
      dirty_worktrees = manager.list_worktrees(status: :dirty)

      expect(clean_worktrees.length).to eq(1)
      expect(clean_worktrees.first.name).to eq('001-clean')
      expect(dirty_worktrees.length).to eq(1)
      expect(dirty_worktrees.first.name).to eq('002-dirty')
    end
  end

  describe '#find_worktree' do
    it 'finds worktree by name' do
      create_test_worktree('001-test')

      worktree = manager.find_worktree('001-test')

      expect(worktree).to be_a(Worktrees::Models::FeatureWorktree)
      expect(worktree.name).to eq('001-test')
    end

    it 'returns nil for non-existent worktree' do
      worktree = manager.find_worktree('nonexistent')
      expect(worktree).to be_nil
    end
  end

  describe '#remove_worktree' do
    it 'removes clean inactive worktree' do
      create_test_worktree('001-test')

      result = manager.remove_worktree('001-test')
      expect(result).to be_truthy
      expect(Dir.exist?(expand_path('.worktrees/001-test'))).to be false
    end

    it 'raises error for non-existent worktree' do
      expect { manager.remove_worktree('nonexistent') }
        .to raise_error(Worktrees::NotFoundError, /Worktree.*not found/)
    end

    it 'prevents removal of dirty worktree without force' do
      create_test_worktree('001-dirty')
      make_dirty_worktree('001-dirty')

      expect { manager.remove_worktree('001-dirty') }
        .to raise_error(Worktrees::StateError, /dirty/)
    end

    it 'forces removal of dirty worktree when requested' do
      create_test_worktree('001-dirty')
      make_dirty_worktree('001-dirty')

      result = manager.remove_worktree('001-dirty', force: true)
      expect(result).to be_truthy
      expect(Dir.exist?(expand_path('.worktrees/001-dirty'))).to be false
    end
  end

  describe '#current_worktree' do
    it 'returns current worktree when in one' do
      create_test_worktree('001-current')

      cd('.worktrees/001-current') do
        current = manager.current_worktree
        expect(current).to be_a(Worktrees::Models::FeatureWorktree)
        expect(current.name).to eq('001-current')
      end
    end

    it 'returns nil when not in a worktree' do
      current = manager.current_worktree
      expect(current).to be_nil
    end
  end
end