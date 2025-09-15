#!/bin/bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

main() {
    echo "Running tests for worktrees CLI..."

    # Check if bats is available
    if ! command -v bats >/dev/null 2>&1; then
        echo "Error: bats (Bash Automated Testing System) is not installed"
        echo "Please install bats: https://github.com/bats-core/bats-core"
        exit 1
    fi

    # Find all .bats test files
    local test_files
    test_files=$(find "$PROJECT_ROOT/tests" -name "*.bats" -type f 2>/dev/null || true)

    if [[ -z "$test_files" ]]; then
        echo "No test files found in tests/ directory"
        echo "Tests will be added during TDD implementation phase"
        exit 0
    fi

    echo "Found test files:"
    echo "$test_files"
    echo

    # Run tests
    # shellcheck disable=SC2086
    bats $test_files
}

main "$@"