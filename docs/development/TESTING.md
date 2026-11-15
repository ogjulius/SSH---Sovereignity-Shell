# Testing

SSH is tested at five levels. Each level is automated where the environment
allows; what is *not* automated is listed honestly in
[COMPATIBILITY.md](../installation/COMPATIBILITY.md).

| Level | What it proves | How | Where |
|---|---|---|---|
| Unit | Pure logic: config schema, fuzzy search, Atlas model, palette contrast, glyph syntax, keybind generators, Lens intents | `src/dev-tests.qml` in Quickshell's own JS engine (239 assertions) | `make test`, every CI job |
| Static | QML syntax | Qt 6 `qmllint` (syntax errors fail; unresolved `qs.*` runtime imports are advisory) | `make test`, CI |
| Load | Every surface instantiates without QML errors, with or without system services | `src/dev-render.qml` offscreen | `make test`, CI |
| Package | Packages build, install, contain the right files with the right modes, run their tests from the installed tree, and uninstall cleanly | makepkg + namcap + pacman; rpmbuild + rpmlint + dnf; nix build + flake check; `scripts/check-layout.sh` | `build-*.yml`, `package-validation.yml` |
| Runtime | SSH runs in a real compositor session: detection, IPC, every surface, Atlas travel and carry verified with the compositor's own CLI, notifications | `scripts/ci/runtime-test.sh` (headless sway → nested compositor → SSH on a private D-Bus) | `ci.yml` (Niri); real hardware (Hyprland) |

## Running locally

```sh
make test                                   # unit + qmllint + load
./scripts/check-layout.sh                   # install/uninstall layout
python3 scripts/check-links.py              # every internal Markdown link
./scripts/benchmark.sh --note "conditions"  # performance (see PERFORMANCE.md)
./scripts/capture-screenshots.sh /tmp/shots # genuine screenshots (Hyprland)
```

`scripts/ci/runtime-test.sh` is meant for disposable containers (it starts
compositors and needs `sway`, `grim`, `foot`, `libnotify` and the compositor
under test); run it as a non-root user.

## Why Hyprland is not in the CI runtime matrix

Hyprland's Aquamarine backend needs a DRM render node (GBM) even when nested;
GitHub-hosted runners have none and Hyprland aborts with
`CBackend::create() failed!`. Hyprland runtime testing is therefore done on
real hardware (see the compositor rows in COMPATIBILITY.md). Niri can run
nested with software rendering, so it is tested in CI.

## Testing without disturbing your desktop

- `SSH_SHELL_NO_NOTIFICATIONS=1` stops SSH from competing for the notification bus name.
- `SSH_SHELL_CONFIG=/tmp/x.json` and `XDG_STATE_HOME=/tmp/state` isolate config and the Atlas map.
- `dbus-run-session -- …` gives SSH a private session bus (it can then own notifications).
