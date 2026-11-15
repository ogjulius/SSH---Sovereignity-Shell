<p align="center"><img src="../../assets/branding/ssh-logo.svg" alt="SSH" width="300"></p>

# Installing SSH on Void Linux

<sub>[Arch Linux](ARCH.md) · [CachyOS](CACHYOS.md) · [EndeavourOS](ENDEAVOUROS.md) · [Fedora](FEDORA.md) · [NixOS](NIXOS.md) · **Void (unofficial)** · [Compatibility](COMPATIBILITY.md) · [All guides](README.md)</sub>

> [!IMPORTANT]
> **Void Linux is an unofficial, community-supported target.** The SSH
> maintainers do not test on Void. Package names in this guide are checked
> against Void's repositories in CI, but the installation itself is unverified.

Void packages Quickshell (`quickshell`) in its official repositories. SSH
installs from source with `make`, or with the provided `xbps-src` template.

**Contents:** [Compatibility](#1-distribution-and-compatibility) · [Compositor](#2-required-compositor) · [Prerequisites](#3-prerequisites) · [Dependencies](#4-required-dependencies) · [Install](#5-installation) · [Configuration](#6-configuration-setup) · [First launch](#7-first-launch) · [Keybinds](#8-keybinding-setup) · [Notifications](#9-notification-integration) · [Audio](#10-audio-integration) · [Network](#11-network-integration) · [Media](#12-media-integration) · [Update](#13-updating-ssh) · [Uninstall](#14-uninstalling-ssh) · [Troubleshooting](#15-troubleshooting) · [Limitations](#16-known-limitations) · [Verify](#17-verification)

## 1. Distribution and compatibility

| | Status |
|---|---|
| Package | **NOT TESTED** — the `xbps-src` template parses and all its dependencies exist in Void's repositories (CI) |
| Installation | **NOT TESTED** |
| Hyprland | **NOT TESTED** — Hyprland is not in Void's official repositories |
| Niri | **NOT TESTED** on Void (`niri` is in Void's repositories) |

Unofficial target. Verified 2026-11-15.

See the full [compatibility matrix](COMPATIBILITY.md) for what each status means.

## 2. Required compositor

SSH runs inside **Hyprland** or **Niri**. Other compositors are not supported
(SSH starts, but workspace features are disabled).

```sh
# Niri is in Void's official repositories:
sudo xbps-install -S niri
```

**Hyprland is not in Void's official repositories.** Community repositories
exist; see the [Hyprland installation guide](https://wiki.hypr.land/Getting-Started/Installation/).
Niri is the simpler path on Void.

Log in to the compositor session before continuing.

## 3. Prerequisites

- An up-to-date system.
- A working Wayland session of Hyprland or Niri.
- About 5 MB of disk space for SSH (Quickshell and Qt are larger if not yet installed).

> [!NOTE]
> Void uses **runit**, not systemd. SSH needs no service of its own, and its
> power actions use `loginctl`, which works with **elogind**.

## 4. Required dependencies

| Package | Why |
|---|---|
| `quickshell` | the QML shell runtime (Void: 0.3.2) |
| `qt6-declarative`, `qt6-svg`, `qt6-wayland` | QML engine, SVG icons, Wayland |
| `font-inter` | interface typeface |
| `make`, `git` | to install from source |

JetBrains Mono is **not packaged in Void**; SSH falls back to another
monospace font automatically (install the font manually for the intended look).
Optional: `pipewire`, `wireplumber`, `NetworkManager`, `bluez`, `upower`,
`brightnessctl`, `elogind`.

## 5. Installation

> [!TIP]
> `./install.sh` on Void installs dependencies with xbps and builds a local
> XBPS package of SSH with `xbps-create` (removable with `xbps-remove ssh-shell`),
> including the **Sovereignity Shell (Niri)** login session. Void is unofficial.

1. **Install Quickshell and SSH's dependencies:**
   ```sh
   sudo xbps-install -S quickshell qt6-declarative qt6-svg qt6-wayland font-inter make git
   qs --version      # expect Quickshell 0.3.x
   ```
2. **Get the source and install it** to `/usr/local` (keeps it apart from xbps-managed files):
   ```sh
   git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
   cd SSH---Sovereignity-Shell
   sudo make install PREFIX=/usr/local
   ```
3. **Confirm:** `command -v ssh-shell` prints `/usr/local/bin/ssh-shell`.

### Alternative: build an XBPS package with `xbps-src`

A template is provided in `packaging/void/srcpkgs/ssh-shell/template`. Before
the first tagged release it contains `@COMMIT@` / `@CHECKSUM@` placeholders:
set `_commit` to a commit hash from this repository and `checksum` to the
SHA-256 of `https://github.com/ogjulius/SSH---Sovereignity-Shell/archive/<commit>.tar.gz`, then:
```sh
cp -r packaging/void/srcpkgs/ssh-shell ~/void-packages/srcpkgs/
cd ~/void-packages && ./xbps-src pkg ssh-shell && sudo xbps-install --repository hostdir/binpkgs ssh-shell
```

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
block from its `shortcuts` options, and you paste it in. With SSH running:

```sh
ssh-shell keybinds hyprland       # Hyprland, classic hyprland.conf
ssh-shell keybinds hyprland-lua   # Hyprland, Lua hyprland.lua
ssh-shell keybinds niri           # Niri config.kdl
```
Append the output to your compositor config, then reload: Hyprland reloads
automatically on save (or `hyprctl reload`); Niri reloads automatically.

You can also open **Settings → Keys** to change the keys and copy the block.
Defaults: `Super+Space` Lens · `Super+Tab` Atlas · `Super+D` launcher ·
`Super+A` Instruments · `Super+Shift+Esc` power · `Super+Alt+arrows` travel ·
`Super+Alt+Shift+arrows` carry the focused window.

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
sudo xbps-install -S pipewire wireplumber
```
Start PipeWire from your compositor's autostart (Void does not run it as a system service).

Verify: scroll over the instrument cluster in the Meridian to change volume;
an on-screen display appears. **Instruments** (`Super+A`) lists outputs and
inputs; right-click a gauge's device name to switch devices.

## 11. Network integration

Network and Wi-Fi control use **NetworkManager** over D-Bus.

```sh
sudo xbps-install -S NetworkManager bluez
sudo ln -s /etc/sv/dbus /var/service/
sudo ln -s /etc/sv/NetworkManager /var/service/
sudo ln -s /etc/sv/bluetoothd /var/service/
```

Verify: the Wi-Fi glyph in the Meridian reflects your connection. In
Instruments, click **Wi-Fi** to toggle it; right-click to list networks,
connect, or enter a passphrase. Bluetooth works the same way through **BlueZ**;
battery data comes from **UPower**, power profiles from
**power-profiles-daemon**, backlight from **brightnessctl**.

```sh
sudo xbps-install -S upower brightnessctl elogind
sudo ln -s /etc/sv/elogind /var/service/
```

## 12. Media integration

Media controls use **MPRIS** and work with any player that exposes it
(browsers, Spotify, mpv with the MPRIS plugin, …). No setup is needed.
Verify: play something, open the **Almanac** (click the clock) or the **Lens**
(`Super+Space`): title, artist, artwork and transport controls appear.

## 13. Updating SSH

```sh
cd SSH---Sovereignity-Shell && git pull && sudo make install PREFIX=/usr/local
sudo xbps-install -Su quickshell
```

Your configuration and Atlas map are never touched by updates. Restart SSH
afterwards: `ssh-shell kill; ssh-shell --daemon`.

## 14. Uninstalling SSH

```sh
cd SSH---Sovereignity-Shell && sudo make uninstall PREFIX=/usr/local
```
`make uninstall` removes every file `make install` created (checked in CI).

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
| Wi-Fi / Bluetooth keys greyed out | NetworkManager / BlueZ not running: link the runit services: `sudo ln -s /etc/sv/NetworkManager /var/service/` (and `bluetoothd`, `dbus`). |
| Brightness gauge missing | `brightnessctl` not installed, or no backlight device (desktops). |
| Monospace text in a different font | JetBrains Mono not installed; SSH falls back automatically. JetBrains Mono is not in Void's repositories; install it manually into `~/.local/share/fonts` if you want the intended look. |
| Keybinds do nothing | Paste the generated block (step 8) and reload your compositor; test with `ssh-shell lens toggle`. |

More: [Troubleshooting](../TROUBLESHOOTING.md).

## 16. Known limitations

- **Unofficial and untested** by the maintainers; package names are CI-checked only.
- No PipeWire/elogind autostart is configured for you; see steps 10–11.
- JetBrains Mono must be installed manually.

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

<sub>[Arch Linux](ARCH.md) · [CachyOS](CACHYOS.md) · [EndeavourOS](ENDEAVOUROS.md) · [Fedora](FEDORA.md) · [NixOS](NIXOS.md) · **Void (unofficial)**</sub>
