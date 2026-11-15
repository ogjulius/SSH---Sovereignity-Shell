# Interaction model

## Vocabulary

- **Cell** — one place on the map, labelled like a chart square: columns are
  letters, rows are numbers (`A1`, `C2`, `−B−1`). A cell may be *bound* to a
  real compositor workspace and may have a *name*.
- **Collection** — a separate plane of cells ("Main", "Studio"), numbered with
  Roman numerals.
- **Cursor** — the cell you are in.
- **Surface** — any SSH panel: Lens, Atlas, launcher, Instruments, Almanac,
  Signals, power menu.

## Universal rules

| Action | Everywhere |
|---|---|
| Close the open surface | `Esc`, or click outside it |
| Move a selection | arrow keys (and `h j k l` in the Atlas) |
| Commit | `Enter` |
| Cycle categories / collections | `Tab` / `Shift+Tab` |
| Focus ring | accent hairline on the focused control |

Only **one surface is open at a time**; opening another replaces it. Surfaces
open on the focused output. Keyboard focus is exclusive while a surface is open,
so keys never leak to the window underneath.

## Travel

| Keys (defaults, generated for your compositor) | Effect |
|---|---|
| `Super+Alt+←↑↓→` | travel to the neighbouring cell |
| `Super+Alt+Shift+←↑↓→` | carry the focused window to the neighbouring cell (and follow) |
| `Super+Tab` | open the Atlas |
| `Super+Space` | open the Lens |
| `Super+D` | launcher |
| `Super+A` | Instruments |
| `Super+Shift+Esc` | power menu |

Arriving at an unbound cell **claims** it: SSH creates a workspace for it. On
Hyprland, row 1 of the first collection mirrors workspaces 1–10, so `Super+3`
and cell `C1` are the same place. Native workspace switches move the cursor; a
workspace SSH has not seen is placed on the map automatically.

## The Lens

Opened with `Super+Space` or the sigil in the Meridian.

- **Centre:** the current cell — name, coordinate, its windows.
  `↑↓` choose, `Enter` focuses, `Del` closes the window.
- **Cardinal points:** the four neighbouring cells, with their window icons.
  `Alt+arrows` travel without closing the Lens; it re-centres.
  `Alt+Shift+arrows` carry the focused window.
- **Corners:** time and media (NW), recent signals (NE), instruments (SE),
  position and key legend (SW).
- **Intent line:** typing searches apps, windows on any workspace, named cells
  and commands (`lock`, `quiet`, `theme`, `new collection`, …) in one ranked list.
  `Esc` clears the query first, then closes.

## The Atlas

Opened with `Super+Tab`, the minimap, or the coordinate in the Meridian.

| Key | Action |
|---|---|
| arrows / `hjkl` | move the selection |
| `Enter` / double-click | go there |
| `M` | move the focused window to the selected cell |
| drag a window tile onto a cell | move that window |
| `R` | name the selected cell |
| `Tab` / `Shift+Tab` | next / previous collection |
| `Shift+N` | new collection |
| `+` / `−`, `Ctrl+wheel` | zoom |
| wheel / `Shift+wheel` | move selection vertically / horizontally |
| `Del` | forget an empty cell's binding |
| `0` / `Home` | back to the cursor |

## Meridian

| Element | Click | Other |
|---|---|---|
| Sigil | Lens | right-click: launcher |
| Coordinate / minimap | Atlas | |
| Row stops | travel to that cell | |
| Readouts | Instruments | scroll: volume |
| Bell | Signals | right-click: quiet mode |
| Clock | Almanac | |

## Feedback

- **Traverse toast** after keyboard travel: a 3×3 window onto the map sliding in
  the direction of travel, with the new coordinate.
- **OSD** for volume, mic and brightness changes.
- **Destructive power actions arm first**: the first press shows "Press again to
  confirm"; the second, within 4 seconds, acts.

## Multi-monitor

The Meridian appears on every output (configurable). Surfaces, the OSD and
toasts open on the focused output. The Atlas is one map for all outputs; each
cell is bound to a workspace, which lives on whichever output the compositor
puts it.
