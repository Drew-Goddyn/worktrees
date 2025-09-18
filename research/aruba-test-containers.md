# Aruba and TestContainers Integration Guide

Testing sophisticated CLI applications requires robust frameworks that can handle complex scenarios involving file systems, git repositories, databases, and external services. This comprehensive guide demonstrates how to elegantly merge Aruba's CLI testing capabilities with TestContainers' containerization features for sophisticated Ruby CLI testing scenarios.

## Current Aruba syntax and API fundamentals

**Aruba provides a comprehensive API for CLI testing across multiple Ruby frameworks**. The current version (2.3+) supports Ruby 3.0+ and integrates seamlessly with RSpec, Cucumber, and Minitest. **The framework excels at file system manipulation, command execution, and environment management** - critical capabilities for testing modern CLI applications.

### Core API methods and patterns

```ruby
# File system operations
write_file('config.yml', <<~YAML)
  database:
    host: localhost
    port: 5432
YAML

create_directory('tmp/output')
append_to_file('log.txt', 'new entry')
chmod(0o755, 'script.sh')

# Command execution with comprehensive output handling
run_command('my-cli-tool --config config.yml')
run_command_and_stop('echo "Hello World"')

# Access execution results
last_command_started.output      # Combined stdout/stderr
last_command_started.stdout      # Standard output only
last_command_started.stderr      # Standard error only  
last_command_started.exit_status # Exit code

# Environment management
set_environment_variable('DATABASE_URL', 'postgres://localhost/test')
with_environment('PATH' => '/custom/path') do
  run_command('my-tool')
end
```

### RSpec integration patterns

```ruby
# spec/cli_integration_spec.rb
require 'aruba/rspec'

RSpec.describe 'Database CLI Tool', type: :aruba do
  let(:command) { 'db-tool' }
  
  before do
    write_file('.config', <<~CONFIG)
      host: #{container_host}
      port: #{container_port}
      database: test_db
    CONFIG
  end

  it 'migrates database schema' do
    run_command("#{command} migrate")
    
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_output(include('Migration complete'))
    expect(file('.migrations/001_initial.sql')).to be_an_existing_file
  end

  # Interactive command testing
  it 'handles interactive setup' do
    run_command("#{command} setup")
    
    expect(last_command_started).to have_output(include('Database name:'))
    type('test_application')
    
    expect(last_command_started).to have_output(include('Username:'))
    type('admin')
    
    expect(last_command_started).to be_successfully_executed
  end
end
```

## TestContainers Ruby API and lifecycle management

**TestContainers Ruby provides lightweight, disposable container instances for integration testing**. While less mature than Java implementations, it offers essential container management capabilities with automatic port mapping and lifecycle management.

### Container lifecycle and configuration

```ruby
require 'testcontainers'

# Basic container setup
postgres_container = Testcontainers::DockerContainer
  .new('postgres:13')
  .with_exposed_port(5432)
  .with_env('POSTGRES_PASSWORD', 'testpass')
  .with_env('POSTGRES_DB', 'testdb')

postgres_container.start

# Access container connection details
host = postgres_container.host
port = postgres_container.mapped_port(5432)
database_url = "postgres://postgres:testpass@#{host}:#{port}/testdb"

# Cleanup
postgres_container.stop
postgres_container.delete
```

### Specialized container modules

```ruby
# Database containers with simplified setup
postgres = Testcontainers::PostgresContainer.new
postgres.start
connection_string = postgres.database_url

# Message queue containers
redis = Testcontainers::DockerContainer
  .new('redis:6.2-alpine')
  .with_exposed_port(6379)
redis.start
redis_url = "redis://#{redis.host}:#{redis.mapped_port(6379)}"

# Web service containers
nginx = Testcontainers::DockerContainer
  .new('nginx:latest')
  .with_exposed_port(80)
nginx.start
service_url = "http://#{nginx.host}:#{nginx.mapped_port(80)}"
```

## Integration architecture patterns

