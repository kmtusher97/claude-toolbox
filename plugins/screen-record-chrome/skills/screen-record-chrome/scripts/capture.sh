#!/usr/bin/env bash
# Usage: capture.sh check | start [-d DIR] [-i SECONDS] [-n COUNT] | stop
# `check` reports the capture backend, whether it flashes the screen, and the exact steps to fix any problem.
# `start` takes a screenshot every INTERVAL seconds into DIR/<session>/frame_NNNNNN.png.
# Works on macOS (screencapture) and Linux (maim, scrot, import, grim, gnome-screenshot).
set -euo pipefail
SHOTS_DIR="${SHOTS_DIR:-$HOME/.screen-recordings}"; INTERVAL="${INTERVAL:-2}"; FPS="${FPS:-10}"
# Optional overrides: ~/.config/screen-record-chrome/config (same variable names)
[ -f "$HOME/.config/screen-record-chrome/config" ] && . "$HOME/.config/screen-record-chrome/config"
PIDFILE="${XDG_RUNTIME_DIR:-${TMPDIR:-/tmp}}/screen-record-chrome.pid"

OS="$(uname -s)"
SESSION=x11; [ -n "${WAYLAND_DISPLAY:-}" ] && SESSION=wayland
have() { command -v "$1" >/dev/null 2>&1; }

installer() {   # install command for package $1 on this machine
  if have brew; then echo "brew install $1"
  elif have apt-get; then echo "sudo apt install $1"
  elif have dnf; then echo "sudo dnf install $1"
  elif have pacman; then echo "sudo pacman -S $1"
  else echo "install $1 with your package manager"; fi
}

# Sets BACKEND (empty if none) and FLASH (yes if each shot flashes the screen).
pick_backend() {
  BACKEND=""; FLASH=no
  if [ "$OS" = "Darwin" ]; then BACKEND=screencapture
  elif [ "$SESSION" = x11 ] && have maim; then BACKEND=maim
  elif [ "$SESSION" = x11 ] && have scrot; then BACKEND=scrot
  elif [ "$SESSION" = x11 ] && have import; then BACKEND=import
  elif [ "$SESSION" = wayland ] && [[ "${XDG_CURRENT_DESKTOP:-}" != *GNOME* ]] && have grim; then BACKEND=grim   # sway, Hyprland
  elif have gnome-screenshot; then BACKEND=gnome-screenshot; FLASH=yes   # the only tool GNOME Wayland allows
  fi
}

shot() {
  case "$BACKEND" in
    screencapture) screencapture -x -t png "$1";;
    maim) maim "$1";;
    scrot) scrot -o "$1";;
    import) import -window root "$1";;
    grim) grim "$1";;
    gnome-screenshot) gnome-screenshot -f "$1";;
  esac
}

check() {
  pick_backend
  echo "os: $OS   session: $SESSION   desktop: ${XDG_CURRENT_DESKTOP:-n/a}"
  echo "capture tool: ${BACKEND:-none}"
  if have ffmpeg; then echo "ffmpeg: ok"; else echo "ffmpeg: MISSING -> $(installer ffmpeg)"; fi
  if [ "$OS" = "Darwin" ]; then
    echo "STATUS: ready. The first capture asks for Screen Recording permission for your terminal app (System Settings > Privacy & Security); allow it and restart the terminal."
  elif [ -n "$BACKEND" ] && [ "$FLASH" = "no" ]; then
    echo "STATUS: ready (no screen flash)"
  elif [ "$SESSION" = wayland ] && [[ "${XDG_CURRENT_DESKTOP:-}" == *GNOME* ]]; then
    [ -n "$BACKEND" ] && echo "STATUS: works, but the screen flashes on every shot (GNOME Wayland)." \
                     || echo "STATUS: no capture tool. Install one: $(installer gnome-screenshot)"
    echo "To remove the flash, switch to an X11 session:"
    n=1
    if ! have maim; then echo "  $n. $(installer maim)  "; n=$((n + 1)); fi
    echo "  $n. Log out, click your name, click the gear icon (bottom right), choose 'Ubuntu on Xorg', log in. No reboot needed."
    echo "Or keep Wayland and use a longer interval (-i 5) to make the flash less frequent."
  elif [ -n "$BACKEND" ]; then
    echo "STATUS: works, but gnome-screenshot flashes the screen. For a flash-free capture: $(installer maim)"
  else
    echo "STATUS: no capture tool. Install one: $(installer maim) (X11) or $(installer grim) (sway/Hyprland) or $(installer gnome-screenshot) (GNOME Wayland)"
  fi
}

cmd="${1:-}"; shift || true
case "$cmd" in
  check) check; exit 0;;
  stop)
    if [ -f "$PIDFILE" ] && kill "$(cat "$PIDFILE")" 2>/dev/null; then rm -f "$PIDFILE"; echo "stopped"; else rm -f "$PIDFILE"; echo "not running"; fi
    exit 0;;
  start) ;;
  *) echo "usage: capture.sh check | start [-d DIR] [-i SECONDS] [-n COUNT] | stop" >&2; exit 1;;
esac

COUNT=0
while getopts "d:i:n:" o; do
  case $o in d) SHOTS_DIR=$OPTARG;; i) INTERVAL=$OPTARG;; n) COUNT=$OPTARG;; *) exit 1;; esac
done

pick_backend
if [ -z "$BACKEND" ]; then check >&2; exit 1; fi
[ "$FLASH" = yes ] && echo "note: $BACKEND flashes the screen on each shot; run 'capture.sh check' for the flash-free setup" >&2

if [ -f "$PIDFILE" ] && kill -0 "$(cat "$PIDFILE")" 2>/dev/null; then
  echo "already running (pid $(cat "$PIDFILE"))" >&2; exit 1
fi

OUT="$SHOTS_DIR/$(date +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"
echo $$ > "$PIDFILE"
trap 'rm -f "$PIDFILE"' EXIT
echo "capturing every ${INTERVAL}s into $OUT using $BACKEND"
i=0
while [ "$COUNT" -eq 0 ] || [ "$i" -lt "$COUNT" ]; do
  i=$((i + 1))
  shot "$(printf '%s/frame_%06d.png' "$OUT" "$i")"
  sleep "$INTERVAL"
done
