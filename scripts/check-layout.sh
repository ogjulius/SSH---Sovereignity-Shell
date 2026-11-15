#!/usr/bin/env bash
# Installation-layout check: `make install` into a staging root, verify the
# tree, permissions and contents, then `make uninstall` and verify nothing is
# left behind.  Usage: scripts/check-layout.sh [PREFIX]
set -euo pipefail
cd "$(dirname "$0")/.."
PREFIX=${1:-/usr}
root=$(mktemp -d); trap 'rm -rf "$root"' EXIT
fail=0; bad() { echo "FAIL  $*"; fail=1; }; ok() { echo "PASS  $*"; }

make -s install DESTDIR="$root" PREFIX="$PREFIX" >/dev/null
P="$root$PREFIX"
[ -x "$P/bin/ssh-shell" ] && ok "ssh-shell installed and executable" || bad "ssh-shell missing or not executable"
[ -f "$P/share/ssh-shell/shell.qml" ] && ok "QML entry point installed" || bad "shell.qml missing"
[ -f "$P/share/licenses/ssh-shell/LICENSE" ] && ok "license installed" || bad "license missing"
[ -f "$P/share/icons/hicolor/scalable/apps/ssh-shell.svg" ] && ok "scalable icon installed" || bad "icon missing"
[ -f "$P/share/doc/ssh-shell/README.md" ] && ok "docs installed" || bad "docs missing"
[ -x "$P/bin/ssh-session" ] && ok "ssh-session installed and executable" || bad "ssh-session missing"
for s in hyprland niri; do
    f="$P/share/wayland-sessions/ssh-$s.desktop"
    if [ -f "$f" ] && grep -q "^Exec=$PREFIX/bin/ssh-session $s$" "$f"; then ok "login session ssh-$s.desktop (Exec=$PREFIX/bin/ssh-session $s)"
    else bad "login session ssh-$s.desktop missing or wrong Exec"; fi
    if command -v desktop-file-validate >/dev/null 2>&1; then
        # DesktopNames is the session-file key display managers read (the
        # compositors' own session files use it too); it is not in the
        # desktop-entry spec, so that one complaint is expected.
        v=$(desktop-file-validate "$f" 2>&1 | grep -v 'key "DesktopNames"' || true)
        [ -z "$v" ] && ok "ssh-$s.desktop passes desktop-file-validate" || bad "ssh-$s.desktop: $v"
    fi
done
[ -f "$P/share/bash-completion/completions/ssh-shell" ] && [ -f "$P/share/fish/vendor_completions.d/ssh-shell.fish" ] \
    && [ -f "$P/share/zsh/site-functions/_ssh-shell" ] && ok "bash, fish and zsh completions installed" || bad "completions missing"
[ -f "$P/share/ssh-shell/check-config.qml" ] && ok "configuration checker installed" || bad "check-config.qml missing"

# Every runtime QML/JS/JSON file in src/ (except dev harnesses) must be installed.
missing=$(cd src && find . -type f \( -name '*.qml' -o -name '*.js' -o -name '*.json' \) ! -name 'dev-*' | while read -r f; do [ -f "$P/share/ssh-shell/$f" ] || echo "$f"; done)
[ -z "$missing" ] && ok "all $(cd src && find . -type f \( -name '*.qml' -o -name '*.js' -o -name '*.json' \) ! -name 'dev-*' | wc -l) runtime source files installed" || bad "not installed: $missing"
[ -z "$(find "$P/share/ssh-shell" -name 'dev-*')" ] && ok "development harnesses excluded" || bad "dev-* files were installed"

# Permissions: no world-writable files, data files 0644, wrapper 0755.
[ -z "$(find "$root" -perm -0002 -type f)" ] && ok "no world-writable files" || bad "world-writable files present"
[ -z "$(find "$P/share/ssh-shell" -type f ! -perm 0644)" ] && ok "data files are 0644" || bad "data files with unexpected modes"
[ "$(stat -c %a "$P/bin/ssh-shell")" = 755 ] && ok "wrapper is 0755" || bad "wrapper mode $(stat -c %a "$P/bin/ssh-shell")"
[ "$(stat -c %a "$P/bin/ssh-session")" = 755 ] && ok "session launcher is 0755" || bad "ssh-session mode $(stat -c %a "$P/bin/ssh-session")"

# The installed wrapper must resolve the installed tree, not a checkout.
grep -q "^here=$PREFIX/bin" "$P/bin/ssh-shell" && ok "wrapper points at $PREFIX/bin" || bad "wrapper prefix not rewritten"

# Nothing outside PREFIX.
outside=$(cd "$root" && find . -type f | grep -v "^\.$PREFIX/" || true)
[ -z "$outside" ] && ok "nothing installed outside $PREFIX" || bad "files outside prefix: $outside"

make -s uninstall DESTDIR="$root" PREFIX="$PREFIX" >/dev/null
left=$(find "$root" -type f | sed "s|$root||")
[ -z "$left" ] && ok "uninstall removes every installed file" || bad "left after uninstall: $left"

[ $fail -eq 0 ] && echo "── layout OK" || echo "── layout FAILED"
exit $fail