**The most effective approach combines TestContainers as the infrastructure layer with Aruba as the CLI testing interface**. This separation of concerns allows TestContainers to manage external dependencies while Aruba focuses on command-line interaction testing.

### Container-first setup strategy

```ruby
# spec/support/container_environment.rb
require 'testcontainers'

module ContainerEnvironment
  extend RSpec::SharedContext
  
  before(:suite) do
    # Start infrastructure containers
    @postgres = Testcontainers::PostgresContainer.new
    @postgres.start
    
    @redis = Testcontainers::DockerContainer
      .new('redis:6.2-alpine')
      .with_exposed_port(6379)
    @redis.start
    
    # Make connection details available to CLI
    ENV['DATABASE_URL'] = @postgres.database_url
    ENV['REDIS_URL'] = "redis://#{@redis.host}:#{@redis.mapped_port(6379)}"
  end
  
  after(:suite) do
    @postgres&.stop
    @redis&.stop
  end
end

# spec/spec_helper.rb
RSpec.configure do |config|
  config.include_context ContainerEnvironment
end
```

### Environment bridging pattern

```ruby
# lib/testing/environment_bridge.rb
class EnvironmentBridge
  def self.setup_for_containers(containers)
    containers.each do |name, container|
      ENV["#{name.upcase}_HOST"] = container.host
      ENV["#{name.upcase}_PORT"] = container.mapped_port.to_s
      
      case name
      when :postgres
        ENV['DATABASE_URL'] = container.database_url
      when :redis  
        ENV['REDIS_URL'] = "redis://#{container.host}:#{container.mapped_port(6379)}"
      end
    end
  end
  
  def self.generate_cli_config(containers)
    config = {
      database: {
        host: containers[:postgres].host,
        port: containers[:postgres].mapped_port(5432),
        name: 'testdb'
      },
      cache: {
        url: "redis://#{containers[:redis].host}:#{containers[:redis].mapped_port(6379)}"
      }
    }
    
    File.write('tmp/test-config.yml', config.to_yaml)
    ENV['CONFIG_PATH'] = File.expand_path('tmp/test-config.yml')
  end
end
```

## Git repository manipulation testing

**Testing CLI tools that manipulate git repositories requires containerized git servers and careful repository state management**. The GitSweeper case study demonstrates sophisticated git testing patterns using Aruba with Docker integration.

### Containerized git server setup

```ruby
# features/support/git_server.rb
require 'docker'

module GitServerHelpers
  def setup_git_server(container_name, port)
    cleanup_existing_container(container_name)
    
    container = Docker::Container.create(
      'Image' => 'petems/dummy-git-repo',
      'ExposedPorts' => { "80/tcp" => {} },
      'HostConfig' => {
        'PortBindings' => { "80/tcp" => [{ "HostPort" => port }] }
      },
      'name' => container_name
    )
    
    container.start
    sleep 3 # Allow container to initialize
    container
  end
  
  private
  
  def cleanup_existing_container(name)
    container = Docker::Container.get(name)
    container.delete(force: true)
  rescue Docker::Error::NotFoundError
    # Container doesn't exist, which is fine
  end
end

# Cucumber step definitions
Given /^I have a git server running called "(\w+)" on port "(\w+)"$/ do |name, port|
  @git_container = setup_git_server(name, port)
end

Given /^I clone "([^"]*)" repository$/ do |repo_url|
  run_command("git clone #{repo_url}")
  expect(last_command_started).to be_successfully_executed
end

After do
  @git_container&.delete(force: true)
end
```

### Git workflow testing patterns

