#!/bin/bash
set -euo pipefail

# Worktree Model
# Implements parsing and status detection for Git worktrees
# Data model fields: name, branch, baseRef, path, isActive, checkedOut, upstream,
# hasUnpushedCommits, isDirty, hasUntracked, opInProgress

# Global variables for storing parsed worktree data
# Format: "name|path|branch|head"
WORKTREE_DATA=()

# Global associative array for status caching (bash 4.0+)
if [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
    declare -A WORKTREE_STATUS_CACHE
else
    # Fallback for older bash versions - disable caching
    WORKTREE_STATUS_CACHE=""
fi

#
# clear_worktree_status_cache()
#
# Clears the worktree status cache to force fresh computations
#
clear_worktree_status_cache() {
    if [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
        unset WORKTREE_STATUS_CACHE
        declare -gA WORKTREE_STATUS_CACHE
    fi
}

#
# parse_worktree_list()
#
# Parses `git worktree list --porcelain` output into WORKTREE_DATA array
# Each element contains: "name|path|branch|head"
#
# Git worktree list --porcelain format:
# worktree <path>
# HEAD <commit-hash>
# branch refs/heads/<branch-name>  [or detached HEAD info]
#
parse_worktree_list() {
    # Clear global array and status cache
    WORKTREE_DATA=()
    clear_worktree_status_cache

    local current_path=""
    local current_head=""
    local current_branch=""

    while IFS= read -r line; do
        if [[ $line =~ ^worktree[[:space:]](.+)$ ]]; then
            # Save previous worktree data if we have it
            if [[ -n $current_path ]]; then
                local name
                name=$(basename "$current_path")
                WORKTREE_DATA+=("$name|$current_path|$current_branch|$current_head")
            fi

            # Start new worktree
            current_path="${BASH_REMATCH[1]:-}"
            current_head=""
            current_branch=""

        elif [[ $line =~ ^HEAD[[:space:]]([a-f0-9]+)$ ]]; then
            current_head="${BASH_REMATCH[1]:-}"

        elif [[ $line =~ ^branch[[:space:]]refs/heads/(.+)$ ]]; then
            current_branch="${BASH_REMATCH[1]:-}"

        elif [[ $line =~ ^detached$ ]]; then
            current_branch="(detached)"
        fi
    done < <(git worktree list --porcelain 2>/dev/null)

    # Don't forget the last worktree
    if [[ -n $current_path ]]; then
        local name
        name=$(basename "$current_path")
        WORKTREE_DATA+=("$name|$current_path|$current_branch|$current_head")
    fi
}

#
# _find_worktree_index(name)
#
# Internal function to find the index of a worktree in WORKTREE_DATA array
# Returns index or -1 if not found
#
_find_worktree_index() {
    local search_name="$1"
    local i=0

    for entry in "${WORKTREE_DATA[@]}"; do
        IFS='|' read -r name path branch head <<< "$entry"
        if [[ $name == "$search_name" ]]; then
            echo "$i"
            return 0
        fi
        ((i++))
    done

    echo "-1"
    return 1
}

#
# get_worktree_status(worktree_name)
#
# Computes derived status for a specific worktree
# Updates the worktree entry in WORKTREE_DATA with status information
# Extended format: "name|path|branch|head|isDirty|hasUntracked|hasUnpushedCommits|upstream|opInProgress|checkedOut"
#
get_worktree_status() {
    local name="$1"
    local index
    index=$(_find_worktree_index "$name")

    if [[ $index -eq -1 ]]; then
        return 1
    fi

    # Check cache first (if available)
    if [[ ${BASH_VERSION%%.*} -ge 4 ]] && [[ -n "${WORKTREE_STATUS_CACHE[$name]:-}" ]]; then
        # Update WORKTREE_DATA with cached status
        WORKTREE_DATA[$index]="${WORKTREE_STATUS_CACHE[$name]}"
        return 0
    fi

    # Extract current data
    IFS='|' read -r name path branch head existing_status <<< "${WORKTREE_DATA[$index]}"

    if [[ ! -d $path ]]; then
        return 1
    fi

    # Change to worktree directory for git operations
    local original_pwd="$PWD"
    cd "$path" || return 1

    # Initialize status values
    local is_dirty="false"
    local has_untracked="false"
    local has_unpushed="false"
    local upstream=""
    local op_in_progress="none"
    local checked_out="true"

    # Check git status --porcelain for dirty/untracked state
    local status_output
    if status_output=$(git status --porcelain 2>/dev/null); then
        while IFS= read -r status_line; do
            if [[ -n $status_line ]]; then
                local status_code="${status_line:0:2}"
                if [[ $status_code =~ [MADRC][[:space:]] || $status_code =~ [[:space:]][MADRC] ]]; then
                    is_dirty="true"
                elif [[ $status_code == "??" ]]; then
                    has_untracked="true"
                fi
            fi
        done <<< "$status_output"
    fi

    # Get upstream information for the branch
    if [[ $branch != "(detached)" ]]; then
        if upstream=$(git rev-parse --abbrev-ref "$branch@{upstream}" 2>/dev/null); then
            # Check for unpushed commits
            local ahead_count
            if ahead_count=$(git rev-list --count "$upstream..$branch" 2>/dev/null); then
                if [[ $ahead_count -gt 0 ]]; then
                    has_unpushed="true"
                fi
            fi
        fi
    else
        checked_out="false"
    fi

    # Check for operations in progress
    if [[ -f .git/MERGE_HEAD ]]; then
        op_in_progress="merge"
    elif [[ -d .git/rebase-merge ]] || [[ -d .git/rebase-apply ]]; then
        op_in_progress="rebase"
    elif [[ -f .git/CHERRY_PICK_HEAD ]]; then
        op_in_progress="cherry-pick"
    elif [[ -f .git/BISECT_LOG ]]; then
        op_in_progress="bisect"
    fi

    # Update the entry with status information
    WORKTREE_DATA[$index]="$name|$path|$branch|$head|$is_dirty|$has_untracked|$has_unpushed|$upstream|$op_in_progress|$checked_out"

    # Return to original directory
    cd "$original_pwd"

    # Cache the computed status (if available)
    if [[ ${BASH_VERSION%%.*} -ge 4 ]]; then
        WORKTREE_STATUS_CACHE[$name]="${WORKTREE_DATA[$index]}"
    fi
}

#
# is_worktree_active(worktree_name)
#
# Determines if the specified worktree is currently active (current working directory)
# Returns 0 (true) if active, 1 (false) if not active
#
is_worktree_active() {
    local name="$1"
    local index
    index=$(_find_worktree_index "$name")

    if [[ $index -eq -1 ]]; then
        return 1
    fi

    IFS='|' read -r _ path _ _ <<< "${WORKTREE_DATA[$index]}"

    # Get current working directory and resolve symlinks
    local current_path
    current_path=$(pwd -P)

    # Get absolute path of worktree and resolve symlinks
    local worktree_path
    worktree_path=$(cd "$path" && pwd -P 2>/dev/null) || return 1

    # Check if current path is within the worktree path
    if [[ $current_path == "$worktree_path"* ]]; then
        return 0
    fi

    return 1
}

#
# get_worktree_field(worktree_name, field_name)
#
# Retrieves a specific field value for a worktree
# Field names: name, branch, path, head, isDirty, hasUntracked, hasUnpushedCommits,
# upstream, opInProgress, checkedOut, isActive
#
get_worktree_field() {
    local name="$1"
    local field="$2"
    local index
    index=$(_find_worktree_index "$name")

    if [[ $index -eq -1 ]]; then
        return 1
    fi

    local entry="${WORKTREE_DATA[$index]}"

    case "$field" in
        "name")
            IFS='|' read -r name _ <<< "$entry"
            echo "$name"
            ;;
        "path")
            IFS='|' read -r _ path _ <<< "$entry"
            echo "$path"
            ;;
        "branch")
            IFS='|' read -r _ _ branch _ <<< "$entry"
            echo "$branch"
            ;;
        "head")
            IFS='|' read -r _ _ _ head _ <<< "$entry"
            echo "$head"
            ;;
        "isActive")
            if is_worktree_active "$name"; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        "isDirty"|"hasUntracked"|"hasUnpushedCommits"|"upstream"|"opInProgress"|"checkedOut")
            # Check if we have status data (10 fields vs 4)
            local field_count
            field_count=$(echo "$entry" | tr '|' '\n' | wc -l)

            if [[ $field_count -lt 10 ]]; then
                # Need to compute status first
                get_worktree_status "$name"
                entry="${WORKTREE_DATA[$index]}"
            fi

            IFS='|' read -r _ _ _ _ is_dirty has_untracked has_unpushed upstream op_in_progress checked_out <<< "$entry"
            case "$field" in
                "isDirty") echo "$is_dirty" ;;
                "hasUntracked") echo "$has_untracked" ;;
                "hasUnpushedCommits") echo "$has_unpushed" ;;
                "upstream") echo "$upstream" ;;
                "opInProgress") echo "$op_in_progress" ;;
                "checkedOut") echo "$checked_out" ;;
            esac
            ;;
        *)
            echo "Unknown field: $field" >&2
            return 1
            ;;
    esac
}

#
# list_worktree_names()
#
# Returns a list of all worktree names (one per line)
#
list_worktree_names() {
    for entry in "${WORKTREE_DATA[@]}"; do
        IFS='|' read -r name _ <<< "$entry"
        echo "$name"
    done
}

#
# worktree_exists(worktree_name)
#
# Returns 0 if worktree exists, 1 if not
#
worktree_exists() {
    local name="$1"
    local index
    index=$(_find_worktree_index "$name")
    [[ $index -ne -1 ]]
}

# Initialize by parsing worktrees when script is sourced
if [[ "${BASH_SOURCE[0]:-}" != "${0:-}" ]]; then
    parse_worktree_list
fi