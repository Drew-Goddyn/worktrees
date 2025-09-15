# CLI Contracts: Manage Git feature worktrees

All commands operate within a Git repository unless noted. Outputs default to human-readable text; `--format json` returns structured JSON. Errors/warnings go to stderr. Exit codes: 0 success, 2 validation error, 3 precondition failure, 4 conflict, 5 unsafe state, 6 not found.

## worktrees create <NNN-kebab-feature>
- Flags:
  - `--base <ref>`: base reference; if omitted, auto-detect default base
  - `--root <path>`: override global root (default `$HOME/.worktrees`)
  - `--reuse-branch`: reuse existing local branch if present and not checked out
  - `--sibling <suffix>`: create sibling branch if branch already checked out elsewhere
  - `--format <text|json>`: output format
- Behavior:
  - Validates name against `^[0-9]{3}-[a-z0-9-]{1,40}$`; reserved names disallowed
  - Auto-fetch base if remote-only; abort with guidance on fetch failure
  - Prevent duplicate checkout; suggest existing worktree or `--sibling`
  - Create worktree directory under root and checkout branch (create or reuse per rules)
- Output (json): `{ name, branch, baseRef, path, active: true }`

## worktrees list [--filter-name <substr>] [--filter-base <branch>] [--page N] [--page-size N]
- Behavior: Lists known worktrees for current repository with paging
- Output (json): `{ items: [ { name, branch, baseRef, path, active, isDirty, hasUnpushedCommits } ], page, pageSize, total }`

## worktrees switch <name>
- Behavior: Switches active working copy to the specified worktree; allowed even if current worktree is dirty; prints a warning summarizing dirty state
- Output (json): `{ current: { name, path }, previous: { name, path }, warnings: [ ... ] }`

## worktrees remove <name>
- Flags:
  - `--delete-branch`: also delete the associated branch if fully merged
  - `--merged-into <base>`: base branch to verify full merge
  - `--force`: allow deletion of untracked/ignored files only; tracked changes or ops in progress never allowed
  - `--format <text|json>`
- Behavior: Disallows removal if tracked changes, unpushed commits/no upstream, or operation in progress. Never deletes tags.
- Output (json): `{ removed: true, branchDeleted: boolean }`

## worktrees status
- Behavior: Shows current worktree status: name, base reference (if known), path
- Output (json): `{ name, baseRef, path }`

## Global
- `--help`, `--version`, `--format`, consistent across commands


