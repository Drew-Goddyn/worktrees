#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
	echo "Formatting shell scripts with shfmt..."

	# Find all shell scripts first (exclude .specify directory)
	local shell_files
	shell_files=$(find "$PROJECT_ROOT" -name "*.sh" -type f -o -path "*/src/cli/*" -type f | grep -v ".git" | grep -v ".specify" | sort)

	if [[ -z "$shell_files" ]]; then
		echo "No shell files found to format"
		exit 0
	fi

	# Check if shfmt is available
	if ! command -v shfmt >/dev/null 2>&1; then
		echo "Warning: shfmt is not installed"
		echo "Manual formatting check will be performed instead."
		echo "Install shfmt for automatic formatting:"
		echo "  brew install shfmt  # macOS"
		echo "  go install mvdan.cc/sh/v3/cmd/shfmt@latest  # Go users"
		echo ""

		# Perform basic formatting validation instead
		echo "Checking for common formatting issues..."
		local issues_found=0

		while IFS= read -r file; do
			echo "Checking $file for formatting issues..."

			# Check for mixed tabs and spaces (basic check)
			if grep -E $'^\t+ +' "$file" >/dev/null 2>&1 || grep -E $'^  +\t+' "$file" >/dev/null 2>&1; then
				echo "  Warning: Mixed tabs and spaces found in $file"
				((issues_found++))
			fi

			# Check for trailing whitespace
			if grep -E '[ \t]+$' "$file" >/dev/null 2>&1; then
				echo "  Warning: Trailing whitespace found in $file"
				((issues_found++))
			fi
		done <<<"$shell_files"

		if [[ $issues_found -eq 0 ]]; then
			echo "No formatting issues detected."
		else
			echo "$issues_found formatting issues detected. Install shfmt to fix automatically."
		fi

		if [[ $issues_found -eq 0 ]]; then
			exit 0
		else
			exit 1
		fi
	fi

	echo "Formatting shell files:"
	echo "$shell_files"
	echo

	# Format files using shfmt
	# -i 0: use tabs for indentation
	# -ci: indent switch cases
	# -w: write result to file instead of stdout
	while IFS= read -r file; do
		echo "Formatting $file..."
		shfmt -i 0 -ci -w "$file"
	done <<<"$shell_files"

	echo "All shell files have been formatted"
}

main "$@"
