<p align="center"><img src="../../assets/branding/ssh-logo.svg" alt="SSH" width="300"></p>

# Installing SSH on Fedora Linux

<sub>[Arch Linux](ARCH.md) · [CachyOS](CACHYOS.md) · [EndeavourOS](ENDEAVOUROS.md) · **Fedora** · [NixOS](NIXOS.md) · [Void (unofficial)](VOID.md) · [Compatibility](COMPATIBILITY.md) · [All guides](README.md)</sub>

Fedora provides Qt 6 and the fonts SSH uses. **Quickshell itself is not in Fedora's official repositories**; the Quickshell documentation points Fedora users to the `errornointernet/quickshell` COPR, a third-party repository not run by the Quickshell or SSH projects. SSH is packaged as an RPM that you build from this repository.

**Contents:** [Compatibility](#1-distribution-and-compatibility) · [Compositor](#2-required-compositor) · [Prerequisites](#3-prerequisites) · [Dependencies](#4-required-dependencies) · [Install](#5-installation) · [Configuration](#6-configuration-setup) · [First launch](#7-first-launch) · [Keybinds](#8-keybinding-setup) · [Notifications](#9-notification-integration) · [Audio](#10-audio-integration) · [Network](#11-network-integration) · [Media](#12-media-integration) · [Update](#13-updating-ssh) · [Uninstall](#14-uninstalling-ssh) · [Troubleshooting](#15-troubleshooting) · [Limitations](#16-known-limitations) · [Verify](#17-verification)

## 1. Distribution and compatibility

| | Status |
|---|---|
| Package | **BUILD PASSED** — `rpmbuild` + `rpmlint` in a `fedora:latest` container (CI) |
| Installation | **INSTALLATION VERIFIED** — `dnf install` (Quickshell 0.3.2 from the COPR), file layout, unit tests from the installed tree, `dnf remove` with nothing left behind (CI) |
| Hyprland | **NOT TESTED** on Fedora |
| Niri | **NOT TESTED** on Fedora |

Installation was verified in a container, not in a Fedora desktop session. Verified 2026-11-15.

See the full [compatibility matrix](COMPATIBILITY.md) for what each status means.

## 2. Required compositor

SSH runs inside **Hyprland** or **Niri**. Other compositors are not supported
(SSH starts, but workspace features are disabled).

```sh
# Niri is in Fedora's official repositories (26.04 at the time of writing):
sudo dnf install niri
```

**Hyprland is not in Fedora's official repositories.** It is distributed for
Fedora through community COPRs; follow the Fedora section of the
[Hyprland installation guide](https://wiki.hypr.land/Getting-Started/Installation/)
and review any COPR before enabling it. SSH has been verified with Hyprland
0.57.2; older versions are untested.

Log in to the compositor session before continuing.

## 3. Prerequisites

- An up-to-date system.
- A working Wayland session of Hyprland or Niri.
- About 5 MB of disk space for SSH (Quickshell and Qt are larger if not yet installed).

> [!WARNING]
> COPR repositories are community-maintained and are not reviewed by Fedora.
> Review [the COPR project](https://copr.fedorainfracloud.org/coprs/errornointernet/quickshell/)
> before enabling it.

## 4. Required dependencies

| Package | Source | Why |
|---|---|---|
| `quickshell` (≥ 0.3) | COPR `errornointernet/quickshell` | the QML shell runtime |
| `qt6-qtdeclarative`, `qt6-qtsvg` | Fedora | QML engine, SVG icons |
| `rsms-inter-fonts`, `jetbrains-mono-fonts` | Fedora | typefaces |
| `rpm-build`, `make`, `git` | Fedora | to build the RPM |

Optional: `pipewire`, `NetworkManager`, `bluez`, `upower`, `power-profiles-daemon`, `brightnessctl` (all in Fedora). Every name above is checked against Fedora's repositories in CI.

## 5. Installation

> [!TIP]
> **Recommended:** run `./install.sh` from a clone of the repository. It does
> everything below for you, adds the **Sovereignity Shell** login sessions and
> validates them; see [the installer](README.md#the-installer-recommended).
> The manual steps below remain for reference.

1. **Enable the Quickshell COPR** and install Quickshell:
   ```sh
   sudo dnf install dnf-plugins-core
   sudo dnf copr enable errornointernet/quickshell
   sudo dnf install quickshell
   qs --version        # expect: Quickshell 0.3.x … Fedora COPR (errornointernet/quickshell)
   ```
2. **Install the build tools:**
   ```sh
   sudo dnf install rpm-build make git
   ```
3. **Get the source and build the RPM** from it:
   ```sh
   git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
   cd SSH---Sovereignity-Shell
   mkdir -p ~/rpmbuild/SOURCES
   git archive --prefix=SSH---Sovereignity-Shell-main/ -o ~/rpmbuild/SOURCES/ssh-shell-main.tar.gz HEAD
   rpmbuild -ba packaging/fedora/ssh-shell.spec
   ```
   Expected at the end: `Wrote: …/rpmbuild/RPMS/noarch/ssh-shell-0.1.0~alpha-1.fc….noarch.rpm`
4. **Install it with dnf**, which also pulls Qt and the fonts:
   ```sh
   sudo dnf install ~/rpmbuild/RPMS/noarch/ssh-shell-*.rpm
   ```
5. **Confirm:**
   ```sh
   rpm -ql ssh-shell | grep -E 'bin/ssh-shell|shell.qml'
   ```

> [!NOTE]
> The *Build · Fedora* workflow also uploads the RPM it builds as a GitHub
> Actions artifact (a GitHub login is required to download artifacts). Prefer
> building it yourself as above.

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

PipeWire is Fedora's default audio server; nothing to install.

```sh
sudo dnf install pipewire   # already present on Fedora Workstation
```

Verify: scroll over the instrument cluster in the Meridian to change volume;
an on-screen display appears. **Instruments** (`Super+A`) lists outputs and
inputs; right-click a gauge's device name to switch devices.

## 11. Network integration

Network and Wi-Fi control use **NetworkManager** over D-Bus.

NetworkManager and BlueZ are installed and enabled by default on Fedora Workstation. If not:

```sh
sudo dnf install NetworkManager bluez
sudo systemctl enable --now NetworkManager bluetooth
```

Verify: the Wi-Fi glyph in the Meridian reflects your connection. In
Instruments, click **Wi-Fi** to toggle it; right-click to list networks,
connect, or enter a passphrase. Bluetooth works the same way through **BlueZ**;
battery data comes from **UPower**, power profiles from
**power-profiles-daemon**, backlight from **brightnessctl**.

```sh
sudo dnf install upower power-profiles-daemon brightnessctl
```

## 12. Media integration

Media controls use **MPRIS** and work with any player that exposes it
(browsers, Spotify, mpv with the MPRIS plugin, …). No setup is needed.
Verify: play something, open the **Almanac** (click the clock) or the **Lens**
(`Super+Space`): title, artist, artwork and transport controls appear.

## 13. Updating SSH

```sh
cd SSH---Sovereignity-Shell && git pull
git archive --prefix=SSH---Sovereignity-Shell-main/ -o ~/rpmbuild/SOURCES/ssh-shell-main.tar.gz HEAD
rpmbuild -ba packaging/fedora/ssh-shell.spec
sudo dnf install ~/rpmbuild/RPMS/noarch/ssh-shell-*.rpm
sudo dnf upgrade quickshell      # Quickshell updates come from the COPR
```

Your configuration and Atlas map are never touched by updates. Restart SSH
afterwards: `ssh-shell kill; ssh-shell --daemon`.

## 14. Uninstalling SSH

```sh
sudo dnf remove ssh-shell
# optionally:
sudo dnf remove quickshell && sudo dnf copr disable errornointernet/quickshell
```
dnf removes every file the RPM installed (this is checked in CI).

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
| Monospace text in a different font | JetBrains Mono not installed; SSH falls back automatically. Install it: `sudo dnf install jetbrains-mono-fonts`. |
| Keybinds do nothing | Paste the generated block (step 8) and reload your compositor; test with `ssh-shell lens toggle`. |

More: [Troubleshooting](../TROUBLESHOOTING.md).

## 16. Known limitations

- **Build verified in CI only** (Fedora container): the RPM builds, installs with dnf, passes its unit tests from the installed tree and uninstalls cleanly. It has **not** been run in a Fedora desktop session yet.
- Quickshell comes from a third-party COPR; its versions may lag or lead Arch's.
- SSH is alpha software.

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

<sub>[Arch Linux](ARCH.md) · [CachyOS](CACHYOS.md) · [EndeavourOS](ENDEAVOUROS.md) · **Fedora** · [NixOS](NIXOS.md) · [Void (unofficial)](VOID.md)</sub>
