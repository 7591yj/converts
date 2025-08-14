#!/usr/bin/env bash
set -euo pipefail
trap 'echo "❌ Script failed on line $LINENO"; exit 1' ERR

if [ $# -lt 1 ]; then
  echo "Usage: $0 <sticker|emoji>"
  exit 1
fi

TYPE="$1"

# Set target size
if [ "$TYPE" = "sticker" ]; then
  TARGET=512
elif [ "$TYPE" = "emoji" ]; then
  TARGET=100
else
  echo "Invalid type: $TYPE. Use 'sticker' or 'emoji'."
  exit 1
fi

# Output folder
OUTDIR="./webm"
mkdir -p "$OUTDIR"

# Supported extensions
EXTS="jpg jpeg png gif webp bmp tiff"

# Gather files
FILES=""
for ext in $EXTS; do
  for f in *."$ext"; do
    [ -e "$f" ] && FILES="$FILES $f"
  done
done

TOTAL=$(echo "$FILES" | wc -w | tr -d ' ')
if [ "$TOTAL" -eq 0 ]; then
  echo "No supported image files found."
  exit 0
fi

COUNT=0
for INPUT in $FILES; do
  COUNT=$((COUNT + 1))
  BASENAME=$(basename "$INPUT")
  NAME="${BASENAME%.*}"
  OUTPUT="${OUTDIR}/${NAME}.webm"

  printf "[%2d/%2d] Converting: %-30s " "$COUNT" "$TOTAL" "$BASENAME"

  # Get original dimensions (portable way)
  WIDTH=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=width -of csv=p=0 "$INPUT")
  HEIGHT=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=height -of csv=p=0 "$INPUT")

  # Choose scaling filter
  if [ "$TYPE" = "sticker" ]; then
    # Longest side = 512, keep aspect ratio, scale up if needed
    if [ "$WIDTH" -ge "$HEIGHT" ]; then
      FILTER="scale=$TARGET:-1:flags=lanczos"
    else
      FILTER="scale=-1:$TARGET:flags=lanczos"
    fi
  else
    # Emoji: exactly 100x100, pad to square
    FILTER="scale='if(gt(iw,ih),$TARGET,-1)':'if(gt(ih,iw),$TARGET,-1)',scale='min(iw,$TARGET)':'min(ih,$TARGET)',pad=$TARGET:$TARGET:(ow-iw)/2:(oh-ih)/2:color=0x00000000"
  fi

  # Temp file for logs
  LOGFILE=$(mktemp /tmp/ffmpeg_log.XXXXXX)

  # Run ffmpeg
  if ! ffmpeg -y \
    -loglevel error \
    -i "$INPUT" \
    -vf "$FILTER,fps=30" \
    -t 3 \
    -an \
    -c:v libvpx-vp9 \
    -b:v 256K \
    -crf 30 \
    -pix_fmt yuva420p \
    "$OUTPUT" 2>"$LOGFILE"; then
    echo "❌ Failed"
    echo "---- ffmpeg log for $BASENAME ----"
    cat "$LOGFILE"
    echo "----------------------------------"
    rm -f "$LOGFILE"
    continue
  fi

  rm -f "$LOGFILE"

  # Check file size
  FILESIZE=$(stat -c%s "$OUTPUT" 2>/dev/null || stat -f%z "$OUTPUT")
  MAXSIZE=$((256 * 1024))

  if [ "$FILESIZE" -gt "$MAXSIZE" ]; then
    LOGFILE=$(mktemp /tmp/ffmpeg_log.XXXXXX)
    if ! ffmpeg -y \
      -loglevel error \
      -i "$OUTPUT" \
      -c:v libvpx-vp9 \
      -b:v 200K \
      -crf 35 \
      -pix_fmt yuva420p \
      "$OUTPUT.tmp.webm" 2>"$LOGFILE"; then
      echo "❌ Failed during size reduction"
      echo "---- ffmpeg log for $BASENAME ----"
      cat "$LOGFILE"
      echo "----------------------------------"
      rm -f "$LOGFILE"
      continue
    fi
    rm -f "$LOGFILE"
    mv "$OUTPUT.tmp.webm" "$OUTPUT"
  fi

  echo "✅ Done"
done

echo "🎉 All conversions complete! Files saved in $OUTDIR/"
exit 0