```ruby
# spec/git_cli_integration_spec.rb
RSpec.describe 'Git Repository CLI', type: :aruba do
  let(:git_server_port) { '8008' }
  let(:repo_url) { "http://localhost:#{git_server_port}/test-repo.git" }
  
  before do
    @git_container = setup_git_server('test-git-server', git_server_port)
    
    # Clone and setup repository
    run_command("git clone #{repo_url}")
    cd('test-repo')
    
    # Configure git identity for testing
    run_command('git config user.email "test@example.com"')
    run_command('git config user.name "Test User"')
  end
  
  after do
    @git_container&.delete(force: true)
  end
  
  it 'creates and pushes feature branches' do
    # Create feature branch
    run_command('git checkout -b feature/new-functionality')
    expect(last_command_started).to be_successfully_executed
    
    # Make changes
    write_file('feature.txt', 'New feature implementation')
    run_command('git add feature.txt')
    run_command('git commit -m "Add new feature"')
    
    # Test CLI tool that manipulates branches
    run_command('branch-manager push-feature')
    expect(last_command_started).to have_output(include('Feature branch pushed'))
    expect(last_command_started).to be_successfully_executed
  end
  
  it 'cleans up merged branches' do
    # Setup multiple branches via CLI
    run_command('branch-manager create-demo-branches')
    
    # Simulate merge process
    run_command('git checkout main')
    run_command('git merge feature/demo-1')
    run_command('git merge feature/demo-2')
    
    # Test cleanup command
    run_command('branch-manager cleanup --dry-run')
    expect(last_command_started).to have_output(/Found 2 merged branches/)
    
    run_command('branch-manager cleanup --force')
    expect(last_command_started).to have_output(include('Deleted 2 branches'))
    expect(last_command_started).to be_successfully_executed
  end
end
```

## File system testing with external services

**Complex CLI applications often manipulate file systems while interacting with external services**. This requires coordinated testing that validates both file operations and service interactions.

### File system testing with service dependencies

```ruby
# spec/file_processor_integration_spec.rb
RSpec.describe 'File Processing CLI', type: :aruba do
  let(:minio_container) do
    Testcontainers::DockerContainer
      .new('minio/minio:latest')
      .with_exposed_port(9000)
      .with_env('MINIO_ROOT_USER', 'testuser')
      .with_env('MINIO_ROOT_PASSWORD', 'testpass123')
  end
  
  before(:all) do
    @minio = minio_container
    @minio.start
    
    # Configure CLI to use test S3 endpoint
    ENV['S3_ENDPOINT'] = "http://#{@minio.host}:#{@minio.mapped_port(9000)}"
    ENV['S3_ACCESS_KEY'] = 'testuser'
    ENV['S3_SECRET_KEY'] = 'testpass123'
  end
  
  after(:all) do
    @minio&.stop
  end
  
  it 'processes files and uploads to S3' do
    # Create test files
    create_directory('input')
    write_file('input/data.csv', <<~CSV)
      name,email,age
      John Doe,john@example.com,30
      Jane Smith,jane@example.com,25
    CSV
    
    write_file('input/config.json', <<~JSON)
      {
        "output_format": "parquet",
        "compression": "snappy"
      }
    JSON
    
    # Process files with CLI
    run_command('file-processor convert --input input/ --output s3://test-bucket/')
    
    expect(last_command_started).to be_successfully_executed
    expect(last_command_started).to have_output(include('Processed 1 files'))
    expect(last_command_started).to have_output(include('Uploaded to s3://test-bucket/'))
    
    # Verify local processing artifacts
    expect(file('tmp/processing.log')).to be_an_existing_file
    expect(file('tmp/processing.log')).to have_file_content(include('Conversion complete'))
  end
  
  it 'handles file system errors gracefully' do
    # Test with read-only directory
    create_directory('readonly')
    chmod(0o444, 'readonly')
    
    run_command('file-processor convert --input readonly/ --output s3://test-bucket/')
    
    expect(last_command_started).to have_exit_status(1)
    expect(last_command_started).to have_output_on_stderr(include('Permission denied'))
  end
end
```

### Advanced file system manipulation patterns

