#!/usr/bin/env bash
# End-to-end test of ./install.sh in a disposable container, as a normal user
# with passwordless sudo:
#   install (Niri, standard profile) → verify files, sessions, config →
#   reinstall (settings kept) → live session test → uninstall → verify.
#   scripts/ci/installer-e2e.sh OUTDIR [session]   ("session" runs the live test)
set -uo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd)
OUT=${1:-e2e-out}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
LIVE=${2:-}
PASS=0; FAIL=0
check() { local n=$1; shift; if "$@" >>"$OUT/checks.log" 2>&1; then PASS=$((PASS+1)); echo "PASS  $n"; else FAIL=$((FAIL+1)); echo "FAIL  $n"; fi; }
CFG=$HOME/.config/ssh-shell/config.json
cd "$REPO"

echo "── install"
./install.sh --yes --plain --compositor=niri --profile=standard --terminal=foot --theme=ember-night 2>&1 | tee "$OUT/install.log"
rc=${PIPESTATUS[0]}
check "installer exits 0"                 test "$rc" = 0
check "installer shows completion"        grep -q "INSTALLATION COMPLETE" "$OUT/install.log"
check "installer never rebooted"          grep -q "unattended mode never reboots" "$OUT/install.log"
check "ssh-shell installed"               test -x /usr/bin/ssh-shell
check "ssh-session installed"             test -x /usr/bin/ssh-session
check "niri session installed"            test -f /usr/share/wayland-sessions/ssh-niri.desktop
check "plain niri session still present"  test -f /usr/share/wayland-sessions/niri.desktop
check "niri installed by the installer"   command -v niri
check "foot installed by the installer"   command -v foot
check "config written"                    test -f "$CFG"
check "config has chosen theme"           grep -q '"accent": "ember"' "$CFG"
check "config has chosen terminal"        grep -q '"terminal": \["foot"\]' "$CFG"
check "config valid (SSH schema)"         ssh-shell check-config "$CFG"
check "doctor passes"                     ssh-shell doctor
check "installer state recorded"          test -f "$HOME/.local/state/ssh-shell/installer.state"
check "log written"                       sh -c 'ls "$HOME"/.local/state/ssh-shell/install-*.log'
check "login shell unchanged"             test "$(getent passwd "$(id -un)" | cut -d: -f7)" = "${EXPECT_SHELL:-/bin/bash}"

echo "── reinstall (settings must be kept)"
echo '{ "appearance": { "accent": "cobalt" } }' > "$CFG"
./install.sh --yes --plain --compositor=niri --profile=minimal --terminal=foot > "$OUT/reinstall.log" 2>&1
check "reinstall exits 0"                 test $? = 0
check "existing settings kept"            grep -q cobalt "$CFG"

if [ "$LIVE" = session ]; then
    echo "── live session"
    # Unprivileged containers cannot exec binaries with file capabilities.
    for b in /usr/bin/sway /usr/bin/niri; do sudo setcap -r "$b" 2>/dev/null || true; done
    "$REPO/scripts/ci/session-test.sh" "$OUT/session"
    check "installed niri session test"   test $? = 0
fi

echo "── uninstall"
./install.sh --uninstall --yes --plain > "$OUT/uninstall.log" 2>&1
check "uninstall exits 0"                 test $? = 0
check "ssh-shell removed"                 test ! -e /usr/bin/ssh-shell
check "ssh-session removed"               test ! -e /usr/bin/ssh-session
check "SSH sessions removed"              test ! -e /usr/share/wayland-sessions/ssh-niri.desktop
check "QML tree removed"                  test ! -e /usr/share/ssh-shell
check "plain niri session kept"           test -f /usr/share/wayland-sessions/niri.desktop
check "dependencies kept (niri)"          command -v niri
check "settings kept by default"          test -f "$CFG"

echo "── installer e2e: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
