#!/usr/bin/env bash
# Usage: make-video.sh [-f FPS] [-o OUTPUT.mp4] [SESSION_DIR]
# SESSION_DIR defaults to the newest session under SHOTS_DIR; output defaults to <SESSION_DIR>.mp4.
set -euo pipefail
SHOTS_DIR="${SHOTS_DIR:-$HOME/.screen-recordings}"; INTERVAL="${INTERVAL:-2}"; FPS="${FPS:-10}"
# Optional overrides: ~/.config/screen-record-chrome/config (same variable names)
[ -f "$HOME/.config/screen-record-chrome/config" ] && . "$HOME/.config/screen-record-chrome/config"

command -v ffmpeg >/dev/null || { echo "ffmpeg missing: brew install ffmpeg (macOS) | sudo apt install ffmpeg (Linux)" >&2; exit 1; }

OUTFILE=""
while getopts "f:o:" o; do
  case $o in f) FPS=$OPTARG;; o) OUTFILE=$OPTARG;; *) exit 1;; esac
done
shift $((OPTIND - 1))

DIR="${1:-$(ls -1d "$SHOTS_DIR"/*/ 2>/dev/null | sort | tail -1)}"
DIR="${DIR%/}"
[ -n "$DIR" ] && [ -f "$DIR/frame_000001.png" ] || { echo "no frames found" >&2; exit 1; }
OUTFILE="${OUTFILE:-$DIR.mp4}"

# Numbered pattern (not -pattern_type glob) so it works with any ffmpeg build.
ffmpeg -y -loglevel error -framerate "$FPS" -i "$DIR/frame_%06d.png" \
  -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" -c:v libx264 -pix_fmt yuv420p "$OUTFILE"
echo "$OUTFILE ($(ls "$DIR" | grep -c '^frame_.*\.png$') frames at ${FPS}fps)"
