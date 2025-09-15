# Quickstart: Manage Git feature worktrees

Prerequisites:
- Git ≥ 2.33
- macOS or Linux shell (zsh/bash)

Concepts:
- Feature worktrees are isolated working copies tied to branches, created under a global root (default `$HOME/.worktrees`).
- Names must match `NNN-kebab-feature` (lowercase, ≤ 40 chars feature part).

Common flows:

## Create a worktree
```bash
worktrees create 001-build-a-tool --base main --format json
```

## List worktrees (paged)
```bash
# Text format (default)
worktrees list --page 1 --page-size 20

# JSON format with all status fields
worktrees list --format json --page 1 --page-size 20

# Fast JSON format without expensive status checks (for large repos)
worktrees list --format json --no-status --page-size 50
```

## Switch to a worktree (allowed even if current is dirty; warning shown)
```bash
worktrees switch 001-build-a-tool
```

## Remove a worktree safely (keep branch)
```bash
worktrees remove 001-build-a-tool
```

## Remove and delete branch when fully merged
```bash
worktrees remove 001-build-a-tool --delete-branch --merged-into main
```

## Check current status
```bash
worktrees status
```

## Advanced Options
- Use `--root <path>` to override the global worktrees root
- Use `--reuse-branch` to reuse an existing local branch not checked out elsewhere
- Use `--sibling` to create a sibling branch when the branch is already checked out in another worktree
- Use `--no-status` with list command for better performance on large repositories
- Use `--format json` for structured output suitable for scripts and tools

## Performance Tips
For repositories with many worktrees (>100):
```bash
# Use filters to narrow results
worktrees list --filter-name "001-*" --filter-base main

# Skip expensive git status checks for faster listing
worktrees list --no-status --page-size 100
```


