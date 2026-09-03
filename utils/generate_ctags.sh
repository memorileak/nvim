#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

FD_ARGS=("-a" "-t" "f")

# Process command-line arguments as file extensions
for ext in "$@"; do
  FD_ARGS+=("-e" "$ext")
done

echo "Scanning with: fd ${FD_ARGS[@]}"

# Find all relevant source files using fd
# fd respects .gitignore by default
mapfile -t files < <(fd "${FD_ARGS[@]}")

# Check if any files were found
if [ ${#files[@]} -eq 0 ]; then
  echo "No matching source code files found."
  exit 0
fi

# Run universal-ctags using standard input list
# -L - tells ctags to read the file list from stdin
# -f .tags explicitly names the output file (overwriting it)
echo "Generating tags file for ${#files[@]} files..."

printf "%s\n" "${files[@]}" | ctags --quiet -L - -f .tags

echo "Tags file '.tags' successfully generated."

# If in the current directory there is a rusty-tags.vi file,
# append its content to our generated .tags file
if [ -f "rusty-tags.vi" ]; then
  echo "Appending rusty-tags.vi to '.tags' file..."
  cat rusty-tags.vi >>.tags
  echo "Appended rusty-tags.vi to '.tags' file."
fi
