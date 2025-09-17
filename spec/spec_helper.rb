# frozen_string_literal: true

require 'worktrees'
require 'support/git_helpers'

RSpec.configure do |config|
  config.include GitHelpers, type: :aruba

  # Clean up before each test to ensure fresh state
  config.before(:each, type: :aruba) do
    cleanup_git_worktrees if respond_to?(:cleanup_git_worktrees)
  end

  # Clean up after each test to prevent interference
  config.after(:each, type: :aruba) do
    cleanup_git_worktrees if respond_to?(:cleanup_git_worktrees)
  end

  # Global cleanup for entire test suite
  config.before(:suite) do
    system("git worktree prune 2>/dev/null || true")
    system("rm -rf tmp/ 2>/dev/null || true")
  end

  config.after(:suite) do
    system("git worktree prune 2>/dev/null || true")
    system("rm -rf tmp/ 2>/dev/null || true")
  end
  # rspec-expectations config goes here
  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  # rspec-mocks config goes here
  config.mock_with :rspec do |c|
    c.verify_partial_doubles = true
  end

  # This setting enables warnings. It's recommended, but in some cases may
  # be too noisy due to issues in dependencies.
  config.warnings = true

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  config.order = :random

  # Seed global randomization in this process using the `--seed` CLI option.
  Kernel.srand config.seed
end