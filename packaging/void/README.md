# Void Linux packaging (unofficial)

Void is an **unofficial, community-supported** target. Full instructions:
[docs/installation/VOID.md](../../docs/installation/VOID.md).

- `srcpkgs/ssh-shell/template` — an `xbps-src` template. Quickshell 0.3.2 and
  every dependency in the template are in Void's official repositories
  (checked in CI by `package-validation.yml`). JetBrains Mono is not packaged
  for Void and is not required.
- Before the first tagged release the template carries `@COMMIT@` and
  `@CHECKSUM@` placeholders; set `_commit` to a commit of this repository and
  `checksum` to the SHA-256 of its GitHub archive.
- The template has not been built with `xbps-src` by the maintainers.
