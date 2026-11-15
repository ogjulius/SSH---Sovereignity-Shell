<p align="center"><img src="../../assets/branding/ssh-logo.svg" alt="SSH" width="300"></p>

# Installing SSH on NixOS

<sub>[Arch Linux](ARCH.md) · [CachyOS](CACHYOS.md) · [EndeavourOS](ENDEAVOUROS.md) · [Fedora](FEDORA.md) · **NixOS** · [Void (unofficial)](VOID.md) · [Compatibility](COMPATIBILITY.md) · [All guides](README.md)</sub>

SSH ships a Nix flake with a package and a NixOS module. Quickshell, Inter and JetBrains Mono come from nixpkgs. The package installs into the Nix store; your settings stay in `~/.config` and `~/.local/state`, so nothing assumes a mutable `/usr`.

**Contents:** [Compatibility](#1-distribution-and-compatibility) · [Compositor](#2-required-compositor) · [Prerequisites](#3-prerequisites) · [Dependencies](#4-required-dependencies) · [Install](#5-installation) · [Configuration](#6-configuration-setup) · [First launch](#7-first-launch) · [Keybinds](#8-keybinding-setup) · [Notifications](#9-notification-integration) · [Audio](#10-audio-integration) · [Network](#11-network-integration) · [Media](#12-media-integration) · [Update](#13-updating-ssh) · [Uninstall](#14-uninstalling-ssh) · [Troubleshooting](#15-troubleshooting) · [Limitations](#16-known-limitations) · [Verify](#17-verification)

## 1. Distribution and compatibility

| | Status |
|---|---|
| Package | **BUILD PASSED** — `nix flake check` and `nix build` (Nix on an Ubuntu runner, CI) |
| Installation | **NOT TESTED** on a NixOS system — the declarative example configurations for Hyprland and Niri *evaluate* in CI |
| Hyprland | **NOT TESTED** on NixOS |
| Niri | **NOT TESTED** on NixOS |

Verified 2026-11-15.

See the full [compatibility matrix](COMPATIBILITY.md) for what each status means.

## 2. Required compositor

SSH runs inside **Hyprland** or **Niri**. Other compositors are not supported
(SSH starts, but workspace features are disabled).

```nix
# configuration.nix — pick one
programs.hyprland.enable = true;
programs.niri.enable = true;
```
Both options are evaluated in CI as part of the example configurations
(`nixosConfigurations.example-hyprland` / `example-niri` in `flake.nix`).

Log in to the compositor session before continuing.

## 3. Prerequisites

- An up-to-date system.
- A working Wayland session of Hyprland or Niri.
- About 5 MB of disk space for SSH (Quickshell and Qt are larger if not yet installed).

> [!NOTE]
> Flakes must be enabled: add `experimental-features = nix-command flakes` to
> `nix.settings` (NixOS) or `~/.config/nix/nix.conf`.

## 4. Required dependencies

Everything is pulled from nixpkgs by the flake:

| Attribute | Why |
|---|---|
| `quickshell` | the QML shell runtime |
| `inter`, `jetbrains-mono` | typefaces (added to `fonts.packages` by the module) |
| `brightnessctl` | backlight control (on the wrapper's `PATH`) |

These attributes are checked against `nixos-unstable` in CI.

## 5. Installation

> [!TIP]
> `./install.sh` on NixOS writes a module with your choices to
> `~/.config/ssh-shell/nixos/ssh-shell.nix` and shows where it goes in your
> flake; it never edits `/etc/nixos`. The module below is what it generates.
> `programs.ssh-shell.hyprland.enable` / `.niri.enable` add the login sessions.

### A. Declarative (recommended)

1. **Add SSH to your system flake:**
   ```nix
   # /etc/nixos/flake.nix
   {
     inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
     inputs.ssh-shell.url = "github:ogjulius/SSH---Sovereignity-Shell";
     inputs.ssh-shell.inputs.nixpkgs.follows = "nixpkgs";

     outputs = { nixpkgs, ssh-shell, ... }: {
       nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         modules = [
           ./configuration.nix
           ssh-shell.nixosModules.default
           { programs.ssh-shell.enable = true; }
         ];
       };
     };
   }
   ```
2. **Rebuild:**
   ```sh
   sudo nixos-rebuild switch --flake /etc/nixos#myhost
   ```
3. **Confirm:** `command -v ssh-shell` prints a `/run/current-system/sw/bin/…` path.

What the module does: adds the package to `environment.systemPackages`, adds
Inter and JetBrains Mono to `fonts.packages`, and enables `services.upower`
(as a default you can override). It does not touch your compositor config.

### B. Standalone package (try it, or non-NixOS with Nix)

```sh
nix run github:ogjulius/SSH---Sovereignity-Shell           # run once
nix profile install github:ogjulius/SSH---Sovereignity-Shell   # install to your profile
```

On a non-NixOS system, Quickshell from nixpkgs needs working OpenGL drivers
for Nix applications (for example via `nixGL`); that setup is outside SSH's
scope.

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

```nix
services.pipewire = { enable = true; wireplumber.enable = true; };
```

Verify: scroll over the instrument cluster in the Meridian to change volume;
an on-screen display appears. **Instruments** (`Super+A`) lists outputs and
inputs; right-click a gauge's device name to switch devices.

## 11. Network integration

Network and Wi-Fi control use **NetworkManager** over D-Bus.

```nix
networking.networkmanager.enable = true;
hardware.bluetooth.enable = true;
```

Verify: the Wi-Fi glyph in the Meridian reflects your connection. In
Instruments, click **Wi-Fi** to toggle it; right-click to list networks,
connect, or enter a passphrase. Bluetooth works the same way through **BlueZ**;
battery data comes from **UPower**, power profiles from
**power-profiles-daemon**, backlight from **brightnessctl**.

```nix
services.upower.enable = true;            # set by the SSH module by default
services.power-profiles-daemon.enable = true;
environment.systemPackages = [ pkgs.brightnessctl ];   # the SSH wrapper already has it on PATH
```

## 12. Media integration

Media controls use **MPRIS** and work with any player that exposes it
(browsers, Spotify, mpv with the MPRIS plugin, …). No setup is needed.
Verify: play something, open the **Almanac** (click the clock) or the **Lens**
(`Super+Space`): title, artist, artwork and transport controls appear.

## 13. Updating SSH

```sh
nix flake update ssh-shell --flake /etc/nixos      # declarative
sudo nixos-rebuild switch --flake /etc/nixos#myhost
# standalone:
nix profile upgrade --all
```

Your configuration and Atlas map are never touched by updates. Restart SSH
afterwards: `ssh-shell kill; ssh-shell --daemon`.

## 14. Uninstalling SSH

Remove `ssh-shell.nixosModules.default` and `programs.ssh-shell.enable` from
your flake and rebuild, or for a profile install:
```sh
nix profile remove ssh-shell
```
Nothing outside the Nix store and your home directory was ever written.

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
| Wi-Fi / Bluetooth keys greyed out | NetworkManager / BlueZ not running: enable `networking.networkmanager.enable` / `hardware.bluetooth.enable` and rebuild. |
| Brightness gauge missing | `brightnessctl` not installed, or no backlight device (desktops). |
| Monospace text in a different font | JetBrains Mono not installed; SSH falls back automatically. The module adds `pkgs.jetbrains-mono` to `fonts.packages`. |
| Keybinds do nothing | Paste the generated block (step 8) and reload your compositor; test with `ssh-shell lens toggle`. |

More: [Troubleshooting](../TROUBLESHOOTING.md).

## 16. Known limitations

- **Build verified in CI** (Nix on Ubuntu): `nix flake check`, `nix build`, the package layout, both example NixOS configurations evaluate, and unit tests pass with nixpkgs' Quickshell. **Not yet run in a NixOS desktop session.**
- The flake follows `nixos-unstable`; Quickshell ≥ 0.3 is required.
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

<sub>[Arch Linux](ARCH.md) · [CachyOS](CACHYOS.md) · [EndeavourOS](ENDEAVOUROS.md) · [Fedora](FEDORA.md) · **NixOS** · [Void (unofficial)](VOID.md)</sub>
