#!/bin/bash

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg could not be found. Please install it first."
  exit 1
fi

output_dir="resized_512x512"
mkdir -p "$output_dir"
for img in *.jpg *.png *.webp; do
  [ -e "$img" ] || continue

  base="${img%.*}"

  output="${output_dir}/${base}_512.webp"

  echo "Processing: $img -> $output"

  ffmpeg -i "$img" -vf scale=512:512 "$output"
done

echo "All files have been resized and saved in '$output_dir'."
