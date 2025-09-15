# Makefile for worktrees CLI

.PHONY: test lint fmt help

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

# Show help
help:
	@echo "Available targets:"
	@echo "  test    - Run all tests via scripts/test.sh"
	@echo "  lint    - Run ShellCheck linting via scripts/lint.sh"
	@echo "  fmt     - Format shell scripts via scripts/format.sh"
	@echo "  help    - Show this help message"
	@echo "  all     - Run lint and test (default)"