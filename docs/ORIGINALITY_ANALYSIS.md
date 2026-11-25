# Originality analysis

This document records how SSH's direction was chosen and where it deliberately
departs from the existing Quickshell ecosystem.

## Method and its limits

- **Verified sources.** Quickshell's real API surface was read from the installed
  0.3.2 type information (`/usr/lib/qt6/qml/Quickshell/**.qmltypes`); Hyprland
  dispatch behaviour from its shipped Lua stubs, default config and live,
  reversible experiments (see `COMPOSITOR_SUPPORT.md`); Niri's IPC from its
  documented JSON protocol.
- **Ecosystem projects** (Noctalia, Caelestia, DankMaterialShell, end-4's dots
  and similar) were considered from their public presentation and general
  familiarity, **not from a source audit**. No code from any of them is used.
  The developer's own local Quickshell configuration was intentionally not read
  so it could not influence the design.

## Recurring patterns in the ecosystem

| Pattern | Typical form | SSH's position |
|---|---|---|
| Bar | Floating, fully rounded pill or islands | Island by default, but carrying a coordinate readout and row stops; a flush ruler-tick strip stays available (`meridian.style`) |
| Workspaces | Numbered dots / pills, 1–10 | Cells on an unbounded 2D map in named collections; numbers survive as row 1 |
| Dashboard | Grid of rounded cards | Compass layout around *where you are* (Lens); ledger-style Almanac |
| Shape language | Large uniform corner radius, Material You tones | Moderate radii or chamfers (`appearance.shape`), hairlines, warm metal accents, no wallpaper-derived tones |
| Launcher | Separate fuzzy list | Also present, but the Lens intent line unifies apps, windows, places and commands |
| Colour | Wallpaper-extracted palettes, saturated accents | Fixed, contrast-tested grounds (Obsidian/Vellum) with desaturated accents |

## Three concepts explored

### A. "Strata" — depth as navigation
Surfaces stack on the z-axis; opening the overview pushes windows back and
reveals layers (session, workspace, window).
- **+** Striking, novel motion.
- **−** Needs live scaled window textures to sell the depth: expensive in RAM and
  GPU, fragile across compositors. Depth is hard to navigate by keyboard.
- **Verdict:** rejected on performance and keyboard usability.

### B. "Meridian" — the precision instrument
One horizontal instrument line; everything unfolds from it like a ruler —
gauges, ticks, numeric readouts, monospace data.
- **+** Very recognisable, cheap to render, excellent for data-dense controls.
- **−** On its own it is a styling, not an interaction model; workspaces remain a list.
- **Verdict:** adopted as the **visual language**, not the whole concept.

### C. "Atlas" — cartographic sovereignty
The desktop as a map: workspaces are cells with coordinates, grouped into
collections; the shell always tells you where you are and what is nearby.
- **+** Gives the Infinite Desktop a coherent model; makes navigation spatial and
  memorable; extends naturally to an overview (Atlas) and a contextual hub (Lens).
- **−** Compositors have no native 2D canvas; SSH must keep the map itself and be
  honest about it.
- **Verdict:** adopted as the **interaction model**.

### Evaluation

Scored 1–5 against the founding criteria (higher is better):

| Criterion | A Strata | B Meridian | C Atlas | **B + C** |
|---|---|---|---|---|
| Originality | 4 | 3 | 5 | **5** |
| Usability | 2 | 4 | 4 | **5** |
| Visual quality | 5 | 4 | 3 | **5** |
| Feasibility | 2 | 5 | 4 | **4** |
| Performance | 1 | 5 | 4 | **4** |
| Accessibility | 2 | 4 | 4 | **4** |
| Extensibility | 3 | 3 | 5 | **5** |

**Chosen direction: Atlas interaction model rendered in the Meridian language.**

## Originality checks applied during implementation

- Shape is a choice, not a fashion: `appearance.shape` switches every surface
  between rounded islands (default, since v0.1.0-alpha) and the chamfered
  survey silhouette. The rounded reading brings SSH closer to the ecosystem
  norm on purpose; what stays SSH's own is the coordinate readout, the map row,
  the compass dashboard and the hand-tuned grounds.
- No icon font: SSH ships its own 24-unit line glyph set (`themes/Icons.js`).
- No wallpaper-derived Material palette: grounds and accents are hand-tuned and
  contrast-tested in CI (`dev-tests.qml`, palette suite).
- Workspace indicator is a *map row* plus minimap, not dots.
- The dashboard is a compass around the user's position, not a card grid.