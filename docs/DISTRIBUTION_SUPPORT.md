# Distribution support

| Distribution | Status | Packaging | Tested |
|---|---|---|---|
| Arch Linux | Official | `packaging/arch/PKGBUILD` (`ssh-shell-git`) | **Yes** — runs on Arch (kernel 7.3.4, Quickshell 0.3.2, Qt 6.12.0). Package built with `makepkg -d` from the git tree (119 files, dev files excluded) and the extracted package run live on Hyprland: all surfaces opened, no errors. Not installed system-wide with `pacman -U` on the test machine. |
| CachyOS | Official | Arch PKGBUILD | **No** — same repositories as Arch; needs verification on a CachyOS install |
| EndeavourOS | Official | Arch PKGBUILD | **No** — same repositories as Arch; needs verification on an EndeavourOS install |
| Fedora Linux | Official | `packaging/fedora/ssh-shell.spec` | **No** — Quickshell must come from outside Fedora's repos |
| NixOS | Official | `flake.nix`, `packaging/nixos/` | **No** — flake not yet evaluated |
| Void Linux | Unofficial (community) | `packaging/void/README.md` | **No** |
| Manjaro | Not supported | — | — |

"Official" describes intent and maintainer commitment; per the project's own
rule, **official support must be backed by testing**. Until a row says *Yes*,
treat that distribution as "expected to work".

## Portability rules SSH follows

- No package manager or init system is referenced in application code.
- Power actions default to `loginctl` (systemd-logind **and** elogind).
- System state comes from D-Bus services and `/proc` / `/sys`, not distro tools.
- Paths follow XDG; the installed tree is read-only (works from the Nix store).
- Optional tools (brightnessctl, power-profiles-daemon) degrade gracefully.
