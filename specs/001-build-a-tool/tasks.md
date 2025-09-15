# Tasks: Manage Git feature worktrees

**Input**: Design documents from `/Users/drewgoddyn/projects/claude-worktrees/specs/001-build-a-tool/`
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
   → quickstart.md: Extract user flows → integration tests
3. Generate tasks by category:
   → Setup: project init, dependencies, linting
   → Tests: contract tests, integration tests
   → Core: models, services, CLI commands
   → Integration: flags, safety checks, logging
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
- **Single project** per plan: `src/`, `tests/` at repository root
- Absolute repo root: `/Users/drewgoddyn/projects/claude-worktrees`

## Phase 3.1: Setup
- [x] T001 Create project structure per implementation plan
  - Paths: `/Users/drewgoddyn/projects/claude-worktrees/src/{cli,models,services,lib}` and `/Users/drewgoddyn/projects/claude-worktrees/tests/{contract,integration,unit}`, `/Users/drewgoddyn/projects/claude-worktrees/scripts`
- [x] T002 Initialize Bash CLI scaffold and tooling
  - Create entrypoint: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees` with `--help|--version|--format` scaffolding only (no behaviors)
  - Create Makefile with targets: `test`, `lint`, `fmt`
  - Add runner scripts: `/Users/drewgoddyn/projects/claude-worktrees/scripts/test.sh`, `/Users/drewgoddyn/projects/claude-worktrees/scripts/lint.sh`, `/Users/drewgoddyn/projects/claude-worktrees/scripts/format.sh`
- [x] T003 [P] Configure linting and formatting
  - ShellCheck config at `/Users/drewgoddyn/projects/claude-worktrees/.shellcheckrc`
  - shfmt usage in `scripts/format.sh`

## Phase 3.2: Tests First (TDD) ⚠️ MUST COMPLETE BEFORE 3.3
**CRITICAL: These tests MUST be written and MUST FAIL before ANY implementation**
- [x] T004 [P] Contract tests from `cli-contracts.md`
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/contract/cli_contracts.bats`
  - Scope: Validate command shapes and flags for `worktrees create|list|switch|remove|status`, exit codes, stderr vs stdout
- [x] T005 [P] Contract tests from `openapi.yaml`
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/contract/openapi_worktrees.bats`
  - Scope: Validate `--format json` output schema for list/create/switch/remove/status against OpenAPI fields
- [x] T006 [P] Integration test: create a worktree
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/integration/create_worktree.bats`
  - Scenario from quickstart.md "Create a worktree"
- [x] T007 [P] Integration test: list worktrees (paged)
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/integration/list_worktrees.bats`
  - Scenario from quickstart.md "List worktrees (paged)"
- [x] T008 [P] Integration test: switch to a worktree
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/integration/switch_worktree.bats`
  - Scenario from quickstart.md "Switch to a worktree"
- [x] T009 [P] Integration test: remove worktree (keep branch)
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/integration/remove_keep_branch.bats`
  - Scenario from quickstart.md "Remove a worktree safely (keep branch)"
- [x] T010 [P] Integration test: remove worktree and delete branch when merged
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/integration/remove_delete_branch.bats`
  - Scenario from quickstart.md "Remove and delete branch when fully merged"

## Phase 3.3: Core Implementation (ONLY after tests are failing)
### Models (from data-model.md)
- [x] T011 [P] Repository model functions
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/models/repository.sh`
  - Implement: detect repo root; resolve default base from remote HEAD→main→master
- [x] T012 [P] FeatureName model and validation
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/models/feature_name.sh`
  - Implement: regex `^[0-9]{3}-[a-z0-9-]{1,40}$`, reserved names, normalization
- [x] T013 [P] Worktree model
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/models/worktree.sh`
  - Implement: representation; parse `git worktree list --porcelain` into fields; derived `active`
- [x] T014 [P] ListQuery model
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/models/list_query.sh`
  - Implement: filterName, filterBase, page, pageSize with validation and caps

### Services and libs
- [x] T015 [P] Worktree service stubs
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/services/worktree_service.sh`
  - Implement: `create_worktree`, `list_worktrees`, `switch_worktree`, `remove_worktree` interfaces (no CLI wiring yet)
- [x] T016 [P] JSON utilities for structured output
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/lib/json.sh`
  - Implement: safe JSON quoting/encoding for text|json outputs (no jq dependency)
- [x] T017 [P] IO utilities and exit code mapping
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/lib/io.sh`
  - Implement: stderr logging helpers, consistent exit codes (0/2/3/4/5/6)

### CLI commands (endpoints; sequential due to shared files)
- [x] T018 Implement `worktrees list` command
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`
  - Wire: parse paging/filters; call service; print json/text
