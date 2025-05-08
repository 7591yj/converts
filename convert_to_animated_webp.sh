#!/bin/bash

if ! command -v ffmpeg &>/dev/null; then
  echo "ffmpeg is not installed. Please install it and try again."
  exit 1
fi

output_dir="animated_webp_output"
mkdir -p "$output_dir"

for vid in *.mp4 *.webm *.gif; do
  [ -e "$vid" ] || continue

  base="${vid%.*}"

  output="${output_dir}/${base}_animated.webp"

  echo "Converting: $vid -> $output"

  ffmpeg -i "$vid" \
    -vcodec libwebp \
    -filter:v fps=fps=20 \
    -lossless 1 \
    -loop 0 \
    -preset default \
    -an \
    -vsync 0 \
    -s 512:512 \
    "$output"
done

echo "All animated conversions completed. Output saved in '$output_dir'."
