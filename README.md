# worktrees - Git Feature Worktree Manager

A Ruby command-line tool for managing Git feature worktrees with a structured naming convention and workflow optimizations.

## Features

- **Structured Naming**: Enforces `NNN-kebab-feature` naming convention (e.g., `001-new-feature`)
- **Global Root Management**: Centralized worktree storage in `~/.worktrees/`
- **Safety First**: Comprehensive safety checks for dirty state and worktree validation
- **Clean Architecture**: Ruby-based with proper error handling and testing
- **Multiple Output Formats**: Human-readable text, structured JSON, and CSV output
- **Complete Workflow**: Create, list, switch, remove, and status operations
- **Command Aliases**: Short aliases for all commands (e.g., `ls` for `list`)

## Installation

### From Source

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd claude-worktrees
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Install the gem:
   ```bash
   gem build worktrees.gemspec
   gem install worktrees-*.gem
   ```

### Development Setup

For development, you can run the CLI directly:
```bash
bundle exec exe/worktrees
```

## Quick Start

```bash
# Create a new feature worktree
worktrees create 001-new-feature
# or use alias
worktrees c 002-bug-fix

# List all worktrees
worktrees list
# or use aliases
worktrees ls
worktrees l

# Switch to a worktree
worktrees switch 001-new-feature
# or use aliases
worktrees sw 001-new-feature
worktrees s 001-new-feature

# Check current worktree status
worktrees status
# or use alias
worktrees st

# Remove a worktree (with safety checks)
worktrees remove 001-new-feature --delete-branch
# or use aliases
worktrees rm 002-bug-fix --force
worktrees r 003-old-feature
```

## Commands Reference

### Global Options

Available on all commands:
- `--verbose` - Enable verbose output
- `-h, --help` - Show help information
- `-v, --version` - Show version information

### `create` (alias: `c`) - Create New Worktree

Create a new feature worktree with structured naming.

```bash
worktrees create <NNN-kebab-feature> [base-ref] [OPTIONS]
```

**Arguments:**
- `<NNN-kebab-feature>` - Feature name (required, must follow naming convention)
- `[base-ref]` - Base branch/commit to create from (optional, defaults to repository default)

**Options:**
- `--worktrees-root <path>` - Override worktrees root directory (defaults to ~/.worktrees)
- `--force` - Create even if validation warnings exist
- `--switch` - Switch to new worktree after creation

**Examples:**
```bash
worktrees create 001-user-auth
worktrees c 002-api-refactor main
worktrees create 003-hotfix --switch
worktrees create 004-experiment --worktrees-root /tmp/worktrees
worktrees c 005-feature --force --switch
```

### `list` (aliases: `ls`, `l`) - List Worktrees

List existing worktrees with filtering and output format options.

```bash
worktrees list [OPTIONS]
```

**Options:**
- `--format <format>` - Output format: text, json, or csv (default: text)
- `--status-only` - Show only status information (shorter output)
- `--filter <status>` - Filter by status: clean, dirty, or active

**Examples:**
```bash
worktrees list
worktrees ls --format json
worktrees l --status-only
worktrees list --filter clean
worktrees ls --filter dirty --format csv
```

### `switch` (aliases: `sw`, `s`) - Switch Worktree

Switch to a different worktree with safety warnings.

```bash
worktrees switch <name>
```

**Arguments:**
- `<name>` - Name of worktree to switch to

**Features:**
- Allows switching even with dirty working directory (shows warning)
- Validates target worktree exists
- Changes to worktree directory automatically

**Examples:**
```bash
worktrees switch 001-feature
worktrees sw 002-bugfix
worktrees s 003-hotfix
```

### `remove` (aliases: `rm`, `r`) - Remove Worktree

Remove a worktree with comprehensive safety checks.

```bash
worktrees remove <name> [OPTIONS]
```

**Arguments:**
- `<name>` - Name of worktree to remove

**Options:**
- `--delete-branch` - Also delete the associated branch (only if fully merged)
- `--force-untracked` - Force removal even if untracked files exist
- `--merge-base <branch>` - Specify merge base for branch deletion safety check
- `--force` - Force removal despite safety warnings (dangerous)

**Safety Checks:**
- Prevents removal of worktrees with uncommitted changes
- Prevents removal of active worktrees
- Verifies branch is fully merged before deletion (when using --delete-branch)
- Checks for untracked files unless --force-untracked is used

**Examples:**
```bash
worktrees remove 001-feature
worktrees rm 002-bugfix --delete-branch
worktrees r 003-experiment --force-untracked
worktrees remove 004-old-feature --delete-branch --merge-base main
```

### `status` (alias: `st`) - Current Status

Show information about the current worktree.

```bash
worktrees status
```

**Output:**
- Current worktree name and status
- Repository information
- Configuration details

**Examples:**
```bash
worktrees status
worktrees st
```

## Feature Naming Convention

All feature names must follow the pattern: `NNN-kebab-feature`

**Rules:**
- Exactly 3 digits followed by a dash
- Feature name in lowercase
- Use dashes to separate words (kebab-case)
- Only alphanumeric characters and dashes allowed

**Valid Examples:**
- `001-user-authentication`
- `123-api-refactor`
- `999-hotfix-deployment`