- [ ] T019 Implement `worktrees create <NNN-kebab-feature>`
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`
  - Wire: validate name; base detection/override; reuse/sibling flags; call service
- [ ] T020 Implement `worktrees switch <name>`
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`
  - Wire: allow dirty; warning to stderr; print current/previous
- [ ] T021 Implement `worktrees remove <name>`
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`
  - Wire: safety prechecks; `--delete-branch` with `--merged-into`; `--force` semantics
- [ ] T022 Implement `worktrees status`
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`
  - Wire: show current worktree ref

## Phase 3.4: Integration
- [ ] T023 Integrate safety checks and merge verification
  - File: `/Users/drewgoddyn/projects/claude-worktrees/src/services/worktree_service.sh`
  - Implement: tracked changes, unpushed commits/no upstream, op in progress; `git merge-base --is-ancestor` for merged checks
- [ ] T024 Wire global flags and output modes
  - Files: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`, `/Users/drewgoddyn/projects/claude-worktrees/src/lib/io.sh`, `/Users/drewgoddyn/projects/claude-worktrees/src/lib/json.sh`
  - Implement: `--help`, `--version`, `--format text|json` consistent across commands
- [ ] T025 Implement global root resolution and setup
  - Files: `/Users/drewgoddyn/projects/claude-worktrees/src/services/worktree_service.sh`, `/Users/drewgoddyn/projects/claude-worktrees/src/models/repository.sh`
  - Implement: default `$HOME/.worktrees`, `WORKTREES_ROOT` and `--root` override; create if missing

## Phase 3.5: Polish
- [ ] T026 [P] Unit tests: FeatureName validation rules
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/unit/feature_name_test.bats`
- [ ] T027 [P] Unit tests: default base detection
  - File: `/Users/drewgoddyn/projects/claude-worktrees/tests/unit/repository_test.bats`
- [ ] T028 [P] Implement list paging caps and performance guards
  - Files: `/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees`, `/Users/drewgoddyn/projects/claude-worktrees/src/services/worktree_service.sh`
- [ ] T029 [P] Documentation pass
  - Update quickstart examples in `/Users/drewgoddyn/projects/claude-worktrees/specs/001-build-a-tool/quickstart.md` and create README at `/Users/drewgoddyn/projects/claude-worktrees/README.md`
- [ ] T030 [P] Ensure ShellCheck/shfmt clean, finalize Makefile targets
  - Run `scripts/lint.sh` and `scripts/format.sh`; adjust code accordingly

## Dependencies
- Setup (T001–T003) before Tests (T004–T010)
- Tests (T004–T010) must fail before Core (T011+)
- Models (T011–T014) before Services (T015–T017)
- Services/Libs (T015–T017) before CLI endpoints (T018–T022)
- Core (T011–T022) before Integration (T023–T025)
- Everything before Polish (T026–T030)
- CLI endpoint tasks T018–T022 are sequential (shared file `/src/cli/worktrees`)

## Parallel Example
```
# Launch T004–T010 together (different test files):
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/contract/cli_contracts.bats"
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/contract/openapi_worktrees.bats"
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/integration/create_worktree.bats"
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/integration/list_worktrees.bats"
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/integration/switch_worktree.bats"
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/integration/remove_keep_branch.bats"
Task: "Create /Users/drewgoddyn/projects/claude-worktrees/tests/integration/remove_delete_branch.bats"

# After models are done, run model tasks in parallel:
Task: "Implement /Users/drewgoddyn/projects/claude-worktrees/src/models/repository.sh"
Task: "Implement /Users/drewgoddyn/projects/claude-worktrees/src/models/feature_name.sh"
Task: "Implement /Users/drewgoddyn/projects/claude-worktrees/src/models/worktree.sh"
Task: "Implement /Users/drewgoddyn/projects/claude-worktrees/src/models/list_query.sh"
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
   - Each endpoint/CLI command → implementation task (sequential if shared files)
   
2. **From Data Model**:
   - Each entity → model creation task [P]
   - Relationships → service layer tasks
   
3. **From User Stories (quickstart flows)**:
   - Each flow → integration test [P]
   - Quickstart scenarios → validation tasks
   
4. **Ordering**:
   - Setup → Tests → Models → Services → Endpoints → Integration → Polish
   - Dependencies block parallel execution

## Validation Checklist
*GATE: Checked by main() before returning*

- [ ] All contracts have corresponding tests (cli-contracts.md, openapi.yaml)
- [ ] All entities have model tasks (Repository, FeatureName, Worktree, ListQuery)
- [ ] All tests come before implementation
- [ ] Parallel tasks truly independent
- [ ] Each task specifies exact file path
- [ ] No task modifies same file as another [P] task


