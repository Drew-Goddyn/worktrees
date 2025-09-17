# worktrees

[![Gem Version](https://badge.fury.io/rb/worktrees.svg)](https://badge.fury.io/rb/worktrees)
[![Ruby](https://img.shields.io/badge/ruby-3.2%2B-ruby.svg)](https://www.ruby-lang.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Clean Git worktree management with enforced naming conventions and safety checks

## Table of Contents

- [Why worktrees?](#why-worktrees)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Commands](#commands)
- [Naming Convention](#naming-convention)
- [Output Formats](#output-formats)
- [Development](#development)
- [Contributing](#contributing)
- [License](#license)

## Why worktrees?

- **Never lose work** switching between features
- **Isolate experiments** without affecting main codebase
- **Maintain clean history** with structured branch names
- **Work on multiple features** simultaneously without stashing

## Installation

### From RubyGems (when published)
```bash
gem install worktrees
```

### From Source
```bash
git clone https://github.com/Drew-Goddyn/claude-worktrees.git
cd claude-worktrees
bundle install
rake install_local
```

### Development Setup
```bash
bundle exec exe/worktrees --help
```

## Quick Start

```bash
# Create a feature worktree
worktrees create 001-user-auth

# List all worktrees
worktrees list

# Switch to a worktree
worktrees switch 001-user-auth

# Check status
worktrees status

# Remove when done
worktrees remove 001-user-auth --delete-branch
```

## Commands

| Command | Aliases | Description | Example |
|---------|---------|-------------|---------|
| `create` | `c` | Create new feature worktree | `worktrees c 001-feature main` |
| `list` | `ls`, `l` | List all worktrees | `worktrees ls --format json` |
| `switch` | `sw`, `s` | Switch to worktree | `worktrees sw 001-feature` |
| `remove` | `rm`, `r` | Remove worktree safely | `worktrees rm 001-feature --delete-branch` |
| `status` | `st` | Show current worktree | `worktrees st` |

### Key Options

- `--format json|csv|text` - Output format (list command)
- `--filter clean|dirty|active` - Filter by status (list command)
- `--delete-branch` - Also delete Git branch (remove command)
- `--force` - Override safety checks
- `--switch` - Switch after creating (create command)

## Naming Convention

Feature names must follow: `NNN-kebab-feature`

✅ **Valid**: `001-user-auth`, `123-api-refactor`, `999-hotfix`
❌ **Invalid**: `1-short`, `001_underscore`, `UPPERCASE`, `main`

## Output Formats

### Text (default)
```
* 001-feature   active   ~/.worktrees/001-feature   (from main)
  002-bugfix    clean    ~/.worktrees/002-bugfix    (from develop)
```

### JSON
```json
{
  "worktrees": [
    {
      "name": "001-feature",
      "status": "active",
      "path": "~/.worktrees/001-feature",
      "base_ref": "main"
    }
  ]
}
```

### CSV
```csv
name,status,path,branch,base_ref,active
001-feature,active,~/.worktrees/001-feature,001-feature,main,true
```

## Development

### Run Tests
```bash
bundle exec rake spec        # All tests
bundle exec rake spec:unit   # Unit tests only
bundle exec rake spec:integration # Integration tests
```

### Project Structure
```
lib/worktrees/           # Ruby source code
├── commands/            # CLI command classes
├── models/              # Data models
└── git_operations.rb    # Git interface

exe/worktrees            # CLI entry point
spec/                    # RSpec test suite
```

### Architecture

- **CLI Layer**: [dry-cli](https://dry-rb.org/gems/dry-cli/) for command parsing
- **Business Logic**: WorktreeManager coordinates operations
- **Git Operations**: Safe shell-out to git commands
- **Testing**: RSpec + [Aruba](https://github.com/cucumber/aruba) with real repositories

## Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b my-feature`
3. Write tests: `bundle exec rake spec`
4. Make changes and ensure tests pass
5. Submit pull request

Follow Ruby community conventions and write tests for new features.

## License

[MIT License](https://opensource.org/licenses/MIT)

---

Built with Ruby 💎