**Invalid Examples:**
- `1-short` (need 3 digits)
- `001_underscore` (use dashes, not underscores)
- `001-UPPERCASE` (must be lowercase)
- `main` or `master` (reserved names)

## Output Formats

### Text Format (Default)
Human-readable output with status information:
```
* 001-feature   active   /Users/you/.worktrees/001-feature        (from main)
  002-bugfix    clean    /Users/you/.worktrees/002-bugfix         (from develop)
  003-hotfix    dirty    /Users/you/.worktrees/003-hotfix         (from main)
```

**Status-only mode:**
```
* 001-feature active
  002-bugfix clean
  003-hotfix dirty
```

### JSON Format
Structured output for scripts and automation:
```json
{
  "worktrees": [
    {
      "name": "001-feature",
      "branch": "001-feature",
      "base_ref": "main",
      "path": "/Users/you/.worktrees/001-feature",
      "status": "active",
      "created_at": "2025-09-15T10:30:00Z",
      "active": true
    },
    {
      "name": "002-bugfix",
      "branch": "002-bugfix",
      "base_ref": "develop",
      "path": "/Users/you/.worktrees/002-bugfix",
      "status": "clean",
      "created_at": "2025-09-14T15:22:00Z",
      "active": false
    }
  ]
}
```

### CSV Format
Comma-separated values for spreadsheet import:
```csv
name,status,path,branch,base_ref,active
001-feature,active,/Users/you/.worktrees/001-feature,001-feature,main,true
002-bugfix,clean,/Users/you/.worktrees/002-bugfix,002-bugfix,develop,false
003-hotfix,dirty,/Users/you/.worktrees/003-hotfix,003-hotfix,main,false
```

## Development

### Project Structure
```
lib/
├── worktrees/
│   ├── cli.rb           # Main CLI application
│   ├── commands/        # Individual command classes
│   │   ├── create.rb
│   │   ├── list.rb
│   │   ├── switch.rb
│   │   ├── remove.rb
│   │   └── status.rb
│   ├── models/          # Data models
│   │   ├── feature_worktree.rb
│   │   ├── repository.rb
│   │   └── worktree_config.rb
│   ├── git_operations.rb    # Git operations
│   └── worktree_manager.rb  # Business logic
exe/
└── worktrees            # CLI entry point
spec/
├── lib/                 # Unit tests (RSpec)
├── features/            # Integration tests (Aruba)
└── support/
    ├── aruba.rb         # Aruba configuration
    └── git_helpers.rb   # Test utilities
archive/                 # Archived bash implementation
├── bash-implementation/ # Original bash source
├── bash-tests/         # Original bash tests
└── README.md           # Archive documentation
```

### Testing

This project uses a comprehensive test suite with:
- **RSpec** for unit tests
- **Aruba** for CLI integration tests

Run the full test suite:
```bash
bundle exec rspec
```

Run specific test types:
```bash
bundle exec rspec spec/lib      # Unit tests
bundle exec rspec spec/features # Integration tests
```

Run specific test files:
```bash
bundle exec rspec spec/lib/worktrees/commands/create_spec.rb
bundle exec rspec spec/features/create_worktree_spec.rb
```

### Code Quality

The project follows Ruby best practices:
- Test-driven development (TDD)
- Clear error handling with structured exceptions
- Modular architecture with separation of concerns
- Comprehensive CLI testing with real git repositories
- No mocks in tests - real git operations for reliability

## Architecture

This tool implements a clean architecture with:

- **CLI Layer**: dry-cli for command parsing and routing
- **Business Logic**: WorktreeManager for core operations
- **Data Models**: Structured representations of worktrees and repositories
- **Git Operations**: Safe shell-out to git commands
- **Error Handling**: Structured exception hierarchy
- **Testing**: Real git repositories in tests (no mocks)

### Error Types
- `ValidationError` - Invalid input or parameters (exit code 2)
- `GitError` - Git command failures (exit code 3)
- `StateError` - Invalid worktree states (exit code 3)
- `NotFoundError` - Worktree not found
- `FileSystemError` - File system operation failures

### Exit Codes
- `0` - Success
- `1` - General error
- `2` - Validation error
- `3` - Git/State error
- `130` - Interrupted (Ctrl+C)

## Command Aliases

All commands support short aliases for faster typing:

| Command | Aliases | Example Usage |
|---------|---------|---------------|
| `create` | `c` | `worktrees c 001-feature` |
| `list` | `ls`, `l` | `worktrees ls --format json` |
| `switch` | `sw`, `s` | `worktrees sw 001-feature` |
| `remove` | `rm`, `r` | `worktrees rm 001-feature` |
| `status` | `st` | `worktrees st` |

## Configuration

The tool supports configuration through:
- Command-line options (highest priority)
- Environment variables
- Configuration files (future feature)

### Environment Variables
- `WORKTREES_ROOT` - Override default worktrees root directory

## Contributing

1. Follow Ruby community conventions
2. Write tests first (TDD approach)
3. Use the existing error handling patterns
4. Test with real git repositories
5. Ensure all tests pass before submitting changes
6. Update documentation for new features

## License

[Add appropriate license information]

---

*Previous bash implementation archived in `archive/` directory*