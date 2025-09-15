#!/bin/bash
set -euo pipefail

# Repository model functions for Git worktree management
# Implements core repository detection and metadata retrieval

#######################################
# Detect Git repository root path
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Absolute path to repository root
# Returns:
#   0 on success, 1 if not in a Git repository
#######################################
detect_repo_root() {
    local repo_root

    if ! repo_root=$(git rev-parse --show-toplevel 2>/dev/null); then
        echo "Error: Not in a Git repository" >&2
        return 1
    fi

    readonly repo_root
    echo "${repo_root}"
    return 0
}

#######################################
# Get default branch name from remote HEAD, falling back to main/master
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Default branch name (without refs/heads/ prefix)
# Returns:
#   0 on success, 1 on error
#######################################
get_default_branch() {
    local default_branch

    # Try to get default branch from remote HEAD
    if default_branch=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null); then
        # Strip refs/remotes/origin/ prefix
        default_branch="${default_branch#refs/remotes/origin/}"
        readonly default_branch
        echo "${default_branch}"
        return 0
    fi

    # Fallback: check if main exists
    if git show-ref --verify --quiet refs/heads/main 2>/dev/null || \
       git show-ref --verify --quiet refs/remotes/origin/main 2>/dev/null; then
        echo "main"
        return 0
    fi

    # Fallback: check if master exists
    if git show-ref --verify --quiet refs/heads/master 2>/dev/null || \
       git show-ref --verify --quiet refs/remotes/origin/master 2>/dev/null; then
        echo "master"
        return 0
    fi

    # If no remotes exist, try to find any local branch
    if ! git remote >/dev/null 2>&1; then
        local first_branch
        if first_branch=$(git branch --format='%(refname:short)' | head -n1 2>/dev/null); then
            echo "${first_branch}"
            return 0
        fi
    fi

    echo "Error: Cannot determine default branch" >&2
    return 1
}

#######################################
# List Git remotes as name,url pairs
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Each remote on separate line as "name,url"
# Returns:
#   0 on success (even if no remotes), 1 on error
#######################################
get_remotes() {
    local remotes_output

    # Get remotes with URLs, filtering to fetch URLs only
    if ! remotes_output=$(git remote -v 2>/dev/null); then
        echo "Error: Failed to retrieve remotes" >&2
        return 1
    fi

    # Filter to fetch URLs only and format as name,url
    # Remote output format: "name\turl (fetch)" and "name\turl (push)"
    echo "${remotes_output}" | grep '(fetch)$' | while IFS=$'\t' read -r name url_and_type; do
        # Remove the " (fetch)" suffix
        local url="${url_and_type% (fetch)}"
        echo "${name},${url}"
    done

    return 0
}

#######################################
# Resolve worktrees root directory with fallback chain
# Globals:
#   HOME - User home directory
#   WORKTREES_ROOT - Optional environment override
# Arguments:
#   $1 - Optional root path override (from --root flag)
# Outputs:
#   Absolute path to worktrees root directory
# Returns:
#   0 on success, 1 on error (cannot create directory)
#######################################
resolve_worktrees_root() {
    local root_path_override="${1:-}"
    local resolved_root

    # Priority order: --root flag > WORKTREES_ROOT env > $HOME/.worktrees default
    if [[ -n "$root_path_override" ]]; then
        resolved_root="$root_path_override"
    elif [[ -n "${WORKTREES_ROOT:-}" ]]; then
        resolved_root="$WORKTREES_ROOT"
    else
        resolved_root="${HOME}/.worktrees"
    fi

    # Convert to absolute path if needed
    if [[ "$resolved_root" != /* ]]; then
        resolved_root="$(pwd)/$resolved_root"
    fi

    # Create directory if it doesn't exist
    if [[ ! -d "$resolved_root" ]]; then
        if ! mkdir -p "$resolved_root" 2>/dev/null; then
            echo "Error: Failed to create worktrees root directory: $resolved_root" >&2
            return 1
        fi
        echo "Info: Created worktrees root directory: $resolved_root" >&2
    fi

    echo "$resolved_root"
    return 0
}

#######################################
# Get repository metadata as JSON
# Combines all repository functions into structured output
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   JSON object with rootPath, defaultBranch, and remotes
# Returns:
#   0 on success, 1 on error
#######################################
get_repository_info() {
    local root_path default_branch remotes_list

    # Get repository root
    if ! root_path=$(detect_repo_root); then
        return 1
    fi

    # Get default branch
    if ! default_branch=$(get_default_branch); then
        return 1
    fi

    # Get remotes (this should not fail)
    remotes_list=$(get_remotes)

    # Output as simple key=value format (can be extended to JSON later)
    echo "rootPath=${root_path}"
    echo "defaultBranch=${default_branch}"
    echo "remotes:"
    if [[ -n "${remotes_list}" ]]; then
        echo "${remotes_list}"
    else
        echo "(no remotes)"
    fi

    return 0
}

# Main execution for testing
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "root")
            detect_repo_root
            ;;
        "branch")
            get_default_branch
            ;;
        "remotes")
            get_remotes
            ;;
        "info")
            get_repository_info
            ;;
        "worktrees-root")
            resolve_worktrees_root "${2:-}"
            ;;
        *)
            echo "Usage: $0 {root|branch|remotes|info|worktrees-root}" >&2
            echo "  root          - Get repository root path" >&2
            echo "  branch        - Get default branch name" >&2
            echo "  remotes       - Get remotes as name,url pairs" >&2
            echo "  info          - Get all repository information" >&2
            echo "  worktrees-root [path] - Resolve worktrees root directory" >&2
            exit 1
            ;;
    esac
fi