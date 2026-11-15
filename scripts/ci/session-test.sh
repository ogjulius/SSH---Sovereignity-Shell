#!/usr/bin/env bash
# Tests the INSTALLED "Sovereignity Shell (Niri)" login session the way a
# display manager starts it (`ssh-session niri`), nested in headless sway.
# For disposable CI containers, after ./install.sh; run as a NON-root user.
#
#   scripts/ci/session-test.sh OUTDIR
#
# Checks: the session file exists and the plain niri session is kept; the
# overlay validates; SSH starts by itself exactly once; its binds are written
# and the merged config validates; the user's niri config is untouched; SSH
# is restarted after a crash; quitting niri ends the session and SSH.
set -uo pipefail
OUT=${1:-session-out}; mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$(id -u)}
mkdir -p -m 700 "$XDG_RUNTIME_DIR"
export LIBGL_ALWAYS_SOFTWARE=1 LANG=C.UTF-8 LC_ALL=C.UTF-8
STATE=${XDG_STATE_HOME:-$HOME/.local/state}/ssh-shell
PASS=0; FAIL=0
check() { local n=$1; shift; if "$@" >>"$OUT/checks.log" 2>&1; then PASS=$((PASS+1)); echo "PASS  $n"; else FAIL=$((FAIL+1)); echo "FAIL  $n"; fi; }
qs_count() { pgrep -fc "^qs -n -p /usr/share/ssh-shell" || true; }
trap 'pkill -P $$ 2>/dev/null; sleep 0.5; pkill -9 -P $$ 2>/dev/null; true' EXIT

check "session file installed"           test -f /usr/share/wayland-sessions/ssh-niri.desktop
check "session Exec is ssh-session niri"  grep -qx 'Exec=/usr/bin/ssh-session niri' /usr/share/wayland-sessions/ssh-niri.desktop
check "plain niri session kept"           test -f /usr/share/wayland-sessions/niri.desktop
check "ssh-session --check niri"          ssh-session --check niri

# The user's own niri config: binds Mod+Space itself (SSH's Lens default).
mkdir -p "$HOME/.config/niri"
cat > "$HOME/.config/niri/config.kdl" <<'EOF'
hotkey-overlay { skip-at-startup; }
prefer-no-csd
binds {
    Mod+Space { spawn "true"; }
    Mod+Shift+E { quit; }
}
EOF
before=$(sha256sum "$HOME/.config/niri/config.kdl")

printf 'output HEADLESS-1 resolution 1920x1080\n' > "$OUT/sway.conf"
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -c "$OUT/sway.conf" >"$OUT/sway.log" 2>&1 &
for _ in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/wayland-1" ] && break; sleep 0.2; done
[ -S "$XDG_RUNTIME_DIR/wayland-1" ] || { echo "headless sway did not start"; tail -20 "$OUT/sway.log"; exit 1; }

# What the display manager runs (Exec= of the session file):
WAYLAND_DISPLAY=wayland-1 dbus-run-session -- ssh-session niri >"$OUT/session.out" 2>&1 &
SESSION_PID=$!
for _ in $(seq 150); do NIRI_SOCKET=$(ls "$XDG_RUNTIME_DIR"/niri.*.sock 2>/dev/null | head -1); [ -n "$NIRI_SOCKET" ] && break; sleep 0.2; done
export NIRI_SOCKET
check "niri started from the session"    test -n "$NIRI_SOCKET"
for _ in $(seq 150); do ssh-shell status 2>/dev/null | grep -q '"compositor":"niri"' && break; sleep 0.2; done
ssh-shell status > "$OUT/status.json" 2>&1
check "SSH started by itself"            grep -q '"compositor":"niri"' "$OUT/status.json"
check "SSH connected to niri IPC"        grep -q '"connected":true' "$OUT/status.json"
sleep 2
check "exactly one SSH instance"         test "$(qs_count)" = 1
check "overlay passes niri validate"     niri validate -c "$STATE/session/niri.kdl"
check "SSH wrote its session binds"      grep -q 'spawn "ssh-shell" "lens" "toggle"' "$STATE/session/niri-binds.kdl"
check "merged config (with binds) valid" niri validate -c "$STATE/session/niri.kdl"
check "user's niri config untouched"     test "$(sha256sum "$HOME/.config/niri/config.kdl")" = "$before"
check "a second start is refused"        sh -c 'timeout 15 ssh-shell 2>&1 | grep -q "already running"'
check "still exactly one SSH instance"   test "$(qs_count)" = 1

pkill -9 -f "^qs -n -p /usr/share/ssh-shell"
for _ in $(seq 40); do [ "$(qs_count)" = 1 ] && break; sleep 0.25; done
check "SSH restarted after a crash"      test "$(qs_count)" = 1
check "crash recorded in shell.log"      grep -q "exited with status" "$STATE/shell.log"

niri msg action quit --skip-confirmation >/dev/null 2>&1
for _ in $(seq 40); do kill -0 $SESSION_PID 2>/dev/null || break; sleep 0.25; done
check "quitting niri ends the session"   sh -c "! kill -0 $SESSION_PID 2>/dev/null"
sleep 1
check "SSH stopped with the session"     test "$(qs_count)" = 0

cp -r "$STATE" "$OUT/state" 2>/dev/null
echo "── installed niri session: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
