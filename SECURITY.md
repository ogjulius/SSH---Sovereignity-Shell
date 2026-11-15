# Security policy

SSH runs continuously inside your desktop session with access to your windows,
notifications, network and audio. We take that seriously.

## Supported versions

Only the latest release (or `main` before the first release) receives fixes.

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Use GitHub's
private vulnerability reporting ("Report a vulnerability" under the Security
tab of the repository). Include steps to reproduce, affected versions and impact.
You can expect an acknowledgement within 7 days.

## Design commitments

- External processes are started with **argv arrays**; no user- or
  network-controlled string is ever interpreted by a shell.
- Hyprland Lua dispatch expressions are built only from integers, validated
  window addresses and escaped string literals.
- Configured commands (`commands.*`) are validated argv lists.
- **No credentials** are embedded; the default weather provider needs none.
  Future providers must read keys from a user-owned file, never from the repo.
- **No telemetry.** The only network request SSH makes is the weather fetch,
  and only after you configure a location.
- Notification text stays in memory unless `notifications.persistHistory` is
  enabled.
- SSH writes only inside `$XDG_CONFIG_HOME/ssh-shell`, `$XDG_STATE_HOME/ssh-shell`
  and theme exports, using atomic writes; it never modifies compositor or
  system configuration.
- Destructive session actions require a second confirmation.
