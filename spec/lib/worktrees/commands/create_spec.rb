# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Worktrees::Commands::Create do
  let(:manager) { instance_double('Worktrees::WorktreeManager') }
  let(:command) { described_class.new(manager) }
  let(:worktree) { instance_double('Worktrees::Models::FeatureWorktree') }

  before do
    allow(worktree).to receive(:name).and_return('001-test')
    allow(worktree).to receive(:path).and_return('/tmp/.worktrees/001-test')
    allow(worktree).to receive(:branch).and_return('001-test')
    allow(worktree).to receive(:base_ref).and_return('main')
    allow(worktree).to receive(:status).and_return(:clean)
  end

  describe '#call' do
    it 'creates worktree with name only' do
      allow(manager).to receive(:create_worktree).with('001-test', nil, {}).and_return(worktree)

      expect { command.call(name: '001-test') }.to output(/Created worktree: 001-test/).to_stdout
    end

    it 'creates worktree with name and base reference' do
      allow(manager).to receive(:create_worktree).with('001-test', 'develop', {}).and_return(worktree)

      expect { command.call(name: '001-test', base_ref: 'develop') }
        .to output(/Base: main/).to_stdout
    end

    it 'handles validation errors gracefully' do
      allow(manager).to receive(:create_worktree)
        .and_raise(Worktrees::ValidationError.new('Invalid name format'))

      expect { command.call(name: 'bad-name') }
        .to output(/ERROR: Validation: Invalid name format/).to_stderr
        .and raise_error(SystemExit) { |error| expect(error.status).to eq(2) }
    end

    it 'handles git errors gracefully' do
      allow(manager).to receive(:create_worktree)
        .and_raise(Worktrees::GitError.new('Base reference not found'))

      expect { command.call(name: '001-test', base_ref: 'nonexistent') }
        .to output(/ERROR: Git: Base reference not found/).to_stderr
        .and raise_error(SystemExit) { |error| expect(error.status).to eq(3) }
    end

    it 'supports worktrees-root option' do
      allow(manager).to receive(:create_worktree)
        .with('001-test', nil, { worktrees_root: '/custom/path' })
        .and_return(worktree)

      expect { command.call(name: '001-test', **{ 'worktrees-root': '/custom/path' }) }
        .to output(/Created worktree/).to_stdout
    end

    it 'supports force option' do
      allow(manager).to receive(:create_worktree)
        .with('001-test', nil, { force: true })
        .and_return(worktree)

      expect { command.call(name: '001-test', force: true) }
        .to output(/Created worktree/).to_stdout
    end

    it 'displays worktree information in readable format' do
      allow(manager).to receive(:create_worktree).and_return(worktree)

      output = capture_stdout { command.call(name: '001-test') }

      expect(output).to include('Created worktree: 001-test')
      expect(output).to include('Path: /tmp/.worktrees/001-test')
      expect(output).to include('Branch: 001-test')
      expect(output).to include('Base: main')
      expect(output).to include('Status: clean')
    end
  end

  describe '#validate_arguments' do
    it 'accepts valid name format' do
      expect { command.send(:validate_arguments, '001-valid-name', nil) }
        .not_to raise_error
    end

    it 'rejects missing name' do
      expect { command.send(:validate_arguments, nil, nil) }
        .to raise_error(Worktrees::ValidationError, /Name is required/)
    end

    it 'rejects empty name' do
      expect { command.send(:validate_arguments, '', nil) }
        .to raise_error(Worktrees::ValidationError, /Name cannot be empty/)
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end