# Compatibility matrix

This page records **what has actually been tested**, how, and when. A status
is only raised with evidence; anything not listed as verified should be
treated as unknown. Please [report your results](../../SUPPORT.md).

_Last updated: 2026-11-15 · SSH 0.1.0-alpha (unreleased) · Quickshell 0.3.2_

## Status levels

| Status | Meaning |
|---|---|
| NOT TESTED | No test on this target yet |
| BUILD PASSED | The package for this target builds in that distribution's environment |
| INSTALLATION VERIFIED | The package installs with the native package manager, has the correct layout, runs its unit tests from the installed tree, and uninstalls cleanly |
| RUNTIME VERIFIED | SSH starts and works in a desktop session on this target |
| COMPOSITOR VERIFIED | SSH's compositor features (detection, workspaces, Atlas travel/carry) are verified against that compositor |
| FULLY VERIFIED | All of the above on real hardware, including a hands-on pass |

## Matrix

| Distribution | Package | Installation | Hyprland | Niri |
|---|---|---|---|---|
| **Arch Linux** | BUILD PASSED | INSTALLATION VERIFIED | COMPOSITOR VERIFIED ¹ | COMPOSITOR VERIFIED ² |
| **CachyOS** | BUILD PASSED ³ | NOT TESTED | NOT TESTED | NOT TESTED |
| **EndeavourOS** | BUILD PASSED ³ | NOT TESTED | NOT TESTED | NOT TESTED |
| **Fedora** | BUILD PASSED | INSTALLATION VERIFIED ⁴ | NOT TESTED | NOT TESTED |
| **NixOS** | BUILD PASSED ⁵ | NOT TESTED | NOT TESTED | NOT TESTED |
| **Void** *(unofficial)* | NOT TESTED ⁶ | NOT TESTED | NOT TESTED ⁷ | NOT TESTED |

No target is **FULLY VERIFIED** yet.

## Evidence

1. **Arch + Hyprland** — real hardware: Arch Linux (kernel 7.3.4), Hyprland
   0.57.2 with a Lua config, Quickshell 0.3.2, Qt 6.12.0, NVIDIA. Verified: every
   surface opens; Atlas travel creates and focuses real workspaces and returns
   (checked with `hyprctl`); native workspace switches move the map cursor;
   Lua dispatch shapes (`focus`, `window.move` with `follow = false`,
   `window.close`) confirmed with reversible experiments; notifications verified
   on a private D-Bus session; genuine screenshots captured. The packaged tree
   (from `makepkg`) was run live with all surfaces opening and no errors.
   *Not yet:* a classic-config Hyprland session, multi-monitor, HiDPI.
   *CI cannot run Hyprland:* Aquamarine needs a DRM render node, which GitHub
   runners lack.
2. **Arch + Niri** — `ci.yml` → *Runtime on niri*: headless sway hosting a
   nested, software-rendered **Niri 26.04** session in an Arch container. 22/22
   checks: detection, IPC, all 7 surfaces open and are released, Atlas travel
   switches Niri's workspace and returns (via `niri msg`), carrying a real
   window to another cell, notification daemon, and the generated keybind block
   passing `niri validate`. Screenshots: [assets/screenshots/niri](../../assets/screenshots/niri).
   *Not yet:* real hardware, multiple outputs.
3. **CachyOS / EndeavourOS** — these distributions use Arch's repositories; the
   shared Arch package is what they install. No install on either has been
   verified.
4. **Fedora** — `build-fedora.yml` in `fedora:latest`: all dependency names
   exist in Fedora; Quickshell 0.3.2 installs from the
   `errornointernet/quickshell` COPR; `rpmbuild`, `rpmlint`, `dnf install`,
   layout checks, unit tests from the installed tree, `dnf remove` with nothing
   left. Not run in a Fedora desktop session. Hyprland is not in Fedora's
   official repositories; Niri 26.04 is.
5. **NixOS** — `build-nixos.yml` (Nix on Ubuntu, not a NixOS machine):
   `nix flake check`, `nix build`, package layout, both declarative example
   configurations (`example-hyprland`, `example-niri`) evaluate, and unit tests
   pass with nixpkgs' Quickshell 0.3.2.
6. **Void** — `package-validation.yml` in the official Void container: the
   `xbps-src` template parses and every dependency exists (Quickshell 0.3.2 is
   in Void's repositories). The template has not been built with `xbps-src`.
7. Hyprland is not in Void's official repositories; Niri is.

## Not covered anywhere yet

- Multi-monitor setups and HiDPI scaling.
- Mesa (AMD/Intel) GPUs on real hardware (Niri CI uses software rendering).
- Long multi-day sessions (repeated-cycle memory tests show no leak; see
  [PERFORMANCE.md](../PERFORMANCE.md)).
- Screen-reader accessibility.
