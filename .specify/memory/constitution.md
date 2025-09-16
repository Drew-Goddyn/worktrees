# Worktrees Constitution

## Core Principles

### I. Technology Appropriateness
Choose implementation language based on tool complexity and maintenance needs:
- Simple scripts (<100 lines): Bash with minimal structure
- Multi-command CLIs: Ruby (dry-cli), Python (Click), or Go (Cobra)
- Service layers only when multiple consumers exist (API + CLI + Web)
- Study similar successful tools (git, docker, rbenv) for patterns

### II. Library-First Architecture
Every feature must be implemented as a standalone library first:
- Libraries must be self-contained and independently testable
- CLI layer only handles argument parsing and output formatting
- Business logic lives in libraries, not CLI layer
- Clear separation between presentation and logic

### III. Test-First Development (NON-NEGOTIABLE)
Strict TDD Red-Green-Refactor cycle:
- Tests written first and must fail before implementation
- Ruby: RSpec for unit tests, Aruba for CLI integration tests
- Use real dependencies (actual git repos, not mocks)
- Test order: Contract → Integration → Unit
- No implementation without failing test first

### IV. Simplicity and Maintainability
Start with simplest architecture that could possibly work:
- Maximum 2 architectural layers for CLI tools (commands + libraries)
- No design patterns without demonstrated need
- Avoid premature abstraction
- YAGNI (You Aren't Gonna Need It) principle applies
- Refactor only when tests are green

### V. Observability and Debugging
All tools must be observable and debuggable:
- Structured logging to stderr
- Verbose mode (-v, --verbose) for debugging
- Clear error messages with actionable next steps
- JSON output for programmatic consumption

### VI. Consistent User Experience
All CLI tools in our ecosystem follow same patterns:
- --help and --version flags on all commands
- --format json/text for output control
- Consistent exit codes (0=success, 1=general, 2=validation, 3=precondition)
- Predictable command structure: noun-verb or verb-noun

## Implementation Standards

### For Ruby CLI Tools
- Framework: dry-cli (consistent, well-tested, minimal magic)
- Testing: RSpec + Aruba (standard in Ruby ecosystem)
- Structure: lib/ for logic, exe/ for CLI entry point
- Dependencies: Bundler for management, minimal external gems

### Anti-Patterns to Avoid
- Service layers in CLI tools (unnecessary abstraction)
- Auto-initialization on require/source (causes side effects)
- Mock-heavy tests (use real dependencies instead)
- Deep inheritance hierarchies (composition over inheritance)
- Global state mutations (pass data explicitly)

## Development Workflow

### Planning Process
- Constitution defines technology choices and architectural principles
- /plan command reads constitution to generate appropriate architecture
- /tasks command reads plan to generate implementation tasks
- Implementation follows tasks in TDD order

### Quality Gates
- All tests must pass before merging
- Code review must verify constitutional compliance
- No implementation without failing test first
- Complexity must be justified in plan documentation

## Governance
- Constitution supersedes all design decisions
- Amendments require documentation of rationale
- Each project must reference this constitution in its README
- Plan and task generation must comply with these principles

**Version**: 1.0.1 | **Ratified**: 2025-01-15 | **Last Amended**: 2025-01-15

## Amendment History
- v1.0.1 (2025-01-15): Added template synchronization for Ruby CLI implementation
  - Updated all templates to enforce constitutional principles
  - Added Ruby-specific guidance and anti-patterns
  - Synchronized command files across AI assistants