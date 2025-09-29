# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Models::WorktreeConfig do
  describe '#initialize' do
    it 'creates config with default values' do
      config = described_class.new

      expect(config.worktrees_root).to match(%r{/.worktrees$})
      expect(config.default_base).to be_nil
      expect(config.force_cleanup).to be false
      expect(config.name_pattern).to be_a(Regexp)
    end

    it 'accepts custom values' do
      config = described_class.new(
        worktrees_root: '/custom/path',
        default_base: 'develop',
        force_cleanup: true
      )

      expect(config.worktrees_root).to eq('/custom/path')
      expect(config.default_base).to eq('develop')
      expect(config.force_cleanup).to be true
    end
  end

  describe '.load' do
    it 'loads from config file when it exists' do
      config_path = '/tmp/.worktrees/config.yml'
      config_content = {
        'worktrees_root' => '/custom/worktrees',
        'default_base' => 'main',
        'force_cleanup' => false
      }

      allow(File).to receive(:exist?).with(config_path).and_return(true)
      allow(YAML).to receive(:load_file).with(config_path).and_return(config_content)

      config = described_class.load(config_path)

      expect(config.worktrees_root).to eq('/custom/worktrees')
      expect(config.default_base).to eq('main')
    end

    it 'returns default config when file does not exist' do
      config_path = '/nonexistent/config.yml'
      allow(File).to receive(:exist?).with(config_path).and_return(false)

      config = described_class.load(config_path)

      expect(config).to be_a(described_class)
      expect(config.default_base).to be_nil
    end

    it 'handles invalid YAML gracefully' do
      config_path = '/tmp/.worktrees/config.yml'
      allow(File).to receive(:exist?).with(config_path).and_return(true)
      syntax_error = Psych::SyntaxError.new('file.yml', 1, 1, 0, 'invalid syntax', 'context')
      allow(YAML).to receive(:load_file).with(config_path).and_raise(syntax_error)

      expect { described_class.load(config_path) }
        .to raise_error(Worktrees::Error, /Invalid configuration file/)
    end
  end

  describe '#valid_name?' do
    it 'validates names against pattern' do
      config = described_class.new

      expect(config.valid_name?('001-test-feature')).to be true
      expect(config.valid_name?('123-another-feature')).to be true
      expect(config.valid_name?('bad_name')).to be false
      expect(config.valid_name?('001')).to be false
    end

    it 'rejects reserved names' do
      config = described_class.new

      expect(config.valid_name?('001-main')).to be false
      expect(config.valid_name?('001-master')).to be false
    end
  end


  describe '#to_h' do
    it 'returns hash representation' do
      config = described_class.new(
        worktrees_root: '/custom/path',
        default_base: 'develop'
      )

      hash = config.to_h

      expect(hash[:worktrees_root]).to eq('/custom/path')
      expect(hash[:default_base]).to eq('develop')
      expect(hash[:force_cleanup]).to be false
    end
  end
end
