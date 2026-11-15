# Void Linux (unofficial, community-supported)

Void is **not** an officially supported target. These notes are a starting
point; they have not been tested by the SSH maintainers.

## Dependencies (XBPS)

```sh
sudo xbps-install -S qt6-declarative qt6-svg qt6-wayland font-inter jetbrains-mono \
    pipewire wireplumber NetworkManager bluez upower brightnessctl elogind
```

Quickshell is not packaged in the official Void repositories at the time of
writing. Build it from source following <https://quickshell.org> (CMake, Qt 6),
or use a community template if one exists for your release.

## Install SSH

```sh
git clone https://github.com/ogjulius/SSH---Sovereignity-Shell.git
cd SSH---Sovereignity-Shell
sudo make install PREFIX=/usr/local
```

## runit and elogind

- SSH has no service of its own; start it from your compositor (`exec-once` /
  `spawn-at-startup`).
- The default power commands use `loginctl`, which works with **elogind**.
  Enable it: `sudo ln -s /etc/sv/elogind /var/service/` (and `dbus`).
- Enable the services you want SSH to read:
  `NetworkManager`, `bluetoothd`, and run PipeWire from your session.

## Known limitations

- No maintainer testing on Void.
- Package names above may differ between Void releases; check with `xbps-query -Rs`.
