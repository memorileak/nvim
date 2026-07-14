#!/bin/bash
# Get git changed files (staged + unstaged) for linting
# Falls back to current file if no changes or not in git repo
# Usage: get_eslint_files.sh <current_file_path>

# Current file path should be passed as the first argument,
# Default to current directory if not provided.
CURRENT_FILE="${1:-.}"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  # Not in a git repo, use current file
  echo "$CURRENT_FILE"
  exit 0
fi

# Get both staged and unstaged changed files
CHANGED_FILES=$(git diff --name-only HEAD 2>/dev/null && git diff --cached --name-only HEAD 2>/dev/null | sort -u)

# Filter for JS/TS/JSX/TSX files
# FILTERED_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|jsx|ts|tsx)$' | sort -u)
FILTERED_FILES=$CHANGED_FILES

# If we have changed files, use them; otherwise fall back to current file
if [ -n "$FILTERED_FILES" ]; then
  echo "$FILTERED_FILES" | tr '\n' ' ' | sed 's/[[:space:]]*$//'
else
  echo "$CURRENT_FILE"
fi
