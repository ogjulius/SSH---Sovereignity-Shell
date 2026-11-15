# Troubleshooting

First, collect facts: `ssh-shell status` prints JSON with the compositor,
connection state, active surface, Atlas state, notification state and config
issues. Logs: run `ssh-shell` in a terminal, or see
`/run/user/$UID/quickshell/by-id/*/log.qslog`.

| Symptom | Cause / fix |
|---|---|
| `no supported compositor detected` | Neither `HYPRLAND_INSTANCE_SIGNATURE` nor `NIRI_SOCKET` is set. Start SSH from inside the compositor session, or set `SSH_SHELL_COMPOSITOR`. |
| Atlas travel does nothing on Hyprland; log shows `')' expected near …` | You are on a Lua-config Hyprland with an older SSH. Update SSH (0.1.0+ detects Lua mode). |
| Notifications don't appear; Signals says SSH is not the daemon | Another daemon (mako, dunst, swaync, another shell) owns `org.freedesktop.Notifications`. Stop it and restart SSH, or set `notifications.enabled` to false to keep yours. |
| Tray is empty | Another program owns the StatusNotifier watcher (another bar). Only one watcher can run. |
| Brightness control missing | `brightnessctl` not installed, or your user lacks backlight permission (install brightnessctl's udev rules / be in the `video` group). |
| Wi-Fi/Bluetooth keys disabled | NetworkManager or BlueZ is not running. SSH only uses those services. |
| Weather says to set a location | By design: SSH never geolocates. Set latitude/longitude in Settings → Almanac. |
| Settings changes are not saved | `config.json` is not valid JSON; SSH refuses to overwrite it. Fix or move the file (Settings → About shows the parse error). |
| Monospace text looks wrong | No JetBrains Mono installed; SSH falls back through Nerd Font builds, Iosevka, Noto Sans Mono, DejaVu Sans Mono. Install `ttf-jetbrains-mono` (Arch) for the intended look. |
| Keybinds do nothing | SSH never edits compositor config. Copy the block from Settings → Keys into your config and reload. Test with `ssh-shell lens toggle` in a terminal. |
| A window moved to the wrong workspace on Niri | Unnamed Niri workspaces are referenced by index on the focused output (see COMPOSITOR_SUPPORT). Name cells in the Atlas (R) to bind them stably. |
| The map looks wrong after reorganising workspaces by hand | Open the Atlas, select a cell, `Del` to forget its binding; the next visit rebinds it. The map file is `~/.local/state/ssh-shell/atlas.json`. |

## Resetting

- Settings only: move `~/.config/ssh-shell/config.json` away.
- The Atlas map: move `~/.local/state/ssh-shell/atlas.json` away (workspaces are unaffected).
- Launcher history: `~/.local/state/ssh-shell/launcher-usage.json`.

## Reporting a bug

Include `ssh-shell status`, your compositor and version, distribution,
`qs --version`, and the relevant log lines. Remove anything private
(window titles appear in status and logs).
