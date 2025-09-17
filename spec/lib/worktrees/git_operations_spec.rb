# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::GitOperations, type: :aruba do
  describe '.create_worktree' do
    before { setup_test_repo }

    it 'creates worktree with valid parameters' do
      worktree_path = expand_path('.worktrees/001-test')
      create_directory('.worktrees')

      result = described_class.create_worktree(worktree_path, '001-test', 'main')
      expect(result).to be true
      expect(Dir.exist?(worktree_path)).to be true
    end

    it 'returns false when git command fails' do
      # Try to create worktree with invalid base branch
      worktree_path = expand_path('.worktrees/001-test')
      create_directory('.worktrees')

      result = described_class.create_worktree(worktree_path, '001-test', 'nonexistent-base')
      expect(result).to be false
    end

    it 'handles existing branch by checking out instead of creating' do
      # Create an existing branch first
      run_command('git checkout -b 001-existing')
      run_command('git checkout main')

      worktree_path = expand_path('.worktrees/001-existing')
      create_directory('.worktrees')

      result = described_class.create_worktree(worktree_path, '001-existing', 'main')
      expect(result).to be true
      expect(Dir.exist?(worktree_path)).to be true
    end
  end

  describe '.list_worktrees' do
    before { setup_test_repo }

    it 'returns parsed worktree information' do
      # Create actual worktrees
      create_test_worktree('001-test')
      create_test_worktree('002-test')

      worktrees = described_class.list_worktrees

      expect(worktrees).to be_an(Array)
      expect(worktrees.length).to eq(3) # main repo + 2 worktrees
      worktree_names = worktrees.map { |w| w[:branch] }.compact
      expect(worktree_names).to include('001-test', '002-test')
    end

    it 'returns main repo when no additional worktrees exist' do
      worktrees = described_class.list_worktrees
      expect(worktrees).to be_an(Array)
      expect(worktrees.length).to eq(1) # Just the main repo
      expect(worktrees.first[:branch]).to eq('main')
    end

    it 'handles git command failure gracefully' do
      # Move to non-git directory to cause failure
      create_directory('non-git')
      cd('non-git') do
        expect { described_class.list_worktrees }
          .to raise_error(Worktrees::GitError, /Failed to list worktrees/)
      end
    end
  end

  describe '.remove_worktree' do
    before { setup_test_repo }

    it 'removes worktree successfully' do
      create_test_worktree('001-test')
      worktree_path = expand_path('.worktrees/001-test')

      expect(Dir.exist?(worktree_path)).to be true
      result = described_class.remove_worktree(worktree_path)
      expect(result).to be true
      expect(Dir.exist?(worktree_path)).to be false
    end

    it 'forces removal when requested' do
      create_test_worktree('001-test')
      worktree_path = expand_path('.worktrees/001-test')
      # Make it dirty to require force
      make_dirty_worktree('001-test')

      result = described_class.remove_worktree(worktree_path, force: true)
      expect(result).to be true
      expect(Dir.exist?(worktree_path)).to be false
    end

    it 'returns false when removal fails' do
      # Try to remove non-existent worktree
      worktree_path = expand_path('.worktrees/nonexistent')

      result = described_class.remove_worktree(worktree_path)
      expect(result).to be false
    end
  end

  describe '.branch_exists?' do
    before { setup_test_repo }

    it 'returns true for existing branch' do
      result = described_class.branch_exists?('main')
      expect(result).to be true
    end

    it 'returns false for non-existent branch' do
      result = described_class.branch_exists?('nonexistent')
      expect(result).to be false
    end

    it 'returns true for newly created branch' do
      run_command('git checkout -b test-branch')
      run_command('git checkout main')

      result = described_class.branch_exists?('test-branch')
      expect(result).to be true
    end
  end

  describe '.current_branch' do
    before { setup_test_repo }

    it 'returns current branch name' do
      expect(described_class.current_branch).to eq('main')
    end

    it 'returns branch name when on feature branch' do
      run_command('git checkout -b feature-branch')

      expect(described_class.current_branch).to eq('feature-branch')
    end
  end

  describe '.is_clean?' do
    before { setup_test_repo }

    it 'returns true for clean repository' do
      expect(described_class.is_clean?(expand_path('.'))).to be true
    end

    it 'returns false for dirty repository' do
      write_file('dirty.txt', 'Uncommitted changes')

      expect(described_class.is_clean?(expand_path('.'))).to be false
    end

    it 'returns true after staging and committing changes' do
      write_file('new-file.txt', 'New content')
      run_command('git add new-file.txt')
      run_command('git commit -m "Add new file"')

      expect(described_class.is_clean?(expand_path('.'))).to be true
    end
  end

  describe '.has_unpushed_commits?' do
    before do
      setup_test_repo
      setup_remote_repo
    end

    it 'returns false when all commits are pushed' do
      expect(described_class.has_unpushed_commits?('main')).to be false
    end

    it 'returns true when commits are unpushed' do
      write_file('unpushed.txt', 'Unpushed content')
      run_command('git add unpushed.txt')
      run_command('git commit -m "Unpushed commit"')

      expect(described_class.has_unpushed_commits?('main')).to be true
    end

    it 'returns false when no upstream exists' do
      # Create a feature branch with no upstream
      run_command('git checkout -b feature-no-upstream')
      write_file('feature.txt', 'Feature content')
      run_command('git add feature.txt')
      run_command('git commit -m "Feature commit"')

      expect(described_class.has_unpushed_commits?('feature-no-upstream')).to be false
    end
  end
end