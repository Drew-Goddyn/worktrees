# frozen_string_literal: true

require 'aruba/rspec'
require_relative 'test_isolation'
require_relative 'ci_environment'

RSpec.configure do |config|
  config.include Aruba::Api
  config.include GitHelpers
  config.include TestIsolation

  # Use the new isolation system for all aruba tests
  config.around(:each, type: :aruba) do |example|
    with_isolated_test do |isolation_context|
      # Set up Aruba within the isolated context
      setup_aruba

      # Set environment variables for the isolated context BEFORE setting working directory
      isolation_context.environment_variables.each do |key, value|
        set_environment_variable(key, value)
        # Also set in Ruby ENV to ensure it sticks
        ENV[key] = value
      end

      # Set Aruba to use our isolated workspace as its working directory
      cd(isolation_context.workspace_path)

      begin
        example.run
      ensure
        # Ensure we return to safe directory before cleanup
        begin
          Dir.chdir(isolation_context.safe_directory)
        rescue StandardError
          nil
        end
      end
    end
  end

  # Legacy cleanup for non-aruba tests that explicitly use git
  config.before(:each) do |example|
    next if example.metadata[:type] == :aruba
    # Only run git cleanup for tests that are actually testing git functionality
    next unless example.metadata[:git] == true

    cleanup_git_worktrees if respond_to?(:cleanup_git_worktrees)
  end

  config.after(:each) do |example|
    next if example.metadata[:type] == :aruba
    # Only run git cleanup for tests that are actually testing git functionality
    next unless example.metadata[:git] == true

    cleanup_git_worktrees if respond_to?(:cleanup_git_worktrees)
  end
end

Aruba.configure do |config|
  # Timeouts will be configured by CIEnvironment for CI
  config.exit_timeout = CIEnvironment.ci_environment? ? 30 : 10
  config.io_wait_timeout = CIEnvironment.ci_environment? ? 10 : 3
  config.startup_wait_time = CIEnvironment.ci_environment? ? 2 : 1

  # Use the exe/worktrees executable
  config.command_search_paths = [File.expand_path('../../exe', __dir__)]

  # Working directory will be set dynamically by isolation system
  # but provide a fallback for non-isolated tests
  config.working_directory = 'tmp/aruba'

  # Allow absolute paths for worktree directory changes
  config.allow_absolute_paths = true

  # Command timeout is handled by exit_timeout above

  # Configure process environment (done via set_environment_variable in tests)
end
