# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task default: :spec

desc "Run all RSpec tests"
task test: :spec

desc "Run linting (RuboCop) if available"
task :lint do
  if system("which rubocop > /dev/null 2>&1")
    sh "rubocop"
  else
    puts "RuboCop not installed. Install with: gem install rubocop"
  end
end

desc "Fix auto-correctable linting issues"
task "lint:fix" do
  if system("which rubocop > /dev/null 2>&1")
    sh "rubocop -A"
  else
    puts "RuboCop not installed. Install with: gem install rubocop"
  end
end

desc "Clean build artifacts"
task :clean do
  sh "rm -f *.gem"
  sh "rm -rf pkg/"
  sh "rm -rf tmp/"
  sh "find . -name '.worktrees' -type d -exec rm -rf {} + 2>/dev/null || true"
  puts "Build artifacts cleaned"
end

desc "Run comprehensive checks (test + lint)"
task ci: [:spec, :lint]

desc "Install the gem locally"
task :install_local do
  sh "gem build worktrees.gemspec"
  sh "gem install worktrees-*.gem"
end

desc "Uninstall the gem locally"
task :uninstall_local do
  sh "gem uninstall worktrees"
end