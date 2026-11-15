# Installation

> SSH is **pre-1.0 alpha** software. See `STATUS.md` for what is tested.

## Requirements

| | |
|---|---|
| Compositor | Hyprland (tested on 0.57.2) or Niri (implemented, not yet tested) |
| Quickshell | ≥ 0.3 (tested on 0.3.2) with Qt ≥ 6.8 (tested on 6.12) |
| Fonts | Inter, Inter Display, JetBrains Mono |
| Optional services | PipeWire, NetworkManager, BlueZ, UPower, power-profiles-daemon, brightnessctl |

Each optional service is detected at runtime; when it is missing, SSH shows the
control as unavailable instead of failing.

## Arch Linux, CachyOS, EndeavourOS

```sh
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell/packaging/arch
makepkg -si
```

This builds `ssh-shell-git` from `packaging/arch/PKGBUILD`, pulling `quickshell`,
`qt6-declarative`, `qt6-svg`, `inter-font` and `ttf-jetbrains-mono` from the
official repositories. CachyOS and EndeavourOS use the same repositories and
the same package. Manjaro is not supported (its repositories lag Arch, and
Quickshell versions there may not match).

## Fedora

Quickshell is not in Fedora's official repositories at the time of writing.
Install it from a Quickshell COPR or build it from source
(<https://quickshell.org>), then:

```sh
sudo dnf install qt6-qtdeclarative qt6-qtsvg rsms-inter-fonts jetbrains-mono-fonts \
    pipewire NetworkManager bluez upower power-profiles-daemon brightnessctl make
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell && sudo make install PREFIX=/usr
```

An RPM spec is provided in `packaging/fedora/ssh-shell.spec`.

## NixOS

```nix
# flake.nix
inputs.ssh-shell.url = "github:ogjulius/SSH---Sovereignity-Shell";

# configuration.nix
imports = [ inputs.ssh-shell.nixosModules.default ];
programs.ssh-shell.enable = true;
```

The package installs into the Nix store and the `ssh-shell` wrapper points at
the store copy; user state stays in `$XDG_CONFIG_HOME` / `$XDG_STATE_HOME`.
For a quick try: `nix run github:ogjulius/SSH---Sovereignity-Shell`.

## Void Linux (unofficial)

See `packaging/void/README.md`.

## From a checkout (any distribution)

```sh
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell
./bin/ssh-shell            # runs src/ directly
sudo make install          # or install to /usr/local
```

## Start SSH with your session

Stop any other bar or notification daemon first (SSH works alongside them, but
only one program can own the notification bus name).

**Hyprland (classic config)**
```
exec-once = ssh-shell
```
**Hyprland (Lua config)** — start `ssh-shell` from your startup section with
`hl.dsp.exec_cmd("ssh-shell")` or your preferred autostart mechanism.

**Niri**
```kdl
spawn-at-startup "ssh-shell"
```

Then open Settings → Keys, copy the generated block for your compositor into
its config, and reload.

## Upgrading

- Your configuration (`~/.config/ssh-shell/`) and map (`~/.local/state/ssh-shell/`)
  are never touched by package upgrades.
- Restart SSH after upgrading: `ssh-shell kill && ssh-shell --daemon`.
- Read `CHANGELOG.md` for option changes; removed options are reported, not fatal.

## Uninstalling

`sudo make uninstall` (or remove the package). To remove your data:
`rm -rf ~/.config/ssh-shell ~/.local/state/ssh-shell`.
