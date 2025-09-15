# worktrees - Git Feature Worktree Manager

A command-line tool for managing Git feature worktrees with a structured naming convention and workflow optimizations.

## Features

- **Structured Naming**: Enforces `NNN-kebab-feature` naming convention (e.g., `001-new-feature`)
- **Global Root Management**: Centralized worktree storage with configurable location
- **Safety First**: Comprehensive safety checks for dirty state, unpushed commits, and merge verification
- **Performance Optimized**: Caching, pagination, and `--no-status` flag for large repositories
- **Dual Output Formats**: Human-readable text and structured JSON output
- **Complete Workflow**: Create, list, switch, remove, and status operations

## Quick Start

```bash
# Create a new feature worktree
worktrees create 001-new-feature

# List all worktrees
worktrees list

# Switch to a worktree
worktrees switch 001-new-feature

# Check current worktree status
worktrees status

# Remove a worktree (with safety checks)
worktrees remove 001-new-feature
```

## Installation

1. Clone this repository
2. Add the `src/cli` directory to your PATH, or create a symlink:
   ```bash
   ln -s /path/to/claude-worktrees/src/cli/worktrees /usr/local/bin/worktrees
   ```

## Commands Reference

### `create` - Create New Worktree

Create a new feature worktree with structured naming.

```bash
worktrees create <NNN-kebab-feature> [OPTIONS]
```

**Options:**
- `--base <branch>` - Base branch/commit to create from [default: auto-detect]
- `--root <path>` - Root directory for worktrees [default: ~/.worktrees]
- `--reuse-branch` - Reuse existing branch if it exists
- `--sibling` - Create as sibling to current worktree
- `--format <format>` - Output format (text|json) [default: text]

**Examples:**
```bash
worktrees create 001-user-auth
worktrees create 002-api-refactor --base develop
worktrees create 003-hotfix --root /tmp/worktrees
```

### `list` - List Worktrees

List existing worktrees with filtering and pagination.

```bash
worktrees list [OPTIONS]
```

**Options:**
- `--filter-name <pattern>` - Filter worktrees by name pattern
- `--filter-base <branch>` - Filter by base branch
- `--page <number>` - Page number for pagination [default: 1]
- `--page-size <size>` - Items per page [default: 20, max: 100]
- `--no-status` - Skip expensive status checks (faster for large repos)
- `--root <path>` - Root directory for worktrees [default: ~/.worktrees]
- `--format <format>` - Output format (text|json) [default: text]

**Examples:**
```bash
worktrees list
worktrees list --filter-name "001-*"
worktrees list --format json --no-status
worktrees list --filter-base main --page-size 50
```

### `switch` - Switch Worktree

Switch to a different worktree with safety warnings.

```bash
worktrees switch <name>
```

**Features:**
- Allows switching even with dirty working directory (shows warning)
- Validates target worktree exists
- Changes to worktree directory automatically

### `remove` - Remove Worktree

Remove a worktree with comprehensive safety checks.

```bash
worktrees remove <name> [OPTIONS]
```

**Options:**
- `--delete-branch` - Also delete the associated branch
- `--merged-into <branch>` - Only delete branch if merged into specified branch
- `--force` - Force removal despite some safety warnings

**Safety Checks:**
- Prevents removal of worktrees with uncommitted changes
- Prevents removal if operations are in progress
- Checks for unpushed commits unless forced
- Verifies branch is merged before deletion

### `status` - Current Status

Show information about the current worktree.

```bash
worktrees status
```

**Output:**
- Current worktree name
- Base branch
- Worktree path

## Configuration

### Environment Variables

- `WORKTREES_ROOT` - Default root directory for all worktrees
- Defaults to `$HOME/.worktrees` if not set

### Global Options

Available on all commands:
- `--format text|json` - Output format
- `--help, -h` - Show help
- `--version, -v` - Show version

## Feature Naming Convention

All feature names must follow the pattern: `NNN-kebab-feature`

**Rules:**
- Exactly 3 digits followed by a dash
- Feature name in lowercase
- Use dashes to separate words (kebab-case)
- Maximum 40 characters for the feature part
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

## Performance Optimization

For repositories with many worktrees (>100), use these optimization strategies:

### Fast Listing
```bash
# Skip expensive git status checks
worktrees list --no-status

# Use filters to narrow results
worktrees list --filter-name "001-*"
worktrees list --filter-base main
```

### JSON Output Comparison
```bash
# Full status (slower, more information)
worktrees list --format json
# Output: {"name", "branch", "baseRef", "path", "active", "isDirty", "hasUnpushedCommits"}

# Fast mode (faster, basic information)
worktrees list --format json --no-status
# Output: {"name", "branch", "baseRef", "path"}
```

## Output Formats

### Text Format (Default)
Human-readable table format with status indicators:
```
NAME                 BRANCH               STATUS          PATH
----                 ------               ------          ----
001-feature          001-feature          active,clean    /Users/you/.worktrees/001-feature
002-bugfix           002-bugfix           clean           /Users/you/.worktrees/002-bugfix
```

### JSON Format
Structured output for scripts and automation:
```json
{
  "items": [
    {
      "name": "001-feature",
      "branch": "001-feature",
      "baseRef": "main",
      "path": "/Users/you/.worktrees/001-feature",
      "active": true,
      "isDirty": false,
      "hasUnpushedCommits": false
    }
  ],
  "page": 1,
  "pageSize": 20,
  "total": 1
}
```

## Development

### Project Structure
```
src/
├── cli/           # Command-line interface
├── lib/           # Shared utilities (JSON, IO)
├── models/        # Data models and validation
└── services/      # Business logic (currently CLI-integrated)

tests/
├── contract/      # API contract tests
├── integration/   # End-to-end workflow tests
└── unit/          # Unit tests for individual components

scripts/           # Development scripts
├── test.sh        # Run all tests
├── lint.sh        # Code linting
└── format.sh      # Code formatting
```

### Testing

Run the full test suite:
```bash
make test
# or
./scripts/test.sh
```

Individual test suites:
```bash
bats tests/contract/    # Contract tests
bats tests/integration/ # Integration tests
bats tests/unit/        # Unit tests
```

### Code Quality

```bash
make lint      # Run ShellCheck linting
make fmt       # Format code with shfmt
```

## Architecture

This tool implements a Test-Driven Development approach with:
- **Contract Tests**: Validate CLI interface and command shapes
- **Integration Tests**: Test complete user workflows
- **Unit Tests**: Test individual components and edge cases
- **Performance Guards**: Warnings and optimizations for large repositories
- **Safety First**: Comprehensive validation and confirmation prompts

## Contributing

1. Follow the existing code style and conventions
2. Add tests for new features
3. Ensure all tests pass before submitting changes
4. Use the established naming patterns for consistency

## License

[Add appropriate license information]