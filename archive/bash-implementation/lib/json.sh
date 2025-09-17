#!/bin/bash

set -euo pipefail

# JSON utilities for structured output without jq dependency
# Implements safe JSON encoding and schema-compliant output

#######################################
# Safely escape a string for JSON
# Handles quotes, backslashes, control characters, and unicode
# Arguments:
#   $1 - String to escape
# Returns:
#   Escaped JSON string (without surrounding quotes)
#######################################
json_escape() {
	local input="${1:-}"

	# Handle empty/null input
	if [[ -z "$input" ]]; then
		printf ""
		return
	fi

	# Escape special characters according to JSON spec
	printf '%s' "$input" | sed \
		-e 's/\\/\\\\/g' \
		-e 's/"/\\"/g' \
		-e 's/\x08/\\b/g' \
		-e 's/\x0C/\\f/g' \
		-e 's/\x0A/\\n/g' \
		-e 's/\x0D/\\r/g' \
		-e 's/\x09/\\t/g'
}

#######################################
# Build a JSON object from key-value pairs
# Arguments:
#   $@ - Alternating key-value pairs (key1 value1 key2 value2 ...)
# Returns:
#   JSON object string
# Example:
#   json_build_object "name" "John" "age" "30" "active" "true"
#######################################
json_build_object() {
	local json="{"
	local first=true

	# Process key-value pairs
	while [[ $# -gt 1 ]]; do
		local key="$1"
		local value="$2"
		shift 2

		# Add comma separator for subsequent items
		if [[ "$first" == "true" ]]; then
			first=false
		else
			json+=","
		fi

		# Handle null values
		if [[ "$value" == "null" ]] || [[ -z "$value" && "$key" != "path" ]]; then
			json+="\"$(json_escape "$key")\":null"
		# Handle boolean values
		elif [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
			json+="\"$(json_escape "$key")\":$value"
		# Handle numeric values (integers only for simplicity)
		elif [[ "$value" =~ ^[0-9]+$ ]]; then
			json+="\"$(json_escape "$key")\":$value"
		# Handle string values
		else
			json+="\"$(json_escape "$key")\":\"$(json_escape "$value")\""
		fi
	done

	json+="}"
	printf '%s' "$json"
}

#######################################
# Build a JSON array from values
# Arguments:
#   $@ - Array values
# Returns:
#   JSON array string
# Example:
#   json_build_array "item1" "item2" "item3"
#######################################
json_build_array() {
	local json="["
	local first=true

	for value in "$@"; do
		# Add comma separator for subsequent items
		if [[ "$first" == "true" ]]; then
			first=false
		else
			json+=","
		fi

		# Handle null values
		if [[ "$value" == "null" ]]; then
			json+="null"
		# Handle boolean values
		elif [[ "$value" == "true" ]] || [[ "$value" == "false" ]]; then
			json+="$value"
		# Handle numeric values
		elif [[ "$value" =~ ^[0-9]+$ ]]; then
			json+="$value"
		# Handle object values (assume already JSON formatted)
		elif [[ "$value" =~ ^\{.*\}$ ]] || [[ "$value" =~ ^\[.*\]$ ]]; then
			json+="$value"
		# Handle string values
		else
			json+="\"$(json_escape "$value")\""
		fi
	done

	json+="]"
	printf '%s' "$json"
}

#######################################
# Format a worktree object per OpenAPI schema
# Schema: {name, branch, baseRef, path, active, isDirty, hasUnpushedCommits}
# Arguments:
#   $1 - name (string)
#   $2 - branch (string)
#   $3 - baseRef (string)
#   $4 - path (string)
#   $5 - active (boolean)
#   $6 - isDirty (boolean)
#   $7 - hasUnpushedCommits (boolean)
# Returns:
#   JSON worktree object
#######################################
json_format_worktree() {
	local name="${1:-}"
	local branch="${2:-}"
	local baseRef="${3:-}"
	local path="${4:-}"
	local active="${5:-false}"
	local isDirty="${6:-false}"
	local hasUnpushedCommits="${7:-false}"

	json_build_object \
		"name" "$name" \
		"branch" "$branch" \
		"baseRef" "$baseRef" \
		"path" "$path" \
		"active" "$active" \
		"isDirty" "$isDirty" \
		"hasUnpushedCommits" "$hasUnpushedCommits"
}

#######################################
# Format worktree data as JSON without expensive status fields
# Arguments:
#   $1 - name
#   $2 - branch
#   $3 - baseRef
#   $4 - path
# Returns:
#   JSON object as string
#######################################
json_format_basic_worktree() {
	local name="${1:-}"
	local branch="${2:-}"
	local baseRef="${3:-}"
	local path="${4:-}"

	json_build_object \
		"name" "$name" \
		"branch" "$branch" \
		"baseRef" "$baseRef" \
		"path" "$path"
}

#######################################
# Format a pagination response per OpenAPI schema
# Schema: {items: [...], page, pageSize, total}
# Arguments:
#   $1 - items (JSON array string)
#   $2 - page (integer)
#   $3 - pageSize (integer)
#   $4 - total (integer)
# Returns:
#   JSON pagination object
#######################################
json_format_pagination() {
	local items="${1:-[]}"
	local page="${2:-1}"
	local pageSize="${3:-10}"
	local total="${4:-0}"

	# Validate items is valid JSON array
	if [[ ! "$items" =~ ^\[.*\]$ ]]; then
		items="[]"
	fi

	printf '{"items":%s,"page":%d,"pageSize":%d,"total":%d}' \
		"$items" "$page" "$pageSize" "$total"
}

#######################################
# Format a switch response per OpenAPI schema
# Schema: {current: {name, path}, previous: {name, path}, warnings: [...]}
# Arguments:
#   $1 - current_name (string)
#   $2 - current_path (string)
#   $3 - previous_name (string)
#   $4 - previous_path (string)
#   $5+ - warnings (array of strings)
# Returns:
#   JSON switch response object
#######################################
json_format_switch() {
	local current_name="${1:-}"
	local current_path="${2:-}"
	local previous_name="${3:-}"
	local previous_path="${4:-}"
	shift 4 || true # Remove first 4 args, remaining are warnings

	local current_obj
	local previous_obj
	local warnings_array

	# Build current object
	current_obj=$(json_build_object "name" "$current_name" "path" "$current_path")

	# Build previous object
	previous_obj=$(json_build_object "name" "$previous_name" "path" "$previous_path")

	# Build warnings array
	if [[ $# -gt 0 ]]; then
		warnings_array=$(json_build_array "$@")
	else
		warnings_array="[]"
	fi

	printf '{"current":%s,"previous":%s,"warnings":%s}' \
		"$current_obj" "$previous_obj" "$warnings_array"
}

#######################################
# Format a remove response per OpenAPI schema
# Schema: {removed: boolean, branchDeleted: boolean}
# Arguments:
#   $1 - removed (boolean)
#   $2 - branchDeleted (boolean)
# Returns:
#   JSON remove response object
#######################################
json_format_remove() {
	local removed="${1:-false}"
	local branchDeleted="${2:-false}"

	json_build_object \
		"removed" "$removed" \
		"branchDeleted" "$branchDeleted"
}

#######################################
# Format an error response
# Arguments:
#   $1 - error message (string)
#   $2 - error code (optional, defaults to "UNKNOWN_ERROR")
# Returns:
#   JSON error object
#######################################
json_format_error() {
	local message="${1:-Unknown error}"
	local code="${2:-UNKNOWN_ERROR}"

	json_build_object \
		"error" "$message" \
		"code" "$code"
}

#######################################
# Validate that a string is valid JSON
# Arguments:
#   $1 - JSON string to validate
# Returns:
#   0 if valid JSON, 1 if invalid
#######################################
json_validate() {
	local json_string="${1:-}"

	# Basic validation - check for balanced braces/brackets
	local brace_count=0
	local bracket_count=0
	local in_string=false
	local escaped=false

	while IFS= read -r -n1 char; do
		if [[ "$escaped" == "true" ]]; then
			escaped=false
			continue
		fi

		case "$char" in
			'\\')
				if [[ "$in_string" == "true" ]]; then
					escaped=true
				fi
				;;
			'"')
				if [[ "$in_string" == "true" ]]; then
					in_string=false
				else
					in_string=true
				fi
				;;
			'{')
				if [[ "$in_string" == "false" ]]; then
					((brace_count++))
				fi
				;;
			'}')
				if [[ "$in_string" == "false" ]]; then
					((brace_count--))
				fi
				;;
			'[')
				if [[ "$in_string" == "false" ]]; then
					((bracket_count++))
				fi
				;;
			']')
				if [[ "$in_string" == "false" ]]; then
					((bracket_count--))
				fi
				;;
		esac
	done <<<"$json_string"

	# Check if brackets and braces are balanced
	if [[ $brace_count -eq 0 ]] && [[ $bracket_count -eq 0 ]]; then
		return 0
	else
		return 1
	fi
}

# Export functions for use in other scripts
export -f json_escape
export -f json_build_object
export -f json_build_array
export -f json_format_worktree
export -f json_format_basic_worktree
export -f json_format_pagination
export -f json_format_switch
export -f json_format_remove
export -f json_format_error
export -f json_validate
