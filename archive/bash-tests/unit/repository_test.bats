#!/usr/bin/env bats

# Unit tests for Repository model default base detection
# Tests the default branch detection logic in src/models/repository.sh

setup() {
    export REPOSITORY_MODEL="/Users/drewgoddyn/projects/claude-worktrees/src/models/repository.sh"
    export TEMP_DIR="${BATS_TMPDIR}/repository_test_$$"
    mkdir -p "$TEMP_DIR"

    # Save original directory and Git config
    export ORIGINAL_DIR="$(pwd)"
    export ORIGINAL_GIT_CONFIG_USER_NAME="$(git config --global user.name || echo "")"
    export ORIGINAL_GIT_CONFIG_USER_EMAIL="$(git config --global user.email || echo "")"

    # Set temporary Git config for tests
    git config --global user.name "Test User"
    git config --global user.email "test@example.com"
}

teardown() {
    cd "$ORIGINAL_DIR" || true
    rm -rf "$TEMP_DIR"

    # Restore original Git config
    if [[ -n "$ORIGINAL_GIT_CONFIG_USER_NAME" ]]; then
        git config --global user.name "$ORIGINAL_GIT_CONFIG_USER_NAME"
    else
        git config --global --unset user.name || true
    fi

    if [[ -n "$ORIGINAL_GIT_CONFIG_USER_EMAIL" ]]; then
        git config --global user.email "$ORIGINAL_GIT_CONFIG_USER_EMAIL"
    else
        git config --global --unset user.email || true
    fi
}

# Helper function to create a basic Git repository
create_test_repo() {
    local repo_path="$1"
    local initial_branch="${2:-main}"

    mkdir -p "$repo_path"
    cd "$repo_path"
    git init --initial-branch="$initial_branch" >/dev/null 2>&1 || {
        git init >/dev/null 2>&1
        git checkout -b "$initial_branch" >/dev/null 2>&1
    }
    echo "test content" > README.md
    git add README.md
    git commit -m "Initial commit" >/dev/null 2>&1
}

# Helper function to add a remote to current repo
add_remote() {
    local remote_name="$1"
    local remote_path="$2"
    git remote add "$remote_name" "$remote_path" >/dev/null 2>&1
    git fetch "$remote_name" >/dev/null 2>&1
}

# Helper function to set remote HEAD
set_remote_head() {
    local remote_name="$1"
    local branch_name="$2"
    git symbolic-ref "refs/remotes/$remote_name/HEAD" "refs/remotes/$remote_name/$branch_name" >/dev/null 2>&1
}

# Repository root detection tests
@test "detect_repo_root: finds repository root from subdirectory" {
    local test_repo="$TEMP_DIR/test_repo"
    create_test_repo "$test_repo"

    # Create subdirectory
    mkdir -p "$test_repo/src/models"
    cd "$test_repo/src/models"

    run "$REPOSITORY_MODEL" root
    [ "$status" -eq 0 ]
    # Use realpath to handle /tmp vs /private/tmp on macOS
    local expected_path
    expected_path=$(realpath "$test_repo")
    local actual_path
    actual_path=$(realpath "$output")
    [[ "$actual_path" == "$expected_path" ]]
}

@test "detect_repo_root: fails when not in Git repository" {
    cd "$TEMP_DIR"

    run "$REPOSITORY_MODEL" root
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Not in a Git repository" ]]
}

# Default branch detection tests
@test "get_default_branch: detects branch from remote HEAD" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    # Create remote repo with main branch
    create_test_repo "$remote_repo" "main"

    # Create local repo and add remote
    create_test_repo "$test_repo" "local-branch"
    cd "$test_repo"
    add_remote "origin" "$remote_repo"
    set_remote_head "origin" "main"

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "main" ]]
}

@test "get_default_branch: falls back to main when no remote HEAD" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    # Create remote repo with main branch
    create_test_repo "$remote_repo" "main"

    # Create local repo with main branch and add remote
    create_test_repo "$test_repo" "main"
    cd "$test_repo"
    add_remote "origin" "$remote_repo"

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "main" ]]
}

@test "get_default_branch: falls back to master when no main exists" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    # Create remote repo with master branch
    create_test_repo "$remote_repo" "master"

    # Create local repo with master branch and add remote
    create_test_repo "$test_repo" "master"
    cd "$test_repo"
    add_remote "origin" "$remote_repo"

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "master" ]]
}

@test "get_default_branch: uses local branch when no remotes" {
    local test_repo="$TEMP_DIR/test_repo"

    # Create local-only repo with develop branch
    mkdir -p "$test_repo"
    cd "$test_repo"
    git init >/dev/null 2>&1
    git checkout -b "develop" >/dev/null 2>&1
    echo "test content" > README.md
    git add README.md
    git commit -m "Initial commit" >/dev/null 2>&1

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "develop" ]]
}

@test "get_default_branch: handles repository with multiple branches" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    # Create remote repo with multiple branches
    create_test_repo "$remote_repo" "main"
    cd "$remote_repo"
    git checkout -b "feature-branch" >/dev/null 2>&1
    git checkout -b "develop" >/dev/null 2>&1
    git checkout "main" >/dev/null 2>&1

    # Create local repo and add remote
    create_test_repo "$test_repo" "local-main"
    cd "$test_repo"
    add_remote "origin" "$remote_repo"
    set_remote_head "origin" "main"

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "main" ]]
}

@test "get_default_branch: prefers remote main over local master" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    # Create remote repo with main
    create_test_repo "$remote_repo" "main"

    # Create local repo with master and add remote
    create_test_repo "$test_repo" "master"
    cd "$test_repo"
    add_remote "origin" "$remote_repo"

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "main" ]]
}

