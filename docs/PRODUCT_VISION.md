# Product vision

> **SSH — Sovereignity Shell.** A brand new feeling of your Hyprland/Niri powered distribution.

## The idea in one sentence

Your desktop is territory; SSH is the instrument you read and move through it with.

## Why another shell

Most Quickshell setups today converge on the same shape: a floating rounded bar,
a dashboard of cards, a control-centre grid, numbered workspace dots. They are
often beautiful, but they treat the desktop as a *list* — of workspaces, of
widgets, of popups.

SSH treats it as a *place*. Workspaces are cells on a map you can extend in any
direction, name, group into collections and travel across with the keyboard.
Every surface of the shell shares that spatial vocabulary: the bar shows your
coordinate and a minimap, the Lens arranges context as a compass around where
you stand, and the Atlas shows the whole map.

## Principles

1. **Sovereignty.** Nothing happens without the user's consent. SSH never edits
   compositor config, never geolocates, never stores notification text on disk
   unless asked, never overwrites a config it could not parse.
2. **One environment, not a widget pile.** One window type, one motion language,
   one set of keys (Esc closes, arrows move, Enter commits) across every surface.
3. **Honest engineering.** No fake controls, no invented numbers. Features that
   SSH builds on top of the compositor (the Atlas) are labelled as such.
4. **Cheap when idle.** Surfaces exist only while open. Sampling and network
   fetches run only while something is looking.
5. **Beautiful by default.** The default theme must be the reason people stay;
   customisation refines it rather than rescues it.

## Who it is for

- People on Hyprland or Niri who want a cohesive shell rather than assembling one.
- Keyboard-first users who think in places ("my writing space", "the build area").
- People on modest hardware who still want something that feels designed.

## Signature experiences

| Experience | What it is |
|---|---|
| **Atlas** (Infinite Desktop) | An unbounded 2D map of workspace cells in named collections, kept by SSH and mapped onto real compositor workspaces. |
| **Lens** (Sovereign Space) | A compass around your current cell: its windows in the centre, neighbouring cells on the cardinal points, session context in the corners, and one intent line that searches apps, windows, places and commands. |
| **Meridian** | A flush instrument strip with ruler ticks, your coordinate, a minimap and the row you are on. |
| **Instruments / Almanac / Signals** | Control centre, dashboard and notifications in the same plate-and-hairline language. |

## What success looks like

Someone sees SSH and recognises it from the chamfered plates and the ruler edge;
someone uses it and, within a minute, travels the map with Alt+arrows without
having read anything.
