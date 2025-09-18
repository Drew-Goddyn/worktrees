# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2024-09-17

### Added
- Initial release of worktrees CLI tool
- Complete Git worktree management with structured naming convention
- Five core commands: `create`, `list`, `switch`, `remove`, `status`
- Command aliases for faster usage (`c`, `ls`/`l`, `sw`/`s`, `rm`/`r`, `st`)
- Enforced `NNN-kebab-feature` naming pattern with validation
- Multiple output formats: text (default), JSON, and CSV
- Comprehensive safety checks for dirty state and active worktrees
- Global worktree storage in `~/.worktrees/` directory
- Built with Ruby using dry-cli framework
- Comprehensive test suite with RSpec and Aruba
- Professional CLI with proper error handling and exit codes

### Features
- **create**: Create feature worktrees with optional base branch and automatic switching
- **list**: List all worktrees with filtering by status and multiple output formats
- **switch**: Safely switch between worktrees with dirty state warnings
- **remove**: Remove worktrees with safety checks and optional branch deletion
- **status**: Show current worktree information and repository details

### Technical
- Ruby 3.2+ required
- Uses dry-cli for command parsing and routing
- Real git repository integration (no mocks in tests)
- Structured exception hierarchy for clear error handling
- MIT licensed

[0.1.0]: https://github.com/Drew-Goddyn/claude-worktrees/releases/tag/v0.1.0