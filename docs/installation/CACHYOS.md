<p align="center"><img src="../../assets/branding/ssh-logo.svg" alt="SSH" width="300"></p>

# Installing SSH on CachyOS

<sub>[Arch Linux](ARCH.md) · **CachyOS** · [EndeavourOS](ENDEAVOUROS.md) · [Fedora](FEDORA.md) · [NixOS](NIXOS.md) · [Void (unofficial)](VOID.md) · [Compatibility](COMPATIBILITY.md) · [All guides](README.md)</sub>

CachyOS is Arch-based and uses Arch's repositories plus its own optimised mirrors. SSH installs with the same Arch package. Commands below work in CachyOS's default `fish` shell and in bash/zsh.

**Contents:** [Compatibility](#1-distribution-and-compatibility) · [Compositor](#2-required-compositor) · [Prerequisites](#3-prerequisites) · [Dependencies](#4-required-dependencies) · [Install](#5-installation) · [Configuration](#6-configuration-setup) · [First launch](#7-first-launch) · [Keybinds](#8-keybinding-setup) · [Notifications](#9-notification-integration) · [Audio](#10-audio-integration) · [Network](#11-network-integration) · [Media](#12-media-integration) · [Update](#13-updating-ssh) · [Uninstall](#14-uninstalling-ssh) · [Troubleshooting](#15-troubleshooting) · [Limitations](#16-known-limitations) · [Verify](#17-verification)

## 1. Distribution and compatibility

| | Status |
|---|---|
| Package | **BUILD PASSED** — the shared Arch package (built in an Arch container) |
| Installation | **NOT TESTED** on CachyOS |
| Hyprland | **NOT TESTED** on CachyOS (verified on Arch) |
| Niri | **NOT TESTED** on CachyOS (verified in CI on Arch packages) |

CachyOS uses Arch's packages, so the Arch results are a strong indication, not proof. Verified 2026-11-15.

See the full [compatibility matrix](COMPATIBILITY.md) for what each status means.

## 2. Required compositor

SSH runs inside **Hyprland** or **Niri**. Other compositors are not supported
(SSH starts, but workspace features are disabled).

```sh
# Hyprland
sudo pacman -S --needed hyprland
# or Niri
sudo pacman -S --needed niri
```

Log in to the compositor session before continuing.

## 3. Prerequisites

- An up-to-date system.
- A working Wayland session of Hyprland or Niri.
- About 5 MB of disk space for SSH (Quickshell and Qt are larger if not yet installed).

> [!TIP]
> CachyOS may install optimised builds of Quickshell or Qt from its own
> `cachyos-*` repositories. That is expected and fine. Check where a package
> comes from with:
> ```sh
> pacman -Si quickshell | grep -E '^(Repository|Version)'
> ```
> SSH needs Quickshell **0.3 or newer**.

## 4. Required dependencies

| Package | Repository | Why |
|---|---|---|
| `quickshell` (≥ 0.3) | extra | the QML shell runtime SSH runs on |
| `qt6-declarative`, `qt6-svg` | extra | QML engine and SVG icon rendering |
| `inter-font`, `ttf-jetbrains-mono` | extra | SSH's interface and data typefaces |
| `git`, `base-devel` | core/extra | to build the package with `makepkg` |

Optional (each feature degrades gracefully without it): `pipewire` + `wireplumber`
(audio), `networkmanager` (network), `bluez` (Bluetooth), `upower` (battery),
`power-profiles-daemon` (power profiles), `brightnessctl` (backlight).

## 5. Installation

> [!TIP]
> **Recommended:** run `./install.sh` from a clone of the repository. It does
> everything below for you, adds the **Sovereignity Shell** login sessions and
> validates them; see [the installer](README.md#the-installer-recommended).
> The manual steps below remain for reference.

1. **Install the build tools** (needed once):
   ```sh
   sudo pacman -S --needed git base-devel
   ```
2. **Get the source:**
   ```sh
   git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
   cd SSH---Sovereignity-Shell/packaging/arch
   ```
3. **Build and install the package.** `makepkg -s` installs the runtime
   dependencies from the official repositories with pacman, builds
   `ssh-shell-git` from the latest commit, runs its unit tests, and `-i` installs it:
   ```sh
   makepkg -si
   ```
   Expected at the end:
   ```text
   ==> Finished making: ssh-shell-git 0.1.0.alpha.r…-1
   …
   (1/1) installing ssh-shell-git
   ```
4. **Confirm** that the files are where they should be:
   ```sh
   pacman -Ql ssh-shell-git | grep -E 'bin/ssh-shell|shell.qml'
   ```
   ```text
   ssh-shell-git /usr/bin/ssh-shell
   ssh-shell-git /usr/share/ssh-shell/shell.qml
   ```

The package installs only under `/usr` and writes nothing to your home
directory. It is not on the AUR yet; building it yourself as above is the
supported path.

## 6. Configuration setup

SSH works with no configuration. Your settings are created the first time you
change something in **Settings** and live in your home directory, never in
the package:

| Path | Contents |
|---|---|
| `~/.config/ssh-shell/config.json` | your choices only (validated; backed up to `config.json.bak` on first save each session) |
| `~/.config/ssh-shell/themes/` | exported themes |
| `~/.local/state/ssh-shell/atlas.json` | your Atlas map (cells, names, collections) |

> [!NOTE]
> If another bar or notification daemon is running, SSH still starts. Stop the
> other bar to avoid two bars, and see [Notifications](#9-notification-integration).

## 7. First launch

Try SSH in a terminal inside your compositor session first:

```sh
ssh-shell
```

What to expect within about half a second:

- the **Meridian** bar appears at the top of every output, showing your
  coordinate (for example `I · MAIN  A1`), a minimap, the clock and status icons;
- the terminal prints a line such as `[ssh] compositor backend: hyprland`
  (or `niri`).

In a second terminal, ask SSH for its status:

```sh
ssh-shell status
```

Expected output (one line of JSON, shortened here):

```json
{"compositor":"hyprland","connected":true,"workspaces":3,"windows":5,"surface":"","atlas":{"enabled":true,"collection":"Main",...},"notifications":{"serving":true,...}}
```

Stop it with `Ctrl+C` (or `ssh-shell kill`), then make it start with your session:

**Hyprland, classic config** (`~/.config/hypr/hyprland.conf`):
```ini
exec-once = ssh-shell --daemon
```
**Hyprland, Lua config** (`~/.config/hypr/hyprland.lua`): the generated block in
step 8 includes the autostart line:
```lua
hl.on("hyprland.start", function () hl.exec_cmd("ssh-shell --daemon") end)
```
**Niri** (`~/.config/niri/config.kdl`):
```kdl
spawn-at-startup "ssh-shell" "--daemon"
```

## 8. Keybinding setup

SSH never edits your compositor configuration. It **generates** a keybind
block from its `keybinds` options, and you paste it in (SSH need not be running):

```sh
ssh-shell keybinds hyprland       # Hyprland, classic hyprland.conf
ssh-shell keybinds hyprland-lua   # Hyprland, Lua hyprland.lua
ssh-shell keybinds niri           # Niri config.kdl
```
Append the output to your compositor config, then reload: Hyprland reloads
automatically on save (or `hyprctl reload`); Niri reloads automatically.

You can also open **Settings → Keys** to change the keys and copy the block.
Defaults: `Super+Space` launcher · `Super+Return` terminal · `Super+A` Atlas ·
`Super+O` Lens · `Super+G` Instruments · `Super+N` Signals · `Super+Y` Almanac ·
`Super+Shift+,` Settings · `Super+Shift+Esc` power · `Super+F1` cheatsheet ·
`Super+Alt+arrows` travel · `Super+Alt+Shift+arrows` carry the focused window.
The scheme and how to change keys: [KEYBINDS.md](../KEYBINDS.md). In the
Sovereignity Shell login sessions these are bound for you.

Test without keybinds: `ssh-shell lens toggle`.

## 9. Notification integration

SSH includes a notification daemon (`org.freedesktop.Notifications`). Only one
program can own that name.

1. Stop and disable any other daemon you autostart (mako, dunst, swaync, or
   another shell), then restart SSH.
2. Send a test notification:
   ```sh
   notify-send "Hello" "From your new shell"
   ```
3. Expected: a popup in the top-right; the bell in the Meridian shows a dot.
   `ssh-shell status` shows `"serving":true`.

To keep your existing daemon instead, set **Settings → Signals → Notification
daemon** off (takes effect on restart).

## 10. Audio integration

SSH talks to **PipeWire** directly (no `pactl`/`wpctl` needed at runtime).

```sh
sudo pacman -S --needed pipewire wireplumber pipewire-pulse
```

`pipewire-pulse` is optional (for PulseAudio applications); SSH itself does not need it.

Verify: scroll over the instrument cluster in the Meridian to change volume;
an on-screen display appears. **Instruments** (`Super+G`) lists outputs and
inputs; right-click a gauge's device name to switch devices.

## 11. Network integration

Network and Wi-Fi control use **NetworkManager** over D-Bus.

```sh
sudo pacman -S --needed networkmanager bluez
sudo systemctl enable --now NetworkManager bluetooth
```

Verify: the Wi-Fi glyph in the Meridian reflects your connection. In
Instruments, click **Wi-Fi** to toggle it; right-click to list networks,
connect, or enter a passphrase. Bluetooth works the same way through **BlueZ**;
battery data comes from **UPower**, power profiles from
**power-profiles-daemon**, backlight from **brightnessctl**.

```sh
sudo pacman -S --needed upower power-profiles-daemon brightnessctl
sudo systemctl enable --now power-profiles-daemon
```

## 12. Media integration

Media controls use **MPRIS** and work with any player that exposes it
(browsers, Spotify, mpv with the MPRIS plugin, …). No setup is needed.
Verify: play something, open the **Almanac** (click the clock) or the **Lens**
(`Super+O`): title, artist, artwork and transport controls appear.

## 13. Updating SSH

```sh
cd SSH---Sovereignity-Shell && git pull
cd packaging/arch && makepkg -si
```
`pkgver` is computed from the commit, so pacman sees each build as an upgrade.

Your configuration and Atlas map are never touched by updates. Restart SSH
afterwards: `ssh-shell kill; ssh-shell --daemon`.

## 14. Uninstalling SSH

```sh
sudo pacman -R ssh-shell-git
```
pacman removes every file the package installed (this is checked in CI).

Remove the autostart and keybind lines you added to your compositor config.
To also delete your data:

```sh
rm -rf ~/.config/ssh-shell ~/.local/state/ssh-shell
```

## 15. Troubleshooting

| Symptom | Fix |
|---|---|
| `ssh-shell: quickshell (qs) is not installed` | Install Quickshell (step 4). |
| `no supported compositor detected` | Start SSH from inside a Hyprland or Niri session (it reads `HYPRLAND_INSTANCE_SIGNATURE` / `NIRI_SOCKET`). |
| Two bars on screen | Stop your previous bar and remove it from autostart. |
| No notification popups; Signals says SSH is not the daemon | Another daemon owns the bus name; see step 9. |
| Wi-Fi / Bluetooth keys greyed out | NetworkManager / BlueZ not running: `sudo systemctl enable --now NetworkManager bluetooth`. |
| Brightness gauge missing | `brightnessctl` not installed, or no backlight device (desktops). |
| Monospace text in a different font | JetBrains Mono not installed; SSH falls back automatically. Install it: `sudo pacman -S ttf-jetbrains-mono`. |
| Keybinds do nothing | Paste the generated block (step 8) and reload your compositor; test with `ssh-shell lens toggle`. |

More: [Troubleshooting](../TROUBLESHOOTING.md).

## 16. Known limitations

- **Not yet tested on CachyOS.** CachyOS uses the same packages as Arch, where SSH is tested, but no CachyOS install has been verified yet. Please report your result.
- CachyOS's optimised (`x86-64-v3/v4`) Qt builds have not been benchmarked with SSH.
- Same compositor caveats as on Arch: Hyprland verified on real hardware (Lua config); Niri verified nested in CI only.

## 17. Verification

Run these after installing; each line says what you should see.

```sh
command -v ssh-shell qs        # two paths
qs --version                   # Quickshell 0.3.x
ssh-shell status               # "connected":true and your compositor name
ssh-shell atlas where          # e.g. "Main A1"
ssh-shell atlas traverse right # your compositor switches workspace
ssh-shell atlas traverse left  # and back
notify-send test "ok"          # popup appears (if SSH is the daemon)
```

If all of these behave as described, SSH is working on your system. Please
report your result (distribution, compositor, versions) so the
[compatibility matrix](COMPATIBILITY.md) can be updated.

---

<sub>[Arch Linux](ARCH.md) · **CachyOS** · [EndeavourOS](ENDEAVOUROS.md) · [Fedora](FEDORA.md) · [NixOS](NIXOS.md) · [Void (unofficial)](VOID.md)</sub>
