# Tasks: [FEATURE NAME]

**Input**: Design documents from `/specs/[###-feature-name]/`
**Prerequisites**: plan.md (required), research.md, data-model.md, contracts/

## Execution Flow (main)
```
1. Load plan.md from feature directory
   → If not found: ERROR "No implementation plan found"
   → Extract: tech stack, libraries, structure
2. Load optional design documents:
   → data-model.md: Extract entities → model tasks
   → contracts/: Each file → contract test task
   → research.md: Extract decisions → setup tasks
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: DB, middleware, logging
   → Polish: unit tests, performance, docs
4. Apply task rules:
   → Different files = mark [P] for parallel
   → Same file = sequential (no [P])
   → Tests before implementation (TDD)
5. Number tasks sequentially (T001, T002...)
6. Generate dependency graph
7. Create parallel execution examples
8. Validate task completeness:
   → All contracts have tests?
   → All entities have models?
   → All endpoints implemented?
9. Return: SUCCESS (tasks ready for execution)
```

## Format: `[ID] [P?] Description`
- **[P]**: Can run in parallel (different files, no dependencies)
- Include exact file paths in descriptions

## Path Conventions
- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 3.1: Setup

### Ruby CLI Project Setup (per Constitution):
- [ ] T001 Create Ruby project structure (lib/, exe/, spec/)
- [ ] T002 Initialize Gemfile with dry-cli, rspec, aruba dependencies
- [ ] T003 [P] Configure RSpec with spec_helper.rb and support/aruba.rb
- [ ] T004 [P] Configure bundler and gemspec file

### General Project Setup:
- [ ] T001 Create project structure per implementation plan
- [ ] T002 Initialize [language] project with [framework] dependencies
- [ ] T003 [P] Configure linting and formatting tools

## Red Phase: Write Failing Tests
**Remember: "I start every feature with a failing test" - write these first, watch them fail**

### Ruby CLI Tests (following "Test Real Behavior"):
- [ ] T005 [P] Aruba feature test for main CLI command in spec/features/[command]_spec.rb
- [ ] T006 [P] RSpec unit test for core logic in spec/lib/[project]_spec.rb
- [ ] T007 [P] Integration test with real dependencies (actual git repos, files, etc.)

### General Tests:
- [ ] T004 [P] API test for key endpoints in tests/api/test_[endpoint].py
- [ ] T005 [P] Integration test for main workflow in tests/integration/test_[workflow].py
- [ ] T006 [P] Edge case tests in tests/edge_cases/test_[scenario].py

## Green Phase: Make Tests Pass
**Goal: Write minimal code to make red tests green - "Simple Over Clever"**

### Ruby CLI Implementation:
- [ ] T008 [P] Main CLI application class in lib/[project]/cli.rb
- [ ] T009 [P] Command classes in lib/[project]/commands/[command].rb (one per command)
- [ ] T010 [P] Core logic modules in lib/[project]/[domain].rb (focused on real problems)
- [ ] T011 [P] CLI entry point in exe/[project] (keep it simple)
- [ ] T012 Error handling that "Fails Gracefully" (good messages, reasonable defaults)

### General Implementation:
- [ ] T008 [P] Core models/classes in src/[domain]/
- [ ] T009 [P] Main functionality in src/[feature]/
- [ ] T010 [P] CLI interface in src/cli/ (if applicable)
- [ ] T011 API endpoints (if applicable)
- [ ] T012 Input validation and error handling
- [ ] T013 Configuration and setup

## Refactor Phase: Clean Up Code
**"Write It Like I'll Maintain It" - make it readable and remove duplication**

- [ ] T015 [P] Refactor repeated patterns (DRY principle)
- [ ] T016 [P] Improve naming and structure (clear communication with future self)
- [ ] T017 [P] Add missing edge case tests (where does this break?)
- [ ] T018 [P] Update documentation with examples and rationale
- [ ] T019 [P] Performance check (measure if it matters, optimize if slow)
- [ ] T020 [P] Security review (validate inputs, avoid injection)

## Final Integration
- [ ] T021 Connect all pieces together
- [ ] T022 End-to-end testing with real scenarios
- [ ] T023 Manual testing and verification

## Dependencies
- Tests (T004-T007) before implementation (T008-T014)
- T008 blocks T009, T015
- T016 blocks T018
- Implementation before polish (T019-T023)

## Parallel Example
```
# Launch T004-T007 together:
Task: "Contract test POST /api/users in tests/contract/test_users_post.py"
Task: "Contract test GET /api/users/{id} in tests/contract/test_users_get.py"
Task: "Integration test registration in tests/integration/test_registration.py"
Task: "Integration test auth in tests/integration/test_auth.py"
```

## Notes
- [P] tasks = different files, no dependencies
- Verify tests fail before implementing
- Commit after each task
- Avoid: vague tasks, same file conflicts

## Task Generation Rules
*Applied during main() execution*

1. **From Contracts**:
   - Each contract file → contract test task [P]
   - Each endpoint → implementation task
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories**:
   - Each story → integration test [P]
   - Quickstart scenarios → validation tasks

4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests
- [ ] All entities have model tasks
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task