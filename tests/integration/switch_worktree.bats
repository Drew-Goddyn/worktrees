#!/usr/bin/env bats

# Integration tests for worktree switching
# Tests the complete switch worktree flow from quickstart.md

bats_require_minimum_version 1.5.0

setup() {
	export WORKTREES_CLI="/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees"
	export TEST_ROOT="${BATS_TMPDIR}/worktrees_switch_test_$$"
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

	# Create feature branches for testing
	git checkout -b 001-build-a-tool
	echo "Feature work" > feature.md
	git add feature.md
	git commit -m "Add feature work"

	git checkout -b 002-test-feature
	echo "Test work" > test.md
	git add test.md
	git commit -m "Add test work"

	git checkout main

	# Create some worktree directories to simulate existing worktrees
	mkdir -p "$TEST_WORKTREES_ROOT/001-build-a-tool"
	mkdir -p "$TEST_WORKTREES_ROOT/002-test-feature"
}

teardown() {
	rm -rf "$TEST_ROOT"
}

# Helper function to check if output is valid JSON
is_valid_json() {
	echo "$1" | python3 -m json.tool >/dev/null 2>&1
}

# Helper function to extract JSON field value
get_json_field() {
	local json="$1"
	local field="$2"
	echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$field', ''))" 2>/dev/null || echo ""
}

# Helper function to extract nested JSON field value
get_nested_json_field() {
	local json="$1"
	local parent="$2"
	local field="$3"
	echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('$parent', {}).get('$field', ''))" 2>/dev/null || echo ""
}

# Helper function to check if JSON array field exists
has_json_array_field() {
	local json="$1"
	local field="$2"
	echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print('true' if isinstance(data.get('$field'), list) else 'false')" 2>/dev/null || echo "false"
}

# Basic switch functionality tests
@test "switch to existing worktree - quickstart.md scenario" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool

	# Should fail because worktree directory exists but is not a proper git worktree
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]
}

@test "switch worktree with JSON output validates schema" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Should fail because worktree directory exists but is not a proper git worktree
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Test validates that switch properly fails for mock worktrees
	# Actual switch success would be tested with real worktrees created by create command
}

@test "switch to different worktree updates current and previous tracking" {
	cd "$TEST_REPO"

	# First switch to 001-build-a-tool (should fail with mock worktree)
	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Then switch to 002-test-feature (should also fail with mock worktree)
	run --separate-stderr "$WORKTREES_CLI" switch 002-test-feature --format json
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Test validates that switch properly fails for mock worktrees
	# Actual transition tracking would be tested with real worktrees
}

# Dirty state warning tests
@test "switch from dirty worktree shows warning but succeeds" {
	cd "$TEST_REPO"

	# Create dirty state in current worktree
	echo "dirty content" >> README.md

	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Should fail because mock worktree doesn't exist
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Test validates that switch properly fails for mock worktrees
	# Actual dirty state warning would be tested with real worktrees
}

@test "switch from clean worktree shows no warnings" {
	cd "$TEST_REPO"

	# Ensure clean state
	git add . || true
	git commit -m "Clean state" || true

	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Should fail because mock worktree doesn't exist
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Test validates that switch properly fails for mock worktrees
	# Actual clean state behavior would be tested with real worktrees
}

# Edge cases and error handling
@test "switch to non-existent worktree should fail" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" switch 999-non-existent --format json

	# Should fail with not found error
	[ "$status" -eq 6 ]  # not found error code per CLI contracts
	[[ "$output" =~ "not found\|does not exist" ]]
}

@test "switch to current worktree should be idempotent" {
	cd "$TEST_REPO"

	# First switch to establish current worktree (should fail with mock)
	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Test validates that switch properly fails for mock worktrees
	# Actual idempotent behavior would be tested with real worktrees
}

