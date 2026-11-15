#!/usr/bin/env bash
# Runtime test of SSH inside a real, nested compositor session.
#
#   scripts/ci/runtime-test.sh hyprland|niri OUTDIR
#
# For disposable CI containers; run as a NON-root user (Hyprland refuses root).
#   headless sway (pixman)  →  nested Hyprland or Niri (software GL)
#   →  SSH on a private D-Bus session, driven over IPC.
# Assertions are checked with the compositor's own CLI (hyprctl / niri msg),
# not with SSH's opinion of itself. Screenshots are taken with grim.
set -uo pipefail
REPO=$(cd "$(dirname "$0")/../.." && pwd)
SELF="$REPO/scripts/ci/runtime-test.sh"

# ── Helpers shared by both phases ────────────────────────────────────
focused_ws() {
    if [ "$COMP" = niri ]; then
        niri msg -j workspaces | python3 -c 'import json,sys;print([w.get("name") or w["idx"] for w in json.load(sys.stdin) if w["is_focused"]][0])'
    else
        hyprctl activeworkspace -j | python3 -c 'import json,sys;print(json.load(sys.stdin)["id"])'
    fi
}
probe_ws() { # workspace of the window with app-id/class "ssh-probe"
    if [ "$COMP" = niri ]; then
        python3 - <<'PY'
import json, subprocess
ws = {w["id"]: (w.get("name") or w["idx"]) for w in json.loads(subprocess.check_output(["niri", "msg", "-j", "workspaces"]))}
print(" ".join(str(ws.get(w["workspace_id"])) for w in json.loads(subprocess.check_output(["niri", "msg", "-j", "windows"])) if w.get("app_id") == "ssh-probe"))
PY
    else
        hyprctl clients -j | python3 -c 'import json,sys;print(" ".join(str(c["workspace"]["id"]) for c in json.load(sys.stdin) if c["class"]=="ssh-probe"))'
    fi
}

# ── Phase 2: inside the private D-Bus session ────────────────────────
if [ "${1:-}" = "--inside" ]; then
    COMP=$2; OUT=$3
    QS=(qs -p "$REPO/src")
    PASS=0; FAIL=0
    check() {
        local name=$1; shift
        if "$@" >>"$OUT/checks.log" 2>&1; then PASS=$((PASS+1)); echo "PASS  $name"
        else FAIL=$((FAIL+1)); echo "FAIL  $name"; fi
    }
    st() { "${QS[@]}" ipc call shell status; }
    j()  { st | python3 -c "import json,sys;d=json.load(sys.stdin);print($1)"; }
    ipc() { "${QS[@]}" ipc call "$@"; }

    "${QS[@]}" >"$OUT/ssh.log" 2>&1 &
    for _ in $(seq 150); do st >/dev/null 2>&1 && break; sleep 0.2; done
    st > "$OUT/status-initial.json" 2>/dev/null
    check "SSH starts and answers IPC"       test -s "$OUT/status-initial.json"
    check "compositor detected as $COMP"     test "$(j 'd["compositor"]')" = "$COMP"
    check "compositor IPC connected"         test "$(j 'd["connected"]')" = "True"
    check "workspaces reported (>=1)"        test "$(j 'd["workspaces"]')" -ge 1
    sleep 1; grim "$OUT/desktop-$COMP.png"

    for s in lens atlas launcher instruments almanac signals power; do
        ipc shell open "$s"; sleep 1.5
        check "surface opens: $s"             test "$(j 'd["surface"]')" = "$s"
        grim "$OUT/$s-$COMP.png"
        ipc panel close; sleep 0.8
    done
    sleep 2
    check "surfaces released after closing" test "$(j 'len(d["loaded"])')" = "0"

    before=$(focused_ws)
    ipc atlas traverse right; sleep 1.5
    after=$(focused_ws)
    echo "traverse: focused workspace $before -> $after" >>"$OUT/checks.log"
    check "traverse right switches the compositor's workspace" test "$before" != "$after"
    check "Atlas cursor reports B1"         test "$(ipc atlas where)" = "Main B1"
    ipc atlas traverse left; sleep 1.5
    check "traverse left returns"           test "$(focused_ws)" = "$before"

    foot --app-id ssh-probe --title ssh-probe sh -c 'sleep 90' >/dev/null 2>&1 &
    for _ in $(seq 75); do [ -n "$(probe_ws)" ] && break; sleep 0.2; done
    w0=$(probe_ws)
    check "probe window opened"             test -n "$w0"
    sleep 1
    ipc atlas carry right; sleep 2
    w1=$(probe_ws)
    echo "carry: probe window workspace $w0 -> $w1, focused $(focused_ws)" >>"$OUT/checks.log"
    check "carry moves the focused window"  test -n "$w1" -a "$w0" != "$w1"
    grim "$OUT/after-carry-$COMP.png"

    notify-send -a CI "Runtime test" "Sent by scripts/ci/runtime-test.sh"; sleep 1.2
    check "notification daemon serving"     test "$(j 'd["notifications"]["serving"]')" = "True"
    check "notification recorded"           test "$(j 'd["notifications"]["history"]')" -ge 1
    grim "$OUT/notification-$COMP.png"

    st > "$OUT/status-final.json" 2>/dev/null
    "${QS[@]}" kill >/dev/null 2>&1
    echo "$PASS $FAIL" > "$OUT/counts"
    exit 0