```ruby
# Testing CLI tools that manage complex directory structures
RSpec.describe 'Project Generator CLI', type: :aruba do
  it 'scaffolds complete project structure' do
    run_command('project-gen new my-app --template=microservice')
    
    expect(last_command_started).to be_successfully_executed
    
    # Verify project structure
    expect(directory('my-app')).to be_an_existing_directory
    expect(file('my-app/Dockerfile')).to be_an_existing_file
    expect(file('my-app/docker-compose.yml')).to be_an_existing_file
    expect(file('my-app/src/main.py')).to be_an_existing_file
    expect(directory('my-app/tests')).to be_an_existing_directory
    
    # Verify configuration content
    expect(file('my-app/docker-compose.yml')).to have_file_content(include('postgres:13'))
    expect(file('my-app/.env.example')).to have_file_content(/DATABASE_URL=/)
  end
  
  it 'handles template customization' do
    # Create custom template
    create_directory('templates/custom')
    write_file('templates/custom/app.py.erb', <<~PYTHON)
      # Generated application: <%= app_name %>
      import os
      
      def main():
          print("Hello from <%= app_name %>!")
      
      if __name__ == "__main__":
          main()
    PYTHON
    
    run_command('project-gen new custom-app --template=templates/custom --app-name="My Custom App"')
    
    expect(last_command_started).to be_successfully_executed
    expect(file('custom-app/app.py')).to have_file_content(include('Hello from My Custom App!'))
  end
end
```

## Error handling and debugging strategies

**Sophisticated CLI testing requires robust error handling and debugging capabilities**. This involves container lifecycle management, test environment debugging, and graceful failure handling.

### Container lifecycle error handling

```ruby
# lib/testing/container_manager.rb
class ContainerManager
  class ContainerError < StandardError; end
  
  def self.with_containers(containers, &block)
    started_containers = []
    
    begin
      containers.each do |name, container_config|
        container = create_container(container_config)
        container.start
        started_containers << [name, container]
        
        wait_for_readiness(container, container_config[:readiness_check])
      end
      
      # Make containers available in test context
      container_map = started_containers.to_h
      yield(container_map)
      
    rescue => e
      # Log container states for debugging
      started_containers.each do |name, container|
        puts "Container #{name} (#{container.id[0..12]}) logs:"
        puts container.logs.split("\n").last(20).join("\n")
      end
      
      raise ContainerError, "Container setup failed: #{e.message}"
      
    ensure
      # Always cleanup containers
      started_containers.each do |_, container|
        container.delete(force: true)
      rescue => cleanup_error
        puts "Warning: Failed to cleanup container: #{cleanup_error.message}"
      end
    end
  end
  
  private
  
  def self.wait_for_readiness(container, check)
    return unless check
    
    timeout = 30
    start_time = Time.now
    
    loop do
      if Time.now - start_time > timeout
        raise ContainerError, "Container readiness timeout after #{timeout}s"
      end
      
      case check[:type]
      when :port
        break if port_open?(container.host, container.mapped_port(check[:port]))
      when :log
        break if container.logs.include?(check[:message])
      when :http
        break if http_ready?("#{container.host}:#{container.mapped_port(check[:port])}")
      end
      
      sleep 0.5
    end
  end
end
```

### Advanced debugging techniques

```ruby
# spec/support/debugging_helpers.rb
module DebuggingHelpers
  def debug_cli_environment
    puts "\n=== CLI Environment Debug ==="
    puts "Working Directory: #{aruba.current_directory}"
    puts "Environment Variables:"
    ENV.each { |k, v| puts "  #{k}=#{v}" if k.match(/_(URL|HOST|PORT)$/) }
    
    puts "\nContainer Status:"
    Docker::Container.all.each do |container|
      puts "  #{container.info['Names'].first}: #{container.info['State']}"
    end
    
    puts "\nFile System:"
    Dir.glob('**/*').each { |file| puts "  #{file}" }
    puts "========================\n"
  end
  
  def capture_failure_artifacts
    return unless last_command_started&.exit_status != 0
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    failure_dir = "tmp/failures/#{timestamp}"
    FileUtils.mkdir_p(failure_dir)
    
    # Save command output
    File.write("#{failure_dir}/stdout.txt", last_command_started.stdout)
    File.write("#{failure_dir}/stderr.txt", last_command_started.stderr)
    File.write("#{failure_dir}/exit_status.txt", last_command_started.exit_status.to_s)
    
    # Save environment state
    File.write("#{failure_dir}/environment.txt", ENV.to_h.inspect)
    
    # Save file system state
    Dir.glob('**/*').each do |file|
      next unless File.file?(file)
      FileUtils.cp(file, "#{failure_dir}/#{File.basename(file)}")
    end
    
    puts "Failure artifacts saved to: #{failure_dir}"
  end
end

RSpec.configure do |config|
  config.include DebuggingHelpers
  
  config.after(:each) do |example|
    if example.exception
      debug_cli_environment if ENV['DEBUG']
      capture_failure_artifacts
    end
  end
end
```

