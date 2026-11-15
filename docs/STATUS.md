# Status

_Last updated: 2026-11-15 — version 0.1.0-alpha "Survey" (unreleased)._

## Summary

The shell runs, every surface works against real system services on
Hyprland, and the Infinite Desktop is verified end to end on a live session.
It is **not ready for a public release**: Niri support is untested, no
genuine desktop screenshots exist yet, and only one distribution has been tested.

## Feature status

Legend: ✅ working and verified · 🟡 implemented, partially verified · ⬜ implemented, not verified · ❌ not implemented

| Area | Status | Evidence / notes |
|---|---|---|
| Meridian bar | ✅ | runs live on Hyprland; renders verified (dark/light) |
| Lens (Sovereign Space) | 🟡 | renders verified with live data; opened live via IPC; keyboard flows not exercised by a human yet |
| Atlas (Infinite Desktop) | ✅ | live: traverse right/down/back created and focused workspaces 2 and 11, native switches moved the cursor, auto-placement and first-run seeding verified, state persisted |
| Atlas window previews | ⬜ | ScreencopyView wired; the offscreen harness cannot capture, not yet seen live |
| Atlas drag-and-drop window move | ⬜ | implemented; the underlying move dispatch is verified |
| Launcher | 🟡 | renders verified with real desktop entries; launching not exercised live |
| Instruments | 🟡 | renders verified with real Wi-Fi, Bluetooth, PipeWire, backlight, battery values; controls not toggled during testing (to avoid changing the machine's state) |
| Almanac | 🟡 | renders verified (calendar, load, temperature); weather fetch path not exercised (no location configured) |
| Signals (notifications) | ✅ | verified on a private D-Bus session: owns the bus name, capabilities, history, quiet mode (critical bypass), clear-all closes senders' notifications |
| Notification popups visuals | ⬜ | daemon logic verified; popup rendering not yet seen live |
| OSD | ⬜ | wired to PipeWire/brightness events; not seen live |
| Power menu | 🟡 | renders verified; actions not executed (by design) |
| Settings | ⬜ | loads in the full shell without errors; not driven by hand yet |
| Theme import/export | ⬜ | implemented |
| Config validation & backups | ✅ | 30+ unit assertions; write-lock on unparseable files |
| Hyprland backend | ✅ | live on 0.57.2 (Lua config); dispatch shapes verified with reversible experiments |
| Hyprland classic config | ⬜ | implemented with long-standing syntax; not re-tested on a classic session |
| Niri backend | ⬜ | implemented against documented IPC; **never run** (Niri not installed on the test machine) |
| Multi-monitor | ⬜ | Meridian per output, surfaces on focused output; only single-output tested |
| Clipboard history | ❌ | planned (cliphist integration in the Lens) |
| Wallpaper management | ❌ | planned |
| Custom widget framework | ❌ | planned |

## Testing status

| Check | Result |
|---|---|
| Unit tests (`scripts/test.sh`) | 234 assertions pass |
| qmllint (Qt 6) syntax | clean |
| Offscreen load of all 8 surfaces | clean |
| Live Hyprland session | runs with no SSH warnings |
| Benchmark | see `PERFORMANCE.md` |
| Arch package build (`makepkg`) | builds; packaged tree runs live with all surfaces, no errors |
| CI | workflow written (`.github/workflows/ci.yml`); not yet run on GitHub |

## Known problems

1. Niri backend untested — the biggest gap before any release.
2. No genuine screenshots: the test session was locked during development; the
   README uses brand art only.
3. RSS memory targets from the brief (100–150 MiB idle) are below Quickshell's
   own baseline on the test machine (198 MiB); see `PERFORMANCE.md`.
4. First open of an icon-bearing surface costs ~29 MiB for Qt's icon-theme stack.
5. Command arguments with spaces can't be edited in Settings (edit the JSON).

## Remaining work before a first public release

- [ ] Run and fix the Niri backend on a real Niri session.
- [ ] Hands-on pass over every surface with keyboard and mouse; take genuine screenshots.
- [ ] Verify CachyOS, EndeavourOS, Fedora, NixOS installs.
- [ ] Run CI on GitHub.
- [ ] Multi-monitor and HiDPI testing.
- [ ] Mesa GPU memory measurements.
