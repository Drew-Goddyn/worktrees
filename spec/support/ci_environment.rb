# frozen_string_literal: true

# CI-specific configuration and debugging utilities
# Provides enhanced error handling, debugging, and timeout adjustments for CI environments
module CIEnvironment
  class << self
    def ci_environment?
      !!(ENV['CI'] || ENV['GITHUB_ACTIONS'] || ENV['BUILDKITE'] || ENV['TRAVIS'])
    end

    def github_actions?
      ENV['GITHUB_ACTIONS'] == 'true'
    end

    def configure_for_ci
      return unless ci_environment?

      # Adjust timeouts for CI environment
      configure_timeouts

      # Set up enhanced logging
      configure_logging

      # Configure cleanup behavior
      configure_cleanup_behavior

      # Set up failure artifact collection
      configure_failure_handling
    end

    def debug_environment
      return unless ci_environment? && ENV['DEBUG']

      puts "\n=== CI Environment Debug Information ==="
      puts "CI Platform: #{detect_ci_platform}"
      puts "Ruby Version: #{RUBY_VERSION}"
      puts "Working Directory: #{Dir.pwd}"
      puts "Temp Directory: #{Dir.tmpdir}"
      puts "Home Directory: #{ENV['HOME']}"

      puts "\nEnvironment Variables:"
      debug_env_vars.each { |k, v| puts "  #{k}=#{v}" }

      puts "\nGit Configuration:"
      debug_git_configuration

      puts "\nFile System State:"
      debug_file_system

      puts "\nProcess Information:"
      puts "  PID: #{Process.pid}"
      puts "  User: #{ENV['USER'] || 'unknown'}"
      puts "========================\n"
    end

    def with_enhanced_error_handling
      yield
    rescue => e
      if ci_environment?
        enhanced_error_reporting(e)
      end
      raise e
    end

    def collect_failure_artifacts(test_name, error)
      return unless ci_environment?

      timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
      artifacts_dir = "tmp/ci_failures/#{timestamp}_#{sanitize_filename(test_name)}"
      FileUtils.mkdir_p(artifacts_dir)

      collect_basic_artifacts(artifacts_dir, error)
      collect_git_artifacts(artifacts_dir)
      collect_system_artifacts(artifacts_dir)

      puts "::warning::Failure artifacts collected in #{artifacts_dir}" if github_actions?
      artifacts_dir
    end

    private

    def detect_ci_platform
      return 'GitHub Actions' if ENV['GITHUB_ACTIONS']
      return 'Buildkite' if ENV['BUILDKITE']
      return 'Travis CI' if ENV['TRAVIS']
      return 'CircleCI' if ENV['CIRCLECI']
      'Unknown CI'
    end

    def configure_timeouts
      # Increase timeouts for CI environment
      if defined?(Aruba)
        Aruba.configure do |config|
          config.exit_timeout = 30  # Increased from default 5
          config.io_wait_timeout = 10  # Increased from default 2
          config.startup_wait_time = 2  # Increased from default 0.5
        end
      end

      # Set environment variables for custom timeouts
      ENV['WORKTREES_TEST_TIMEOUT'] = '30'
      ENV['WORKTREES_GIT_TIMEOUT'] = '15'
    end

    def configure_logging
      # Enable verbose logging in CI
      ENV['WORKTREES_VERBOSE'] = 'true'
      ENV['WORKTREES_DEBUG'] = 'true' if ENV['DEBUG']

      # Configure git for better error reporting
      ENV['GIT_TRACE'] = '1' if ENV['GIT_DEBUG']
    end

    def configure_cleanup_behavior
      # Be more aggressive about cleanup in CI
      ENV['WORKTREES_FORCE_CLEANUP'] = 'true'

      # Set shorter cleanup retry intervals
      ENV['WORKTREES_CLEANUP_RETRY_DELAY'] = '0.1'
      ENV['WORKTREES_CLEANUP_MAX_RETRIES'] = '5'
    end

    def configure_failure_handling
      # Configure RSpec to collect artifacts on failure
      if defined?(RSpec)
        RSpec.configure do |config|
          config.after(:each) do |example|
            if example.exception && ci_environment?
              collect_failure_artifacts(example.full_description, example.exception)
            end
          end
        end
      end
    end

    def debug_env_vars
      ENV.select { |k, _| k.match?(/^(CI|GITHUB|RUBY|GIT|HOME|PWD|TMPDIR|WORKTREES)/) }
         .sort
         .to_h
    end

    def debug_git_configuration
      configs = %w[user.name user.email init.defaultBranch core.autocrlf]
      configs.each do |config|
        value = `git config --get #{config} 2>/dev/null`.strip
        puts "  #{config}: #{value.empty? ? '(not set)' : value}"
      end
    end

    def debug_file_system
      begin
        entries = Dir.glob('**/*', File::FNM_DOTMATCH)
                     .reject { |f| f.match?(%r{^\.+$}) }
                     .sort
                     .first(20)

        entries.each { |entry| puts "  #{entry}" }
        puts "  ... (#{Dir.glob('**/*').length} total entries)" if Dir.glob('**/*').length > 20
      rescue => e
        puts "  Error reading file system: #{e.message}"
      end
    end

    def enhanced_error_reporting(error)
      puts "\n::error::Enhanced Error Report"
      puts "Error Class: #{error.class}"
      puts "Error Message: #{error.message}"
      puts "Backtrace:"
      error.backtrace&.first(10)&.each { |line| puts "  #{line}" }

      puts "\nCurrent Directory: #{Dir.pwd rescue 'unknown'}"
      puts "Process ID: #{Process.pid}"
      puts "Time: #{Time.now}"
    end

    def collect_basic_artifacts(artifacts_dir, error)
      File.write("#{artifacts_dir}/error.txt", error.message)
      File.write("#{artifacts_dir}/backtrace.txt", error.backtrace.join("\n")) if error.backtrace
      File.write("#{artifacts_dir}/environment.txt", ENV.to_h.inspect)
      File.write("#{artifacts_dir}/pwd.txt", (Dir.pwd rescue 'unknown'))
    end

    def collect_git_artifacts(artifacts_dir)
      git_commands = [
        ['git status --porcelain', 'git_status.txt'],
        ['git log --oneline -10', 'git_log.txt'],
        ['git branch -a', 'git_branches.txt'],
        ['git worktree list --porcelain', 'git_worktrees.txt'],
        ['git config --list --local', 'git_config_local.txt'],
        ['git config --list --global', 'git_config_global.txt']
      ]

      git_commands.each do |command, filename|
        begin
          output = `#{command} 2>&1`
          File.write("#{artifacts_dir}/#{filename}", output)
        rescue => e
          File.write("#{artifacts_dir}/#{filename}", "Error: #{e.message}")
        end
      end
    end

    def collect_system_artifacts(artifacts_dir)
      system_commands = [
        ['ls -la', 'ls_current.txt'],
        ['df -h', 'disk_usage.txt'],
        ['ps aux', 'processes.txt'],
        ['env', 'environment_vars.txt']
      ]

      system_commands.each do |command, filename|
        begin
          output = `#{command} 2>&1`
          File.write("#{artifacts_dir}/#{filename}", output)
        rescue => e
          File.write("#{artifacts_dir}/#{filename}", "Error: #{e.message}")
        end
      end
    end

    def sanitize_filename(name)
      name.gsub(/[^a-zA-Z0-9_-]/, '_')[0..50]
    end
  end
end

# Auto-configure when loaded
CIEnvironment.configure_for_ci