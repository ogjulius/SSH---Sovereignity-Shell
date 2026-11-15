# Installing SSH

Pick your distribution. Each guide is complete on its own: dependencies,
installation, first launch, keybinds, integrations, updating, uninstalling,
troubleshooting and verification.

| Distribution | Support | Guide | Tested |
|---|---|---|---|
| Arch Linux | Official | [ARCH.md](ARCH.md) | package installs; Hyprland and Niri verified |
| CachyOS | Official | [CACHYOS.md](CACHYOS.md) | shared Arch package builds; CachyOS untested |
| EndeavourOS | Official | [ENDEAVOUROS.md](ENDEAVOUROS.md) | shared Arch package builds; EndeavourOS untested |
| Fedora Linux | Official | [FEDORA.md](FEDORA.md) | RPM builds, installs and uninstalls (container) |
| NixOS | Official | [NIXOS.md](NIXOS.md) | flake builds; NixOS examples evaluate |
| Void Linux | **Unofficial** | [VOID.md](VOID.md) | dependency names checked only |
| Manjaro | Not supported | — | — |

Exact statuses and evidence: **[COMPATIBILITY.md](COMPATIBILITY.md)**.

## The installer (recommended)

```sh
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell
./install.sh
```

`install.sh` is a POSIX `sh` script that runs the installer with bash, so it
works from fish, zsh or any other shell. Run it as your normal user; it asks
for your password (sudo or doas) only for system steps.

**What it does, in order**

1. Detects the distribution, Hyprland and Niri (with versions), your shells,
   terminals and display manager.
2. Asks for: compositor (Hyprland, Niri or both; which session to preselect),
   terminal (installed ones first), profile, theme, what to do with existing
   SSH settings, and whether to preselect the SSH session on the login screen.
3. Shows every dependency (already installed / will be installed / skipped
   because it conflicts with something you have / not available) and every
   change, grouped into *system*, *your account* and *not changed*.
4. After you confirm: enables extra repositories if needed (Fedora COPRs,
   shown in the plan), installs dependencies with the native package manager,
   builds a native SSH package from the checkout and installs it, writes your
   settings, sets the login-screen preselection.
5. Validates: binaries on `PATH`, the session files, the plain recovery
   sessions, `ssh-session --check` for each compositor, your settings against
   SSH's schema, and `ssh-shell doctor`.
6. Shows **INSTALLATION COMPLETE** with **[ REBOOT NOW ] [ REBOOT LATER ]**.
   It reboots only after you choose REBOOT NOW and confirm.

| Profile | Modules | Extra packages |
|---|---|---|
| Minimal | Meridian, Lens, Atlas, launcher, Instruments, Almanac, power menu | required only |
| Standard | + Signals (notifications), OSD | PipeWire/WirePlumber, NetworkManager, UPower, brightnessctl, portal, libnotify |
| Complete | + weather | + BlueZ, power-profiles-daemon |
| Custom | your choice | your choice |

Installing a service package never enables or starts it. A package that would
conflict with one you have (for example power-profiles-daemon with TLP or
tuned-ppd) is skipped and reported, never swapped.

**Per distribution**

| | Method |
|---|---|
| Arch, CachyOS, EndeavourOS | pacman for dependencies (from the current databases: no partial upgrade), `makepkg` builds `ssh-shell` from `packaging/arch/PKGBUILD.local` |
| Fedora | dnf; Quickshell from the `errornointernet/quickshell` COPR, Hyprland from `solopasha/hyprland` (Fedora ships neither); `rpmbuild` from `packaging/fedora/ssh-shell.spec`; never `--allowerasing` |
| NixOS | writes `~/.config/ssh-shell/nixos/ssh-shell.nix` and shows where it goes in your flake; can run `nixos-rebuild switch` once you have added it. It never edits `/etc/nixos`. |
| Void (unofficial) | xbps for dependencies; a local XBPS package built with `xbps-create` (so `xbps-remove ssh-shell` uninstalls it). Hyprland is not in Void's repositories: Niri, or a Hyprland you installed yourself. |

**Options**

| Option | |
|---|---|
| `--dry-run` | show the plan, change nothing |
| `--yes` | unattended: take the defaults (never reboots) |
| `--compositor=hyprland\|niri\|both`, `--profile=minimal\|standard\|complete`, `--terminal=BIN`, `--theme=NAME` | answers for `--yes` |
| `--preselect` / `--no-preselect`, `--replace-config` | login-screen preselection; replace existing settings (backed up) |
| `--plain` | numbered prompts instead of the arrow-key interface (chosen automatically on limited terminals) |
| `--uninstall` | remove SSH; dependencies and settings are kept unless you ask |

**Logs:** `~/.local/state/ssh-shell/install-<date>.log`. What the installer
added (dependencies, repositories, backups) is recorded in
`~/.local/state/ssh-shell/installer.state`, which `--uninstall` uses.

## Login sessions

The package adds two entries to your display manager:

- **Sovereignity Shell (Hyprland)** runs `ssh-session hyprland`
- **Sovereignity Shell (Niri)** runs `ssh-session niri`

`ssh-session` starts the compositor with **your own configuration** and starts
SSH exactly once when it is up:

- *Hyprland:* `start-hyprland` runs unchanged. SSH then adds its keybinds at
  runtime (`hyprctl`); any key combination your config already binds keeps your
  action. Nothing is written to your Hyprland config.
- *Niri (25.11 or newer):* niri runs with `NIRI_CONFIG` pointing at a generated
  overlay in `~/.local/state/ssh-shell/session/` that includes SSH's binds
  first and your `~/.config/niri/config.kdl` second, so your binds and settings
  win. Your file is not modified.

Autostart entries in your compositor config still run in the SSH session.
`SSH_SESSION` is set to `hyprland` or `niri` there, so you can skip things you
only want elsewhere (Hyprland Lua: `if not os.getenv("SSH_SESSION") then … end`).
If SSH crashes it is restarted (up to three times in quick succession); if it
cannot start at all, the compositor keeps running with your config. The plain
**Hyprland** / **Niri** sessions are never modified. Without a display manager,
log in on a text console and run `ssh-session hyprland` or `ssh-session niri`.

Logs: `~/.local/state/ssh-shell/session.log` and `shell.log`. `ssh-shell doctor`
checks the whole setup.

## Requirements (all distributions)

| | |
|---|---|
| Compositor | Hyprland or Niri |
| Quickshell | 0.3 or newer (Qt 6) |
| Fonts | Inter (required for the intended look), JetBrains Mono (optional; SSH falls back) |
| Optional services | PipeWire, NetworkManager, BlueZ, UPower, power-profiles-daemon, brightnessctl |

Every optional service is detected at runtime. When one is missing, SSH shows
that control as unavailable instead of failing.

## Manually from a checkout (development, or other distributions)

```sh
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell
./bin/ssh-shell                         # runs src/ directly; needs Quickshell installed
sudo make install PREFIX=/usr/local     # or install system-wide
sudo make uninstall PREFIX=/usr/local
```

`make install` writes only under the prefix; `make uninstall` removes exactly
what it installed (checked in CI by `scripts/check-layout.sh`).

## Why Manjaro is not supported

Manjaro holds Arch packages back for testing, so its Quickshell and Qt versions
can differ from the ones SSH is tested with. It may work; it is not supported.
