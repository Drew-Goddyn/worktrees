# Research: Manage Git feature worktrees

This document consolidates decisions made to resolve ambiguities and define the technical approach for the Git worktrees management tool. Each decision includes rationale and alternatives considered.

## Unknowns Resolved

### U1. Language/Runtime for CLI
- Decision: Bash (POSIX-compatible) using Git CLI; require Git ≥ 2.33.
- Rationale: Native fit for Git operations; zero external runtime; easiest distribution; portable across macOS/Linux.
- Alternatives considered: Python 3.11 (richer stdlib, dependency mgmt), Node.js 20 (ecosystem). Rejected for added runtime dependency and packaging overhead for v1.

### U2. Default worktrees root
- Decision: `$HOME/.worktrees` as the global hidden root; override via `--root` flag or config env `WORKTREES_ROOT`.
- Rationale: Hidden, global, avoids clutter inside repo; clear single place to manage storage.
- Alternatives considered: Project-local `.worktrees` under repo root (risks clutter, nested repos), `$HOME/worktrees` (not hidden).

### U3. Base detection when not provided
- Decision: Default to repository default branch (remote HEAD) if available; else `main` if present; else `master`.
- Mechanism: Use `git symbolic-ref --quiet refs/remotes/origin/HEAD` to detect remote HEAD; fall back via `git show-ref --verify` checks.
- Rationale: Matches FR-008; ensures predictable default.

### U4. Naming convention enforcement
- Decision: Enforce regex `^[0-9]{3}-[a-z0-9-]{1,40}$`; case-insensitive uniqueness across worktrees; reserved names `main`, `master` disallowed.
- Rationale: Meets FR-005; prevents collisions; keeps names readable and sortable.
- Alternatives considered: Allow uppercase/underscores; rejected for cross-platform safety and simplicity.

### U5. Pre-existing local branch with requested feature name (different base)
- Decision: Error by default. Provide `--reuse-branch` to reuse if not checked out in any worktree; require explicit `--base` acknowledgment mismatch.
- Rationale: Safety first; avoids silent divergence.

### U6. Branch already checked out in another worktree
- Decision: Disallow duplicate checkout. Offer selecting existing worktree or `--sibling <suffix>` to create a sibling branch (e.g., `-2`).
- Rationale: Aligns FR-013 and Git worktree rules.

### U7. Dirty-state policies
- Decision: Switching allowed with a prominent warning summarizing dirty state. Removal blocked if tracked changes exist or an operation is in progress; removal blocked if unpushed commits or no upstream. `--force` only deletes untracked/ignored files.
- Rationale: Matches FR-011.

### U8. Cleanup semantics for tags
- Decision: Never delete tags automatically. Tag deletion (if desired) must be manual.
- Rationale: Tags are often shared/released artifacts; high risk to remove automatically.

### U9. Scale expectations and listing
- Decision: Expect up to ~100 worktrees per repo. Implement filtering by name and base; paging with `--page` and `--page-size` (default 20, max 100).
- Rationale: Keeps CLI responsive; avoids overwhelming output (Edge case note in spec).

### U10. Safety checks for removal
- Decision: Consider fully merged only if `git merge-base --is-ancestor <branch> <base>` returns success; require explicit `--delete-branch` and `--merged-into <base>` to delete branch.
- Rationale: Prevents data loss and enforces explicit user intent.

### U11. Worktree path issues
- Decision: Prevent creation if target path exists/non-empty; robust quoting for spaces/special chars; treat names differing only by case as duplicates on case-insensitive filesystems.
- Rationale: Cross-platform correctness and safety.

### U12. Non-repo execution
- Decision: Detect repo root via `git rev-parse --show-toplevel`; refuse commands outside a repo; print clear guidance.
- Rationale: Avoid misuse and unclear state.

## Best Practices Collected
- Provide `--format json|text` across commands; default `text` for humans, `json` for tooling.
- Print actionable errors with remediation steps (e.g., suggest `git fetch --all --prune` when base missing remotely).
- Log to stderr for warnings/errors; stdout reserved for primary output payloads.
- Exit codes: 0 success, 2 validation error, 3 precondition failure, 4 conflict, 5 unsafe state, 6 not found.

## Decisions Summary
- Language: Bash + Git CLI; Tests planned with `bats` during implementation.
- Root: `$HOME/.worktrees` with `--root` and `WORKTREES_ROOT` override.
- Naming: `^[0-9]{3}-[a-z0-9-]{1,40}$`, case-insensitive unique; reserved names disallowed.
- Defaults: Base auto-detected from remote HEAD; explicit override supported.
- Safety: Conservative removal policy; explicit flags for dangerous ops.
- Scale: Paging and filtering supported in list.
- Tags: Never auto-deleted.

All NEEDS CLARIFICATION items are resolved above.


