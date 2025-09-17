#!/bin/bash
# FeatureName model - validation and normalization for git worktree feature names
set -euo pipefail

# FeatureName validation regex: 3 digits, dash, then 1-40 lowercase alphanumeric/dash chars
readonly FEATURE_NAME_REGEX='^[0-9]{3}-[a-z0-9-]{1,40}$'

# Reserved names that cannot be used as feature names
readonly -a RESERVED_NAMES=("main" "master")

#######################################
# Validates a feature name against the required regex pattern
# Globals:
#   FEATURE_NAME_REGEX
# Arguments:
#   $1 - feature name to validate
# Returns:
#   0 if valid, 2 if invalid format
# Outputs:
#   Error message to stderr if invalid
#######################################
validate_feature_name() {
	local feature_name="$1"

	if [[ ! "$feature_name" =~ $FEATURE_NAME_REGEX ]]; then
		echo "Error: Feature name '$feature_name' must match pattern: ^[0-9]{3}-[a-z0-9-]{1,40}$" >&2
		echo "Examples: '001-build-tool', '123-feature-name'" >&2
		return 2
	fi

	return 0
}

#######################################
# Checks if a feature name is reserved (main or master)
# Globals:
#   RESERVED_NAMES
# Arguments:
#   $1 - feature name to check
# Returns:
#   0 if reserved, 1 if not reserved
#######################################
is_reserved_name() {
	local feature_name="$1"
	local normalized_name
	normalized_name=$(echo "$feature_name" | tr '[:upper:]' '[:lower:]')

	local reserved_name
	for reserved_name in "${RESERVED_NAMES[@]}"; do
		if [[ "$normalized_name" == "$reserved_name" ]]; then
			return 0
		fi
	done

	return 1
}

#######################################
# Normalizes a feature name to lowercase
# Arguments:
#   $1 - feature name to normalize
# Outputs:
#   Normalized (lowercase) feature name to stdout
#######################################
normalize_feature_name() {
	local feature_name="$1"
	echo "$feature_name" | tr '[:upper:]' '[:lower:]'
}

#######################################
# Full validation of a feature name including format and reserved name checks
# Arguments:
#   $1 - feature name to validate
# Returns:
#   0 if valid, 2 if validation error
# Outputs:
#   Error messages to stderr if invalid
#######################################
validate_full_feature_name() {
	local feature_name="$1"

	# First check if it's a reserved name
	if is_reserved_name "$feature_name"; then
		echo "Error: Feature name '$feature_name' is reserved (main/master not allowed)" >&2
		return 2
	fi

	# Then validate format
	if ! validate_feature_name "$feature_name"; then
		return 2
	fi

	return 0
}

# If script is run directly (not sourced), provide CLI interface
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	if [[ $# -eq 0 ]]; then
		echo "Usage: $0 <command> <feature_name>" >&2
		echo "Commands:" >&2
		echo "  validate <name>    - Validate feature name format" >&2
		echo "  is_reserved <name> - Check if name is reserved" >&2
		echo "  normalize <name>   - Normalize name to lowercase" >&2
		echo "  validate_full <name> - Full validation (format + reserved check)" >&2
		exit 1
	fi

	command="$1"
	shift

	case "$command" in
		"validate")
			if [[ $# -ne 1 ]]; then
				echo "Error: validate requires exactly one argument" >&2
				exit 1
			fi
			validate_feature_name "$1"
			;;
		"is_reserved")
			if [[ $# -ne 1 ]]; then
				echo "Error: is_reserved requires exactly one argument" >&2
				exit 1
			fi
			if is_reserved_name "$1"; then
				echo "true"
				exit 0
			else
				echo "false"
				exit 1
			fi
			;;
		"normalize")
			if [[ $# -ne 1 ]]; then
				echo "Error: normalize requires exactly one argument" >&2
				exit 1
			fi
			normalize_feature_name "$1"
			;;
		"validate_full")
			if [[ $# -ne 1 ]]; then
				echo "Error: validate_full requires exactly one argument" >&2
				exit 1
			fi
			validate_full_feature_name "$1"
			;;
		*)
			echo "Error: Unknown command '$command'" >&2
			exit 1
			;;
	esac
fi
