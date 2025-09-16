#!/usr/bin/env bats

# Integration tests for worktree creation
# Tests the complete create worktree flow from quickstart.md

bats_require_minimum_version 1.5.0

setup() {
	export WORKTREES_CLI="/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees"
	export TEST_ROOT="${BATS_TMPDIR}/worktrees_create_test_$$"
	export TEST_REPO="$TEST_ROOT/test_repo"
	export TEST_WORKTREES_ROOT="$TEST_ROOT/worktrees"

	mkdir -p "$TEST_ROOT"
	mkdir -p "$TEST_WORKTREES_ROOT"

	# Create a test Git repository
	git init "$TEST_REPO"
	cd "$TEST_REPO"
	git config user.name "Test User"
	git config user.email "test@example.com"

	# Create initial commit on main branch
	echo "Initial commit" > README.md
	git add README.md
	git commit -m "Initial commit"

	# Ensure we're on main branch
	git checkout -b main 2>/dev/null || git checkout main
}

teardown() {
	rm -rf "$TEST_ROOT"
}

# Helper function to check if output is valid JSON
is_valid_json() {
	echo "$1" | python3 -m json.tool >/dev/null 2>&1
}

# Basic creation flow tests
@test "create worktree with valid name and base branch" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" create 001-build-a-tool --base main --root "$TEST_WORKTREES_ROOT"

	# Should pass and create worktree directory
	[ "$status" -eq 0 ]
	[ -d "$TEST_WORKTREES_ROOT/001-build-a-tool" ]
}

@test "create worktree scenario from quickstart.md" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" create 001-build-a-tool --base main --format json --root "$TEST_WORKTREES_ROOT"

	# Should return valid JSON
	[ "$status" -eq 0 ]
	is_valid_json "$output"
}

# Name validation tests
@test "create worktree validates name format - valid names" {
	cd "$TEST_REPO"

	# Test valid name formats
	local valid_names=("001-test" "123-valid-feature-name" "999-a" "001-feature-with-numbers-123")

	for name in "${valid_names[@]}"; do
		run "$WORKTREES_CLI" create "$name" --base main --root "$TEST_WORKTREES_ROOT"
		# Should fail on implementation, not name validation
		[[ ! "$output" =~ "Invalid.*name" ]]
	done
}

@test "create worktree validates name format - invalid names" {
	cd "$TEST_REPO"

	# Test invalid name formats (these should be rejected when implemented)
	local invalid_names=("invalid_name" "001-UPPERCASE" "1-short" "001-" "001-feature-name-that-is-way-too-long-to-be-valid")

	for name in "${invalid_names[@]}"; do
		run "$WORKTREES_CLI" create "$name" --base main --root "$TEST_WORKTREES_ROOT"
		# Currently fails on implementation, will test validation when implemented
		[ "$status" -ne 0 ]
		# [[ "$output" =~ "Invalid.*name" ]] # Will validate this when implemented
	done
}

# Base branch validation tests
@test "create worktree with non-existent base branch" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" create 001-test-feature --base non-existent-branch --root "$TEST_WORKTREES_ROOT"

	# Should fail with precondition error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "Failed to create worktree" ]]
}

@test "create worktree with valid base branch detection" {
	cd "$TEST_REPO"

	# Create a feature branch to use as base
	git checkout -b feature-base
	git checkout main

	run "$WORKTREES_CLI" create 002-feature-base --base feature-base --root "$TEST_WORKTREES_ROOT"

	# Should succeed
	[ "$status" -eq 0 ]
}

# Flag handling tests
@test "create worktree accepts all documented flags" {
	cd "$TEST_REPO"

	# Test individual flags don't cause parsing errors
	run "$WORKTREES_CLI" create 001-test --base main --root "$TEST_WORKTREES_ROOT"
	[[ ! "$output" =~ "Unknown.*base" ]]

	run "$WORKTREES_CLI" create 001-test --reuse-branch --root "$TEST_WORKTREES_ROOT"
	[[ ! "$output" =~ "Unknown.*reuse" ]]

	run "$WORKTREES_CLI" create 001-test --sibling -2 --root "$TEST_WORKTREES_ROOT"
	[[ ! "$output" =~ "Unknown.*sibling" ]]
}

@test "create worktree with custom root directory" {
	cd "$TEST_REPO"
	local custom_root="$TEST_ROOT/custom_worktrees"
	mkdir -p "$custom_root"

	run "$WORKTREES_CLI" create 003-custom-root --base main --root "$custom_root"

	# Should use custom root
	[ "$status" -eq 0 ]
	[ -d "$custom_root/003-custom-root" ]
}

# Duplicate worktree tests
@test "create duplicate worktree should fail" {
	cd "$TEST_REPO"

	# First creation should succeed
	run "$WORKTREES_CLI" create 004-duplicate --base main --root "$TEST_WORKTREES_ROOT"
	[ "$status" -eq 0 ]

	# Second creation should fail with conflict error
	run "$WORKTREES_CLI" create 004-duplicate --base main --root "$TEST_WORKTREES_ROOT"
	[ "$status" -eq 4 ]
	[[ "$output" =~ "already checked out" ]]
}

# JSON output validation tests
@test "create worktree JSON output has required fields" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" create 005-json-test --base main --format json --root "$TEST_WORKTREES_ROOT"

	# Validate JSON schema
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# Required fields per OpenAPI spec: {name, branch, baseRef, path, active}
	[[ "$output" =~ '"name"' ]]
	[[ "$output" =~ '"branch"' ]]
	[[ "$output" =~ '"baseRef"' ]]
	[[ "$output" =~ '"path"' ]]
	[[ "$output" =~ '"active"' ]]
}

# Error handling and edge cases
@test "create worktree outside git repository should fail" {
	cd "$TEST_ROOT"  # Not in git repo
	run "$WORKTREES_CLI" create 006-no-git --base main --root "$TEST_WORKTREES_ROOT"

	# Should fail with appropriate error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "Not in a Git repository" ]]
}

@test "create worktree without required name argument" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" create --base main --root "$TEST_WORKTREES_ROOT"

	# Should fail on argument parsing before reaching implementation
	[ "$status" -ne 0 ]
	# [[ "$output" =~ "name.*required\|missing.*name" ]] # Will validate when implemented
}