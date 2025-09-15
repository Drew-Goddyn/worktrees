#!/bin/bash
set -euo pipefail

# IO utilities and exit code mapping for claude-worktrees
# Provides consistent logging and error handling infrastructure

# Exit code constants per CLI contracts
readonly EXIT_SUCCESS=0
readonly EXIT_VALIDATION_ERROR=2
readonly EXIT_PRECONDITION_FAILURE=3
readonly EXIT_CONFLICT=4
readonly EXIT_UNSAFE_STATE=5
readonly EXIT_NOT_FOUND=6

# Color codes for terminal output
readonly COLOR_RED='\033[0;31m'
readonly COLOR_YELLOW='\033[0;33m'
readonly COLOR_BLUE='\033[0;34m'
readonly COLOR_NC='\033[0m' # No Color

# Program name for consistent messaging
readonly PROGRAM_NAME="${0##*/}"

#
# log_error() - Write error messages to stderr
#
# Usage: log_error "message"
#
# Outputs formatted error message to stderr with timestamp and error prefix.
# Uses red color if terminal supports colors.
#
log_error() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -t 2 ]]; then
        # Terminal supports colors
        printf "${COLOR_RED}[ERROR]${COLOR_NC} %s - %s: %s\n" \
            "$timestamp" "$PROGRAM_NAME" "$message" >&2
    else
        printf "[ERROR] %s - %s: %s\n" \
            "$timestamp" "$PROGRAM_NAME" "$message" >&2
    fi
}

#
# log_warning() - Write warning messages to stderr
#
# Usage: log_warning "message"
#
# Outputs formatted warning message to stderr with timestamp and warning prefix.
# Uses yellow color if terminal supports colors.
#
log_warning() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -t 2 ]]; then
        # Terminal supports colors
        printf "${COLOR_YELLOW}[WARNING]${COLOR_NC} %s - %s: %s\n" \
            "$timestamp" "$PROGRAM_NAME" "$message" >&2
    else
        printf "[WARNING] %s - %s: %s\n" \
            "$timestamp" "$PROGRAM_NAME" "$message" >&2
    fi
}

#
# log_info() - Write info messages to stderr
#
# Usage: log_info "message"
#
# Outputs formatted info message to stderr with timestamp and info prefix.
# Uses blue color if terminal supports colors.
#
log_info() {
    local message="$1"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    if [[ -t 2 ]]; then
        # Terminal supports colors
        printf "${COLOR_BLUE}[INFO]${COLOR_NC} %s - %s: %s\n" \
            "$timestamp" "$PROGRAM_NAME" "$message" >&2
    else
        printf "[INFO] %s - %s: %s\n" \
            "$timestamp" "$PROGRAM_NAME" "$message" >&2
    fi
}

#
# get_exit_code() - Map error types to exit codes
#
# Usage: get_exit_code "error_type"
#
# Maps error type strings to appropriate exit codes according to CLI contracts.
# Returns the exit code for the given error type.
#
# Supported error types:
#   - success: 0
#   - validation: 2
#   - precondition: 3
#   - conflict: 4
#   - unsafe: 5
#   - not_found: 6
#
get_exit_code() {
    local error_type="$1"

    case "$error_type" in
        "success")
            echo "$EXIT_SUCCESS"
            ;;
        "validation")
            echo "$EXIT_VALIDATION_ERROR"
            ;;
        "precondition")
            echo "$EXIT_PRECONDITION_FAILURE"
            ;;
        "conflict")
            echo "$EXIT_CONFLICT"
            ;;
        "unsafe")
            echo "$EXIT_UNSAFE_STATE"
            ;;
        "not_found")
            echo "$EXIT_NOT_FOUND"
            ;;
        *)
            log_error "Unknown error type: $error_type"
            echo "$EXIT_VALIDATION_ERROR"
            ;;
    esac
}

#
# exit_with_code() - Exit with consistent code mapping
#
# Usage: exit_with_code "error_type" ["message"]
#
# Exits the program with the appropriate exit code for the given error type.
# Optionally logs an error message before exiting.
#
# Examples:
#   exit_with_code "success"
#   exit_with_code "validation" "Invalid argument provided"
#   exit_with_code "not_found" "File not found: config.yml"
#
exit_with_code() {
    local error_type="$1"
    local message="${2:-}"
    local exit_code

    exit_code=$(get_exit_code "$error_type")

    if [[ -n "$message" ]]; then
        case "$error_type" in
            "success")
                log_info "$message"
                ;;
            *)
                log_error "$message"
                ;;
        esac
    fi

    exit "$exit_code"
}

#
# is_terminal() - Check if output is going to a terminal
#
# Usage: if is_terminal; then ...; fi
#
# Returns 0 if stdout is a terminal, 1 otherwise.
# Useful for conditional color/formatting output.
#
is_terminal() {
    [[ -t 1 ]]
}

#
# is_error_terminal() - Check if stderr is going to a terminal
#
# Usage: if is_error_terminal; then ...; fi
#
# Returns 0 if stderr is a terminal, 1 otherwise.
# Useful for conditional color/formatting in error output.
#
is_error_terminal() {
    [[ -t 2 ]]
}

# Export functions for use by other scripts
export -f log_error
export -f log_warning
export -f log_info
export -f get_exit_code
export -f exit_with_code
export -f is_terminal
export -f is_error_terminal