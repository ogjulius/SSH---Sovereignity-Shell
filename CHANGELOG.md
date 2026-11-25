# Changelog

All notable changes to SSH are recorded here. The project follows
[Semantic Versioning](https://semver.org/); until 1.0, minor versions may
change configuration options (changes are always validated and reported, never
fatal).

## [Unreleased] — 0.1.0-alpha "Survey"

First working pre-release. Not yet published.

### Changed (interface pass)
- **Shape is now a choice** (`appearance.shape`, default `round`). Surfaces
  close their corners as rounded islands or as the original chamfered plates;
  `Plate` draws the rounded reading as a plain rectangle, so the default shape
  needs no `QtQuick.Shapes` node. Rounded surfaces can carry a soft top-edge
  light (`appearance.shine`).
- **The Meridian floats** (`meridian.style`, default `island`): inset from the
  screen edges, rounded, with the ruler-tick edge reserved for `flush`
  (`meridian.showTicks` therefore defaults to `false`).
- Default plate opacity 0.94 → 0.90, so a compositor blur rule reads as glass.
- **Application icons are opt-in** (`appearance.appIcons`, default `false`).
  Qt's icon-theme loader and SVG engine are the single largest allocation in
  the shell; with icons off the Launcher, Lens and Atlas draw SSH's own
  glyphs instead. Measured on one machine: idle **352 → 282 MiB RSS**
  (225 → 161 MiB PSS), first surface open **+101 → +71 MiB**, peak
  **485 → 385 MiB**, startup **1.62 → 1.16 s**.
- **Launcher** rebuilt as a two-pane finder: a recycling `ListView` (was a
  full `Repeater`, so long result sets no longer instantiate every row), a
  category-glyph fallback per result, a quiet inspector for the selected app,
  an explicit empty state, a scroll indicator and a keyboard legend. It now
  opens centred rather than high on the screen.
- **Meridian** groups its three zones with hairlines, and the active row stop
  is marked by an accent plate plus its underline instead of the underline
  alone.
- **Settings** numeric rows show real units (`94%`, `1.08×`, `19 h`, `5500 ms`)
  instead of a bare `1.00`, and rows that depend on another option (schedule
  hours, preview budget, OSD time, weather fields) appear only when they apply.
- **Default text scale** raised to `1.08`, and persistent guidance in the Lens
  (status line, keyboard legend, empty states, neighbour labels) moved from the
  faintest tone to the dim tone.

### Added
- **`./install.sh`:** clone-and-install for Arch, CachyOS, EndeavourOS,
  Fedora, NixOS (declarative module) and Void (unofficial). Interactive
  (arrow keys, numbered fallback) or unattended (`--yes`), with profiles,
  module/integration selection, themes, terminal choice, a full dependency and
  change list before anything happens, logs, validation, an
  INSTALLATION COMPLETE screen with REBOOT NOW / REBOOT LATER, and
  `--uninstall`.
- **Login sessions** "Sovereignity Shell (Hyprland)" and "Sovereignity Shell
  (Niri)" via `ssh-session`: the compositor runs with the user's own config,
  SSH starts exactly once and is restarted after a crash; plain compositor
  sessions are untouched.
- **Session keybinds** (`session.keybinds`): inside SSH sessions the shortcuts
  are bound automatically (Hyprland at runtime, Niri through an included
  file); combinations the user already binds are left alone.
- `ssh-shell doctor`, `ssh-shell check-config`, `ssh-shell version`; bash,
  fish and zsh completions.
- CI runs `install.sh` end to end in Arch, Fedora and Void containers,
  including a live test of the installed Niri session.
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
- Void template comment claimed Quickshell was not packaged for Void (it is).
- Niri: Atlas cells bound to deleted unnamed workspaces are re-claimed.
- Anchored panels opened by keybind/IPC sit at the right edge.
- Settings rows align on wide windows; launcher chips fit one line.
- Missing app icons fall back correctly on Quickshell 0.3.2.
- Fonts resolve against installed families (Nerd Font builds of JetBrains Mono).
- `PKGBUILD` `check()` can no longer hang `makepkg`.
