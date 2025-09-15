# Makefile for worktrees CLI

.PHONY: test lint fmt help install uninstall clean check ci

# Default target
all: lint test

# Run all tests
test:
	@echo "Running tests..."
	@./scripts/test.sh

# Run linting with ShellCheck
lint:
	@echo "Running linting..."
	@./scripts/lint.sh

# Format code with shfmt
fmt:
	@echo "Formatting code..."
	@./scripts/format.sh

# Install worktrees CLI system-wide
install:
	@echo "Installing worktrees CLI to /usr/local/bin..."
	@install -m 755 src/cli/worktrees /usr/local/bin/worktrees
	@echo "Installation complete. Run 'worktrees --help' to get started."

# Uninstall worktrees CLI
uninstall:
	@echo "Removing worktrees CLI from /usr/local/bin..."
	@rm -f /usr/local/bin/worktrees
	@echo "Uninstallation complete."

# Clean up temporary files and test artifacts
clean:
	@echo "Cleaning up temporary files..."
	@find . -name "*.tmp" -type f -delete 2>/dev/null || true
	@find . -path "*/.worktrees" -type d -exec rm -rf {} + 2>/dev/null || true
	@rm -rf /tmp/test-worktrees 2>/dev/null || true
	@echo "Cleanup complete."

# Basic syntax and validation check (fallback when ShellCheck not available)
check:
	@echo "Running basic syntax validation..."
	@scripts/check.sh

# CI/CD target - comprehensive checks for continuous integration
ci: check test
	@echo "All CI checks passed successfully."

# Show help
help:
	@echo "Available targets:"
	@echo "  test      - Run all tests via scripts/test.sh"
	@echo "  lint      - Run ShellCheck linting via scripts/lint.sh"
	@echo "  fmt       - Format shell scripts via scripts/format.sh"
	@echo "  check     - Run basic syntax validation (fallback for missing ShellCheck)"
	@echo "  install   - Install worktrees CLI to /usr/local/bin"
	@echo "  uninstall - Remove worktrees CLI from /usr/local/bin"
	@echo "  clean     - Clean up temporary files and test artifacts"
	@echo "  ci        - Run all checks for continuous integration"
	@echo "  help      - Show this help message"
	@echo "  all       - Run lint and test (default)"
	@echo ""
	@echo "Development setup:"
	@echo "  For full linting support, install ShellCheck and shfmt:"
	@echo "    brew install shellcheck shfmt  # macOS"
	@echo "    apt-get install shellcheck     # Ubuntu/Debian"