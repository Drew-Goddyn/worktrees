# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::WorktreeManager do
  let(:repository) { instance_double('Worktrees::Models::Repository') }
  let(:config) { instance_double('Worktrees::Models::WorktreeConfig') }
  let(:manager) { described_class.new(repository, config) }

  before do
    allow(config).to receive(:worktrees_root).and_return('/tmp/.worktrees')
    allow(config).to receive(:expand_worktrees_root).and_return('/tmp/.worktrees')
    allow(repository).to receive(:default_branch).and_return('main')
  end

  describe '#create_worktree' do
    it 'creates worktree with valid name and base' do
      allow(config).to receive(:valid_name?).with('001-test').and_return(true)
      allow(repository).to receive(:branch_exists?).with('main').and_return(true)
      allow(Worktrees::GitOperations).to receive(:create_worktree).and_return(true)
      allow(File).to receive(:directory?).and_return(true)

      worktree = manager.create_worktree('001-test', 'main')

      expect(worktree).to be_a(Worktrees::Models::FeatureWorktree)
      expect(worktree.name).to eq('001-test')
      expect(worktree.base_ref).to eq('main')
    end

    it 'raises validation error for invalid name' do
      allow(config).to receive(:valid_name?).with('bad-name').and_return(false)

      expect { manager.create_worktree('bad-name', 'main') }
        .to raise_error(Worktrees::ValidationError, /Invalid name/)
    end

    it 'raises error for non-existent base reference' do
      allow(config).to receive(:valid_name?).with('001-test').and_return(true)
      allow(repository).to receive(:branch_exists?).with('nonexistent').and_return(false)

      expect { manager.create_worktree('001-test', 'nonexistent') }
        .to raise_error(Worktrees::GitError, /Base reference.*not found/)
    end

    it 'uses default base when none provided' do
      allow(config).to receive(:valid_name?).with('001-test').and_return(true)
      allow(repository).to receive(:branch_exists?).with('main').and_return(true)
      allow(Worktrees::GitOperations).to receive(:create_worktree).and_return(true)
      allow(File).to receive(:directory?).and_return(true)

      worktree = manager.create_worktree('001-test')

      expect(worktree.base_ref).to eq('main')
    end

    it 'raises error when worktree creation fails' do
      allow(config).to receive(:valid_name?).with('001-test').and_return(true)
      allow(repository).to receive(:branch_exists?).with('main').and_return(true)
      allow(Worktrees::GitOperations).to receive(:create_worktree).and_return(false)

      expect { manager.create_worktree('001-test', 'main') }
        .to raise_error(Worktrees::GitError, /Failed to create worktree/)
    end
  end

  describe '#list_worktrees' do
    it 'returns list of worktrees' do
      git_worktrees = [
        { path: '/tmp/.worktrees/001-test', branch: '001-test' },
        { path: '/tmp/.worktrees/002-test', branch: '002-test' }
      ]
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return(git_worktrees)
      allow(File).to receive(:directory?).and_return(true)

      worktrees = manager.list_worktrees

      expect(worktrees).to be_an(Array)
      expect(worktrees.length).to eq(2)
      expect(worktrees.first).to be_a(Worktrees::Models::FeatureWorktree)
    end

    it 'returns empty array when no worktrees exist' do
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return([])

      worktrees = manager.list_worktrees
      expect(worktrees).to eq([])
    end

    it 'filters worktrees by status' do
      git_worktrees = [
        { path: '/tmp/.worktrees/001-clean', branch: '001-clean' },
        { path: '/tmp/.worktrees/002-dirty', branch: '002-dirty' }
      ]
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return(git_worktrees)
      allow(File).to receive(:directory?).and_return(true)
      allow(Worktrees::GitOperations).to receive(:is_clean?).with('/tmp/.worktrees/001-clean').and_return(true)
      allow(Worktrees::GitOperations).to receive(:is_clean?).with('/tmp/.worktrees/002-dirty').and_return(false)

      clean_worktrees = manager.list_worktrees(status: :clean)

      expect(clean_worktrees.length).to eq(1)
      expect(clean_worktrees.first.name).to eq('001-clean')
    end
  end

  describe '#find_worktree' do
    it 'finds worktree by name' do
      git_worktrees = [{ path: '/tmp/.worktrees/001-test', branch: '001-test' }]
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return(git_worktrees)
      allow(File).to receive(:directory?).and_return(true)

      worktree = manager.find_worktree('001-test')

      expect(worktree).to be_a(Worktrees::Models::FeatureWorktree)
      expect(worktree.name).to eq('001-test')
    end

    it 'returns nil for non-existent worktree' do
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return([])

      worktree = manager.find_worktree('nonexistent')
      expect(worktree).to be_nil
    end
  end

  describe '#remove_worktree' do
    let(:worktree) { instance_double('Worktrees::Models::FeatureWorktree') }

    before do
      allow(worktree).to receive(:name).and_return('001-test')
      allow(worktree).to receive(:path).and_return('/tmp/.worktrees/001-test')
      allow(worktree).to receive(:branch).and_return('001-test')
      allow(worktree).to receive(:active?).and_return(false)
      allow(worktree).to receive(:dirty?).and_return(false)
    end

    it 'removes clean inactive worktree' do
      allow(manager).to receive(:find_worktree).with('001-test').and_return(worktree)
      allow(Worktrees::GitOperations).to receive(:remove_worktree).and_return(true)

      result = manager.remove_worktree('001-test')
      expect(result).to be_truthy
    end

    it 'prevents removal of active worktree' do
      allow(worktree).to receive(:active?).and_return(true)
      allow(manager).to receive(:find_worktree).with('001-test').and_return(worktree)

      expect { manager.remove_worktree('001-test') }
        .to raise_error(Worktrees::StateError, /Cannot remove active worktree/)
    end

    it 'prevents removal of dirty worktree without force' do
      allow(worktree).to receive(:dirty?).and_return(true)
      allow(manager).to receive(:find_worktree).with('001-test').and_return(worktree)

      expect { manager.remove_worktree('001-test') }
        .to raise_error(Worktrees::StateError, /has uncommitted changes/)
    end

    it 'allows force removal of dirty worktree with untracked files' do
      allow(worktree).to receive(:dirty?).and_return(true)
      allow(manager).to receive(:find_worktree).with('001-test').and_return(worktree)
      allow(Worktrees::GitOperations).to receive(:remove_worktree).and_return(true)

      result = manager.remove_worktree('001-test', force_untracked: true)
      expect(result).to be_truthy
    end

    it 'raises error for non-existent worktree' do
      allow(manager).to receive(:find_worktree).with('nonexistent').and_return(nil)

      expect { manager.remove_worktree('nonexistent') }
        .to raise_error(Worktrees::ValidationError, /not found/)
    end
  end

  describe '#current_worktree' do
    it 'returns current worktree when in one' do
      allow(Dir).to receive(:pwd).and_return('/tmp/.worktrees/001-current')
      git_worktrees = [{ path: '/tmp/.worktrees/001-current', branch: '001-current' }]
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return(git_worktrees)
      allow(File).to receive(:directory?).and_return(true)

      current = manager.current_worktree
      expect(current).to be_a(Worktrees::Models::FeatureWorktree)
      expect(current.name).to eq('001-current')
    end

    it 'returns nil when not in a worktree' do
      allow(Dir).to receive(:pwd).and_return('/some/other/path')
      allow(Worktrees::GitOperations).to receive(:list_worktrees).and_return([])

      current = manager.current_worktree
      expect(current).to be_nil
    end
  end
end