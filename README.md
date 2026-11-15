<p align="center"><img src="assets/branding/ssh-banner.png" alt="SSH — Sovereignity Shell" width="100%"></p>

<p align="center"><b>A brand new feeling of your Hyprland/Niri powered distribution.</b></p>

<p align="center">
<code>0.1.0-alpha</code> · Quickshell 0.3 · Qt 6 · Hyprland · Niri · GPL-3.0-or-later
</p>

---

**SSH (Sovereignity Shell)** is a Quickshell desktop shell built on one idea:
your desktop is **territory**, not a list. Workspaces are cells on a map you can
extend in every direction, name, group into collections and travel with the
keyboard, and every part of the shell speaks that spatial language.

> **Status: alpha.** Runs daily-driver-complete on Hyprland; the Niri backend is
> written but not yet tested. See [docs/STATUS.md](docs/STATUS.md). There are no
> screenshots yet on purpose: they will be added from a real session after the
> hands-on QA pass, never mocked up.

## What makes it different

| | |
|---|---|
| **Atlas — the Infinite Desktop** | An unbounded 2D map of workspace cells (`A1`, `C2`, `−B−1`) grouped into collections. Travel with `Super+Alt+arrows`, carry windows with `Super+Alt+Shift+arrows`, drag windows between cells, name places. SSH keeps the map and binds each cell to a real workspace; your compositor's own workspace keys keep working, and row 1 is workspaces 1–10. |
| **Lens — Sovereign Space** | A compass around where you are: the current cell's windows in the centre, the four neighbouring cells on the cardinal points (travel without closing it), session context in the corners, and one intent line that searches apps, windows, places and commands together. |
| **Meridian** | A flush instrument strip with a ruler-tick edge, your coordinate, a minimap of the neighbourhood and the stops in your current row. No floating pill. |
| **One design language** | Chamfered plates instead of rounded rectangles, hairlines, warm-silver accents on obsidian or vellum, an original glyph set, numbers in monospace. Contrast is unit-tested. |
| **Sovereignty** | Never edits your compositor config, never geolocates, keeps notification text in memory unless you opt in, never overwrites a config it cannot parse. |
| **Light** | Only the bar is resident; every surface is created on open and destroyed on close. ~0.03 % idle CPU and +38 MiB over a bare Quickshell bar ([measured](docs/PERFORMANCE.md)). |

Also: a launcher with frecency, **Instruments** (Wi-Fi, Bluetooth, audio
devices, mic, brightness, power profiles, battery), the **Almanac** (calendar
with ISO weeks, keyless weather, load meters, media), **Signals** (notification
daemon with actions, history and quiet mode), OSD, a two-step power menu and a
Settings window generated from the config schema.

## Compatibility

| | Status |
|---|---|
| Hyprland 0.57 (Lua config) | ✅ tested live |
| Hyprland (classic config) | 🟡 implemented, not re-tested |
| Niri | ⬜ implemented, **untested** |
| Arch Linux | ✅ tested |
| CachyOS · EndeavourOS · Fedora · NixOS | ⬜ packaging provided, not yet verified |
| Void Linux | unofficial, notes provided |
| Manjaro | not supported |

Details: [compositors](docs/COMPOSITOR_SUPPORT.md) · [distributions](docs/DISTRIBUTION_SUPPORT.md).

## Install

```sh
# Arch / CachyOS / EndeavourOS
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell/packaging/arch && makepkg -si
```

Fedora, NixOS (flake + module), Void and from-source instructions:
[docs/INSTALLATION.md](docs/INSTALLATION.md).

Start it with your session (`exec-once = ssh-shell` on Hyprland,
`spawn-at-startup "ssh-shell"` on Niri), then open **Settings → Keys** and paste
the generated keybind block into your compositor config.

## Default keys (generated, yours to change)

| | |
|---|---|
| `Super+Space` | Lens |
| `Super+Tab` | Atlas |
| `Super+D` | Launcher |
| `Super+A` | Instruments |
| `Super+Alt+arrows` | travel the map |
| `Super+Alt+Shift+arrows` | carry the focused window |
| `Super+Shift+Esc` | power menu |

Everything is also scriptable: `ssh-shell atlas traverse left`,
`ssh-shell panel toggle instruments`, `ssh-shell status`.

## Documentation

[Vision](docs/PRODUCT_VISION.md) · [Originality](docs/ORIGINALITY_ANALYSIS.md) ·
[Design](docs/DESIGN_PHILOSOPHY.md) · [Interaction](docs/INTERACTION_MODEL.md) ·
[Architecture](docs/ARCHITECTURE.md) · [Configuration](docs/CONFIGURATION.md) ·
[Theming](docs/THEMING.md) · [Performance](docs/PERFORMANCE.md) ·
[Troubleshooting](docs/TROUBLESHOOTING.md) · [Development](docs/DEVELOPMENT.md) ·
[Roadmap](docs/ROADMAP.md) · [Status](docs/STATUS.md)

## Contributing

Contributions are welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Security
issues: [SECURITY.md](SECURITY.md).

## License

GPL-3.0-or-later. SSH is an independent project; it is not affiliated with
Quickshell, Hyprland or Niri.
