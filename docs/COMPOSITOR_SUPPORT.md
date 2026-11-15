# Compositor support

SSH supports **Hyprland** and **Niri** through one shared UI and separate backends.
Detection: `$HYPRLAND_INSTANCE_SIGNATURE` → Hyprland, `$NIRI_SOCKET` → Niri.
Override with `SSH_SHELL_COMPOSITOR=hyprland|niri|none`.

| | Hyprland | Niri |
|---|---|---|
| Backend | Quickshell's native `Quickshell.Hyprland` IPC | `$NIRI_SOCKET` JSON event stream + `niri msg` actions |
| Workspace refs | `id:<n>` (numeric) | `name:<label>` for SSH-created cells, `id:<n>` (session-only) otherwise |
| Window geometry in Atlas | yes (`lastIpcObject.at/size`) | no (window icons instead) |
| Window previews | yes (one-shot screencopy of toplevels) | not yet |
| Classic + Lua config | both (auto-detected via `Hyprland.usingLua`) | n/a |
| Reconnection | handled by Quickshell's module; a compositor restart ends the session anyway | exponential back-off reconnect (0.5 s → 10 s) |
| **Tested** | **yes, live on 0.57.2 (Lua config)** | **no — implemented against the documented IPC, not yet run** |

## The Atlas is SSH's, not the compositor's

Neither compositor has a 2D infinite canvas. Hyprland has numbered/named
workspaces; Niri has a dynamic vertical strip of workspaces per output with
horizontally scrolling columns inside each. SSH keeps the map (cells,
collections, names) in its own state file and binds each cell to a real
workspace. Standard workspace operations keep working: switching workspaces
with your normal keybinds simply moves SSH's cursor.

## Hyprland

**Events:** coalesced rebuild on any `rawEvent` and on the workspace/toplevel
models changing; `refreshToplevels()` after window open/move/float/title
events and when the Atlas opens (for geometry).

**Dispatch.** Hyprland ≥ 0.55 can be configured in Lua; in that mode `dispatch`
takes Lua expressions and classic strings fail with
`')' expected near …`. SSH emits:

| Action | Classic | Lua (verified on 0.57.2) |
|---|---|---|
| focus workspace | `workspace N` | `hl.dsp.focus({ workspace = N })` |
| move window | `movetoworkspace[silent] N,address:0x…` | `hl.dsp.window.move({ workspace = N, window = "address:0x…", follow = bool })` |
| focus window | `focuswindow address:0x…` | `hl.dsp.focus({ window = "address:0x…" })` |
| close window | `closewindow address:0x…` | `hl.dsp.window.close({ window = "address:0x…" })` |
| exit | `exit` | `hl.dsp.exit()` |

Verification method (2026-11-15, Hyprland 0.57.2): `focus` re-targeted at the
current workspace (no-op); `window.move` of an unfocused window to workspace 11
with `follow = false` and back, checking placement and focus with
`hyprctl clients`; `window.close` with `window = …` on one of two throwaway
terminals while the other was focused. Note that unknown keys are silently
accepted by the Lua API, which is why behaviour was checked rather than just
the return value.

**Limitations:** special (scratchpad) workspaces are excluded from the map.
Classic-config dispatch is implemented to Hyprland's long-standing syntax but
was not re-tested on a classic-config session in this release.

## Niri

**Events:** one socket connection sends `"EventStream"` and consumes
`WorkspacesChanged`, `WorkspaceActivated`, `WorkspaceUrgencyChanged`,
`WindowsChanged`, `WindowOpenedOrChanged`, `WindowClosed`,
`WindowFocusChanged` and `WindowUrgencyChanged`; other events are ignored.
State is published at most once per frame.

**Actions** run sequentially through a queue of `niri msg action …` processes
(argv arrays): `focus-workspace`, `set-workspace-name --workspace <idx>`,
`move-window-to-workspace --window-id … --focus …`, `focus-window --id`,
`close-window --id`, `quit --skip-confirmation`.

**Claiming a cell** names niri's trailing empty workspace on the focused output
(`ssh-<collection>-<x>_<y>`) and focuses it, giving the cell a stable binding.

**Known limitations / risks (untested):**
- Unnamed workspaces are referenced by index on the *focused* output; focusing
  an unnamed workspace on another output may target the wrong one.
- Action flag names follow niri's documented CLI; if a niri release changes
  them, actions will log errors (the UI stays up).
- No previews or window geometry in the Atlas yet.

Niri support must be tested on a real session before it can be called official.
See `STATUS.md`.
