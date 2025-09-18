# frozen_string_literal: true

require 'worktrees'
require 'support/git_helpers'
require 'support/ci_environment'

def safe_global_cleanup
  original_dir = Dir.pwd

  begin
    # Clean up any leftover temporary directories
    system('rm -rf tmp/ 2>/dev/null') if Dir.exist?('tmp')

    # Global git worktree cleanup
    system('git worktree prune 2>/dev/null') if File.exist?('.git')
  rescue StandardError => e
    warn "Warning: Global cleanup failed: #{e.message}"
  ensure
    # Ensure we're in a safe directory
    Dir.chdir(original_dir) if Dir.exist?(original_dir)
  end
end

RSpec.configure do |config|
  config.include GitHelpers

  # Enable CI debugging if in CI environment
  config.before(:suite) do
    if CIEnvironment.ci_environment?
      puts "Running tests in CI environment: #{CIEnvironment.detect_ci_platform}"
      CIEnvironment.debug_environment if ENV['DEBUG']
    end

    # Global cleanup for entire test suite
    safe_global_cleanup
  end

  config.after(:suite) do
    # Final cleanup
    safe_global_cleanup
    puts "\nTest suite completed in CI environment" if CIEnvironment.ci_environment?
  end

  # Test error handling with CI-specific reporting
  config.around(:each) do |example|
    CIEnvironment.with_enhanced_error_handling { example.run }
  rescue StandardError => e
    # Enhanced error reporting for CI
    if CIEnvironment.ci_environment? && ENV['DEBUG']
      puts "\n=== Test Failure Debug Information ==="
      puts "Test: #{example.full_description}"
      puts "Error: #{e.class}: #{e.message}"
      puts "Current Directory: #{begin
        Dir.pwd
      rescue StandardError
        'unknown'
      end}"
      puts "Working Directory Exists: #{begin
        Dir.exist?(Dir.pwd)
      rescue StandardError
        false
      end}"
    end
    raise e
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
