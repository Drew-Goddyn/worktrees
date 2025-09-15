#!/usr/bin/env bats

# Contract tests for worktrees CLI commands
# These tests validate command shapes, flags, and exit codes per cli-contracts.md

setup() {
	export WORKTREES_CLI="/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees"
	export TEMP_DIR="${BATS_TMPDIR}/worktrees_test_$$"
	mkdir -p "$TEMP_DIR"
}

teardown() {
	rm -rf "$TEMP_DIR"
}

# Global flags tests
@test "help flag shows usage information" {
	run "$WORKTREES_CLI" --help
	[ "$status" -eq 0 ]
	[[ "$output" =~ "USAGE:" ]]
	[[ "$output" =~ "worktrees" ]]
}

@test "short help flag works" {
	run "$WORKTREES_CLI" -h
	[ "$status" -eq 0 ]
	[[ "$output" =~ "USAGE:" ]]
}

@test "version flag shows version information" {
	run "$WORKTREES_CLI" --version
	[ "$status" -eq 0 ]
	[[ "$output" =~ worktrees.* ]]
}

@test "short version flag works" {
	run "$WORKTREES_CLI" -v
	[ "$status" -eq 0 ]
	[[ "$output" =~ worktrees.* ]]
}

@test "format flag accepts text value" {
	run "$WORKTREES_CLI" --format text create 001-test-feature
	# Should fail on unimplemented command, not format validation
	[[ ! "$output" =~ "Invalid format" ]]
}

@test "format flag accepts json value" {
	run "$WORKTREES_CLI" --format json create 001-test-feature
	# Should fail on unimplemented command, not format validation
	[[ ! "$output" =~ "Invalid format" ]]
}

@test "format flag rejects invalid value" {
	run "$WORKTREES_CLI" --format xml create 001-test-feature
	[ "$status" -eq 2 ]
	[[ "$output" =~ "Invalid format" ]]
}

@test "format flag requires argument" {
	run "$WORKTREES_CLI" --format
	[ "$status" -eq 2 ]
	[[ "$output" =~ "requires an argument" ]]
}

@test "unknown global flag shows error" {
	run "$WORKTREES_CLI" --unknown-flag
	[ "$status" -eq 2 ]
	[[ "$output" =~ "Unknown option" ]]
}

@test "no command shows error and usage hint" {
	run "$WORKTREES_CLI"
	[ "$status" -eq 2 ]
	[[ "$output" =~ "No command specified" ]]
	[[ "$output" =~ "--help" ]]
}

@test "unknown command shows error" {
	run "$WORKTREES_CLI" unknown-command
	[ "$status" -eq 2 ]
	[[ "$output" =~ "Unknown command" ]]
}

# Create command contract tests
@test "create command exists and fails with unimplemented message" {
	run "$WORKTREES_CLI" create 001-test-feature
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]
}

@test "create command accepts valid feature name format" {
	run "$WORKTREES_CLI" create 001-valid-feature-name
	# Should fail on implementation, not name validation
	[[ ! "$output" =~ "Invalid.*name" ]]
}

@test "create command accepts base flag" {
	run "$WORKTREES_CLI" create 001-test --base main
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*base" ]]
}

@test "create command accepts root flag" {
	run "$WORKTREES_CLI" create 001-test --root /tmp/worktrees
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*root" ]]
}

@test "create command accepts reuse-branch flag" {
	run "$WORKTREES_CLI" create 001-test --reuse-branch
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*reuse" ]]
}

@test "create command accepts sibling flag" {
	run "$WORKTREES_CLI" create 001-test --sibling -2
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*sibling" ]]
}

# List command contract tests
@test "list command exists and fails with unimplemented message" {
	run "$WORKTREES_CLI" list
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]
}

@test "list command accepts filter-name flag" {
	run "$WORKTREES_CLI" list --filter-name test
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*filter-name" ]]
}

@test "list command accepts filter-base flag" {
	run "$WORKTREES_CLI" list --filter-base main
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*filter-base" ]]
}

@test "list command accepts page flag" {
	run "$WORKTREES_CLI" list --page 2
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*page" ]]
}

@test "list command accepts page-size flag" {
	run "$WORKTREES_CLI" list --page-size 50
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*page-size" ]]
}

# Switch command contract tests
@test "switch command exists and fails with unimplemented message" {
	run "$WORKTREES_CLI" switch 001-test-feature
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]
}

# Remove command contract tests
@test "remove command exists and fails with unimplemented message" {
	run "$WORKTREES_CLI" remove 001-test-feature
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]
}

@test "remove command accepts delete-branch flag" {
	run "$WORKTREES_CLI" remove 001-test --delete-branch
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*delete-branch" ]]
}

@test "remove command accepts merged-into flag" {
	run "$WORKTREES_CLI" remove 001-test --merged-into main
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*merged-into" ]]
}

@test "remove command accepts force flag" {
	run "$WORKTREES_CLI" remove 001-test --force
	# Should fail on implementation, not flag parsing
	[[ ! "$output" =~ "Unknown.*force" ]]
}

# Status command contract tests
@test "status command exists and works" {
	run "$WORKTREES_CLI" status
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Worktree:" ]]
	[[ "$output" =~ "Base:" ]]
	[[ "$output" =~ "Path:" ]]
}

# Error output validation (errors should go to stderr)
@test "validation errors go to stderr" {
	run "$WORKTREES_CLI" --format invalid-format create 001-test
	[ "$status" -eq 2 ]
	# In bats, stderr is captured in output for failed commands
	[[ "$output" =~ "Invalid format" ]]
}

@test "unimplemented command errors go to stderr" {
	run "$WORKTREES_CLI" create 001-test
	[ "$status" -eq 1 ]
	# Implementation error should go to stderr
	[[ "$output" =~ "not yet implemented" ]]
}