# Distribution support

| Distribution | Tier | Guide |
|---|---|---|
| Arch Linux | Official | [ARCH.md](installation/ARCH.md) |
| CachyOS | Official | [CACHYOS.md](installation/CACHYOS.md) |
| EndeavourOS | Official | [ENDEAVOUROS.md](installation/ENDEAVOUROS.md) |
| Fedora Linux | Official | [FEDORA.md](installation/FEDORA.md) |
| NixOS | Official | [NIXOS.md](installation/NIXOS.md) |
| Void Linux | Unofficial (community) | [VOID.md](installation/VOID.md) |
| Manjaro | Not supported | — |

Test status for each target lives in one place:
**[installation/COMPATIBILITY.md](installation/COMPATIBILITY.md)**.

"Official" describes intent and maintainer commitment; per the project's own
rule, **official support must be backed by testing**. Until a row says *Yes*,
treat that distribution as "expected to work".

## Portability rules SSH follows

- No package manager or init system is referenced in application code.
- Power actions default to `loginctl` (systemd-logind **and** elogind).
- System state comes from D-Bus services and `/proc` / `/sys`, not distro tools.
- Paths follow XDG; the installed tree is read-only (works from the Nix store).
- Optional tools (brightnessctl, power-profiles-daemon) degrade gracefully.