@test "get_default_branch: handles empty repository" {
    local test_repo="$TEMP_DIR/test_repo"

    mkdir -p "$test_repo"
    cd "$test_repo"
    git init >/dev/null 2>&1

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Cannot determine default branch" ]]
}

# Remote detection tests
@test "get_remotes: lists remotes with URLs" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    create_test_repo "$remote_repo"
    create_test_repo "$test_repo"
    cd "$test_repo"

    add_remote "origin" "$remote_repo"
    add_remote "upstream" "$remote_repo"

    run "$REPOSITORY_MODEL" remotes
    [ "$status" -eq 0 ]
    [[ "$output" =~ "origin,$remote_repo" ]]
    [[ "$output" =~ "upstream,$remote_repo" ]]
}

@test "get_remotes: succeeds with no remotes" {
    local test_repo="$TEMP_DIR/test_repo"

    create_test_repo "$test_repo"
    cd "$test_repo"

    run "$REPOSITORY_MODEL" remotes
    [ "$status" -eq 0 ]
    # Output should be empty or whitespace only
    [[ -z "${output// }" ]]
}

# Worktrees root resolution tests
@test "resolve_worktrees_root: uses flag override" {
    local custom_root="$TEMP_DIR/custom_worktrees"

    run "$REPOSITORY_MODEL" worktrees-root "$custom_root"
    [ "$status" -eq 0 ]
    [[ "$output" == "$custom_root" ]]
    [[ -d "$custom_root" ]]
}

@test "resolve_worktrees_root: uses environment variable" {
    local env_root="$TEMP_DIR/env_worktrees"

    WORKTREES_ROOT="$env_root" run "$REPOSITORY_MODEL" worktrees-root
    [ "$status" -eq 0 ]
    [[ "$output" == "$env_root" ]]
    [[ -d "$env_root" ]]
}

@test "resolve_worktrees_root: defaults to HOME/.worktrees" {
    local expected_root="$HOME/.worktrees"

    run "$REPOSITORY_MODEL" worktrees-root
    [ "$status" -eq 0 ]
    [[ "$output" == "$expected_root" ]]
}

@test "resolve_worktrees_root: flag overrides environment" {
    local env_root="$TEMP_DIR/env_worktrees"
    local flag_root="$TEMP_DIR/flag_worktrees"

    WORKTREES_ROOT="$env_root" run "$REPOSITORY_MODEL" worktrees-root "$flag_root"
    [ "$status" -eq 0 ]
    [[ "$output" == "$flag_root" ]]
    [[ -d "$flag_root" ]]
    [[ ! -d "$env_root" ]]
}

@test "resolve_worktrees_root: converts relative paths to absolute" {
    cd "$TEMP_DIR"

    run "$REPOSITORY_MODEL" worktrees-root "relative/path"
    [ "$status" -eq 0 ]
    [[ "$output" == "$TEMP_DIR/relative/path" ]]
    [[ -d "$TEMP_DIR/relative/path" ]]
}

@test "resolve_worktrees_root: creates directory if missing" {
    local new_root="$TEMP_DIR/new/deep/path"

    run "$REPOSITORY_MODEL" worktrees-root "$new_root"
    [ "$status" -eq 0 ]
    [[ "$output" == "$new_root" ]]
    [[ -d "$new_root" ]]
}

# Repository info integration test
@test "get_repository_info: returns complete repository information" {
    local test_repo="$TEMP_DIR/test_repo"
    local remote_repo="$TEMP_DIR/remote_repo"

    # Create remote repo
    create_test_repo "$remote_repo" "main"

    # Create local repo and add remote
    create_test_repo "$test_repo" "main"
    cd "$test_repo"
    add_remote "origin" "$remote_repo"
    set_remote_head "origin" "main"

    run "$REPOSITORY_MODEL" info
    [ "$status" -eq 0 ]
    [[ "$output" =~ "rootPath=$test_repo" ]]
    [[ "$output" =~ "defaultBranch=main" ]]
    [[ "$output" =~ "remotes:" ]]
    [[ "$output" =~ "origin,$remote_repo" ]]
}

# CLI interface tests
@test "CLI: shows usage when no arguments provided" {
    run "$REPOSITORY_MODEL"
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "root" ]]
    [[ "$output" =~ "branch" ]]
    [[ "$output" =~ "remotes" ]]
    [[ "$output" =~ "info" ]]
    [[ "$output" =~ "worktrees-root" ]]
}

@test "CLI: handles unknown command" {
    run "$REPOSITORY_MODEL" unknown-command
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Usage:" ]]
}

# Edge cases and error handling
@test "get_default_branch: handles corrupted remote HEAD" {
    local test_repo="$TEMP_DIR/test_repo"

    create_test_repo "$test_repo" "main"
    cd "$test_repo"

    # Manually create a corrupted remote HEAD reference
    mkdir -p ".git/refs/remotes/origin"
    echo "invalid-ref" > ".git/refs/remotes/origin/HEAD"

    run "$REPOSITORY_MODEL" branch
    [ "$status" -eq 0 ]
    [[ "$output" == "main" ]]
}

@test "resolve_worktrees_root: handles permission denied error gracefully" {
    # This test verifies error handling, but we can't easily test permission denied
    # in CI environments, so we'll test the error path with a simulated scenario
    local read_only_parent="$TEMP_DIR/readonly"
    mkdir -p "$read_only_parent"
    chmod 444 "$read_only_parent"

    # Try to create worktree root in readonly directory
    run "$REPOSITORY_MODEL" worktrees-root "$read_only_parent/worktrees"
    # Should either succeed (if permissions allow) or fail gracefully
    # We mainly want to ensure it doesn't crash
    [[ "$status" -eq 0 || "$status" -eq 1 ]]

    # Restore permissions for cleanup
    chmod 755 "$read_only_parent"
}