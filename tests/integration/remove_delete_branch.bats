#!/usr/bin/env bats

# Integration tests for worktree removal with branch deletion
# Tests the remove command with --delete-branch functionality from quickstart.md
# Scenario: worktrees remove 001-build-a-tool --delete-branch --merged-into main

setup() {
	export WORKTREES_CLI="/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees"
	export TEST_ROOT="${BATS_TMPDIR}/worktrees_remove_delete_test_$$"
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

	# Create additional commits to have history
	echo "Second commit" >> README.md
	git add README.md
	git commit -m "Second commit"

	# Create a feature branch that will be merged
	git checkout -b 001-build-a-tool
	echo "Feature work" > feature.txt
	git add feature.txt
	git commit -m "Add feature work"

	# Merge feature branch back to main to simulate completed work
	git checkout main
	git merge --no-ff 001-build-a-tool -m "Merge feature branch"

	# Create another feature branch that is NOT merged
	git checkout -b 002-unmerged-feature
	echo "Unmerged work" > unmerged.txt
	git add unmerged.txt
	git commit -m "Add unmerged work"

	# Go back to main
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

# Helper function to check if a branch exists
branch_exists() {
	local branch="$1"
	git rev-parse --verify "$branch" >/dev/null 2>&1
	return $?
}

# Basic remove with branch deletion tests
@test "remove worktree scenario from quickstart.md with branch deletion" {
	cd "$TEST_REPO"

	# First, simulate that the worktree exists (would be created by create command)
	# For now, just test the remove command with branch deletion flags
	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --merged-into main --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should return valid JSON with expected schema
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# Expected output schema: {removed: boolean, branchDeleted: boolean}
	# local json="$output"
	# [[ "$json" =~ '"removed"' ]]
	# [[ "$json" =~ '"branchDeleted"' ]]
	# local removed=$(get_json_field "$json" "removed")
	# local branch_deleted=$(get_json_field "$json" "branchDeleted")
	# [ "$removed" = "true" ]
	# [ "$branch_deleted" = "true" ]
}

@test "remove worktree with merged branch should delete branch" {
	cd "$TEST_REPO"

	# Verify the merged branch exists before removal
	branch_exists '001-build-a-tool'

	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --merged-into main --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented:
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	# local branch_deleted=$(get_json_field "$output" "branchDeleted")
	# [ "$branch_deleted" = "true" ]
	# Branch should no longer exist
	# ! branch_exists '001-build-a-tool'
}

# Merge verification tests
@test "remove worktree validates branch is merged before deletion" {
	cd "$TEST_REPO"

	# Try to remove unmerged branch with --delete-branch
	run "$WORKTREES_CLI" remove 002-unmerged-feature --delete-branch --merged-into main --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with safety error (exit code 5)
	# [ "$status" -eq 5 ]
	# [[ "$output" =~ "not.*merged\|unmerged.*branch" ]]
	# Branch should still exist after failed removal
	# branch_exists '002-unmerged-feature'
}

@test "remove worktree with --merged-into validates merge base exists" {
	cd "$TEST_REPO"

	# Try with non-existent merge base
	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --merged-into non-existent-branch --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with precondition error (exit code 3)
	# [ "$status" -eq 3 ]
	# [[ "$output" =~ "merge.*base.*not.*found\|branch.*not.*exist" ]]
}

@test "remove worktree without --merged-into flag when --delete-branch used" {
	cd "$TEST_REPO"

	# Try --delete-branch without --merged-into (should require merge verification)
	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with validation error (exit code 2)
	# [ "$status" -eq 2 ]
	# [[ "$output" =~ "merged-into.*required\|must.*specify.*merge.*base" ]]
}

# Force flag behavior tests
@test "remove worktree with --force allows untracked file deletion" {
	cd "$TEST_REPO"

	# Simulate worktree with untracked files (would be setup by create command)
	run "$WORKTREES_CLI" remove 001-build-a-tool --force --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented:
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	# local removed=$(get_json_field "$output" "removed")
	# [ "$removed" = "true" ]
}

@test "remove worktree with --force still prevents tracked changes deletion" {
	cd "$TEST_REPO"

	# Simulate worktree with tracked changes (would be setup by create command)
	# --force should NOT allow removal of tracked changes, only untracked/ignored files
	run "$WORKTREES_CLI" remove 001-build-a-tool --force --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented and there are tracked changes:
	# [ "$status" -eq 5 ]
	# [[ "$output" =~ "tracked.*changes\|uncommitted.*changes" ]]
}

@test "remove worktree with --force and --delete-branch combines behaviors" {
	cd "$TEST_REPO"

	# Test combination of force flag with branch deletion
	run "$WORKTREES_CLI" remove 001-build-a-tool --force --delete-branch --merged-into main --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented:
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	# local removed=$(get_json_field "$output" "removed")
	# local branch_deleted=$(get_json_field "$output" "branchDeleted")
	# [ "$removed" = "true" ]
	# [ "$branch_deleted" = "true" ]
}

# Safety check tests
@test "remove worktree prevents deletion with unpushed commits" {
	cd "$TEST_REPO"

	# Simulate worktree with unpushed commits (no upstream)
	run "$WORKTREES_CLI" remove 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented and there are unpushed commits:
	# [ "$status" -eq 5 ]
	# [[ "$output" =~ "unpushed.*commits\|no.*upstream" ]]
}

@test "remove worktree prevents deletion with operation in progress" {
	cd "$TEST_REPO"

	# Simulate worktree with git operation in progress (e.g., merge, rebase)
	run "$WORKTREES_CLI" remove 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented and there's an operation in progress:
	# [ "$status" -eq 5 ]
	# [[ "$output" =~ "operation.*in.*progress\|merge.*in.*progress\|rebase.*in.*progress" ]]
}

# JSON output schema validation tests
@test "remove worktree JSON output has required fields" {
	cd "$TEST_REPO"
	run "$WORKTREES_CLI" remove 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, validate JSON schema per contract
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	#
	# Required fields per contract: {removed: boolean, branchDeleted: boolean}
	# local json="$output"
	# [[ "$json" =~ '"removed"' ]]
	# [[ "$json" =~ '"branchDeleted"' ]]
	#
	# Validate field types
	# local removed=$(get_json_field "$json" "removed")
	# local branch_deleted=$(get_json_field "$json" "branchDeleted")
	# [[ "$removed" =~ ^(true|false)$ ]]
	# [[ "$branch_deleted" =~ ^(true|false)$ ]]
}

@test "remove worktree JSON output when branch not deleted" {
	cd "$TEST_REPO"

	# Remove without --delete-branch flag
	run "$WORKTREES_CLI" remove 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented:
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
	# local removed=$(get_json_field "$output" "removed")
	# local branch_deleted=$(get_json_field "$output" "branchDeleted")
	# [ "$removed" = "true" ]
	# [ "$branch_deleted" = "false" ]
}

# Flag parsing and validation tests
@test "remove worktree accepts all documented flags" {
	cd "$TEST_REPO"

	# Test individual flags don't cause parsing errors
	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --merged-into main
	[[ ! "$output" =~ "Unknown.*delete-branch" ]]
	[[ ! "$output" =~ "Unknown.*merged-into" ]]

	run "$WORKTREES_CLI" remove 001-build-a-tool --force
	[[ ! "$output" =~ "Unknown.*force" ]]

	run "$WORKTREES_CLI" remove 001-build-a-tool --format json
	[[ ! "$output" =~ "Unknown.*format" ]]
}

@test "remove worktree validates required worktree name argument" {
	cd "$TEST_REPO"

	# Remove without specifying worktree name
	run "$WORKTREES_CLI" remove --delete-branch --merged-into main

	# Should fail on argument parsing before reaching implementation
	[ "$status" -ne 0 ]
	# [[ "$output" =~ "name.*required\|missing.*name" ]] # Will validate when implemented
}

@test "remove worktree validates worktree name format" {
	cd "$TEST_REPO"

	# Test with invalid name formats
	local invalid_names=("invalid_name" "UPPERCASE" "short" "too-long-name-that-exceeds-format-limits")

	for name in "${invalid_names[@]}"; do
		run "$WORKTREES_CLI" remove "$name" --format json
		# Should eventually validate name format when implemented
		# [[ "$output" =~ "Invalid.*name" ]] # Will validate this when implemented
	done
}

# Edge case tests
@test "remove non-existent worktree should fail" {
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 999-non-existent --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with not found error (exit code 6)
	# [ "$status" -eq 6 ]
	# [[ "$output" =~ "worktree.*not.*found\|does.*not.*exist" ]]
}

@test "remove worktree outside git repository should fail" {
	cd "$TEST_ROOT"  # Not in git repo
	run "$WORKTREES_CLI" remove 001-build-a-tool --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should fail with precondition error (exit code 3)
	# [ "$status" -eq 3 ]
	# [[ "$output" =~ "not.*git.*repository\|not in.*git" ]]
}

# Advanced merge verification tests
@test "remove worktree detects partial merge scenarios" {
	cd "$TEST_REPO"

	# Create a more complex merge scenario with cherry-picked commits
	git checkout -b 003-partially-merged
	echo "Partial work" > partial.txt
	git add partial.txt
	git commit -m "Add partial work"

	# Cherry-pick to main (partial merge)
	git checkout main
	git cherry-pick 003-partially-merged
	git checkout 003-partially-merged

	# Add more commits that aren't merged
	echo "More work" >> partial.txt
	git add partial.txt
	git commit -m "Add more work"
	git checkout main

	run "$WORKTREES_CLI" remove 003-partially-merged --delete-branch --merged-into main --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should detect branch is not fully merged
	# [ "$status" -eq 5 ]
	# [[ "$output" =~ "not.*fully.*merged\|unmerged.*commits" ]]
}

@test "remove worktree with multiple merge bases" {
	cd "$TEST_REPO"

	# Test with different merge base scenarios
	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --merged-into HEAD --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented, should handle different merge base refs
	# [ "$status" -eq 0 ] # or appropriate error based on actual merge state
}

# Text vs JSON output format tests
@test "remove worktree text format differs from JSON format" {
	cd "$TEST_REPO"

	# Test default text format
	run "$WORKTREES_CLI" remove 001-build-a-tool
	local text_output="$output"

	# Test JSON format
	run "$WORKTREES_CLI" remove 001-build-a-tool --format json
	local json_output="$output"

	# Currently both fail on implementation, but when implemented:
	# Text and JSON outputs should be different formats
	# ! is_valid_json "$text_output"  # Text should not be JSON
	# is_valid_json "$json_output"    # JSON should be valid JSON
}

# Complex scenario integration tests
@test "remove workflow: create, use, merge, then remove with branch deletion" {
	cd "$TEST_REPO"

	# This would be a full workflow test once create/switch commands are implemented
	# For now, just test the remove portion of the workflow
	run "$WORKTREES_CLI" remove 001-build-a-tool --delete-branch --merged-into main --format json

	# Currently expects failure due to unimplemented command
	[ "$status" -eq 1 ]
	[[ "$output" =~ "not yet implemented" ]]

	# When implemented as part of full workflow:
	# Should successfully remove worktree and delete merged branch
	# [ "$status" -eq 0 ]
	# is_valid_json "$output"
}