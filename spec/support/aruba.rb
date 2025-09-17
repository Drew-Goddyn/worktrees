# frozen_string_literal: true

require 'aruba/rspec'

RSpec.configure do |config|
  config.include Aruba::Api
  config.include GitHelpers

  config.before(:each) do
    setup_aruba
    cleanup_git_worktrees if respond_to?(:cleanup_git_worktrees)
  end

  config.after(:each) do
    cleanup_git_worktrees if respond_to?(:cleanup_git_worktrees)
  end
end

Aruba.configure do |config|
  config.exit_timeout = 5
  config.io_wait_timeout = 2
  config.startup_wait_time = 0.5

  # Use the exe/worktrees executable
  config.command_search_paths = [File.expand_path('../../exe', __dir__)]

  # Create temporary git repositories for testing
  config.working_directory = 'tmp/aruba'

  # Allow absolute paths for worktree directory changes
  config.allow_absolute_paths = true
end