# Screenshots

Every image here is a **genuine capture of SSH running live**. Hyprland
images: real hardware, Hyprland 0.57.2 (Arch Linux, 1920×1080), taken with
`scripts/capture-screenshots.sh` on 2026-11-15. Niri images: `grim` inside the
CI runtime test (nested Niri 26.04). None are mock-ups or offscreen renders.

How they were made (reproducible):

- SSH ran on a private D-Bus session with an isolated config and state; the
  notifications shown were sent by the script.
- The Atlas map uses demo cell names (Mail, Notes, Studio, …) created in the
  isolated state file, as a user would by pressing `R` in the Atlas.
- Captures were taken on an empty workspace; panels are cropped to SSH's own
  pixels via `ssh-shell shell rect`.
- Capture config: `appearance.opacity = 1`, `lens.dim = 0.95`,
  `atlas.previews = false`. Faint traces of the developer's own desktop can be
  seen behind the Lens backdrop.
- **Redaction:** the Wi-Fi network name in `control-center/instruments.png` is
  pixelated.

| Folder | Contents | Status |
|---|---|---|
| `desktop-bar/` | Meridian bar, Almanac | captured |
| `sovereign-space/` | Lens | captured |
| `infinite-desktop/` | Atlas | captured |
| `launcher/` | Launcher | captured |
| `control-center/` | Instruments | captured |
| `notifications/` | popups, Signals history | captured |
| `settings/` | Settings window | captured |
| `hyprland/` | power menu on Hyprland | captured |
| `niri/` | Lens; a window after `atlas carry right` | captured in CI: nested Niri 26.04, software-rendered (`ci.yml` → *Runtime on niri*), on Niri's default grey backdrop |
| `media/` | Almanac with an MPRIS player | **not yet available** — no player ran on the capture bus |