## Performance optimization techniques

**High-performance CLI testing requires strategic optimization approaches**. The most significant performance gains come from in-process testing, shared container management, and selective test execution.

### In-process testing for Ruby CLIs

```ruby
# lib/cli/launcher.rb
module CLI
  class Launcher
    attr_accessor :argv, :stdin, :stdout, :stderr, :kernel
    
    def initialize(argv, stdin = STDIN, stdout = STDOUT, stderr = STDERR, kernel = Kernel)
      self.argv = argv
      self.stdin = stdin
      self.stdout = stdout
      self.stderr = stderr
      self.kernel = kernel
    end
    
    def execute!
      begin
        # Parse commands and execute business logic
        result = process_command(argv)
        stdout.puts result[:output] if result[:output]
        stderr.puts result[:error] if result[:error]
        
        exit_code = result[:exit_code] || 0
        
      rescue StandardError => e
        stderr.puts "Error: #{e.message}"
        exit_code = 1
      ensure
        # Never call exit() directly - use kernel.exit for testability
        kernel.exit(exit_code)
      end
    end
    
    private
    
    def process_command(args)
      # CLI business logic implementation
      { output: "Command executed successfully", exit_code: 0 }
    end
  end
end

# spec/cli_spec.rb
RSpec.describe 'CLI Performance', type: :aruba do
  before do
    # Configure Aruba for in-process testing
    aruba.config.command_launcher = :in_process
    aruba.config.main_class = CLI::Launcher
  end
  
  it 'executes commands quickly in-process' do
    start_time = Time.now
    
    run_command('process-data --input data.csv --output results.json')
    
    execution_time = Time.now - start_time
    expect(execution_time).to be < 0.1  # Sub-100ms execution
    expect(last_command_started).to be_successfully_executed
  end
end
```

### Shared container management

```ruby
# spec/support/shared_containers.rb
class SharedContainerSuite
  @containers = {}
  @mutex = Mutex.new
  
  def self.get_container(type, config = {})
    @mutex.synchronize do
      @containers[type] ||= create_and_start_container(type, config)
    end
  end
  
  def self.cleanup_all
    @mutex.synchronize do
      @containers.each_value(&:delete)
      @containers.clear
    end
  end
  
  private
  
  def self.create_and_start_container(type, config)
    container = case type
    when :postgres
      Testcontainers::PostgresContainer.new
    when :redis
      Testcontainers::DockerContainer.new('redis:6.2-alpine').with_exposed_port(6379)
    when :elasticsearch
      Testcontainers::DockerContainer
        .new('elasticsearch:7.17.0')
        .with_exposed_port(9200)
        .with_env('discovery.type', 'single-node')
    end
    
    container.start
    container
  end
end

RSpec.configure do |config|
  config.after(:suite) do
    SharedContainerSuite.cleanup_all
  end
end
```

### Parallel testing coordination

