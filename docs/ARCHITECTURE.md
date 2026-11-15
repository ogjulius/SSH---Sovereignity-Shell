# Architecture

SSH is interpreted QML on Quickshell 0.3 / Qt 6. There is no build step.

```
src/
  shell.qml              entry: resident Meridian, lazy surfaces, IPC handlers
  configuration/         Schema.js (single source of truth), Config, Paths, Version
  themes/                Theme (tokens), Palettes.js, Icons.js, presets/*.json
  utilities/             pure JS: AtlasModel.js, Fuzzy.js, Fmt.js  (unit-tested)
  components/            design primitives + SurfaceWindow
  compositors/           Compositor facade
    hyprland/Backend.qml   Quickshell.Hyprland IPC; classic + Lua dispatch
    niri/Backend.qml       $NIRI_SOCKET event stream + `niri msg` actions
  services/              singletons over system interfaces and shell state
  modules/<surface>/     UI: <Surface>Content.qml (pure item) + <Surface>.qml (window)
  dev-render.qml         offscreen render harness (not installed)
  dev-tests.qml          unit tests (not installed)
```

## Layers and dependency direction

```
modules  ─►  components  ─►  themes  ─►  configuration
   │              │
   └──►  services ─┴──►  compositors ─► configuration
```

- **configuration** depends on nothing else in SSH.
- **themes** read configuration only.
- **compositors** know nothing about the UI or the Atlas.
- **services** may use compositors and configuration; they never import modules.
- **modules** compose everything; modules never import each other except to
  reuse a content component (the Lens embeds `MediaStrip` and `NotificationCard`).

No cycles; no state duplicated across layers. The Atlas map lives only in
`services/Atlas.qml`; compositor state lives only in the active backend.

## Lifecycles

| Thing | Created | Destroyed |
|---|---|---|
| Services | on first reference | never (singletons) |
| Meridian | at start, one per selected output | when the output disappears |
| Surfaces | `Surfaces.open(name)` flips `loaded[name]`; a `LazyLoader` instantiates the window | after the exit animation, `SurfaceWindow` calls `Surfaces.release(name)`; a deferred `gc()` follows |
| Toasts window | while there are popups | when the last popup expires |
| OSD / traverse toast | on event | after a timeout |
| Settings | `SettingsHub.open()` | window closed |

Every surface is two files: `XContent.qml`, a plain `Item` that can be rendered
and tested on its own, and `X.qml`, a two-line `SurfaceWindow` wrapper that only
declares placement. Placement, motion, dimming, focus, Esc and click-outside are
implemented once, in `components/SurfaceWindow.qml`.

## Compositor abstraction

`Compositor` exposes one normalised model regardless of backend:

```
workspaces: [{ ref, id, name, idx, output, active, focused, urgent, windows }]
windows:    [{ id, title, appId, workspaceRef, focused, floating, x, y, w, h, monW, monH, handle }]
focusedWorkspaceRef, focusedWindowId, focusedOutput, connected
caps: { numericIds, namedWorkspaces, geometry, previews }
focusRef(ref, create)  moveWindowTo(id, ref, follow, create)  focusWindow(id)  closeWindow(id)  quit()
```

Workspace references are strings: `id:<n>` or `name:<label>`. Backends are
loaded with a `Loader` by source path, so Hyprland's module is never initialised
under Niri. Updates are event-driven and coalesced (one rebuild per burst).
See `COMPOSITOR_SUPPORT.md` for each backend's details and limits.

## The Atlas (Infinite Desktop)

`utilities/AtlasModel.js` is pure, unit-tested data logic; `services/Atlas.qml`
wires it to the compositor and to disk.

- State: `{ version, active, collections: [{ id, name, cursor, cells: { "x,y": { ref, name } } }] }`,
  persisted to `$XDG_STATE_HOME/ssh-shell/atlas.json` (debounced, atomic writes),
  sanitised on load so a damaged file is repaired rather than discarded.
- **SSH → compositor:** traverse/carry/goto resolve the target cell, allocate a
  ref if the cell is unbound, then call the backend.
  - Hyprland: numeric ids. Row 1 of the first collection mirrors workspaces 1–10;
    other cells take the lowest free id ≥ 11.
  - Niri: `name:ssh-<collection>-<x>_<y>`; the backend names niri's trailing empty
    workspace and focuses it.
- **compositor → SSH:** a focused-workspace change moves the cursor to the bound
  cell, or auto-places the workspace (numbered 1–10 → row 1, else at/near the cursor).

## Rendering cost control

- Atlas cells are a **recycled pool**: `(visible cols + 3) × (visible rows + 3)`
  delegates re-targeted to new coordinates as the view pans; none are created
  or destroyed while panning.
- Unclaimed cells draw a survey cross only; the window map inside a cell is a
  `Loader` that exists only when the cell has windows.
- Window previews: one-shot `ScreencopyView { live: false }`, only for the
  selected cell's 3×3 neighbourhood, only at zoom ≥ 0.85, within the
  `atlas.maxPreviews` budget (selected cell ≤ 6, neighbours share the rest).
- Stats sampling and weather fetching use demand counters: they run only while
  a view holds them.
- Artwork/notification images decode at display size (`sourceSize`).

## Configuration

`configuration/Schema.js` declares each option once (type, default, range or
enum). `Config.merge` validates per key: valid values are kept, invalid ones fall
back to defaults with a warning, unknown keys are reported. The user file holds
only explicit choices (values equal to defaults are removed on save). See
`CONFIGURATION.md`.

## Security posture

- External processes are always started with argv arrays
  (`Process.command`, `Quickshell.execDetached([...])`); no user-controlled
  string is ever interpreted by a shell. The single `sh -c` in SSH (thermal-zone
  discovery in `services/Stats.qml`) is a fixed literal with no interpolation.
- Hyprland Lua dispatch strings are built only from integers, validated window
  addresses (`/^0x[0-9a-f]+$/i`) and escaped string literals.
- Commands the user configures (`commands.*`) are argv arrays validated by the schema.
- No credentials exist in the code base; the weather provider needs none.

## Decisions (ADR log)

| # | Decision | Why |
|---|---|---|
| 1 | Quickshell + QML only, no C++ plugin | zero build step, distro-friendly, contributor-friendly |
| 2 | Atlas state kept by SSH, mapped onto real workspaces | no compositor offers a 2D canvas; honesty over illusion |
| 3 | Row 1 ↔ workspaces 1–10 on Hyprland | native `Super+N` binds keep working and agree with the map |
| 4 | Niri via raw socket + `niri msg` | Quickshell has no Niri module; argv-only actions stay safe |
| 5 | One `SurfaceWindow`, content/window split | consistent behaviour; content is renderable in tests |
| 6 | Lazy surfaces + deferred `gc()` | measured: flat memory under repeated open/close |
| 7 | Own glyph set via Shapes | identity, theme recolouring, no icon-font dependency |
| 8 | Compositor owns keybinds; SSH generates snippets | SSH never edits compositor config |
| 9 | Notification history in memory by default | notification text is private |
