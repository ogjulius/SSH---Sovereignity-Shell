# Roadmap

## Done — Phases 1–8 (foundation through optimisation), in 0.1.0-alpha

- [x] Product research, originality analysis, design philosophy, interaction model
- [x] Architecture, validated configuration, startup
- [x] Design tokens, typography, geometry, glyph set, components, motion
- [x] Meridian, launcher, workspace visualisation, tray, OSD
- [x] Audio, network, Bluetooth, brightness, battery, notifications, MPRIS
- [x] Lens (Sovereign Space), Atlas (Infinite Desktop), spatial navigation, collections
- [x] Hyprland backend (classic + Lua), Niri backend (untested), shared abstraction, reconnection
- [x] Settings, themes, presets, import/export, output selection, keybind generator
- [x] Benchmarks; idle CPU and repeated-open memory optimised with measurements
- [x] Packaging for Arch / CachyOS / EndeavourOS, Fedora, NixOS; Void notes

## Next — 0.1.0 (first public release gate)

- [ ] Niri: run, fix, document real behaviour; Atlas window geometry from `WindowLayoutsChanged`
- [ ] Hands-on QA of every surface; genuine screenshots in the README
- [ ] Distribution verification (CachyOS, EndeavourOS, Fedora, NixOS)
- [ ] CI green on GitHub
- [ ] Multi-monitor / HiDPI pass

## 0.2

- [ ] Clipboard history in the Lens (cliphist), with privacy controls
- [ ] Wallpaper per collection (the Atlas collection becomes a place with its own look)
- [ ] Atlas: cell colours/tags, collection overview zoom level, keyboard window picking inside a cell
- [ ] Lens: per-app actions (e.g. new window, quit), calculator intent
- [ ] Polkit authentication agent in the SSH language
- [ ] Session lock surface
- [ ] Translations

## Later

- [ ] Custom widget framework (QML drop-ins under `~/.config/ssh-shell/widgets/`)
- [ ] Niri-native Atlas mapping that uses columns as the horizontal axis
- [ ] Accessibility audit with a screen reader
