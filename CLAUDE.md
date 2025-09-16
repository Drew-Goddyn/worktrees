# Claude Code Development Guidelines - Worktrees Project

This project follows the constitutional principles defined in `.specify/memory/constitution.md` for Ruby CLI development.

## Technology Stack (Per Constitution v1.0.0)

### Core Technologies
- **Language**: Ruby 3.2+
- **CLI Framework**: dry-cli (minimal, well-tested, consistent)
- **Testing**: RSpec for unit tests, Aruba for CLI integration tests
- **Dependencies**: Bundler for management, minimal external gems
- **Structure**: `lib/` for logic, `exe/` for CLI entry point

### Project Structure
```
lib/
├── worktrees/
│   ├── cli.rb           # Main CLI application
│   ├── commands/        # Individual command classes
│   │   ├── create.rb
│   │   ├── list.rb
│   │   └── remove.rb
│   └── git_operations.rb # Business logic modules
exe/
└── worktrees            # CLI entry point
spec/
├── lib/                 # Unit tests
├── features/            # Aruba integration tests
└── support/
    └── aruba.rb         # Aruba configuration
```

## Constitutional Compliance

### Article I: Technology Appropriateness ✅
- Using Ruby for multi-command CLI (appropriate complexity)
- Using dry-cli framework (proven pattern)
- No service layers (unnecessary abstraction avoided)

### Article II: Library-First Architecture ✅
- Core logic in `lib/worktrees/` modules
- CLI layer only handles argument parsing and output
- Clear separation between presentation and business logic

### Article III: Test-First Development (NON-NEGOTIABLE) ✅
- RSpec for unit tests of business logic
- Aruba for CLI integration tests with real git repositories
- TDD: Write failing tests first, then implement
- No mock-heavy tests - use real git operations

### Article IV: Simplicity and Maintainability ✅
- Maximum 2 layers: commands + business logic
- No design patterns without demonstrated need
- YAGNI principle applied throughout

## Anti-Patterns to Avoid

❌ **Service layers in CLI tools** - Use simple modules and functions instead
❌ **Auto-initialization on require** - Explicit initialization only
❌ **Mock-heavy tests** - Use real git repositories and operations
❌ **Deep inheritance hierarchies** - Prefer composition
❌ **Global state mutations** - Pass data explicitly between functions

## Development Workflow

### Planning Phase
1. Constitution defines technology choices (Ruby + dry-cli)
2. `/plan` command reads constitution and generates appropriate architecture
3. `/tasks` command generates Ruby-specific implementation tasks

### Implementation Phase
1. **RED**: Write failing test (RSpec unit test or Aruba feature test)
2. **GREEN**: Write minimal code to make test pass
3. **REFACTOR**: Improve code while keeping tests green
4. Commit only when tests are passing

### Testing Approach
- **Unit tests**: Test business logic modules in isolation
- **Integration tests**: Use Aruba to test CLI commands end-to-end
- **Real dependencies**: Create actual git repositories for testing
- **No mocks**: Test against real git operations

## Code Quality Guidelines

### Error Handling
- Structured logging to stderr only
- Clear error messages with actionable next steps
- Consistent exit codes (0=success, 1=general, 2=validation, 3=precondition)

### User Experience
- `--help` and `--version` on all commands
- `--format json/text` for output control
- Predictable command structure (verb-noun pattern)
- Verbose mode (`-v, --verbose`) for debugging

### Code Style
- Follow Ruby community conventions
- Prefer explicit over clever
- No premature optimization
- Refactor only when tests are green

## Implementation Notes

### Bash Lessons Learned
This project originally attempted implementation in bash but discovered:
- Service layers caused architecture mismatch in bash
- Auto-initialization on `source` created side effects
- Mock vs real testing confusion
- Global state management problems

These issues are avoided in Ruby through:
- Natural module system (no source conflicts)
- Explicit initialization patterns
- Proper object-oriented design
- Clear testing boundaries

### Next Steps
1. Run `/plan` command to generate Ruby-specific implementation plan
2. Run `/tasks` command to create Ruby task list
3. Execute tasks following TDD methodology
4. Validate against constitutional principles throughout

---

*Based on Constitution v1.0.0 - Last updated: 2025-01-15*