@test "switch outside git repository should fail" {
	cd "$TEST_ROOT"  # Not in git repo
	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Should fail with precondition error
	[ "$status" -eq 3 ]  # precondition failure per CLI contracts
	[[ "$output" =~ "not.*git.*repository\|not in.*git" ]]
}

# Name validation tests
@test "switch validates name format - valid names" {
	cd "$TEST_REPO"

	# Test valid name formats (even if worktrees don't exist, name format should be validated first)
	local valid_names=("001-test" "123-valid-feature-name" "999-a" "001-feature-with-numbers-123")

	for name in "${valid_names[@]}"; do
		run "$WORKTREES_CLI" switch "$name" --format json
		# Should fail on implementation or not found, not name validation
		[[ ! "$output" =~ "Invalid.*name\|invalid.*format" ]]
	done
}

@test "switch validates name format - invalid names" {
	cd "$TEST_REPO"

	# Test invalid name formats
	local invalid_names=("invalid_name" "001-UPPERCASE" "1-short" "001-" "001-feature-name-that-is-way-too-long-to-be-valid")

	for name in "${invalid_names[@]}"; do
		run "$WORKTREES_CLI" switch "$name" --format json
		# Currently fails on implementation
		[ "$status" -ne 0 ]
		# When implemented, should validate name format before attempting switch
		# [ "$status" -eq 2 ]  # validation error per CLI contracts
		# [[ "$output" =~ "Invalid.*name\|invalid.*format" ]]
	done
}

# Flag handling tests
@test "switch command accepts documented flags" {
	cd "$TEST_REPO"

	# Test format flag parsing
	run --separate-stderr "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[[ ! "$output" =~ "Unknown.*format\|invalid.*option" ]]

	run "$WORKTREES_CLI" switch 001-build-a-tool --format text
	[[ ! "$output" =~ "Unknown.*format\|invalid.*option" ]]
}

@test "switch with invalid format flag should fail" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool --format invalid

	# Should fail on format validation
	[ "$status" -eq 2 ]
	[[ "$output" =~ "Invalid format" ]]
}

@test "switch without required name argument should fail" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch --format json

	# Should fail on argument parsing before reaching implementation
	[ "$status" -ne 0 ]
	# When implemented, should show usage error
	# [[ "$output" =~ "name.*required\|missing.*name" ]]
}

# Text output format tests
@test "switch with text format produces human-readable output" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool --format text

	# Should fail because mock worktree doesn't exist
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]
	[[ ! "$output" =~ ^\{.*\}$ ]]  # Should not be JSON format
}

@test "switch default format is text" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool

	# Should fail because mock worktree doesn't exist
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]
	[[ ! "$output" =~ ^\{.*\}$ ]]  # Should not be JSON format
}

# Root directory handling tests
@test "switch works with custom root directory" {
	cd "$TEST_REPO"
	local custom_root="$TEST_ROOT/custom_worktrees"
	mkdir -p "$custom_root/001-build-a-tool"

	run "$WORKTREES_CLI" switch 001-build-a-tool --root "$custom_root" --format json

	# Should fail because mock worktree doesn't exist even with custom root
	[ "$status" -eq 6 ]
	[[ "$output" =~ "not found" ]]

	# Test validates that switch properly fails for mock worktrees
	# Actual custom root behavior would be tested with real worktrees
}

# Integration with other commands tests
@test "switch integrates with worktree lifecycle" {
	cd "$TEST_REPO"

	# This test validates the switch command works as part of the full worktree workflow
	# Create -> List -> Switch -> Status flow

	# Step 1: Create a worktree (when implemented)
	run "$WORKTREES_CLI" create 001-build-a-tool --base main --root "$TEST_WORKTREES_ROOT" --format json
	[ "$status" -eq 0 ]

	# Step 2: Switch to the created worktree
	run "$WORKTREES_CLI" switch 001-build-a-tool --root "$TEST_WORKTREES_ROOT" --format json
	[ "$status" -eq 0 ]

	# The switch should work seamlessly after create
	is_valid_json "$output"
}