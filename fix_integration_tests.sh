#!/bin/bash

# Script to fix integration tests by removing "not yet implemented" expectations
# and enabling the real test assertions

set -euo pipefail

# List of integration test files that need fixing
TEST_FILES=(
    "tests/integration/list_worktrees.bats"
    "tests/integration/switch_worktree.bats"
    "tests/integration/remove_keep_branch.bats"
    "tests/integration/remove_delete_branch.bats"
)

for file in "${TEST_FILES[@]}"; do
    echo "Fixing $file..."

    # Create a backup
    cp "$file" "$file.backup"

    # Use sed to remove the "not yet implemented" expectations
    # This removes lines that check for status -eq 1 AND "not yet implemented"
    # Also uncomments the real test assertions
    sed -i '' '
        # Remove lines checking for status -eq 1 with "not yet implemented"
        /\[ "\$status" -eq 1 \]/d
        /\[\[ "\$output" =~ "not yet implemented" \]\]/d

        # Remove comment markers from real assertions (lines starting with #)
        # But be careful to only uncomment test assertions, not all comments
        s/^[[:space:]]*# \[\[ /\t[[ /
        s/^[[:space:]]*# \[ /\t[ /
        s/^[[:space:]]*# is_valid_json/\tis_valid_json/
        s/^[[:space:]]*# run/\trun/

        # Remove placeholder comment lines about "Currently fails on implementation"
        /# Currently fails on implementation/d
        /# When implemented/d
    ' "$file"

    echo "Fixed $file"
done

echo "Integration test fix complete!"
echo ""
echo "You may want to review and manually adjust specific test expectations"
echo "that don't match the actual implementation behavior."