fi

# ── Phase 1: compositors ─────────────────────────────────────────────
COMP=$1; OUT=${2:-runtime-out}
mkdir -p "$OUT"; OUT=$(cd "$OUT" && pwd)
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-$(id -u)}
mkdir -p -m 700 "$XDG_RUNTIME_DIR"
export LIBGL_ALWAYS_SOFTWARE=1
trap 'pkill -P $$ 2>/dev/null; sleep 0.5; pkill -9 -P $$ 2>/dev/null; true' EXIT

printf 'output HEADLESS-1 resolution 1920x1080\ndefault_border none\n' > "$OUT/sway.conf"
WLR_BACKENDS=headless WLR_RENDERER=pixman WLR_LIBINPUT_NO_DEVICES=1 sway -c "$OUT/sway.conf" >"$OUT/sway.log" 2>&1 &
for _ in $(seq 50); do [ -S "$XDG_RUNTIME_DIR/wayland-1" ] && break; sleep 0.2; done
[ -S "$XDG_RUNTIME_DIR/wayland-1" ] || { echo "headless sway did not start"; tail -20 "$OUT/sway.log"; exit 1; }
HOST=wayland-1

if [ "$COMP" = niri ]; then
    printf 'hotkey-overlay { skip-at-startup; }\nprefer-no-csd\n' > "$OUT/niri.kdl"
    WAYLAND_DISPLAY=$HOST niri -c "$OUT/niri.kdl" >"$OUT/compositor.log" 2>&1 &
    for _ in $(seq 150); do NIRI_SOCKET=$(ls "$XDG_RUNTIME_DIR"/niri.*.sock 2>/dev/null | head -1); [ -n "$NIRI_SOCKET" ] && break; sleep 0.2; done
    [ -n "${NIRI_SOCKET:-}" ] || { echo "niri did not start"; tail -40 "$OUT/compositor.log"; exit 1; }
    export NIRI_SOCKET
    niri msg version >"$OUT/compositor-version.txt" 2>&1
elif [ "$COMP" = hyprland ]; then
    printf 'monitor = , 1920x1080@60, 0x0, 1\nmisc {\n    disable_hyprland_logo = true\n    disable_splash_rendering = true\n}\n' > "$OUT/hyprland.conf"
    WAYLAND_DISPLAY=$HOST Hyprland -c "$OUT/hyprland.conf" >"$OUT/compositor.log" 2>&1 &
    for _ in $(seq 150); do sig=$(ls "$XDG_RUNTIME_DIR/hypr" 2>/dev/null | head -1); [ -n "$sig" ] && [ -S "$XDG_RUNTIME_DIR/hypr/$sig/.socket.sock" ] && break; sleep 0.2; done
    [ -n "${sig:-}" ] || { echo "Hyprland did not start"; tail -40 "$OUT/compositor.log"; exit 1; }
    export HYPRLAND_INSTANCE_SIGNATURE=$sig
    hyprctl version >"$OUT/compositor-version.txt" 2>&1
else
    echo "usage: $0 hyprland|niri OUTDIR"; exit 2
fi
sleep 3
NESTED=$(ls -t "$XDG_RUNTIME_DIR" | grep -E '^wayland-[0-9]+$' | grep -vx "$HOST" | head -1)
[ -n "$NESTED" ] || { echo "nested compositor exposed no Wayland socket"; exit 1; }
export WAYLAND_DISPLAY=$NESTED
echo "host=$HOST nested=$NESTED compositor=$COMP ($(head -1 "$OUT/compositor-version.txt"))"

# Isolated SSH config/state for the run.
export SSH_SHELL_CONFIG="$OUT/config.json" XDG_STATE_HOME="$OUT/state" XDG_CONFIG_HOME="$OUT/config-home"
dbus-run-session -- "$SELF" --inside "$COMP" "$OUT"
read -r PASS FAIL < "$OUT/counts" 2>/dev/null || { PASS=0; FAIL=1; }

qmlerr=$(sed 's/\x1b\[[0-9;]*m//g' "$OUT/ssh.log" 2>/dev/null | grep -E "TypeError|ReferenceError|is not defined|Cannot read property|Failed to load configuration" | sort -u)
if [ -n "$qmlerr" ]; then echo "FAIL  no QML errors in SSH log"; echo "$qmlerr"; FAIL=$((FAIL+1)); else echo "PASS  no QML errors in SSH log"; PASS=$((PASS+1)); fi
sed 's/\x1b\[[0-9;]*m//g' "$OUT/ssh.log" 2>/dev/null | grep -iE "dispatch|niri msg|niri:" | sort -u | head -30 > "$OUT/backend-warnings.txt"
[ -s "$OUT/backend-warnings.txt" ] && { echo "backend warnings:"; cat "$OUT/backend-warnings.txt"; }

echo "── $COMP runtime: $PASS passed, $FAIL failed"
echo "$COMP $PASS $FAIL $(head -1 "$OUT/compositor-version.txt" 2>/dev/null)" > "$OUT/summary.txt"
[ "$FAIL" -eq 0 ]
