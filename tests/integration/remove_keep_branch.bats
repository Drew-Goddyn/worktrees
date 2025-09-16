#!/usr/bin/env bats

# Integration tests for remove worktree (keep branch)
# Tests the complete remove worktree flow from quickstart.md: "worktrees remove 001-build-a-tool"

bats_require_minimum_version 1.5.0

setup() {
	export WORKTREES_CLI="/Users/drewgoddyn/projects/claude-worktrees/src/cli/worktrees"
	export TEST_ROOT="${BATS_TMPDIR}/worktrees_remove_test_$$"
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
	echo "Feature 1 content" > feature1.txt
	git add feature1.txt
	git commit -m "Add feature 1"
	git checkout main

	git checkout -b feature-branch-2
	echo "Feature 2 content" > feature2.txt
	git add feature2.txt
	git commit -m "Add feature 2"
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

# Helper function to simulate worktree directory (since create isn't implemented yet)
create_mock_worktree() {
	local name="$1"
	local worktree_path="$TEST_WORKTREES_ROOT/$name"
	mkdir -p "$worktree_path"

	# Initialize as git worktree (simplified mock)
	cd "$worktree_path"
	git init --quiet
	echo "Mock worktree content" > mock_file.txt
	git add mock_file.txt
	git commit -m "Mock worktree commit" --quiet

	cd "$TEST_REPO"
}

# Basic removal flow tests
@test "remove worktree with valid name" {
	cd "$TEST_REPO"

	# Mock a worktree directory since create isn't implemented
	create_mock_worktree "001-build-a-tool"

	run "$WORKTREES_CLI" remove 001-build-a-tool --root "$TEST_WORKTREES_ROOT"

	# Should succeed and remove worktree directory
	[ "$status" -eq 0 ]
	[ ! -d "$TEST_WORKTREES_ROOT/001-build-a-tool" ]
}

@test "remove worktree scenario from quickstart.md" {
	cd "$TEST_REPO"

	# Mock the specific worktree from quickstart example
	create_mock_worktree "001-build-a-tool"

	run "$WORKTREES_CLI" remove 001-build-a-tool

	# Should succeed
	[ "$status" -eq 0 ]
	[ ! -d "$TEST_WORKTREES_ROOT/001-build-a-tool" ]
}

@test "remove worktree keeps branch by default" {
	cd "$TEST_REPO"

	# Create branch and mock worktree
	git checkout -b 001-test-feature
	git checkout main
	create_mock_worktree "001-test-feature"

	run "$WORKTREES_CLI" remove 001-test-feature --root "$TEST_WORKTREES_ROOT"

	# Should remove worktree but keep branch
	[ "$status" -eq 0 ]
	[ ! -d "$TEST_WORKTREES_ROOT/001-test-feature" ]
	git branch | grep -q "001-test-feature"  # Branch should still exist
}

# JSON output validation tests
@test "remove worktree JSON output has required fields" {
	cd "$TEST_REPO"
	create_mock_worktree "001-test-feature"

	run --separate-stderr "$WORKTREES_CLI" remove 001-test-feature --format json --root "$TEST_WORKTREES_ROOT"

	# Validate JSON schema: {removed: boolean, branchDeleted: boolean}
	[ "$status" -eq 0 ]
	is_valid_json "$output"

	local removed=$(get_json_field "$output" "removed")
	local branch_deleted=$(get_json_field "$output" "branchDeleted")
	[ "$removed" = "true" ]
	[ "$branch_deleted" = "false" ]  # Default behavior keeps branch
}

@test "remove worktree JSON boolean fields are proper booleans" {
	cd "$TEST_REPO"
	create_mock_worktree "001-test-feature"

	run --separate-stderr "$WORKTREES_CLI" remove 001-test-feature --format json --root "$TEST_WORKTREES_ROOT"

	# Ensure boolean values are not strings
	[ "$status" -eq 0 ]
	is_valid_json "$output"
	[[ "$output" =~ '"removed":[[:space:]]*true' ]]
	[[ "$output" =~ '"branchDeleted":[[:space:]]*false' ]]
	[[ ! "$output" =~ '"removed":[[:space:]]*"true"' ]]  # Should not be string
}

# Safety check tests - dirty worktree
@test "remove worktree with uncommitted changes should fail" {
	cd "$TEST_REPO"
	create_mock_worktree "001-dirty-feature"

	# Simulate dirty worktree by adding uncommitted files
	echo "Uncommitted changes" > "$TEST_WORKTREES_ROOT/001-dirty-feature/dirty_file.txt"

	run "$WORKTREES_CLI" remove 001-dirty-feature --root "$TEST_WORKTREES_ROOT"

	# Should fail with precondition error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "uncommitted.*changes\|dirty.*worktree" ]]
	[ -d "$TEST_WORKTREES_ROOT/001-dirty-feature" ]  # Should not be removed
}

@test "remove worktree with staged but uncommitted changes should fail" {
	cd "$TEST_REPO"
	create_mock_worktree "001-staged-feature"

	# Simulate staged changes in worktree
	cd "$TEST_WORKTREES_ROOT/001-staged-feature"
	echo "Staged changes" > staged_file.txt
	git add staged_file.txt
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 001-staged-feature --root "$TEST_WORKTREES_ROOT"

	# Should fail with precondition error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "staged.*changes\|uncommitted.*changes" ]]
	[ -d "$TEST_WORKTREES_ROOT/001-staged-feature" ]  # Should not be removed
}

# Safety check tests - unpushed commits
@test "remove worktree with unpushed commits should fail" {
	cd "$TEST_REPO"
	create_mock_worktree "001-unpushed-feature"

	# Simulate unpushed commits (no upstream tracking)
	cd "$TEST_WORKTREES_ROOT/001-unpushed-feature"
	echo "Unpushed commit" > unpushed_file.txt
	git add unpushed_file.txt
	git commit -m "Unpushed commit" --quiet
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 001-unpushed-feature --root "$TEST_WORKTREES_ROOT"

	# Should fail with precondition error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "unpushed.*commits\|no.*upstream" ]]
	[ -d "$TEST_WORKTREES_ROOT/001-unpushed-feature" ]  # Should not be removed
}

# Safety check tests - operations in progress
@test "remove worktree with merge in progress should fail" {
	cd "$TEST_REPO"
	create_mock_worktree "001-merge-feature"

	# Simulate merge in progress (create .git/MERGE_HEAD file)
	mkdir -p "$TEST_WORKTREES_ROOT/001-merge-feature/.git"
	echo "dummy merge head" > "$TEST_WORKTREES_ROOT/001-merge-feature/.git/MERGE_HEAD"

	run "$WORKTREES_CLI" remove 001-merge-feature --root "$TEST_WORKTREES_ROOT"

	# Should fail with precondition error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "operation.*progress\|merge.*progress" ]]
	[ -d "$TEST_WORKTREES_ROOT/001-merge-feature" ]  # Should not be removed
}

@test "remove worktree with rebase in progress should fail" {
	cd "$TEST_REPO"
	create_mock_worktree "001-rebase-feature"

	# Simulate rebase in progress (create .git/rebase-merge directory)
	mkdir -p "$TEST_WORKTREES_ROOT/001-rebase-feature/.git/rebase-merge"

	run "$WORKTREES_CLI" remove 001-rebase-feature --root "$TEST_WORKTREES_ROOT"

	# Should fail with precondition error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "operation.*progress\|rebase.*progress" ]]
	[ -d "$TEST_WORKTREES_ROOT/001-rebase-feature" ]  # Should not be removed
}

# Edge case tests
@test "remove non-existent worktree should fail" {
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 999-non-existent --root "$TEST_WORKTREES_ROOT"

	# Should fail with not found error
	[ "$status" -eq 2 ]
	[[ "$output" =~ "not found\|does not exist" ]]
}

@test "remove worktree with invalid name format" {
	cd "$TEST_REPO"

	# Test various invalid name formats
	local invalid_names=("invalid_name" "UPPERCASE" "001-" "toolong-feature-name-that-exceeds-character-limits")

	for name in "${invalid_names[@]}"; do
		run "$WORKTREES_CLI" remove "$name" --root "$TEST_WORKTREES_ROOT"

		# Should validate name format
		[ "$status" -ne 0 ]
		[[ "$output" =~ "Invalid.*name" ]]
	done
}

@test "remove worktree outside git repository should fail" {
	cd "$TEST_ROOT"  # Not in git repo

	run "$WORKTREES_CLI" remove 001-test-feature --root "$TEST_WORKTREES_ROOT"

	# Should fail with appropriate error
	[ "$status" -eq 3 ]
	[[ "$output" =~ "not.*git.*repository\|not in.*git" ]]
}

@test "remove worktree without required name argument" {
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove --root "$TEST_WORKTREES_ROOT"

	# Should fail on argument parsing before reaching implementation
	[ "$status" -ne 0 ]
	# [[ "$output" =~ "name.*required\|missing.*name" ]]  # Will validate when implemented
}

# Custom root directory tests
@test "remove worktree with custom root directory" {
	cd "$TEST_REPO"
	local custom_root="$TEST_ROOT/custom_worktrees"
	mkdir -p "$custom_root"

	# Mock worktree in custom root
	create_mock_worktree "001-custom-feature"
	mv "$TEST_WORKTREES_ROOT/001-custom-feature" "$custom_root/"

	run "$WORKTREES_CLI" remove 001-custom-feature --root "$custom_root"

	# Should use custom root
	[ "$status" -eq 0 ]
	[ ! -d "$custom_root/001-custom-feature" ]
}

# Flag handling tests
@test "remove worktree accepts documented flags" {
	cd "$TEST_REPO"
	create_mock_worktree "001-test-feature"

	# Test individual flags don't cause parsing errors
	run "$WORKTREES_CLI" remove 001-test-feature --root "$TEST_WORKTREES_ROOT"
	[[ ! "$output" =~ "Unknown.*root" ]]

	run --separate-stderr "$WORKTREES_CLI" remove 001-test-feature --format json
	[[ ! "$output" =~ "Unknown.*format" ]]

	run "$WORKTREES_CLI" remove 001-test-feature --force
	[[ ! "$output" =~ "Unknown.*force" ]]
}

# Force flag behavior tests (should only allow untracked/ignored files)
@test "remove worktree with --force allows untracked files only" {
	cd "$TEST_REPO"
	create_mock_worktree "001-force-feature"

	# Add untracked file
	echo "Untracked content" > "$TEST_WORKTREES_ROOT/001-force-feature/untracked.txt"

	run "$WORKTREES_CLI" remove 001-force-feature --force --root "$TEST_WORKTREES_ROOT"

	# Should succeed with --force for untracked files
	[ "$status" -eq 0 ]
	[ ! -d "$TEST_WORKTREES_ROOT/001-force-feature" ]
}

@test "remove worktree with --force still fails on tracked changes" {
	cd "$TEST_REPO"
	create_mock_worktree "001-force-tracked-feature"

	# Add tracked but modified file
	cd "$TEST_WORKTREES_ROOT/001-force-tracked-feature"
	echo "Modified tracked content" >> mock_file.txt  # Modify existing tracked file
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 001-force-tracked-feature --force --root "$TEST_WORKTREES_ROOT"

	# Should still fail even with --force
	[ "$status" -eq 3 ]
	[[ "$output" =~ "tracked.*changes.*never.*allowed" ]]
	[ -d "$TEST_WORKTREES_ROOT/001-force-tracked-feature" ]  # Should not be removed
}

# Clean worktree removal success cases
@test "remove clean worktree succeeds" {
	cd "$TEST_REPO"
	create_mock_worktree "001-clean-feature"

	# Ensure worktree is clean (no modifications)
	cd "$TEST_WORKTREES_ROOT/001-clean-feature"
	git status --porcelain | wc -l | grep -q "^0$" || {
		# Clean up any uncommitted changes
		git reset --hard HEAD >/dev/null 2>&1
	}
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 001-clean-feature --root "$TEST_WORKTREES_ROOT"

	# Should succeed
	[ "$status" -eq 0 ]
	[ ! -d "$TEST_WORKTREES_ROOT/001-clean-feature" ]
}

@test "remove worktree with all changes committed and pushed succeeds" {
	cd "$TEST_REPO"
	create_mock_worktree "001-pushed-feature"

	# Simulate pushed worktree (create upstream tracking)
	cd "$TEST_WORKTREES_ROOT/001-pushed-feature"
	git remote add origin "$TEST_REPO" 2>/dev/null || true
	git branch --set-upstream-to=origin/main 2>/dev/null || true
	cd "$TEST_REPO"

	run "$WORKTREES_CLI" remove 001-pushed-feature --root "$TEST_WORKTREES_ROOT"

	# Should succeed
	[ "$status" -eq 0 ]
	[ ! -d "$TEST_WORKTREES_ROOT/001-pushed-feature" ]
}

# Text output format tests
@test "remove worktree text output is user-friendly" {
	cd "$TEST_REPO"
	create_mock_worktree "001-text-feature"

	run "$WORKTREES_CLI" remove 001-text-feature --root "$TEST_WORKTREES_ROOT"

	# Should provide clear text output
	[ "$status" -eq 0 ]
	[[ "$output" =~ "Removed.*worktree.*001-text-feature" ]]
	[[ "$output" =~ "Branch.*001-text-feature.*preserved" ]]
}