#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
	echo "Running basic shell script validation..."

	# Find all shell scripts (exclude .specify directory)
	local shell_files
	shell_files=$(find "$PROJECT_ROOT" -name "*.sh" -type f -o -path "*/src/cli/*" -type f | grep -v ".git" | grep -v ".specify" | sort)

	if [[ -z "$shell_files" ]]; then
		echo "No shell files found to validate"
		exit 0
	fi

	echo "Validating shell files:"
	echo "$shell_files"
	echo

	local exit_code=0
	local total_files=0
	local passed_files=0

	# Run basic syntax check
	while IFS= read -r file; do
		((total_files++))
		echo -n "Checking syntax of $file... "

		if bash -n "$file" 2>/dev/null; then
			echo "✓ OK"
			((passed_files++))
		else
			echo "✗ FAILED"
			echo "  Syntax error in $file"
			bash -n "$file" # Show the actual error
			exit_code=1
		fi
	done <<<"$shell_files"

	echo
	echo "Validation Summary:"
	echo "  Total files: $total_files"
	echo "  Passed: $passed_files"
	echo "  Failed: $((total_files - passed_files))"

	if [[ $exit_code -eq 0 ]]; then
		echo "✓ All shell files passed basic validation"
	else
		echo "✗ Some shell files failed validation"
		echo ""
		echo "For more comprehensive checking, install ShellCheck:"
		echo "  brew install shellcheck  # macOS"
		echo "  apt-get install shellcheck  # Ubuntu/Debian"
	fi

	exit $exit_code
}

main "$@"
