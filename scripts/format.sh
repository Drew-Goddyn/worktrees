#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
    echo "Formatting shell scripts with shfmt..."

    # Check if shfmt is available
    if ! command -v shfmt >/dev/null 2>&1; then
        echo "Error: shfmt is not installed"
        echo "Please install shfmt: https://github.com/mvdan/sh"
        exit 1
    fi

    # Find all shell scripts
    local shell_files
    shell_files=$(find "$PROJECT_ROOT" -name "*.sh" -type f -o -path "*/src/cli/*" -type f | grep -v ".git" | sort)

    if [[ -z "$shell_files" ]]; then
        echo "No shell files found to format"
        exit 0
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
    done <<< "$shell_files"

    echo "All shell files have been formatted"
}

main "$@"