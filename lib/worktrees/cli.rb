# frozen_string_literal: true

require 'dry/cli'

module Worktrees
  module CLI
    extend Dry::CLI::Registry

    register 'create', Worktrees::Commands::Create, aliases: ['c']
    register 'list', Worktrees::Commands::List, aliases: ['ls', 'l']
    register 'switch', Worktrees::Commands::Switch, aliases: ['sw', 's']
    register 'remove', Worktrees::Commands::Remove, aliases: ['rm', 'r']
    register 'status', Worktrees::Commands::Status, aliases: ['st']
  end

  class App
    def self.start
      begin
        # Ensure we're in a git repository
        unless Dir.exist?('.git') || system('git rev-parse --git-dir >/dev/null 2>&1')
          warn 'ERROR: Not in a git repository'
          warn 'Run this command from inside a git repository'
          exit(1)
        end

        Dry::CLI.new(CLI).call
      rescue Interrupt
        warn "\nInterrupted"
        exit(130)
      rescue StandardError => e
        warn "ERROR: #{e.message}"
        exit(1)
      end
    end
  end
end