# Feature Specification: Manage Git feature worktrees

**Feature Branch**: `[001-build-a-tool]`  
**Created**: 2025-09-15  
**Status**: Draft  
**Input**: User description: "Build a tool to manage Git worktrees for feature-based development: enable quick creation of feature-specific worktrees from a chosen base, list and switch between worktrees, enforce clear naming to avoid collisions, and support safe cleanup of completed worktrees. Focus narrowly on worktree lifecycle and navigation."

## Execution Flow (main)
```
1. Parse user description from Input
   → If empty: ERROR "No feature description provided"
2. Extract key concepts from description
   → Identify: actors, actions, data, constraints
3. For each unclear aspect:
   → Mark with [NEEDS CLARIFICATION: specific question]
4. Fill User Scenarios & Testing section
   → If no clear user flow: ERROR "Cannot determine user scenarios"
5. Generate Functional Requirements
   → Each requirement must be testable
   → Mark ambiguous requirements
6. Identify Key Entities (if data involved)
7. Run Review Checklist
   → If any [NEEDS CLARIFICATION]: WARN "Spec has uncertainties"
   → If implementation details found: ERROR "Remove tech details"
8. Return: SUCCESS (spec ready for planning)
```

---

## ⚡ Quick Guidelines
- ✅ Focus on WHAT users need and WHY
- ❌ Avoid HOW to implement (no tech stack, APIs, code structure)
- 👥 Written for business stakeholders, not developers

### Section Requirements
- **Mandatory sections**: Must be completed for every feature
- **Optional sections**: Include only when relevant to the feature
- When a section doesn't apply, remove it entirely (don't leave as "N/A")

### For AI Generation
When creating this spec from a user prompt:
1. **Mark all ambiguities**: Use [NEEDS CLARIFICATION: specific question] for any assumption you'd need to make
2. **Don't guess**: If the prompt doesn't specify something (e.g., "login system" without auth method), mark it
3. **Think like a tester**: Every vague requirement should fail the "testable and unambiguous" checklist item
4. **Common underspecified areas**:
   - User types and permissions
   - Data retention/deletion policies  
   - Performance targets and scale
   - Error handling behaviors
   - Integration requirements
   - Security/compliance needs

---

## User Scenarios & Testing *(mandatory)*

### Primary User Story
As a developer working across multiple features, I want to create isolated Git worktrees per feature, list and switch between them, and safely clean them up when finished so that I can work in parallel without polluting my main repository workspace.

### Acceptance Scenarios
1. **Given** no existing worktree for a requested feature, **When** a developer requests creation from a specified base, **Then** a uniquely named feature worktree is created and made active.
2. **Given** multiple worktrees exist, **When** a developer requests a list of worktrees, **Then** the system returns each worktree's name, source/base reference, and whether it is currently active.
3. **Given** a feature worktree exists, **When** a developer switches to it, **Then** the active working copy becomes that worktree without modifying other worktrees.
4. **Given** a finished worktree, **When** a developer requests safe cleanup, **Then** the worktree is removed without unintended data loss, the branch is kept by default, and branch deletion is allowed only with explicit opt-in and only if fully merged into a specified base.
5. **Given** a worktree has uncommitted changes, **When** a developer switches away to another worktree, **Then** switching proceeds and a clear warning summarizes the dirty state.
6. **Given** a worktree has uncommitted changes or untracked/ignored files, **When** a developer requests removal, **Then** removal is blocked by default; explicit force is allowed only for untracked/ignored files; removal is never allowed if there are unpushed commits or an operation (e.g., rebase/merge/cherry-pick) in progress.

### Edge Cases
- Base reference does not exist or is unreachable.
- Duplicate or invalid feature name: prevent collisions and guide the user to choose a different name.
- Existing branch without a corresponding worktree: on create, reuse the existing branch for the new worktree; no new branch is required.
- Attempt to remove the currently active worktree: disallow and guide the user.
- Worktree directory manually moved or deleted outside the tool: detect and reconcile or offer cleanup.
- Large repositories with many worktrees: provide filtering or paging for listing. [NEEDS CLARIFICATION: expected scale and limits]
- Base reference exists only on remote and is not fetched locally: auto-fetch the base; on fetch failure, abort with clear guidance.
- Branch already checked out in another worktree: disallow duplicate checkout; offer selecting the existing worktree or creating a sibling branch via explicit opt-in.
- Pre-existing local branch name conflicts with requested feature name (different base): decide whether to reuse or error. [NEEDS CLARIFICATION]
- Target worktree path already exists or is non-empty: prevent creation and guide to a new path/name.
- Worktree path contains spaces or special characters: ensure operations handle quoting safely.
- Case-insensitive filesystem collisions (e.g., macOS): treat names differing only by case as duplicates.
- Dirty worktree handling: switching away is allowed with a warning; removal is blocked if tracked changes are present and blocked by default for untracked/ignored files unless explicitly forced; removal is never allowed if there are unpushed commits/no upstream or an operation in progress.
- Command executed outside a Git repository or inside a nested repository: detect repository root and prevent misuse with clear messaging.
- Stale worktree metadata after manual filesystem changes: offer pruning or repair.
- Environment lacks required Git features/version for worktrees: detect and inform with remediation steps.

