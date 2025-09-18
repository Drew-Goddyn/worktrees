# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Models::FeatureWorktree do
  let(:valid_attributes) do
    {
      name: '001-test-feature',
      path: '/tmp/worktrees/001-test-feature',
      branch: '001-test-feature',
      base_ref: 'main',
      status: :clean,
      created_at: Time.now,
      repository_path: '/tmp/test-repo'
    }
  end

  describe '#initialize' do
    it 'creates a worktree with valid attributes' do
      worktree = described_class.new(**valid_attributes)

      expect(worktree.name).to eq('001-test-feature')
      expect(worktree.path).to eq('/tmp/worktrees/001-test-feature')
      expect(worktree.status).to eq(:clean)
    end

    it 'raises error with invalid name format' do
      invalid_attributes = valid_attributes.merge(name: 'bad_name')

      expect { described_class.new(**invalid_attributes) }
        .to raise_error(Worktrees::ValidationError, /Invalid name format/)
    end

    it 'raises error with reserved name' do
      invalid_attributes = valid_attributes.merge(name: '001-main')

      expect { described_class.new(**invalid_attributes) }
        .to raise_error(Worktrees::ValidationError, /Reserved name 'main'/)
    end
  end

  describe '#valid?' do
    it 'returns true for valid worktree' do
      worktree = described_class.new(**valid_attributes)
      expect(worktree.valid?).to be true
    end

    it 'returns false for invalid name using class method' do
      expect(described_class.validate_name('invalid')).to be false
    end
  end

  describe '#active?' do
    it 'returns true when status is active' do
      worktree = described_class.new(**valid_attributes, status: :active)
      expect(worktree.active?).to be true
    end

    it 'returns false when status is not active' do
      worktree = described_class.new(**valid_attributes)
      expect(worktree.active?).to be false
    end
  end

  describe '#dirty?' do
    it 'returns true when status is dirty' do
      worktree = described_class.new(**valid_attributes, status: :dirty)
      expect(worktree.dirty?).to be true
    end

    it 'returns false when status is clean' do
      worktree = described_class.new(**valid_attributes)
      expect(worktree.dirty?).to be false
    end
  end

  describe '#to_h' do
    it 'returns hash representation' do
      worktree = described_class.new(**valid_attributes)
      hash = worktree.to_h

      expect(hash[:name]).to eq('001-test-feature')
      expect(hash[:status]).to eq(:clean)
      expect(hash[:path]).to eq('/tmp/worktrees/001-test-feature')
    end
  end

  describe '.validate_name' do
    it 'accepts valid names' do
      expect(described_class.validate_name('001-test-feature')).to be_truthy
      expect(described_class.validate_name('123-another-feature')).to be_truthy
    end

    it 'rejects invalid formats' do
      expect(described_class.validate_name('bad_name')).to be_falsey
      expect(described_class.validate_name('001')).to be_falsey
      expect(described_class.validate_name('001-')).to be_falsey
    end

    it 'rejects reserved names' do
      expect(described_class.validate_name('001-main')).to be_falsey
      expect(described_class.validate_name('001-master')).to be_falsey
    end
  end
end
