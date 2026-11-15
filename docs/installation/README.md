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

## Requirements (all distributions)

| | |
|---|---|
| Compositor | Hyprland or Niri |
| Quickshell | 0.3 or newer (Qt 6) |
| Fonts | Inter (required for the intended look), JetBrains Mono (optional; SSH falls back) |
| Optional services | PipeWire, NetworkManager, BlueZ, UPower, power-profiles-daemon, brightnessctl |

Every optional service is detected at runtime. When one is missing, SSH shows
that control as unavailable instead of failing.

## From a checkout (any distribution, for development)

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
