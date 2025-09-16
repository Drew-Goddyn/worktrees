#!/bin/bash
#
# Worktree Service - Core business logic for Git worktree operations
#
# This service provides the main interface for worktree operations including
# creation, listing, switching, and removal. It acts as the business logic layer
# between the CLI interface and the underlying Git worktree commands.
#

set -euo pipefail

# Script metadata
[[ -z "${SCRIPT_DIR:-}" ]] && readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source dependencies (when they exist)
# These will be implemented in future tasks
# source "$SCRIPT_DIR/../models/repository.sh" 2>/dev/null || true
# source "$SCRIPT_DIR/../models/feature_name.sh" 2>/dev/null || true
# source "$SCRIPT_DIR/../models/worktree.sh" 2>/dev/null || true

# Error handling
readonly ERR_INVALID_PARAMS=10
readonly ERR_WORKTREE_EXISTS=11
readonly ERR_WORKTREE_NOT_FOUND=12
readonly ERR_INVALID_REFERENCE=13
readonly ERR_OPERATION_FAILED=14
readonly ERR_UNSAFE_OPERATION=15

#
# create_worktree - Create a new Git worktree
#
# Creates a new worktree with the specified name, base reference, and location.
# Handles validation, path creation, and worktree initialization.
#
# Parameters:
#   $1 - name: Worktree name (required) - must be valid branch/directory name
#   $2 - base_ref: Base Git reference (required) - branch, tag, or commit
#   $3 - root_path: Root path for worktree (required) - directory path
#   $@ - flags: Additional flags (optional) - passed through to git worktree
#
# Returns:
#   0 on success, error code on failure
#   Outputs JSON with worktree details or error message
#
# Example:
#   create_worktree "feature-001" "main" "/path/to/worktrees" "--track"
#
create_worktree() {
	local -r name="${1:-}"
	local -r base_ref="${2:-}"
	local -r root_path="${3:-}"
	shift 3 || true
	local -r flags=("$@")

	# Parameter validation
	if [[ -z "$name" ]]; then
		echo '{"error": "Worktree name is required", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	if [[ -z "$base_ref" ]]; then
		echo '{"error": "Base reference is required", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	if [[ -z "$root_path" ]]; then
		echo '{"error": "Root path is required", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	# Validate name format (basic validation for now)
	if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo '{"error": "Invalid worktree name format", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	# TODO: Implement worktree creation logic
	# - Check if worktree already exists
	# - Validate base_ref exists
	# - Create worktree directory structure
	# - Initialize Git worktree
	# - Set up branch tracking if needed

	echo '{"status": "not_implemented", "message": "create_worktree implementation pending"}' >&2
	return $ERR_OPERATION_FAILED
}

#
# list_worktrees - List existing worktrees with optional filtering
#
# Lists all Git worktrees with their status, paths, and metadata.
# Supports filtering and formatting options.
#
# Parameters:
#   $@ - query_params: Query parameters (optional)
#        --format=json|text|table (default: json)
#        --filter=pattern (filter by name pattern)
#        --status=active|all (default: all)
#        --path=absolute|relative (default: absolute)
#
# Returns:
#   0 on success, error code on failure
#   Outputs formatted worktree list or error message
#
# Example:
#   list_worktrees --format=table --status=active
#
list_worktrees() {
	local format="json"
	local filter=""
	local status="all"
	local path_format="absolute"

	# Parse query parameters
	for arg in "$@"; do
		case $arg in
			--format=*)
				format="${arg#*=}"
				;;
			--filter=*)
				filter="${arg#*=}"
				;;
			--status=*)
				status="${arg#*=}"
				;;
			--path=*)
				path_format="${arg#*=}"
				;;
			*)
				echo '{"error": "Unknown parameter: '$arg'", "code": '$ERR_INVALID_PARAMS'}' >&2
				return $ERR_INVALID_PARAMS
				;;
		esac
	done

	# Validate parameters
	case $format in
		json | text | table) ;;
		*)
			echo '{"error": "Invalid format: '$format'", "code": '$ERR_INVALID_PARAMS'}' >&2
			return $ERR_INVALID_PARAMS
			;;
	esac

	case $status in
		active | all) ;;
		*)
			echo '{"error": "Invalid status filter: '$status'", "code": '$ERR_INVALID_PARAMS'}' >&2
			return $ERR_INVALID_PARAMS
			;;
	esac

	# TODO: Implement worktree listing logic
	# - Query Git worktrees
	# - Apply filters
	# - Format output according to requested format
	# - Handle different path formats

	echo '{"status": "not_implemented", "message": "list_worktrees implementation pending"}' >&2
	return $ERR_OPERATION_FAILED
}

