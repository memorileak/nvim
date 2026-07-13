#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Find all relevant source files using fd
# fd respects .gitignore by default
mapfile -t files < <(fd \
  -t f \
  -e js -e jsx -e mjs -e cjs \
  -e ts -e tsx -e mts -e cts \
  -e rs \
  -e py)

# Check if any files were found
if [ ${#files[@]} -eq 0 ]; then
  echo "No matching source code files found."
  exit 0
fi

# Run universal-ctags using standard input list
# -L - tells ctags to read the file list from stdin
# -f .tags explicitly names the output file (overwriting it)
echo "Generating Vim-compatible tags file for ${#files[@]} files..."

printf "%s\n" "${files[@]}" | ctags -L - -f .tags

echo "Tags file '.tags' successfully generated for Vim/Neovim."
