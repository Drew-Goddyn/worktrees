# frozen_string_literal: true

require 'aruba/rspec'

RSpec.configure do |config|
  config.include Aruba::Api

  config.before(:each) do
    setup_aruba
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
end