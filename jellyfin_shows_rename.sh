#!/bin/bash

# Extract season number from parent directory (expects "Season XX")
season_dir="$(basename "$(pwd)")"
if [[ "$season_dir" =~ [Ss]eason[[:space:]]*([0-9]+) ]]; then
    season_num=$(printf "%02d" "${BASH_REMATCH[1]}")
else
    echo "Error: Parent directory must be named like 'Season 01'"
    exit 1
fi

# Process each regular file in the directory
for file in *; do
    [[ -f "$file" ]] || continue

    base="$file"
    new_file=""

    # Handle "#NN" pattern
    if [[ "$base" =~ (.*?)[[:space:]]*#[[:space:]]*([0-9]+)[[:space:]]*(.*) ]]; then
        prefix="${BASH_REMATCH[1]}"
        ep_num=$(printf "%02d" "${BASH_REMATCH[2]}")
        suffix="${BASH_REMATCH[3]}"
        new_file="${prefix} S${season_num}E${ep_num}: ${suffix}"

    # Handle "Episode NN :" pattern (with exact spacing). Supports both half-width and full-width colons.
    elif [[ "$base" =~ (.*?)Episode[[:space:]]+([0-9]+)[[:space:]]*[:：][[:space:]]*(.*) ]]; then
        prefix="${BASH_REMATCH[1]}"
        ep_num=$(printf "%02d" "${BASH_REMATCH[2]}")
        suffix="${BASH_REMATCH[3]}"
        new_file="${prefix} S${season_num}E${ep_num}: ${suffix}"
    fi

    # If a new name is constructed and differs from original, rename
    if [[ -n "$new_file" && "$file" != "$new_file" ]]; then
        mv -v -- "$file" "$new_file"
    fi
done
