# Release process

## Versioning

SSH follows [Semantic Versioning](https://semver.org/).

- **Pre-1.0** (`0.y.z`): minor versions may change configuration options. Every
  change is validated and reported at runtime; none is fatal. Pre-releases carry
  a suffix: `0.1.0-alpha`, `0.1.0-beta.1`, `0.1.0-rc.1`.
- **1.0** will be declared when every officially supported distribution and both
  compositors are at least *runtime verified* in
  [COMPATIBILITY.md](../installation/COMPATIBILITY.md).
- The version lives in one place: `src/configuration/Version.qml`. Packaging
  derives from it (`PKGBUILD` `pkgver()`), or must be bumped alongside it
  (`ssh-shell.spec`, `packaging/nixos/package.nix`, the Void template).
- Package-format spellings: Arch `0.1.0.alpha`, RPM `0.1.0~alpha`, Void
  `0.1.0alpha` (each format's rule for pre-release ordering).
- Tags: `v0.1.0-alpha`. Releases are created from tags on `main`.

## Checklist

A release is cut only when **every** box is checked, and **only with the
maintainer's explicit approval**.

### Code and tests
- [ ] `make test` passes locally.
- [ ] All workflows green on the release commit (CI, Arch, Fedora, Nix, package validation).
- [ ] Runtime verification recorded for each compositor in COMPATIBILITY.md, with dates.
- [ ] Benchmark re-run; PERFORMANCE.md updated with the new numbers.

### Documentation
- [ ] `CHANGELOG.md`: move *Unreleased* to the new version with the date.
- [ ] `docs/STATUS.md` and `docs/installation/COMPATIBILITY.md` reflect reality.
- [ ] `python3 scripts/check-links.py` passes.
- [ ] Screenshots are genuine and current (`assets/screenshots/README.md` updated).

### Packaging
- [ ] Version bumped in `Version.qml`, the RPM spec, `package.nix`, the Void template.
- [ ] `packaging/arch/.SRCINFO` regenerated (`makepkg --printsrcinfo`).
- [ ] Void template `_commit` / `checksum` point at the release tag archive.

### Security
- [ ] `git grep` scan for credentials, tokens, personal paths and e-mail addresses.
- [ ] Review of new `Process` / `execDetached` calls: argv arrays only.
- [ ] Dependencies reviewed (no new runtime dependency without a reason).

### Publish (after approval)
- [ ] Annotated tag `vX.Y.Z[-suffix]` pushed.
- [ ] GitHub release marked **pre-release** for any `-alpha/-beta/-rc`.
- [ ] Attach only artifacts built by CI from the tagged commit; never upload
      locally built packages; never link to artifacts that do not exist.
