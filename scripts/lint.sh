#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
	echo "Running ShellCheck linting for worktrees CLI..."

	# Check if ShellCheck is available
	if ! command -v shellcheck >/dev/null 2>&1; then
		echo "Warning: shellcheck is not installed"
		echo "Falling back to basic syntax checking..."
		echo "Install shellcheck for comprehensive linting:"
		echo "  brew install shellcheck  # macOS"
		echo "  apt-get install shellcheck  # Ubuntu/Debian"
		echo ""
		exec "$PROJECT_ROOT/scripts/check.sh"
	fi

	# Find all shell scripts (exclude .specify directory)
	local shell_files
	shell_files=$(find "$PROJECT_ROOT" -name "*.sh" -type f -o -path "*/src/cli/*" -type f | grep -v ".git" | grep -v ".specify" | sort)

	if [[ -z "$shell_files" ]]; then
		echo "No shell files found to lint"
		exit 0
	fi

	echo "Linting shell files:"
	echo "$shell_files"
	echo

	# Run ShellCheck
	local exit_code=0
	while IFS= read -r file; do
		echo "Checking $file..."
		if ! shellcheck "$file"; then
			exit_code=1
		fi
	done <<<"$shell_files"

	if [[ $exit_code -eq 0 ]]; then
		echo "All shell files passed ShellCheck"
	else
		echo "Some shell files failed ShellCheck validation"
	fi

	exit $exit_code
}

main "$@"
