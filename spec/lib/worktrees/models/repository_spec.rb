# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Models::Repository do
  let(:temp_repo_path) { '/tmp/test-repo' }

  describe '#initialize' do
    it 'creates repository with valid git directory' do
      # Mock File.directory? to simulate valid .git directory
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      repo = described_class.new(temp_repo_path)
      expect(repo.root_path).to eq(temp_repo_path)
    end

    it 'raises error for invalid repository' do
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(false)

      expect { described_class.new(temp_repo_path) }
        .to raise_error(Worktrees::GitError, /Not a git repository/)
    end
  end

  describe '#default_branch' do
    it 'detects main as default branch' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      # Mock git command to return main as default
      allow(repo).to receive(:git_default_branch).and_return('main')

      expect(repo.default_branch).to eq('main')
    end

    it 'falls back to master if main does not exist' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      allow(repo).to receive(:git_default_branch).and_return('master')

      expect(repo.default_branch).to eq('master')
    end
  end

  describe '#branch_exists?' do
    it 'returns true for existing branch' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      allow(repo).to receive(:git_branch_exists?).with('main').and_return(true)

      expect(repo.branch_exists?('main')).to be true
    end

    it 'returns false for non-existent branch' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      allow(repo).to receive(:git_branch_exists?).with('nonexistent').and_return(false)

      expect(repo.branch_exists?('nonexistent')).to be false
    end
  end

  describe '#remote_url' do
    it 'returns origin URL when present' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      allow(repo).to receive(:git_remote_url).and_return('https://github.com/user/repo.git')

      expect(repo.remote_url).to eq('https://github.com/user/repo.git')
    end

    it 'returns nil when no remote exists' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      allow(repo).to receive(:git_remote_url).and_return(nil)

      expect(repo.remote_url).to be_nil
    end
  end

  describe '#worktrees_path' do
    it 'returns configured worktrees directory' do
      repo = described_class.new(temp_repo_path)
      allow(File).to receive(:directory?).with("#{temp_repo_path}/.git").and_return(true)

      config = instance_double('Worktrees::Models::WorktreeConfig')
      allow(config).to receive(:worktrees_root).and_return('/home/user/.worktrees')
      allow(repo).to receive(:config).and_return(config)

      expect(repo.worktrees_path).to eq('/home/user/.worktrees')
    end
  end
end