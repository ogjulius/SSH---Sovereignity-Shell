# Design philosophy and design system

SSH looks like a well-made instrument: obsidian and graphite surfaces, warm-silver
metal, hairline rules, precise cut corners, numbers set in a monospace. It should
feel calm at rest and exact in motion.

All tokens live in `src/themes/Theme.qml` (derived from config) and
`src/themes/Palettes.js`. Modules never hard-code visual values.

## Colour

Two grounds, both slightly warm so the silver accent reads as metal:

| Token | Obsidian (dark) | Vellum (light) | Use |
|---|---|---|---|
| `void_` | `#0a0a0b` | `#d9d4ca` | backdrops, dims |
| `plate` | `#111113` | `#f6f3ed` | primary surfaces |
| `raised` | `#18181b` | `#fdfcf9` | hover / elevated |
| `sunken` | `#0d0d0f` | `#ebe6dd` | wells, tracks, inputs |
| `line` / `lineStrong` | `#26262b` / `#3a3a41` | `#d8d2c7` / `#bdb5a8` | hairlines |
| `text` / `textDim` / `textFaint` | `#ece8e1` / `#a8a39a` / `#6b6760` | `#1b1a18` / `#57534d` / `#8d877e` | type |
| `positive` / `caution` / `critical` | `#8fb59a` / `#d4b06a` / `#d6766a` | `#3f7a52` / `#8f6a1d` / `#a9443a` | signals |

**Accents** are desaturated and re-tuned per ground: *argent* (default),
*brass*, *ember*, *verdigris*, *cobalt*, *oxblood*, or a custom hex. Ink on an
accent fill is chosen by computed contrast.

**Contrast is tested**, not hoped for: the unit tests assert text/plate ≥ 7:1,
dim text ≥ 4.5:1, faint text ≥ 3:1, and every accent ≥ 3:1 on both grounds.

Accent is used sparingly: the current position, focus, the active state of a
key, the fill of a gauge. Never large fills; never gradients for decoration.

## Typography

| Role | Family | Size (×fontScale) | Notes |
|---|---|---|---|
| `micro` | JetBrains Mono | 9.5 | uppercase, +1.6 tracking: section marks, coordinates |
| `data` | JetBrains Mono | 11 | tabular figures: clocks, values |
| `caption` | Inter | 11 | secondary text |
| `body` | Inter | 12.5 | default |
| `lead` | Inter Medium | 14 | emphasis |
| `title` | Inter SemiBold | 17 | panel titles |
| `heading` | Inter Display SemiBold | 24 | coordinates in the Lens |
| `display` | Inter Display Light | 44 | the clock |

## Space

A 4-point rhythm: `s1`=2, `s2`=4, `s3`=8, `s4`=12, `s5`=16, `s6`=24, `s7`=32, `s8`=48.

## Geometry: two silhouettes, one budget

`appearance.shape` chooses how every surface closes its corners:

| Shape | Reading | Sizes (`cutS` / `cutM` / `cutL`) |
|---|---|---|
| `round` (default) | floating islands, softened edges | 9 / 15 / 23 |
| `cut` | the survey silhouette: top-left and bottom-right corners cut | 4 / 8 / 14 |

Both are scaled by `appearance.chamfer` (0 gives square plates), and both are
drawn by the same `Plate`: call sites pass `Theme.cutS/cutM/cutL` and never
branch. Round plates are plain rectangles — no `QtQuick.Shapes` node, so the
default shape is also the cheaper one to render.

Rounded surfaces may carry a **shine**: a short white gradient along the top
edge (`appearance.shine`), and the Meridian can float as an **island** inset
from the screen edges (`meridian.style`). Hairlines stay 1px in both shapes.

## Depth

No drop shadows by default. Depth comes from ground steps (sunken → plate →
raised), hairline borders, and an optional backdrop dim. Translucency is a
single `appearance.opacity` value applied to plates; blur is delegated to the
compositor (a `layerrule` for `ssh-*` namespaces), so SSH never pays for it.

## Motion

| Token | Duration | Curve | Use |
|---|---|---|---|
| `durMicro` | 110 ms | — | colour/hover |
| `durStd` | 190 ms | enter `(0.16,1,0.3,1)` / exit `(0.7,0,0.84,0)` | surfaces, toggles |
| `durSpatial` | 320 ms | `(0.2,0,0,1)` | map travel, panning |

Every duration is multiplied by `appearance.animationScale`; at 0 SSH does not
animate at all. Motion communicates state: surfaces settle 6–8px into place,
the minimap and traverse toast slide in the direction of travel.

## Iconography

Original line glyphs on a 24-unit grid (`themes/Icons.js`), square caps, mitred
joins, 1.5px visual stroke at any size, rendered via `QtQuick.Shapes` so they
recolour with the theme. Third-party icons (apps, tray) are shown as-is but small.

## Components

| Component | Role |
|---|---|
| `Plate` | rounded island or chamfered plate; the base of every panel, key and card |
| `Ticks` / `Rule` | ruler ticks and hairlines |
| `Label` | typographic roles |
| `Icon`, `IconButton` | glyphs |
| `Pressable` | hover/press/focus behaviour for anything clickable |
| `Key` | quick toggle tile with corner mark |
| `Toggle` | square shuttle switch |
| `InstrumentSlider` | gauge with quarter ticks and a needle |
| `Field` | text entry |
| `ListRow` | list entry (apps, windows, devices, results) |
| `SectionMark` | `01 — TITLE ────` numbered section header |
| `SurfaceWindow` | the single window type for every surface |