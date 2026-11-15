# Keybinds

SSH's default keys follow one small system, so you can guess a key before you
look it up. Press **Super+F1** at any time to see them all.

## The system

1. **One base modifier: Super.** Every SSH action starts with Super, the
   desktop modifier on Hyprland and Niri. SSH never uses Ctrl, or Alt alone.
2. **Alt means space.** Super+Alt moves you across the Atlas; adding Shift
   takes the focused window along. Alt is used for nothing else.
3. **Letters name the destination.** **A**tlas, **O**rient (the Lens, your
   compass), **G**auges (Instruments), **N**otifications (Signals),
   **Y**ear (the Almanac, the calendar).
4. **Conventions where one exists.** Super+Space searches (the launcher),
   Super+Return opens a terminal, Super+F1 is help, comma is settings.
5. **Leave the compositor's keys alone.** No default collides with a bind in
   stock Hyprland or Niri configuration (see [below](#why-these-letters)).
   Closing windows, focus, workspaces 1–9 and screenshots remain your
   compositor's job.
6. **Every key is a command.** Each bind runs a stable `ssh-shell` verb, so
   anything a key does, a script can do.

## Defaults

| Keys | Action | Command |
|---|---|---|
| `Super+Space` | Launcher: search and start applications | `ssh-shell launcher toggle` |
| `Super+Return` | Terminal (`commands.terminal`) | `ssh-shell terminal` |
| `Super+A` | Atlas: the map of your workspaces | `ssh-shell atlas toggle` |
| `Super+O` | Lens: compass around the current cell | `ssh-shell lens toggle` |
| `Super+G` | Instruments: audio, network, Bluetooth, brightness, power | `ssh-shell panel toggle instruments` |
| `Super+N` | Signals: notifications and history | `ssh-shell panel toggle signals` |
| `Super+Y` | Almanac: calendar, weather, load, media | `ssh-shell panel toggle almanac` |
| `Super+Shift+,` | Settings | `ssh-shell settings toggle` |
| `Super+Shift+Esc` | Power menu | `ssh-shell panel toggle power` |
| `Super+F1` | Cheatsheet: every SSH keybind | `ssh-shell keybinds cheatsheet` |
| `Super+Alt+←↑↓→` | Travel to the neighbouring cell | `ssh-shell atlas traverse <direction>` |
| `Super+Alt+Shift+←↑↓→` | Carry the focused window there (and follow) | `ssh-shell atlas carry <direction>` |
| Volume, mute, mic, brightness keys | Change the value and show the OSD | `ssh-shell audio up` … `ssh-shell brightness down` |
| `Esc` | Close the open SSH surface | `ssh-shell panel close` |

**Closing things.** `Esc` closes whatever SSH surface is open; it is handled by
SSH itself, not bound in the compositor. Closing a *window* is your
compositor's bind (Hyprland's default `Super+C`, Niri's `Super+Q`), and a
terminal closes itself. SSH binds no close key of its own.

`ssh-shell keybinds list` prints this table with your current keys.

## Why these letters

Checked against Hyprland 0.57's shipped `hyprland.lua` and Niri's
`default-config.kdl` (2026-11-15). The obvious letters were taken:

| Wanted | Taken by | Chosen instead |
|---|---|---|
| `Super+L` for the Lens | Niri: focus column right (H/J/K/L); widely used for locking | `Super+O`, *orient* |
| `Super+I` for Instruments | Niri: focus workspace up | `Super+G`, *gauges* |
| `Super+C` for the calendar | Hyprland: close window; Niri: centre column | `Super+Y`, *year* |
| `Super+,` for Settings | Niri: consume window into column | `Super+Shift+,` |
| `Super+W` to close a surface | Niri: tabbed column display | none: `Esc` closes surfaces |
| `Super+Shift+/` for the cheatsheet | Niri: its own hotkey overlay | `Super+F1` |

Super+Shift variants that open a surface on another monitor are not part of
the scheme (multi-monitor is not verified yet); surfaces open on the focused
output. A unit test (`src/dev-tests.qml`) fails if a default ever collides
with those stock binds again.

## How keys reach your compositor

- **In the Sovereignity Shell login sessions** the keys are bound
  automatically. A combination your own compositor config already binds keeps
  your action (SSH logs which ones in `~/.local/state/ssh-shell/shell.log`).
  Turn this off with `session.keybinds`.
- **In a plain Hyprland or Niri session** SSH never edits your compositor
  config. Generate a block and paste it in:

  ```sh
  ssh-shell keybinds hyprland       # classic hyprland.conf
  ssh-shell keybinds hyprland-lua   # Lua hyprland.lua (also autostarts SSH)
  ssh-shell keybinds niri           # config.kdl
  ```

  These read your configuration file directly, so they work whether or not
  SSH is running.

## How to change a keybind

Keys are options in the `keybinds` section of `~/.config/ssh-shell/config.json`,
in Hyprland notation, `"MODS, KEY"`:

```json
{
  "keybinds": {
    "lens": "SUPER, L",
    "almanac": ""
  }
}
```

An empty string unbinds an action; `traverse` and `carry` take modifiers only
(they are combined with the arrow keys). Or edit them in **Settings → Keys**,
which lists every action with its command and description.

Then:

- **SSH session:** nothing to do. The binds are updated as soon as the file
  changes (Niri reloads the included file; Hyprland is rebound at runtime).
- **Plain session:** rerun `ssh-shell keybinds <target>` and replace the block
  in your compositor config.

The old `shortcuts` section (before 0.1.0) still works: its values are used
and SSH reports that the section is now called `keybinds`.

## First run

The first time SSH starts, the Meridian shows **KEYS · SUPER+F1**. Click it to
open the cheatsheet, or × to dismiss it. Either way it is gone for good
(`firstRun.cheatsheetHint` in the config; Settings → Keys can show it again).
