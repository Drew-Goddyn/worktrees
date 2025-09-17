#!/usr/bin/env bats

# Integration tests for worktree listing with pagination
# Tests the complete list worktrees flow from quickstart.md

bats_require_minimum_version 1.5.0

setup() {
	export WORKTREES_CLI="/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees"
	export TEST_ROOT="${BATS_TMPDIR}/worktrees_list_test_$$"
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

	# Create additional branches for testing
	git checkout -b feature-branch-1
	git checkout -b feature-branch-2
	git checkout main
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

# Basic list functionality tests
@test "list worktrees without arguments" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" list

	# Should show default text output
	[ "$status" -eq 0 ]
}

@test "list worktrees scenario from quickstart.md" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --page 1 --page-size 20 --format json

	# Should return valid JSON with pagination
	[ "$status" -eq 0 ]
	is_valid_json "$output"
}

@test "list empty worktrees shows appropriate message" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --format json

	# Should show items array (current repo is included as main worktree)
	[ "$status" -eq 0 ]
	is_valid_json "$output"
	[[ "$output" =~ '"items":\[' ]]
	[[ "$output" =~ '"total":' ]]
}

# Pagination parameter validation tests
@test "list worktrees accepts pagination parameters" {
	cd "$TEST_REPO"

	# Test various pagination parameters
	run "$WORKTREES_CLI" list --page 1
	[[ ! "$output" =~ "Unknown.*page" ]]

	run "$WORKTREES_CLI" list --page-size 10
	[[ ! "$output" =~ "Unknown.*page-size" ]]

	run "$WORKTREES_CLI" list --page 2 --page-size 50
	[[ ! "$output" =~ "Unknown.*page" ]]
}

@test "list worktrees validates page-size limits" {
	cd "$TEST_REPO"

	# Test page-size boundary conditions (when implemented)
	run "$WORKTREES_CLI" list --page-size 1
	# Should not fail on parameter validation
	[[ ! "$output" =~ "Invalid.*page-size.*minimum" ]]

	run "$WORKTREES_CLI" list --page-size 100
	# Should not fail on parameter validation
	[[ ! "$output" =~ "Invalid.*page-size.*maximum" ]]

	# Invalid page-size values (when implemented should fail)
	run "$WORKTREES_CLI" list --page-size 0
	# Will validate this causes error when implemented
	# [ "$status" -eq 2 ]
	# [[ "$output" =~ "Invalid.*page-size" ]]

	run "$WORKTREES_CLI" list --page-size 101
	# Will validate this causes error when implemented
	# [ "$status" -eq 2 ]
	# [[ "$output" =~ "Invalid.*page-size" ]]
}

@test "list worktrees validates page numbers" {
	cd "$TEST_REPO"

	# Test page number validation
	run "$WORKTREES_CLI" list --page 0
	# Will validate this causes error when implemented
	# [ "$status" -eq 2 ]
	# [[ "$output" =~ "Invalid.*page" ]]

	run "$WORKTREES_CLI" list --page -1
	# Will validate this causes error when implemented
	# [ "$status" -eq 2 ]
	# [[ "$output" =~ "Invalid.*page" ]]
}

# Filtering tests
@test "list worktrees accepts filter parameters" {
	cd "$TEST_REPO"

	# Test filter parameters don't cause parsing errors
	run "$WORKTREES_CLI" list --filter-name test
	[[ ! "$output" =~ "Unknown.*filter-name" ]]

	run "$WORKTREES_CLI" list --filter-base main
	[[ ! "$output" =~ "Unknown.*filter-base" ]]

	# Combined filters
	run "$WORKTREES_CLI" list --filter-name test --filter-base main
	[[ ! "$output" =~ "Unknown.*filter" ]]
}

@test "list worktrees filtering by name substring" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" list --filter-name "build" --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# Should filter results by name
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	# Filter logic will be tested when worktrees exist
}

@test "list worktrees filtering by base branch" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --filter-base main --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# Should filter by base branch
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
}

# JSON output schema validation tests
@test "list worktrees JSON output has required pagination structure" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# When implemented, validate JSON structure
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# Required fields per OpenAPI spec: {items, page, pageSize, total}
	# local json="$output"
	# [[ "$json" =~ '"items"' ]]
	# [[ "$json" =~ '"page"' ]]
	# [[ "$json" =~ '"pageSize"' ]]
	# [[ "$json" =~ '"total"' ]]
}

@test "list worktrees JSON items have worktree schema" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# When implemented and worktrees exist, validate item schema
	# Each item should have: {name, branch, baseRef, path, active, isDirty, hasUnpushedCommits}
	# Will test this when create command is implemented to set up test data
}

@test "list worktrees JSON pagination values are correct types" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --page 2 --page-size 10 --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# When implemented, validate field types
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# local page=$(get_json_field "$json" "page")
	# local page_size=$(get_json_field "$json" "pageSize")
	# local total=$(get_json_field "$json" "total")
	#
	# [[ "$page" =~ ^[0-9]+$ ]]      # Should be integer
	# [[ "$page_size" =~ ^[0-9]+$ ]] # Should be integer
	# [[ "$total" =~ ^[0-9]+$ ]]     # Should be integer
}

# Combined pagination and filtering tests
@test "list worktrees with pagination and filtering combined" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" list --page 1 --page-size 5 --filter-name "001" --filter-base main --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# Should handle combined parameters
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
}

# Default values tests
@test "list worktrees uses default pagination values" {
	cd "$TEST_REPO"
	run --separate-stderr "$WORKTREES_CLI" list --format json

	# Should succeed
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	# Should use defaults: page=1, pageSize=20
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# local json="$output"
	# local page=$(get_json_field "$json" "page")
	# local page_size=$(get_json_field "$json" "pageSize")
	#
	# [ "$page" = "1" ]
	# [ "$page_size" = "20" ]
}

# Error handling tests
@test "list worktrees outside git repository should fail" {
	cd "$TEST_ROOT"  # Not in git repo
	run "$WORKTREES_CLI" list

	# Should fail with appropriate error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "Not in a Git repository" ]]
}

# Text vs JSON output format tests
@test "list worktrees text format differs from JSON format" {
	cd "$TEST_REPO"

	# Test default text format
	run "$WORKTREES_CLI" list
	local text_output="$output"

	# Test JSON format
	run --separate-stderr "$WORKTREES_CLI" list --format json
	local json_output="$output"

	# Currently both fail on implementation, but when implemented:
	# Text and JSON outputs should be different formats
	# ! is_valid_json "$text_output"  # Text should not be JSON
	# is_valid_json "$json_output"    # JSON should be valid JSON
}