```ruby
# spec/support/parallel_containers.rb
class ParallelTestCoordinator
  def self.setup_parallel_databases
    return unless ENV['TEST_ENV_NUMBER']
    
    worker_number = ENV['TEST_ENV_NUMBER']
    container_name = "postgres_test_#{worker_number}"
    
    @postgres = Testcontainers::PostgresContainer
      .new("postgres:13")
      .with_name(container_name)
    @postgres.start
    
    ENV['DATABASE_URL'] = @postgres.database_url
  end
  
  def self.cleanup_parallel_databases
    @postgres&.delete
  end
end

# Configure per-worker container setup
RSpec.configure do |config|
  config.before(:suite) do
    ParallelTestCoordinator.setup_parallel_databases
  end
  
  config.after(:suite) do
    ParallelTestCoordinator.cleanup_parallel_databases
  end
end
```

## Architectural guidance and best practices

**Successful CLI testing architectures follow clear separation of concerns, robust environment management, and comprehensive error handling**. These patterns enable maintainable, scalable, and reliable test suites for complex CLI applications.

### Testing architecture layers

```ruby
# 1. Infrastructure Layer (TestContainers)
class InfrastructureLayer
  def self.setup_test_environment
    {
      database: Testcontainers::PostgresContainer.new,
      cache: redis_container,
      message_queue: rabbitmq_container,
      object_storage: minio_container
    }
  end
end

# 2. CLI Interface Layer (Aruba)
class CLITestLayer
  include Aruba::Api
  
  def setup_cli_environment(infrastructure)
    bridge_infrastructure_to_cli(infrastructure)
    setup_aruba
    configure_cli_defaults
  end
end

# 3. Business Logic Verification Layer
class BusinessLogicVerification
  def verify_workflow_completion(expected_outcomes)
    expected_outcomes.each do |outcome|
      verify_outcome(outcome)
    end
  end
end
```

### Configuration management patterns

```ruby
# config/test_environment.rb
class TestEnvironment
  def self.configure
    # Container configuration
    configure_containers
    
    # CLI application configuration
    configure_cli_application
    
    # Test framework configuration
    configure_test_frameworks
  end
  
  private
  
  def self.configure_containers
    Testcontainers.configure do |config|
      config.ryuk_disabled = ENV['CI'] == 'true'  # Disable cleanup in CI
      config.container_default_wait_time = 30
    end
  end
  
  def self.configure_cli_application
    ENV['CLI_CONFIG_PATH'] = generate_test_config_path
    ENV['CLI_LOG_LEVEL'] = 'debug'
    ENV['CLI_ENVIRONMENT'] = 'test'
  end
  
  def self.configure_test_frameworks
    Aruba.configure do |config|
      config.exit_timeout = 30
      config.io_wait_timeout = 5
      config.working_directory = 'tmp/aruba'
      config.home_directory = File.expand_path('tmp/home')
    end
  end
end
```

### Error resilience patterns

```ruby
# lib/testing/resilient_testing.rb
module ResilientTesting
  def with_retry(attempts: 3, delay: 1, exceptions: [StandardError])
    attempt = 1
    
    begin
      yield
    rescue *exceptions => e
      if attempt < attempts
        sleep delay
        attempt += 1
        retry
      else
        raise e
      end
    end
  end
  
  def with_container_health_check(container, &block)
    ensure_container_healthy(container)
    yield
  rescue => e
    # Re-check container health on failure
    unless container_healthy?(container)
      container.restart
      ensure_container_healthy(container)
      retry
    end
    raise e
  end
  
  private
  
  def ensure_container_healthy(container)
    timeout = 30
    start_time = Time.now
    
    until container_healthy?(container)
      if Time.now - start_time > timeout
        raise "Container failed health check after #{timeout}s"
      end
      sleep 1
    end
  end
  
  def container_healthy?(container)
    # Implementation depends on container type
    container.logs.include?('ready to accept connections')
  end
end
```

This comprehensive integration approach provides a robust foundation for testing sophisticated CLI applications. **The key to success lies in treating TestContainers as your infrastructure management layer and Aruba as your CLI interaction testing interface**, with careful attention to environment bridging, error handling, and performance optimization. This architecture scales effectively from simple command testing to complex multi-service integration scenarios while maintaining test reliability and developer productivity.