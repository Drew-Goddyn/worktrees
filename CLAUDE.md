# Claude Code Development Guidelines - Worktrees Project

This project follows my personal development principles defined in `.specify/memory/constitution.md`.

## My Technology Choices

### Why Ruby
**I choose Ruby because it makes me productive and happy.** Life's too short for verbose languages when building personal tools. Ruby lets me focus on solving problems instead of fighting syntax.

### Core Technologies
- **Language**: Ruby 3.2+ (Ruby First principle)
- **CLI Framework**: dry-cli (proven library, not reinventing wheels)
- **Testing**: RSpec for unit tests, Aruba for CLI integration tests
- **Dependencies**: Bundler, minimal external gems
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

## Following My Principles

### "Ruby First" ✅
**Using Ruby because it makes me productive and happy.** Multi-command CLI tools are perfect for Ruby + dry-cli. No fighting verbose syntax - just solving the actual problem.

### "Simple Over Clever" ✅
**Code I can understand in six months.** Clear naming, obvious structure, focused purpose. No unnecessary abstraction or enterprise patterns.

### "Start Simple, Grow Thoughtfully" ✅
**Starting as a simple worktree management script.** Only adding complexity as I actually need it, not as I think I might need it.

### "Test-Driven Development is Fundamental" ✅
**Writing tests first, always.** Red-Green-Refactor cycle:
- RSpec for unit tests of core logic
- Aruba for CLI integration tests with real git repositories
- Testing real behavior, not mocked abstractions

## What I've Learned to Avoid

Based on the bash attempt and general experience:

**Over-engineering** - Started with "service layers" in bash. Learned to keep it simple.
**Auto-magic initialization** - Things that happen automatically on import/require cause problems.
**Mock-heavy tests** - Testing fake behavior instead of real behavior leads to surprises.
**Clever abstractions** - Code that's hard to understand in six months isn't worth it.
**Feature creep** - Tools that do everything end up doing nothing well.

## My Development Workflow

### Planning Phase
1. Personal principles guide technology choices (Ruby + dry-cli)
2. `/plan` command reads my principles and generates sensible architecture
3. `/tasks` command creates Red-Green-Refactor tasks

### Red-Green-Refactor Implementation
1. **RED**: Write failing test first (RSpec unit test or Aruba feature test)
2. **GREEN**: Write minimal code to make test pass (Simple Over Clever)
3. **REFACTOR**: Clean up code while keeping tests green (Write It Like I'll Maintain It)
4. Commit when tests are green

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

*Based on Personal Principles v2.0.0 - Last updated: 2025-01-15*ALWAYS use ONLY Environments for ANY and ALL file, code, or shell operations—NO EXCEPTIONS—even for simple or generic requests.

DO NOT install or use the git cli with the environment_run_cmd tool. All environment tools will handle git operations for you. Changing ".git" yourself will compromise the integrity of your environment.

You MUST inform the user how to view your work using `container-use log <env_id>` AND `container-use checkout <env_id>`. Failure to do this will make your work inaccessible to others.
