# Gemini CLI Agent Context

Use Gemini for broad codebase or multi-file analysis beyond Cursor context. Paths are absolute or relative to repo root.

Examples:

```bash
gemini -p "@./ Summarize this project's structure and identify any existing Git tooling"

gemini -p "@specs/001-build-a-tool/ @src/ Verify whether a worktrees CLI exists; if not, outline key modules"

gemini -p "@specs/001-build-a-tool/contracts/ Analyze CLI contracts and propose test cases for bats"
```

Conventions:
- Prefer `--all_files` when scanning the entire repo.
- Use `@specs/001-build-a-tool/` to keep the feature context in view.
- Keep prompts specific to contracts, data model, and quickstart to generate targeted insights.


