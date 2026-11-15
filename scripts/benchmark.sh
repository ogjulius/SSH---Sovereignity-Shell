#!/usr/bin/env bash
# SSH benchmark: RSS, peak RSS, idle CPU, startup latency and growth under
# repeated surface open/close. Requires a running Wayland session with
# Hyprland or Niri. Results go to bench-results/<timestamp>.md.
#
#   scripts/benchmark.sh [--cycles N] [--idle SECONDS] [--note "conditions"]
#
# Notes
# - Notifications are disabled during the run (SSH_SHELL_NO_NOTIFICATIONS=1)
#   so the benchmark never fights an existing notification daemon.
# - Session lock state cannot be detected reliably (many lockers do not set
#   logind's LockedHint). Record run conditions with --note.
set -euo pipefail
cd "$(dirname "$0")/.."
CYCLES=20; IDLE=20; NOTE=""
while [ $# -gt 0 ]; do case $1 in --cycles) CYCLES=$2; shift 2;; --idle) IDLE=$2; shift 2;; --note) NOTE=$2; shift 2;; *) echo "unknown arg $1"; exit 2;; esac; done

[ -n "${WAYLAND_DISPLAY:-}" ] || { echo "needs a Wayland session"; exit 1; }
CLK=$(getconf CLK_TCK)
mkdir -p bench-results
OUT="bench-results/$(date +%Y%m%d-%H%M%S).md"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"; pkill -P $$ 2>/dev/null || true' EXIT

rss()  { awk '/^VmRSS/{print $2}' "/proc/$1/status"; }
hwm()  { awk '/^VmHWM/{print $2}' "/proc/$1/status"; }
pss()  { awk '/^Pss:/{print $2}' "/proc/$1/smaps_rollup" 2>/dev/null || echo 0; }
ticks(){ awk '{print $14+$15}' "/proc/$1/stat"; }
mb()   { awk -v k="$1" 'BEGIN{printf "%.1f", k/1024}'; }
pidof_qs() { # newest qs whose cmdline contains $1
    pgrep -n -f -- "qs .*$1" ; }


# ── Baseline ──────────────────────────────────────────────────────────
qs -p scripts/bench/baseline >/dev/null 2>&1 &
sleep 4
bp=$(pidof_qs scripts/bench/baseline); b_rss=$(rss "$bp"); b_pss=$(pss "$bp")
kill "$bp"; sleep 0.5

# ── SSH startup ───────────────────────────────────────────────────────
export SSH_SHELL_NO_NOTIFICATIONS=1
export SSH_SHELL_CONFIG="$tmp/config.json"   # defaults; never touches the user's file
t0=$(date +%s%N)
qs -n -p src >"$tmp/ssh.log" 2>&1 &
until qs -p src ipc call shell status >/dev/null 2>&1; do sleep 0.05; done
t1=$(date +%s%N)
startup_ms=$(( (t1 - t0) / 1000000 ))
pid=$(pidof_qs "-p src")
sleep 6
idle_rss=$(rss "$pid"); idle_pss=$(pss "$pid")

# ── Idle CPU ──────────────────────────────────────────────────────────
c0=$(ticks "$pid"); sleep "$IDLE"; c1=$(ticks "$pid")
idle_cpu=$(awk -v d=$((c1-c0)) -v s="$IDLE" -v k="$CLK" 'BEGIN{printf "%.2f", 100*d/k/s}')

# ── Per-surface cost (open → settle → measure → close → release) ──────
declare -A open_rss
for s in lens atlas launcher instruments almanac signals power; do
    qs -p src ipc call shell open "$s" >/dev/null; sleep 2
    open_rss[$s]=$(rss "$pid")
    qs -p src ipc call panel close >/dev/null; sleep 1.2
done
after_tour=$(rss "$pid")

# ── Repeated open/close ───────────────────────────────────────────────
pre_cycles=$(rss "$pid")
for i in $(seq 1 "$CYCLES"); do
    for s in lens atlas launcher; do
        qs -p src ipc call shell open "$s" >/dev/null; sleep 0.35
        qs -p src ipc call panel close >/dev/null; sleep 0.35
    done
done
sleep 3
post_cycles=$(rss "$pid"); peak=$(hwm "$pid")
loaded=$(qs -p src ipc call shell status | sed -n 's/.*"loaded":\(\[[^]]*\]\).*/\1/p')
kill "$pid"

{
echo "# SSH benchmark — $(date -Iseconds)"
echo
echo "| | |"; echo "|---|---|"
echo "| Host | $(uname -r), $(nproc) CPUs, $(awk '/MemTotal/{printf "%.1f GiB", $2/1048576}' /proc/meminfo) |"
echo "| Quickshell | $(qs --version | head -1) |"
echo "| Qt | $(pacman -Q qt6-base 2>/dev/null | cut -d' ' -f2 || echo unknown) |"
echo "| Compositor | ${XDG_CURRENT_DESKTOP:-unknown} |"
echo "| Notes | ${NOTE:-—} |"
echo
echo "| Measurement | Value |"; echo "|---|---|"
echo "| Baseline Quickshell (one bar), RSS / PSS | $(mb "$b_rss") MiB / $(mb "$b_pss") MiB |"
echo "| SSH startup to first IPC reply | ${startup_ms} ms |"
echo "| SSH idle RSS / PSS | $(mb "$idle_rss") MiB / $(mb "$idle_pss") MiB |"
echo "| SSH idle CPU (avg over ${IDLE}s) | ${idle_cpu} % of one core |"
for s in lens atlas launcher instruments almanac signals power; do
    echo "| RSS with $s open | $(mb "${open_rss[$s]}") MiB (+$(mb $(( ${open_rss[$s]} - idle_rss ))) ) |"
done
echo "| RSS after closing all surfaces | $(mb "$after_tour") MiB |"
echo "| RSS before / after ${CYCLES}× (lens, atlas, launcher) cycles | $(mb "$pre_cycles") → $(mb "$post_cycles") MiB |"
echo "| Peak RSS (VmHWM) | $(mb "$peak") MiB |"
echo "| Surfaces still instantiated after closing | ${loaded:-[]} |"
} | tee "$OUT"
echo; echo "saved $OUT"
