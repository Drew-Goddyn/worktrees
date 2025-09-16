# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::GitOperations do
  let(:test_repo_path) { '/tmp/test-repo' }
  let(:worktree_path) { '/tmp/worktrees/001-test' }

  describe '.create_worktree' do
    it 'creates worktree with valid parameters' do
      expect(described_class).to receive(:system)
        .with('git', 'worktree', 'add', '-b', '001-test', worktree_path, 'main')
        .and_return(true)

      result = described_class.create_worktree(worktree_path, '001-test', 'main')
      expect(result).to be true
    end

    it 'returns false when git command fails' do
      expect(described_class).to receive(:system)
        .with('git', 'worktree', 'add', '-b', '001-test', worktree_path, 'main')
        .and_return(false)

      result = described_class.create_worktree(worktree_path, '001-test', 'main')
      expect(result).to be false
    end

    it 'handles existing branch by checking out instead of creating' do
      expect(described_class).to receive(:branch_exists?).with('001-existing').and_return(true)
      expect(described_class).to receive(:system)
        .with('git', 'worktree', 'add', worktree_path, '001-existing')
        .and_return(true)

      result = described_class.create_worktree(worktree_path, '001-existing', 'main')
      expect(result).to be true
    end
  end

  describe '.list_worktrees' do
    it 'returns parsed worktree information' do
      git_output = "/tmp/worktrees/001-test abc1234 [001-test]\n/tmp/worktrees/002-test def5678 [002-test]"
      expect(described_class).to receive(:`)
        .with('git worktree list --porcelain')
        .and_return(git_output)

      worktrees = described_class.list_worktrees

      expect(worktrees).to be_an(Array)
      expect(worktrees.length).to eq(2)
      expect(worktrees.first[:path]).to include('001-test')
    end

    it 'returns empty array when no worktrees exist' do
      expect(described_class).to receive(:`)
        .with('git worktree list --porcelain')
        .and_return('')

      worktrees = described_class.list_worktrees
      expect(worktrees).to eq([])
    end

    it 'handles git command failure' do
      expect(described_class).to receive(:`)
        .with('git worktree list --porcelain')
        .and_raise(StandardError.new('git failed'))

      expect { described_class.list_worktrees }
        .to raise_error(Worktrees::GitError, /Failed to list worktrees/)
    end
  end

  describe '.remove_worktree' do
    it 'removes worktree successfully' do
      expect(described_class).to receive(:system)
        .with('git', 'worktree', 'remove', worktree_path)
        .and_return(true)

      result = described_class.remove_worktree(worktree_path)
      expect(result).to be true
    end

    it 'forces removal when requested' do
      expect(described_class).to receive(:system)
        .with('git', 'worktree', 'remove', '--force', worktree_path)
        .and_return(true)

      result = described_class.remove_worktree(worktree_path, force: true)
      expect(result).to be true
    end

    it 'returns false when removal fails' do
      expect(described_class).to receive(:system)
        .with('git', 'worktree', 'remove', worktree_path)
        .and_return(false)

      result = described_class.remove_worktree(worktree_path)
      expect(result).to be false
    end
  end

  describe '.branch_exists?' do
    it 'returns true for existing branch' do
      expect(described_class).to receive(:system)
        .with('git', 'show-ref', '--verify', '--quiet', 'refs/heads/main')
        .and_return(true)

      expect(described_class.branch_exists?('main')).to be true
    end

    it 'returns false for non-existent branch' do
      expect(described_class).to receive(:system)
        .with('git', 'show-ref', '--verify', '--quiet', 'refs/heads/nonexistent')
        .and_return(false)

      expect(described_class.branch_exists?('nonexistent')).to be false
    end
  end

  describe '.current_branch' do
    it 'returns current branch name' do
      expect(described_class).to receive(:`)
        .with('git rev-parse --abbrev-ref HEAD')
        .and_return("main\n")

      expect(described_class.current_branch).to eq('main')
    end

    it 'handles detached HEAD' do
      expect(described_class).to receive(:`)
        .with('git rev-parse --abbrev-ref HEAD')
        .and_return("HEAD\n")

      expect(described_class.current_branch).to eq('HEAD')
    end
  end

  describe '.is_clean?' do
    it 'returns true for clean repository' do
      expect(described_class).to receive(:system)
        .with('git', 'diff-index', '--quiet', 'HEAD', chdir: worktree_path)
        .and_return(true)

      expect(described_class.is_clean?(worktree_path)).to be true
    end

    it 'returns false for dirty repository' do
      expect(described_class).to receive(:system)
        .with('git', 'diff-index', '--quiet', 'HEAD', chdir: worktree_path)
        .and_return(false)

      expect(described_class.is_clean?(worktree_path)).to be false
    end
  end

  describe '.has_unpushed_commits?' do
    it 'returns true when commits are unpushed' do
      expect(described_class).to receive(:`)
        .with('git rev-list @{u}..HEAD')
        .and_return("abc1234\ndef5678\n")

      expect(described_class.has_unpushed_commits?('feature-branch')).to be true
    end

    it 'returns false when all commits are pushed' do
      expect(described_class).to receive(:`)
        .with('git rev-list @{u}..HEAD')
        .and_return('')

      expect(described_class.has_unpushed_commits?('feature-branch')).to be false
    end

    it 'returns false when no upstream exists' do
      expect(described_class).to receive(:`)
        .with('git rev-list @{u}..HEAD')
        .and_raise(StandardError.new('no upstream'))

      expect(described_class.has_unpushed_commits?('feature-branch')).to be false
    end
  end
end