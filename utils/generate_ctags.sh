#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

EXT_FILE="./.tags.ext"
FD_ARGS=("-t" "f")

# Check if the extensions file exists and is not empty
if [ -s "$EXT_FILE" ]; then
  mapfile -t EXT_ARGS < <(sed 's/^/-e /' $EXT_FILE)
  FD_ARGS+=(${EXT_ARGS[@]})
fi

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
