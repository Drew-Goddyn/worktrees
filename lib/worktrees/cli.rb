# frozen_string_literal: true

require 'dry/cli'

module Worktrees
  # CLI registry and command registration for worktree management
  module CLI
    extend Dry::CLI::Registry

    register 'create', Worktrees::Commands::Create, aliases: ['c']
    register 'list', Worktrees::Commands::List, aliases: %w[ls l]
    register 'switch', Worktrees::Commands::Switch, aliases: %w[sw s]
    register 'remove', Worktrees::Commands::Remove, aliases: %w[rm r]
    register 'status', Worktrees::Commands::Status, aliases: ['st']
  end

  # Main application entry point with git repository validation
  class App
    def self.start
      validate_git_repository
      run_cli
    rescue Interrupt
      handle_interrupt
    rescue StandardError => e
      handle_error(e)
    end

    private_class_method def self.validate_git_repository
      # Use git's own repository detection which traverses up the directory tree
      return if system('git rev-parse --git-dir >/dev/null 2>&1')

      warn 'ERROR: Not in a git repository'
      warn 'Run this command from inside a git repository'
      exit(1)
    end

    private_class_method def self.run_cli
      Dry::CLI.new(CLI).call
    end

    private_class_method def self.handle_interrupt
      warn "\nInterrupted"
      exit(130)
    end

    private_class_method def self.handle_error(error)
      warn "ERROR: #{error.message}"
      exit(1)
    end
  end
end
