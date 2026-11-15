# Contributing to SSH

Thank you for helping build SSH. This project values **honest engineering**:
working code over placeholders, measurements over claims, and a coherent
experience over feature count.

## Before you start

- Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
  [docs/DESIGN_PHILOSOPHY.md](docs/DESIGN_PHILOSOPHY.md).
- For anything larger than a fix, open an issue first so we can agree on the
  design — especially for new surfaces or options.

## Development loop

See [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md). In short:

```sh
SSH_SHELL_NO_NOTIFICATIONS=1 SSH_SHELL_CONFIG=/tmp/ssh-dev.json qs -p src
make test
```

## Rules of the house

1. **No fake controls.** If a control cannot reach a real interface, show it as
   unavailable.
2. **No hard-coded visuals.** Use `Theme` tokens and the components in
   `src/components/`.
3. **No option without effect.** New options go into `configuration/Schema.js`,
   Settings (`modules/settings/Pages.js`) and `docs/CONFIGURATION.md`.
4. **No shell interpolation.** Start processes with argv arrays only.
5. **Compositor access goes through `Compositor`.** Backends must not leak
   compositor specifics into modules.
6. **Measure performance claims** with `scripts/benchmark.sh` and include the
   report in your PR.
7. **Screenshots must be genuine.** Offscreen renders from `dev-render.qml` are
   fine for review but must be labelled as renders.
8. **Respect originality.** Don't port components or signature layouts from other
   shells. Inspiration is fine; copies are not.

## Commits and pull requests

- Small, focused commits with messages that explain *why*.
- `make test` must pass. Update docs and `CHANGELOG.md` (Unreleased) as needed.
- Describe how you tested, on which compositor and distribution.

## Code style

- QML: 4-space indent, `PascalCase.qml` components, `id`s in camelCase,
  `required property` for delegate data, bindings over imperative updates.
- JS libraries: `.pragma library`, pure functions where possible, unit-tested in
  `src/dev-tests.qml`.
- Comments explain intent and constraints, briefly.

## Licensing

By contributing you agree that your contribution is licensed under
GPL-3.0-or-later.
