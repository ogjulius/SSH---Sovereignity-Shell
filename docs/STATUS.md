# Status

_Last updated: 2026-11-15 (afternoon) — version 0.1.0-alpha "Survey" (unreleased)._

## Summary

SSH runs on Hyprland (real hardware) and passes its full runtime suite on Niri
26.04 in CI. Packages build and install/uninstall cleanly on Arch and Fedora
(CI containers) and the Nix flake builds. Genuine screenshots are in the README.
It is **not ready for a stable release**: no target is fully verified on real
hardware for both compositors, and CachyOS, EndeavourOS, NixOS (as a system)
and Void have not been installed on. Per-target evidence:
[installation/COMPATIBILITY.md](installation/COMPATIBILITY.md).

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
| Notification popups visuals | ✅ | captured live on Hyprland (`assets/screenshots/notifications/`) |
| OSD | ⬜ | wired to PipeWire/brightness events; not seen live |
| Power menu | 🟡 | renders verified; actions not executed (by design) |
| Settings | 🟡 | captured live; layout fixed from screenshot review; controls not exercised by hand |
| Theme import/export | ⬜ | implemented |
| Config validation & backups | ✅ | 30+ unit assertions; write-lock on unparseable files |
| Hyprland backend | ✅ | live on 0.57.2 (Lua config); dispatch shapes verified with reversible experiments |
| Hyprland classic config | ⬜ | implemented with long-standing syntax; not re-tested on a classic session |
| Niri backend | ✅ | CI runtime suite on Niri 26.04 (nested, software-rendered): 22/22, including Atlas travel and carry checked via `niri msg`; not yet on real hardware |
| Multi-monitor | ⬜ | Meridian per output, surfaces on focused output; only single-output tested |
| Clipboard history | ❌ | planned (cliphist integration in the Lens) |
| Wallpaper management | ❌ | planned |
| Custom widget framework | ❌ | planned |

## Testing status

| Check | Result |
|---|---|
| Unit tests | 239 assertions pass (local and every CI job) |
| qmllint (Qt 6) | no syntax errors |
| Offscreen load of all surfaces | clean, with and without system services |
| Install layout (`make install`/`uninstall`) | verified, CI |
| Arch package | builds, namcap clean of errors, installs/uninstalls with pacman, CI |
| Fedora RPM | builds, installs/uninstalls with dnf (COPR Quickshell), CI |
| Nix flake | `flake check` + build; NixOS examples (Hyprland, Niri) evaluate, CI |
| Void template | parses; dependencies exist, CI |
| Runtime on Niri | 22/22 in a nested Niri 26.04 session, CI |
| Runtime on Hyprland | live on real hardware; not possible in CI (no DRM render node) |
| Internal links | `scripts/check-links.py`: 0 broken |

## Known problems

1. Niri verified only nested/software-rendered in CI, not on real hardware.
2. Hyprland classic-config dispatch not re-tested since the Lua work.
3. RSS memory targets from the brief (100–150 MiB idle) are below Quickshell's
   own baseline on the test machine (198 MiB); see `PERFORMANCE.md`.
4. First open of an icon-bearing surface costs ~29 MiB for Qt's icon-theme stack.
5. Command arguments with spaces can't be edited in Settings (edit the JSON).

## Remaining work before a first public release

- [x] Run and fix the Niri backend on a real Niri session (CI, nested).
- [x] Genuine screenshots (Hyprland, live; Niri, CI).
- [x] CI on GitHub (5 workflows).
- [ ] Niri on real hardware.
- [ ] Hands-on keyboard/mouse pass over every surface.
- [ ] Verify CachyOS, EndeavourOS, Fedora desktop, NixOS system installs.
- [ ] Multi-monitor and HiDPI testing.
- [ ] Mesa GPU memory measurements.
