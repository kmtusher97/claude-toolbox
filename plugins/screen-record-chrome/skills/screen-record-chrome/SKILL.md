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

## Step 0: check setup (always do this first)

    scripts/capture.sh check

It prints the capture tool, whether ffmpeg is present, and a `STATUS:` line with the exact fix if anything is off.

- `STATUS: ready` — go on to Capture.
- Anything else — relay the printed steps to the user in plain words, with the install command as a copy-paste line
  prefixed with `! ` (e.g. `! sudo apt install maim`) so they can run it in the prompt. Don't run `sudo` yourself.
- On GNOME Wayland the only available tool flashes the screen on every shot. Offer the user the choice: record anyway
  with a longer interval (`-i 5`), or switch to an X11 session (install `maim`, log out, pick "Ubuntu on Xorg" at the
  gear icon; no reboot). Warn that logging out ends this Claude session and they will need to resume it.
- Never change system settings (GDM config, gsettings) unless the user asks.

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
- It records the whole screen, so other windows and tab titles end up in the video. Mention this before sharing.
- Videos land next to their frame folders, in `~/.screen-recordings/<timestamp>.mp4` by default.
- macOS: `screencapture`; the terminal app needs Screen Recording permission (System Settings > Privacy & Security).
- Linux X11: `maim`, else `scrot`, else `import` (no flash). Linux Wayland: `grim` on sway/Hyprland; GNOME only allows `gnome-screenshot` (flashes).
- If the video won't play in VLC, check whether VLC itself starts; the files are plain H.264 MP4 and `ffplay <file>` is a quick check.
- Report the output path and frame count when done. Don't delete the frames unless asked.
