# Changelog

All notable changes to SSH are recorded here. The project follows
[Semantic Versioning](https://semver.org/); until 1.0, minor versions may
change configuration options (changes are always validated and reported, never
fatal).

## [Unreleased] — 0.1.0-alpha "Survey"

First working pre-release. Not yet published.

### Added
- **Atlas (Infinite Desktop):** unbounded 2D map of workspace cells in named
  collections, persisted by SSH and mapped onto real workspaces; traverse,
  carry, rename, drag-and-drop window moves, recycled-delegate canvas, one-shot
  window previews within a configurable budget; native workspace switches sync
  back to the map.
- **Lens (Sovereign Space):** compass layout around the current cell with
  neighbour travel, session corners and a unified intent line (apps, windows,
  named cells, commands).
- **Meridian** bar with ruler ticks, coordinate, minimap, row stops, focused
  window, tray, instrument readouts, signals bell and clock.
- **Launcher** with categories, fuzzy search, frecency and recent apps.
- **Instruments** control centre: Wi-Fi (scan, connect, passphrase, forget),
  Bluetooth (power, discovery, connect), output/input selection and volume,
  microphone, brightness, power profiles, battery details.
- **Almanac** dashboard: clock, calendar with ISO weeks, keyless Open-Meteo
  weather (explicit location only), CPU/memory/temperature on demand, media.
- **Signals:** notification daemon with popups, history grouped by app,
  actions, quiet mode (critical still shown), optional persistence (off).
- **OSD**, **power menu** with two-step confirmation, **traverse toast**.
- **Settings** window generated from the configuration schema; accent picker,
  collections, keybind generator for Hyprland and Niri, theme import/export,
  output selection, diagnostics.
- **Compositor backends:** Hyprland (classic and Lua-config dispatch) and Niri
  (JSON event stream; untested).
- Validated configuration with backups and write-lock on unparseable files.
- Original glyph set, Obsidian/Vellum grounds, six accents, six theme presets.
- `ssh-shell` CLI, IPC targets for every action, test runner (unit, lint,
  load), offscreen render harness, benchmark script.
- Packaging for Arch (also CachyOS/EndeavourOS), Fedora (spec), NixOS (flake +
  module with example configurations), Void (`xbps-src` template).
- Six standalone installation tutorials and an evidence-based compatibility matrix.
- GitHub Actions: CI (unit, lint, load, layout, links, nested-Niri runtime
  suite), Arch/Fedora/Nix package builds with native install/uninstall, and
  dependency-name validation; packages uploaded as artifacts.
- Genuine screenshots and `scripts/capture-screenshots.sh`; `shell rect` and
  `shell keybinds` IPC; Hyprland Lua keybind generation.

### Fixed
- Niri: Atlas cells bound to deleted unnamed workspaces are re-claimed.
- Anchored panels opened by keybind/IPC sit at the right edge.
- Settings rows align on wide windows; launcher chips fit one line.
- Missing app icons fall back correctly on Quickshell 0.3.2.
- Fonts resolve against installed families (Nerd Font builds of JetBrains Mono).
- `PKGBUILD` `check()` can no longer hang `makepkg`.