## Requirements *(mandatory)*

### Functional Requirements
- **FR-001**: The system MUST allow developers to create isolated feature worktrees from a specified base reference.
- **FR-002**: The system MUST list existing worktrees for the current repository with name, base reference, and active status.
- **FR-003**: The system MUST switch the active working copy to a selected worktree on request.
- **FR-004**: The system MUST safely remove a finished worktree without unintended data loss; keep the branch by default, and allow branch deletion only with explicit opt-in and only if fully merged into a specified base.
- **FR-005**: The system MUST enforce this naming convention and uniqueness:
   - Format: NNN-kebab-feature
   - Charset: lowercase [a-z0-9-]
   - Length: feature segment ≤ 40 characters
   - Uniqueness: case-insensitive unique across existing worktrees
   - Reserved names disallowed: 'main', 'master'
- **FR-006**: The system MUST validate preconditions (e.g., base reference existence, clean state) and provide actionable feedback, including auto-fetching a remote-only base before creation and aborting with clear guidance on failure.
- **FR-007**: The system MUST present clear status of the current worktree (name, base reference, path).
- **FR-008**: The system MUST select a default base when none is provided: use the repository's default branch (remote HEAD) when available; else use 'main' if it exists; else use 'master'. The chosen base MUST be displayed and always overrideable via flag/config.
- **FR-009**: The system MUST handle invalid or conflicting operations with informative messages (e.g., cannot remove active worktree).
- **FR-010**: The system MUST default to a global hidden worktrees root under the user's workspace (kept separate from primary repositories) and MUST allow override via flag and config. The chosen location MUST be displayed.
- **FR-011**: The system MUST enforce conservative dirty-state policies: allow switching between worktrees even if the current worktree is dirty (with a visible warning); block removal if tracked changes are present or an operation is in progress; block removal if the branch has unpushed commits or no upstream; allow explicit force solely to delete untracked/ignored files.
- **FR-012**: The system SHOULD provide responsive UX for common operations (create, list, switch); specific performance targets are deferred until post-MVP metrics are collected.
 - **FR-013**: When a requested branch is already checked out in another worktree, the system MUST disallow duplicate checkout and offer either selecting the existing worktree or creating a sibling branch via explicit opt-in.
 - **FR-014**: When creating a worktree and a local branch with the requested name exists and is not checked out in any worktree, the system MUST reuse that branch rather than creating a new branch.
 - **FR-015**: For v1, the system MUST expose a command-line interface. Non-CLI interfaces are out of scope.
 - **FR-016**: For v1, the system MUST operate only on the current Git repository; cross-repository scanning or actions are out of scope.

*Ambiguities to resolve:*
- Cleanup semantics are [NEEDS CLARIFICATION: whether to delete associated tags]

### Key Entities *(include if feature involves data)*
- **Feature Worktree**: An isolated working copy tied to a specific feature branch; created from a base reference.
- **Base Reference**: The source branch or commit from which a feature worktree is created.
- **Feature Name**: The human-readable label used to name and identify a worktree.
- **Repository**: The Git project within which feature worktrees are managed.

---

## Review & Acceptance Checklist
*GATE: Automated checks run during main() execution*

### Content Quality
- [ ] No implementation details (languages, frameworks, APIs)
- [ ] Focused on user value and business needs
- [ ] Written for non-technical stakeholders
- [ ] All mandatory sections completed

### Requirement Completeness
- [ ] No [NEEDS CLARIFICATION] markers remain
- [ ] Requirements are testable and unambiguous  
- [ ] Success criteria are measurable
- [ ] Scope is clearly bounded
- [ ] Dependencies and assumptions identified

---

## Execution Status
*Updated by main() during processing*

- [ ] User description parsed
- [ ] Key concepts extracted
- [ ] Ambiguities marked
- [ ] User scenarios defined
- [ ] Requirements generated
- [ ] Entities identified
- [ ] Review checklist passed

---


