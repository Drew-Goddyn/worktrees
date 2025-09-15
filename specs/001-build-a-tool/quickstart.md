# Quickstart: Manage Git feature worktrees

Prerequisites:
- Git ≥ 2.33
- macOS or Linux shell (zsh/bash)

Concepts:
- Feature worktrees are isolated working copies tied to branches, created under a global root (default `$HOME/.worktrees`).
- Names must match `NNN-kebab-feature` (lowercase, ≤ 40 chars feature part).

Common flows (anticipated CLI; implementation to follow tasks):

## Create a worktree
```bash
worktrees create 001-build-a-tool --base main --format json
```

## List worktrees (paged)
```bash
worktrees list --page 1 --page-size 20 --format json
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

Notes:
- Use `--root` to override the global worktrees root.
- Use `--reuse-branch` to reuse an existing local branch not checked out elsewhere.
- Use `--sibling -2` to create a sibling branch when the branch is already checked out in another worktree.


