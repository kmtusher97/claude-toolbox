---
name: screen-record-chrome
description: Record a desktop or Chrome browsing session as screenshots taken at an interval into a configurable folder, then stitch them into an MP4 with ffmpeg. Use when the user wants a screen recording or timelapse video made from screenshots.
disable-model-invocation: false
user-invocable: true
allowed-tools: Bash
---

# Screen record chrome

Scripts live in the `scripts/` folder next to this file (`~/.claude/skills/screen-record-chrome/scripts/` when installed manually).
Defaults are screenshot folder `~/.screen-recordings`, 2s interval, 10fps video; override with
`-d`/`-i`/`-f`, env vars (`SHOTS_DIR`, `INTERVAL`, `FPS`), or `~/.config/screen-record-chrome/config`.

## Capture

Run in the background (`run_in_background`) so the session stays usable:

    scripts/capture.sh start [-d DIR] [-i SECONDS] [-n COUNT]

Frames go to `DIR/<timestamp>/frame_NNNNNN.png`. Without `-n` it runs until stopped:

    scripts/capture.sh stop

## Make the video

    scripts/make-video.sh [-f FPS] [-o OUT.mp4] [SESSION_DIR]

With no `SESSION_DIR` it uses the newest session. Output defaults to `<SESSION_DIR>.mp4`.

## Notes

- `$ARGUMENTS` can carry the folder, interval, or FPS the user wants; map them to the flags above.
- Videos land next to their frame folders, in `~/.screen-recordings/<timestamp>.mp4` by default.
- macOS: uses `screencapture`; the terminal app needs Screen Recording permission (System Settings > Privacy & Security). `brew install ffmpeg`.
- Linux: picks `gnome-screenshot` (required on GNOME Wayland, where other tools are blocked; it may flash the screen on each shot),
  else `grim` (sway/Hyprland), else `maim`/`scrot`/`import` on X11. `sudo apt install ffmpeg gnome-screenshot`.
- Report the output path and frame count when done. Don't delete the frames unless asked.
