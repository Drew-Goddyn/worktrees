# frozen_string_literal: true

require 'spec_helper'
require 'support/aruba'

RSpec.describe Worktrees::Models::Repository, type: :aruba do
  describe '#initialize' do
    it 'creates repository with valid git directory' do
      setup_test_repo

      repo = described_class.new(expand_path('.'))
      expect(repo.root_path).to eq(expand_path('.'))
    end

    it 'raises error for invalid repository' do
      # Create a directory that's not a git repo
      create_directory('not-a-repo')

      expect { described_class.new(expand_path('not-a-repo')) }
        .to raise_error(Worktrees::GitError, /Not a git repository/)
    end
  end

  describe '#default_branch' do
    it 'detects main as default branch' do
      setup_test_repo

      repo = described_class.new(expand_path('.'))
      expect(repo.default_branch).to eq('main')
    end

    it 'falls back to master if main does not exist' do
      # Create repo with master as default (older git behavior)
      run_command('git init')
      run_command('git config user.email "test@example.com"')
      run_command('git config user.name "Test User"')
      run_command('git checkout -b master')
      write_file('README.md', '# Test')
      run_command('git add README.md')
      run_command('git commit -m "Initial commit"')

      repo = described_class.new(expand_path('.'))
      expect(repo.default_branch).to eq('master')
    end
  end

  describe '#branch_exists?' do
    it 'returns true for existing branch' do
      setup_test_repo

      repo = described_class.new(expand_path('.'))
      expect(repo.branch_exists?('main')).to be true
    end

    it 'returns false for non-existent branch' do
      setup_test_repo

      repo = described_class.new(expand_path('.'))
      expect(repo.branch_exists?('nonexistent')).to be false
    end
  end

  describe '#remote_url' do
    it 'returns origin URL when present' do
      setup_test_repo
      setup_remote_repo

      repo = described_class.new(expand_path('.'))
      expect(repo.remote_url).to include('./remote.git')
    end

    it 'returns nil when no remote exists' do
      setup_test_repo

      repo = described_class.new(expand_path('.'))
      expect(repo.remote_url).to be_nil
    end
  end

  describe '#worktrees_path' do
    it 'returns configured worktrees directory' do
      setup_test_repo

      repo = described_class.new(expand_path('.'))
      # This will use default config which should return ~/.worktrees
      expect(repo.worktrees_path).to match(/.worktrees$/)
    end
  end
end