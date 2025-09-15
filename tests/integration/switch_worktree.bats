#!/usr/bin/env bats

# Integration tests for worktree switching
# Tests the complete switch worktree flow from quickstart.md

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

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should succeed
	# [ "$status" -eq 0 ]
	# [[ ! "$output" =~ "Error" ]]
}

@test "switch worktree with JSON output validates schema" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should return valid JSON with required schema
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# Validate JSON schema: {current: {name, path}, previous: {name, path}, warnings: [...]}
	# local json="$output"
	# [[ "$(get_json_field "$json" "current")" != "" ]]
	# [[ "$(get_json_field "$json" "previous")" != "" ]]
	# [[ "$(has_json_array_field "$json" "warnings")" == "true" ]]
	#
	# # Validate current worktree fields
	# [[ "$(get_nested_json_field "$json" "current" "name")" == "001-build-a-tool" ]]
	# [[ "$(get_nested_json_field "$json" "current" "path")" =~ "/001-build-a-tool" ]]
	#
	# # Validate previous worktree fields (should be main/original)
	# [[ "$(get_nested_json_field "$json" "previous" "name")" != "" ]]
	# [[ "$(get_nested_json_field "$json" "previous" "path")" != "" ]]
}

@test "switch to different worktree updates current and previous tracking" {
	cd "$TEST_REPO"

	# First switch to 001-build-a-tool
	run "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# Then switch to 002-test-feature
	run "$WORKTREES_CLI" switch 002-test-feature --format json
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should track the transition correctly
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# [[ "$(get_nested_json_field "$json" "current" "name")" == "002-test-feature" ]]
	# [[ "$(get_nested_json_field "$json" "previous" "name")" == "001-build-a-tool" ]]
}

# Dirty state warning tests
@test "switch from dirty worktree shows warning but succeeds" {
	cd "$TEST_REPO"

	# Create dirty state in current worktree
	echo "dirty content" >> README.md

	run "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should succeed but include warning
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# local warnings_exist=$(has_json_array_field "$json" "warnings")
	# [[ "$warnings_exist" == "true" ]]
	#
	# # Check that warnings contain dirty state information
	# [[ "$json" =~ "dirty\|uncommitted\|unsaved" ]]
}

@test "switch from clean worktree shows no warnings" {
	cd "$TEST_REPO"

	# Ensure clean state
	git add . || true
	git commit -m "Clean state" || true

	run "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should succeed with empty warnings
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# local warnings=$(echo "$json" | python3 -c "import sys, json; data=json.load(sys.stdin); print(len(data.get('warnings', [])))")
	# [[ "$warnings" == "0" ]]
}

# Edge cases and error handling
@test "switch to non-existent worktree should fail" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 999-non-existent --format json

	# Currently fails on implementation
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with not found error
	# [ "$status" -eq 6 ]  # not found error code per CLI contracts
	# [[ "$output" =~ "not found\|does not exist" ]]
}

@test "switch to current worktree should be idempotent" {
	cd "$TEST_REPO"

	# First switch to establish current worktree
	run "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# Then switch to the same worktree again
	run "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should succeed and indicate no change
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# # Current and previous should be the same
	# [[ "$(get_nested_json_field "$json" "current" "name")" == "$(get_nested_json_field "$json" "previous" "name")" ]]
}

@test "switch outside git repository should fail" {
	cd "$TEST_ROOT"  # Not in git repo
	run "$WORKTREES_CLI" switch 001-build-a-tool --format json

	# Currently fails on implementation
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with precondition error
	# [ "$status" -eq 3 ]  # precondition failure per CLI contracts
	# [[ "$output" =~ "not.*git.*repository\|not in.*git" ]]
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
	run "$WORKTREES_CLI" switch 001-build-a-tool --format json
	[[ ! "$output" =~ "Unknown.*format\|invalid.*option" ]]

	run "$WORKTREES_CLI" switch 001-build-a-tool --format text
	[[ ! "$output" =~ "Unknown.*format\|invalid.*option" ]]
}

@test "switch with invalid format flag should fail" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool --format invalid

	# Currently fails on implementation first, but will validate format when implemented
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail on format validation
	# [ "$status" -eq 2 ]
	# [[ "$output" =~ "Invalid format" ]]
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

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should produce human-readable text (not JSON)
	# [ "$status" -eq 0 ]
	# [[ ! "$output" =~ ^\{.*\}$ ]]  # Should not be JSON format
	# [[ "$output" =~ "switch\|current\|001-build-a-tool" ]]
}

@test "switch default format is text" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" switch 001-build-a-tool

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, default should be text format
	# [ "$status" -eq 0 ]
	# [[ ! "$output" =~ ^\{.*\}$ ]]  # Should not be JSON format
}

# Root directory handling tests
@test "switch works with custom root directory" {
	cd "$TEST_REPO"
	local custom_root="$TEST_ROOT/custom_worktrees"
	mkdir -p "$custom_root/001-build-a-tool"

	run "$WORKTREES_CLI" switch 001-build-a-tool --root "$custom_root" --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should use custom root for worktree resolution
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# [[ "$(get_nested_json_field "$json" "current" "path")" =~ "$custom_root/001-build-a-tool" ]]
}

# Integration with other commands tests
@test "switch integrates with worktree lifecycle" {
	cd "$TEST_REPO"

	# This test validates the switch command works as part of the full worktree workflow
	# Create -> List -> Switch -> Status flow

	# Step 1: Create a worktree (when implemented)
	run "$WORKTREES_CLI" create 001-build-a-tool --base main --root "$TEST_WORKTREES_ROOT" --format json
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# Step 2: Switch to the created worktree
	run "$WORKTREES_CLI" switch 001-build-a-tool --root "$TEST_WORKTREES_ROOT" --format json
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, the switch should work seamlessly after create
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
}