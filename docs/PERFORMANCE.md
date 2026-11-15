# Performance

All numbers on this page were **measured**, with `scripts/benchmark.sh` and the
ad-hoc experiments described below. Reproduce them on your machine and please
report results (with the generated `bench-results/*.md`).

## Test machine

| | |
|---|---|
| Kernel / distro | 7.3.4-arch1-1, Arch Linux |
| CPU / RAM | 8 threads, 15.3 GiB |
| GPU stack | NVIDIA proprietary GL (large shared GL libraries count toward RSS) |
| Compositor | Hyprland 0.57.2 (Lua config), one 1920×1080 output |
| Quickshell / Qt | 0.3.2 / 6.12.0 (Quickshell links jemalloc) |
| Conditions | session locked during runs, notifications disabled, default config |

## Results (2026-11-15)

| Measurement | Value |
|---|---|
| **Baseline:** minimal Quickshell config (one bar, one text) | **198 MiB RSS / 97 MiB PSS** |
| SSH idle | **236 MiB RSS / 127 MiB PSS** (+38 MiB RSS over baseline) |
| SSH idle CPU, active terminal retitling windows (2 × 30 s) | **0.00–0.03 %** of one core |
| Startup to first IPC reply | **≈ 0.4 s** (359–410 ms over 3 runs) |
| First surface opened (any) | +87 … +101 MiB |
| After all surfaces closed | ≈ 314–322 MiB; surfaces destroyed (`loaded: []`) |
| Peak RSS (whole benchmark) | 369–375 MiB |

### Per-surface first-open cost (each in a fresh process)

| Surface | First open | After 30 open/close cycles |
|---|---|---|
| Power menu (no app icons) | +17 MiB | flat |
| Launcher | +56 MiB | flat |
| Lens | +67 MiB | flat |
| Atlas | +68 MiB | flat |

A trivial full-screen Quickshell overlay with no SSH code costs **+15 MiB** on
first open and stays flat for 40 cycles: that is the fixed price of a second
layer surface (buffers, render context). The launcher costs **+27 MiB without
app icons** and +56 MiB with 8 icons: about **29 MiB is Qt's icon-theme loader
and SVG icon engine**, loaded once on the first themed icon and shared by every
surface afterwards.

### Repeated open/close (lens → atlas → launcher, alternating)

| | 1 | 20 | 40 | 60 | 80 cycles |
|---|---|---|---|---|---|
| Before deferred GC | 306 | 331 | 365 | 364 | 356 MiB |
| **With deferred GC** (shipped) | 321 | 327 | 325 | 327 | — MiB |

Without intervention RSS plateaued about 130 MiB over idle because V4 only
collects under allocation pressure, so destroyed surfaces' JS objects lingered.
SSH now runs one `gc()` 1.5 s after the last surface is released, which keeps
the steady state flat. No unbounded growth (leak) was observed in any test.

## The memory targets

The founding brief set aspirational targets of **100–150 MiB idle** and
**150–250 MiB in normal use** (RSS). On this machine **Quickshell itself, with
one bar, already uses 198 MiB RSS**, so the RSS targets are not reachable by
any Quickshell shell here, and SSH does not meet them. What SSH controls is its
overhead above that baseline:

- **+38 MiB RSS idle** (+30 MiB PSS) for the full resident shell (bar on every
  output, all system services connected).
- Normal use with surfaces opened at least once settles around **+90 MiB** over
  idle, most of which is the shared icon theme and layer-surface buffers.

RSS overstates memory on NVIDIA because the large proprietary GL libraries are
counted in full; **PSS** (shared pages divided among users) is the fairer
number: 97 MiB baseline, 127 MiB SSH idle. Expect lower absolute numbers on
Mesa drivers (not yet measured).

## What keeps SSH cheap

- Only the Meridian is resident; every surface is created on open and destroyed
  after its exit animation, followed by a deferred GC.
- No polling while idle: compositor, audio, network, Bluetooth, battery and
  MPRIS are event-driven. Brightness is read once and after changes.
- `/proc` sampling (CPU, memory, temperature) and weather fetching run only while
  the Almanac is open (demand counters).
- Hyprland title events coalesce over 400 ms with no IPC round-trip.
- Atlas canvas uses a fixed pool of recycled cell delegates; window previews are
  single captures (not live), only around the selection, within a budget.
- Images decode at display size; artwork and notification images are bounded.

## How to measure

```sh
scripts/benchmark.sh --cycles 20 --idle 30 --note "describe your conditions"
```

The script measures a minimal Quickshell baseline first, then SSH with an
isolated temporary config (your config is never read or written), and saves a
Markdown report to `bench-results/`. It disables SSH's notification daemon so it
never competes with yours.

## Not yet measured

- Mesa (AMD/Intel) GPUs; multi-monitor setups; HiDPI scales.
- Niri.
- Long-running sessions (multi-day). The repeated-cycle tests show no leak, but a
  multi-day soak test has not been run.
- Interaction latency (input-to-frame) of surfaces.
