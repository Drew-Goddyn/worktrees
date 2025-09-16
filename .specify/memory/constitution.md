# Personal CLI Tools Development Principles

## My Philosophy

These are my core principles for building CLI tools that I actually want to use and maintain. They help me create tools that solve real problems without becoming problems themselves.

---

## Core Values

### Ruby First
**I choose Ruby because it makes me productive and happy.** Life's too short for verbose languages when I'm building personal tools. Ruby lets me focus on solving problems instead of fighting syntax.

### Simple Over Clever
**I prefer code I can understand in six months.** Clever one-liners are fun, but clear, readable code is a gift to my future self. When I need to debug at 2 AM, I'll thank myself for writing obvious code.

### Libraries Over NIH Syndrome
**I use proven libraries instead of reinventing wheels.** The Ruby ecosystem has solved most problems better than I could in an evening. My time is better spent on the unique parts of my problem.

---

## Building Principles

### Start Simple, Grow Thoughtfully
**Every tool starts as a simple script.** I only add complexity when I actually need it, not when I think I might. Features that aren't used are just maintenance burden.

### Test-Driven Development is Fundamental
**I write tests first, always.** TDD isn't academic ceremony - it's the fastest way to build CLI tools that actually work. Starting with tests forces me to think about the interface before getting lost in implementation details.

**I test real behavior over mocked abstractions.** CLI tools live at integration boundaries - file systems, networks, databases. Testing against real dependencies catches the problems that actually break tools in production use.

**I prioritize integration testing for CLI tools.** Unit tests verify logic; integration tests verify that my tool works in the real world with real files, real services, and real edge cases.

### Fail Gracefully
**Things go wrong, so I plan for it.** Good error messages help me debug faster. Reasonable defaults mean my tools work without fiddling. Validation catches problems early.

---

## Security Basics

### Trust Nothing External
**I validate all inputs and avoid shell injection.** Using `system('ls', user_input)` instead of `system("ls #{user_input}")` prevents nasty surprises. It's a simple habit that prevents major headaches.

### Keep Secrets Secret
**No passwords or API keys in code.** Environment variables or config files that stay out of git. My future self will thank me when I don't accidentally leak credentials.

### Stay Updated
**I keep dependencies current and use tools like `bundle audit`.** Security vulnerabilities are real, and staying patched is easier than dealing with breaches.

---

## User Experience (Even When the User Is Me)

### Help That Actually Helps
**My tools explain themselves clearly.** Good help text, clear error messages, and examples for common usage. If I can't remember how to use my own tool, it needs better help.

### Consistent and Predictable
**I follow CLI conventions people expect.** Standard flags, consistent output formats, and behavior that matches other tools. Fighting muscle memory is annoying.

### Show Progress, Handle Interruption
**Long operations show progress and handle Ctrl+C gracefully.** Nothing worse than wondering if a tool hung or is just slow.

---

## Quality Habits

### Red-Green-Refactor is My Default Workflow
**I start every feature with a failing test.** Write the test, watch it fail (red), make it pass with minimal code (green), then clean up (refactor). This cycle keeps me focused and prevents over-engineering.

**I test the CLI interface, not just the internals.** Aruba tests how users actually interact with my tool. Unit tests for complex logic, Aruba scenarios for user workflows, test-containers for integration points.

### Write It Like I'll Maintain It
**Because I will.** Clear naming, reasonable comments, and structure that makes sense. Code is communication with my future self.

### Measure What Matters
**I know how my tools perform on real data.** If it's slow, I measure before optimizing. Premature optimization is the root of all evil, but so is ignoring real performance problems.

### Document the Why
**I capture decisions and trade-offs.** A simple README with examples and any non-obvious choices. Six months later, I'll have forgotten why I did things a certain way.

### Test Coverage That Actually Matters
**I focus on testing behavior that users care about.** High line coverage of trivial code is meaningless. Testing that my tool correctly handles malformed input and provides helpful errors is essential.

**Integration tests catch the bugs that matter most.** CLI tools fail at boundaries - file handling, external APIs, system integration. I test these integration points with real dependencies, not simulation.

---

## Practical Guidelines

### Testing Philosophy Guides Tool Choice
**I choose testing tools that validate real CLI behavior.** Tools that test actual command execution and real dependencies reveal problems that matter. Mocking frameworks have their place, but CLI testing demands reality-based validation.

**I test happy paths AND edge cases.** What happens when files don't exist? When network calls fail? When users pass malformed input? Edge case testing prevents 2 AM debugging sessions.

### Configuration That Works
**Command-line args override environment variables override config files.** This gives me flexibility without confusion. Reasonable defaults mean most tools work out of the box.

### One Thing Well
**Each tool has a clear, focused purpose.** If I'm tempted to add unrelated features, maybe I need a separate tool. Unix philosophy scales down to personal tools too.

### Build for Change
**I assume requirements will evolve.** Modular design and clear interfaces make adaptation easier. Today's quick script might become tomorrow's essential tool.

---

## Personal Development Rules

### Learn by Building
**I try new patterns and libraries in personal tools.** It's a safe place to experiment before using techniques in important projects. Mistakes here are learning opportunities.

### Share What Works
**If I build something useful, I consider sharing it.** Open source gives back to the community that provides the libraries I depend on. Plus, external users find bugs I miss.

### Evolve Standards
**These principles change as I learn.** What works for me now might not work forever. I update my approach based on what I learn from successes and failures.

---

## Implementation Freedom

**These are principles, not rules.** They guide decisions but don't replace thinking. Sometimes the right choice breaks a principle - that's fine if I understand why.

**Context matters.** A quick one-off script has different needs than a tool I'll use daily. I scale my effort to match the tool's importance and lifespan.

**Done is better than perfect.** These principles help me build better tools, not perfect ones. The goal is solving problems, not following rules.

---

## Why This Matters

Building personal tools with TDD and sound principles means:
- **Faster development** - tests catch mistakes immediately instead of during late-night debugging sessions
- **Fearless refactoring** - comprehensive tests enable confident code improvement
- **Real confidence** - tools tested against actual behavior work reliably in real conditions
- **Better learning** - TDD develops design skills that transfer to every project
- **Genuine productivity** - tools that work correctly under real conditions

**TDD for personal tools isn't overkill - it's self-respect.** My time is valuable, and spending it debugging preventable issues is wasteful. Testing first means tools work correctly from day one.

**Testing real behavior prevents surprises.** CLI tools live at integration boundaries. Testing with real files, real services, and real edge cases catches the problems that actually matter.

Good habits in small projects build the muscle memory for larger ones. Plus, life's more enjoyable when my tools work reliably and I can trust them completely.

---

**Version**: 2.0.0 | **Adopted**: 2025-01-15

## Version History
- v2.0.0 (2025-01-15): Replaced formal constitution with personal principles
  - Shifted from enterprise patterns to personal development philosophy
  - Simplified language and removed unnecessary formality
  - Focused on Ruby-first, TDD, and practical simplicity
- v1.0.1 (2025-01-15): [Archived] Formal constitution with enterprise patterns