#
# switch_worktree - Switch to a different worktree
#
# Changes the current working context to the specified worktree.
# This may involve changing directories and updating environment.
#
# Parameters:
#   $1 - name: Target worktree name (required)
#
# Returns:
#   0 on success, error code on failure
#   Outputs JSON with switch result or error message
#
# Example:
#   switch_worktree "feature-001"
#
switch_worktree() {
	local -r name="${1:-}"

	# Parameter validation
	if [[ -z "$name" ]]; then
		echo '{"error": "Worktree name is required", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	# Validate name format
	if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo '{"error": "Invalid worktree name format", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	# TODO: Implement worktree switching logic
	# - Verify worktree exists
	# - Get worktree path
	# - Handle any pre-switch cleanup
	# - Switch context (this may require shell integration)
	# - Update environment variables if needed

	echo '{"status": "not_implemented", "message": "switch_worktree implementation pending"}' >&2
	return $ERR_OPERATION_FAILED
}

#
# check_worktree_safety - Validate safety requirements for worktree removal
#
# Checks for conditions that would make worktree removal unsafe or require
# special handling. Some conditions are never allowed (tracked changes,
# unpushed commits, operations in progress), while others can be overridden
# with --force (untracked files).
#
# Parameters:
#   $1 - name: Worktree name to check (required)
#   $2 - force: Whether --force flag is enabled (true/false)
#
# Returns:
#   0 on success (safe to remove), non-zero with JSON error on failure
#
check_worktree_safety() {
	local name="$1"
	local force="$2"

	# Validate parameters
	if [[ -z "$name" ]]; then
		echo '{"error": "Worktree name is required", "code": 10}' >&2
		return 10
	fi

	# Check if currently active (safety check)
	if is_worktree_active "$name"; then
		echo '{"error": "Cannot remove active worktree", "code": 15}' >&2
		return 15
	fi

	# Get worktree status
	local is_dirty has_untracked has_unpushed op_in_progress
	is_dirty=$(get_worktree_field "$name" "isDirty")
	has_untracked=$(get_worktree_field "$name" "hasUntracked")
	has_unpushed=$(get_worktree_field "$name" "hasUnpushedCommits")
	op_in_progress=$(get_worktree_field "$name" "opInProgress")

	local safety_violations=()

	# Check for tracked changes (never allowed, even with --force)
	if [[ "$is_dirty" == "true" ]]; then
		safety_violations+=("Worktree has uncommitted changes")
	fi

	# Check for operation in progress (never allowed, even with --force)
	if [[ "$op_in_progress" != "none" ]]; then
		safety_violations+=("Worktree has operation in progress: $op_in_progress")
	fi

	# Check for unpushed commits (never allowed, even with --force)
	if [[ "$has_unpushed" == "true" ]]; then
		safety_violations+=("Worktree has unpushed commits")
	fi

	# Report critical safety violations
	if [[ ${#safety_violations[@]} -gt 0 ]]; then
		local violations_json=""
		for violation in "${safety_violations[@]}"; do
			if [[ -n "$violations_json" ]]; then
				violations_json+=", "
			fi
			violations_json+="\"$violation\""
		done
		echo "{\"error\": \"Safety violations detected\", \"violations\": [$violations_json], \"code\": 15}" >&2
		return 15
	fi

	# Check for untracked files (allowed with --force)
	if [[ "$has_untracked" == "true" && "$force" != "true" ]]; then
		echo '{"error": "Worktree has untracked files. Use --force to allow removal", "code": 15}' >&2
		return 15
	fi

	return 0
}

#
# check_branch_merged - Verify branch is fully merged before deletion
#
# Uses git merge-base --is-ancestor to check if the branch is fully
# merged into the specified base branch. This prevents accidental
# deletion of unmerged work.
#
# Parameters:
#   $1 - branch: Branch name to check
#   $2 - base: Base branch to check merge status against
#
# Returns:
#   0 on success (branch is merged), non-zero with JSON error on failure
#
check_branch_merged() {
	local branch="$1"
	local base="$2"

	# Validate parameters
	if [[ -z "$branch" ]]; then
		echo '{"error": "Branch name is required", "code": 10}' >&2
		return 10
	fi

	if [[ -z "$base" ]]; then
		echo '{"error": "Base branch is required for merge check", "code": 10}' >&2
		return 10
	fi

	# Verify base branch exists
	if ! git show-ref --verify --quiet "refs/heads/$base" 2>/dev/null &&
		! git show-ref --verify --quiet "refs/remotes/origin/$base" 2>/dev/null; then
		echo '{"error": "Base branch does not exist: '$base'", "code": 12}' >&2
		return 12
	fi

	# Check if branch is fully merged
	if ! git merge-base --is-ancestor "$branch" "$base" 2>/dev/null; then
		echo '{"error": "Branch '$branch' is not fully merged into '$base'", "code": 15}' >&2
		return 15
	fi

	return 0
}

#
# remove_worktree - Remove an existing worktree
#
# Removes a worktree and optionally cleans up associated branches and data.
# Provides safety checks to prevent accidental deletion.
#
# Parameters:
#   $1 - name: Worktree name to remove (required)
#   $2 - force: Force flag (true/false, optional, default: false)
#   $3 - delete_branch: Delete branch flag (true/false, optional, default: false)
#   $4 - merged_into: Base branch for merge check (optional, used with delete_branch)
#
# Returns:
#   0 on success, error code on failure
#   Outputs JSON with removal result or error message
#
# Example:
#   remove_worktree "feature-001" "true" "true" "main"
#
remove_worktree() {
	local name="${1:-}"
	local force="${2:-false}"
	local delete_branch="${3:-false}"
	local merged_into="${4:-}"

	# Parameter validation
	if [[ -z "$name" ]]; then
		echo '{"error": "Worktree name is required", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	# Validate name format
	if [[ ! "$name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
		echo '{"error": "Invalid worktree name format", "code": '$ERR_INVALID_PARAMS'}' >&2
		return $ERR_INVALID_PARAMS
	fi

	# Import models and dependencies
	if ! source "$SCRIPT_DIR/../models/worktree.sh" 2>/dev/null; then
		echo '{"error": "Failed to load worktree model", "code": '$ERR_OPERATION_FAILED'}' >&2
		return $ERR_OPERATION_FAILED
	fi

	if ! source "$SCRIPT_DIR/../lib/io.sh" 2>/dev/null; then
		echo '{"error": "Failed to load IO utilities", "code": '$ERR_OPERATION_FAILED'}' >&2
		return $ERR_OPERATION_FAILED
	fi

	# Validate worktree exists
	if ! worktree_exists "$name"; then
		echo '{"error": "Worktree not found: '$name'", "code": '$ERR_WORKTREE_NOT_FOUND'}' >&2
		return $ERR_WORKTREE_NOT_FOUND
	fi

	# Get target worktree information
	local target_path branch_name
	target_path=$(get_worktree_field "$name" "path")
	branch_name=$(get_worktree_field "$name" "branch")

	# Check safety violations
	local safety_result
	if ! safety_result=$(check_worktree_safety "$name" "$force"); then
		local exit_code
		exit_code=$(echo "$safety_result" | grep -o '"code": [0-9]*' | cut -d':' -f2 | tr -d ' ')
		echo "$safety_result" >&2
		return ${exit_code:-$ERR_OPERATION_FAILED}
	fi

	# Handle branch deletion if requested
	local branch_will_be_deleted=false
	if [[ "$delete_branch" == "true" && "$branch_name" != "(detached)" ]]; then
		# Set default merged_into if not specified
		if [[ -z "$merged_into" ]]; then
			# Try to get default branch
			if ! merged_into=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@'); then
				# Fall back to common defaults
				if git show-ref --verify --quiet "refs/heads/main" 2>/dev/null ||
					git show-ref --verify --quiet "refs/remotes/origin/main" 2>/dev/null; then
					merged_into="main"
				elif git show-ref --verify --quiet "refs/heads/master" 2>/dev/null ||
					git show-ref --verify --quiet "refs/remotes/origin/master" 2>/dev/null; then
					merged_into="master"
				else
					echo '{"error": "Could not determine default branch for merge check. Please specify with --merged-into", "code": '$ERR_INVALID_PARAMS'}' >&2
					return $ERR_INVALID_PARAMS
				fi
			fi
		fi

		# Check if branch is fully merged
		local merge_check
		if ! merge_check=$(check_branch_merged "$branch_name" "$merged_into"); then
			local exit_code
			exit_code=$(echo "$merge_check" | grep -o '"code": [0-9]*' | cut -d':' -f2 | tr -d ' ')
			echo "$merge_check" >&2
			return ${exit_code:-$ERR_OPERATION_FAILED}
		fi
		branch_will_be_deleted=true
	fi

	# Remove the worktree
	local git_remove_cmd=("git" "worktree" "remove")
	if [[ "$force" == "true" ]]; then
		git_remove_cmd+=("--force")
	fi
	git_remove_cmd+=("$target_path")

	if ! "${git_remove_cmd[@]}" 2>/dev/null; then
		echo '{"error": "Failed to remove worktree", "code": '$ERR_OPERATION_FAILED'}' >&2
		return $ERR_OPERATION_FAILED
	fi

	# Delete branch if requested and safe
	if [[ "$branch_will_be_deleted" == "true" ]]; then
		if ! git branch -d "$branch_name" 2>/dev/null; then
			# If -d fails, the branch might not be fully merged despite our check
			echo '{"error": "Worktree removed but failed to delete branch: '$branch_name'", "code": '$ERR_OPERATION_FAILED'}' >&2
			return $ERR_OPERATION_FAILED
		fi
	fi

	# Return success with status
	local result="{\"status\": \"success\", \"removed\": true, \"branchDeleted\": $branch_will_be_deleted}"
	echo "$result"
	return 0
}

#
# _validate_git_repo - Internal helper to validate Git repository
#
# Checks if the current directory is within a Git repository.
# Used by other functions for basic validation.
#
# Returns:
#   0 if valid Git repo, 1 otherwise
#
_validate_git_repo() {
	if ! git rev-parse --git-dir >/dev/null 2>&1; then
		echo '{"error": "Not in a Git repository", "code": '$ERR_OPERATION_FAILED'}' >&2
		return 1
	fi
	return 0
}

#
# _get_worktree_path - Internal helper to construct worktree path
#
# Builds the full path for a worktree based on name and root path.
#
# Parameters:
#   $1 - name: Worktree name
#   $2 - root_path: Root directory for worktrees
#
# Returns:
#   Outputs the full worktree path
#
_get_worktree_path() {
	local -r name="$1"
	local -r root_path="$2"

	# Normalize path and combine
	local normalized_root
	normalized_root="$(cd "$root_path" 2>/dev/null && pwd)" || echo "$root_path"

	echo "${normalized_root}/${name}"
}

# Export functions for external use
if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
	# Script is being sourced
	export -f create_worktree
	export -f list_worktrees
	export -f switch_worktree
	export -f remove_worktree
	export -f check_worktree_safety
	export -f check_branch_merged
fi
