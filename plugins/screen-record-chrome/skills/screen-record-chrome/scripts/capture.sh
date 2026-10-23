#!/usr/bin/env bash
# Usage: capture.sh start [-d DIR] [-i SECONDS] [-n COUNT] | stop
# Takes a screenshot every INTERVAL seconds into DIR/<session>/frame_NNNNNN.png.
# Works on macOS (screencapture) and Linux (gnome-screenshot, grim, maim, scrot, import).
set -euo pipefail
SHOTS_DIR="${SHOTS_DIR:-$HOME/.screen-recordings}"; INTERVAL="${INTERVAL:-2}"; FPS="${FPS:-10}"
# Optional overrides: ~/.config/screen-record-chrome/config (same variable names)
[ -f "$HOME/.config/screen-record-chrome/config" ] && . "$HOME/.config/screen-record-chrome/config"
PIDFILE="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/screen-record-chrome.pid"

cmd="${1:-}"; shift || true
if [ "$cmd" = "stop" ]; then
  if [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null; then rm -f "$PIDFILE"; echo "stopped"; else rm -f "$PIDFILE"; echo "not running"; fi
  exit 0
fi
[ "$cmd" = "start" ] || { echo "usage: capture.sh start [-d DIR] [-i SECONDS] [-n COUNT] | stop" >&2; exit 1; }

COUNT=0
while getopts "d:i:n:" o; do
  case $o in d) SHOTS_DIR=$OPTARG;; i) INTERVAL=$OPTARG;; n) COUNT=$OPTARG;; *) exit 1;; esac
done

# Pick a capture backend; defines shot FILE.
if [ "$(uname -s)" = "Darwin" ]; then
  # First run needs Screen Recording permission for the terminal app (System Settings > Privacy & Security).
  shot() { screencapture -x -t png "$1"; }
elif [ -z "${WAYLAND_DISPLAY:-}" ] && command -v maim >/dev/null; then
  shot() { maim "$1"; }                  # X11: no flash, unlike gnome-screenshot
elif [ -z "${WAYLAND_DISPLAY:-}" ] && command -v scrot >/dev/null; then
  shot() { scrot -o "$1"; }
elif [ -z "${WAYLAND_DISPLAY:-}" ] && command -v import >/dev/null; then
  shot() { import -window root "$1"; }
elif [ -n "${WAYLAND_DISPLAY:-}" ] && [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]] && command -v grim >/dev/null; then
  shot() { grim "$1"; }                  # wlroots compositors (sway, Hyprland)
elif command -v gnome-screenshot >/dev/null; then
  shot() { gnome-screenshot -f "$1"; }   # GNOME Wayland (42+) allows only this; it flashes the screen on each shot
else
  echo "no screenshot tool found. Linux: sudo apt install maim or scrot (X11) | grim (sway/Hyprland) | gnome-screenshot (GNOME Wayland)" >&2
  exit 1
fi

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "already running (pid $(cat "$PIDFILE"))" >&2; exit 1
fi

OUT="$SHOTS_DIR/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT
echo "capturing every ${INTERVAL}s into $OUT"
i=0
while [ "$COUNT" -eq 0 ] || [ "$i" -lt "$COUNT" ]; do
  i=$((i + 1))
  shot "$(printf '%s/frame_%06d.png' "$OUT" "$i")"
  sleep "$INTERVAL"
done
