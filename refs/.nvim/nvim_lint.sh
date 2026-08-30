#!/bin/bash

# Run TypeScript compiler in noEmit mode to check for type errors
# npx --no-install tsc -p tsconfig.app.json --noEmit --pretty false 2>&1 |
#     sed '/^[[:space:]]*$/d'

# Capture optional file path argument
ADDITIONAL_FILE="$1"

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  exit 0
fi

# Get both staged and unstaged changed files (excluding deleted)
CHANGED_FILES=$(
  {
    git diff --name-only --diff-filter=d 2>/dev/null
    git diff --cached --name-only --diff-filter=d 2>/dev/null
  } | sort -u
)

# Combine changed files with optional file path
if [ -n "$ADDITIONAL_FILE" ]; then
  CHANGED_FILES=$(
    {
      echo "$CHANGED_FILES"
      echo "$ADDITIONAL_FILE"
    } | sort -u
  )
fi

# Exit early if no changes and no optional file provided
if [ -z "$CHANGED_FILES" ]; then
  exit 0
fi

# Filter for JavaScript/TypeScript files
if command -v rg >/dev/null 2>&1; then
  FILTERED_FILES=$(echo "$CHANGED_FILES" | rg -e '\.(js|jsx|mjs|cjs|ts|tsx|mts|cts|d\.ts|d\.mts|d\.cts)$')
else
  FILTERED_FILES=$(echo "$CHANGED_FILES" | grep -E '\.(js|jsx|mjs|cjs|ts|tsx|mts|cts|d\.ts|d\.mts|d\.cts)$')
fi

# Exit if no JS/TS files changed
if [ -z "$FILTERED_FILES" ]; then
  exit 0
fi

# Convert newlines to space-separated list
FILTERED_FILES=$(echo "$FILTERED_FILES" | tr '\n' ' ' | sed 's/[[:space:]]*$//')

# Check formatter file exists
ESLINT_FORMATTER_FILE="$(pwd)/.nvim/eslint_formatter.js"
if [ ! -f "$ESLINT_FORMATTER_FILE" ]; then
  echo "Warning: Formatter file not found: $ESLINT_FORMATTER_FILE" >&2
  exit 1
fi

# Run eslint and filter empty lines
# shellcheck disable=SC2086
npx --no-install eslint -f "$ESLINT_FORMATTER_FILE" $FILTERED_FILES 2>&1 |
  sed '/^[[:space:]]*$/d'
