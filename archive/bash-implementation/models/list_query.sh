#!/bin/bash
set -euo pipefail

# ListQuery model for managing worktree list queries
# Implements validation and filtering for paginated worktree listings

# Default values
readonly DEFAULT_PAGE=1
readonly DEFAULT_PAGE_SIZE=20
readonly MAX_PAGE_SIZE=100
readonly MIN_PAGE_SIZE=1

#
# validate_page() - Validate page parameter
# Arguments:
#   $1 - page value to validate
# Returns:
#   0 - valid page
#   2 - validation error
# Output:
#   Error message to stderr on validation failure
#
validate_page() {
	local page="$1"

	# Check if it's a positive integer
	if ! [[ "$page" =~ ^[1-9][0-9]*$ ]]; then
		echo "Error: page must be a positive integer ≥ 1, got: $page" >&2
		return 2
	fi

	return 0
}

#
# validate_page_size() - Validate pageSize parameter
# Arguments:
#   $1 - pageSize value to validate
# Returns:
#   0 - valid pageSize
#   2 - validation error
# Output:
#   Error message to stderr on validation failure
#
validate_page_size() {
	local page_size="$1"

	# Check if it's a positive integer
	if ! [[ "$page_size" =~ ^[1-9][0-9]*$ ]]; then
		echo "Error: pageSize must be a positive integer, got: $page_size" >&2
		return 2
	fi

	# Check minimum bound
	if ((page_size < MIN_PAGE_SIZE)); then
		echo "Error: pageSize must be at least $MIN_PAGE_SIZE, got: $page_size" >&2
		return 2
	fi

	# Check maximum bound
	if ((page_size > MAX_PAGE_SIZE)); then
		echo "Error: pageSize must not exceed $MAX_PAGE_SIZE, got: $page_size" >&2
		return 2
	fi

	return 0
}

#
# filter_matches() - Apply filters to worktree data
# Arguments:
#   $1 - filterName (optional, case-insensitive substring match)
#   $2 - filterBase (optional, exact branch name match)
#   $3 - worktree_name
#   $4 - worktree_base_ref
# Returns:
#   0 - matches filters
#   1 - does not match filters
#
filter_matches() {
	local filter_name="${1:-}"
	local filter_base="${2:-}"
	local worktree_name="$3"
	local worktree_base_ref="$4"

	# Apply filterName (case-insensitive substring matching)
	if [[ -n "$filter_name" ]]; then
		local lowercase_name
		local lowercase_filter
		lowercase_name=$(echo "$worktree_name" | tr '[:upper:]' '[:lower:]')
		lowercase_filter=$(echo "$filter_name" | tr '[:upper:]' '[:lower:]')

		if [[ "$lowercase_name" != *"$lowercase_filter"* ]]; then
			return 1
		fi
	fi

	# Apply filterBase (exact branch name matching)
	if [[ -n "$filter_base" ]]; then
		if [[ "$worktree_base_ref" != "$filter_base" ]]; then
			return 1
		fi
	fi

	return 0
}

#
# build_list_query() - Construct validated list query with defaults
# Arguments:
#   $1 - filterName (optional)
#   $2 - filterBase (optional)
#   $3 - page (optional, defaults to 1)
#   $4 - pageSize (optional, defaults to 20)
# Returns:
#   0 - success
#   2 - validation error
# Output:
#   Query parameters on stdout in format: filterName|filterBase|page|pageSize
#
build_list_query() {
	local filter_name="${1:-}"
	local filter_base="${2:-}"
	local page="${3:-$DEFAULT_PAGE}"
	local page_size="${4:-$DEFAULT_PAGE_SIZE}"

	# Validate page
	if ! validate_page "$page"; then
		return 2
	fi

	# Validate pageSize
	if ! validate_page_size "$page_size"; then
		return 2
	fi

	# Output validated query parameters
	printf "%s|%s|%s|%s\n" "$filter_name" "$filter_base" "$page" "$page_size"
	return 0
}

# Export functions for use by other scripts
if [[ "${BASH_SOURCE[0]:-}" != "${0}" ]]; then
	# Script is being sourced
	export -f validate_page
	export -f validate_page_size
	export -f filter_matches
	export -f build_list_query
else
	# Script is being executed directly - provide usage info
	cat >&2 <<'EOF'
Usage: This script provides ListQuery model functions for worktree management.

Functions:
  validate_page <page>                    - Validate page parameter (≥ 1)
  validate_page_size <pageSize>          - Validate pageSize (1-100, default 20)
  filter_matches <name> <base> <wt_name> <wt_base> - Apply filters to worktree
  build_list_query [name] [base] [page] [pageSize] - Build validated query

Source this script to use the functions:
  source list_query.sh
EOF
	exit 2
fi
