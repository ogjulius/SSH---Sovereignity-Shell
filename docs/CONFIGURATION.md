# Configuration

Everything is configurable from **Settings** (`ssh-shell settings open`, the gear
in Instruments, or the Lens command "Settings"). Settings writes
`$XDG_CONFIG_HOME/ssh-shell/config.json` (default `~/.config/ssh-shell/config.json`).

## How the file works

- It holds **only your choices**. Anything not in the file uses the default;
  setting an option back to its default removes it from the file.
- It is **validated per option**. An invalid value is replaced by its default and
  reported (Settings → About → Config issues, and the log). Unknown keys are
  reported and ignored.
- If the file is **not valid JSON**, SSH runs on defaults and **refuses to write**
  to it until you fix or move it — your file is never overwritten.
- The first save of each session copies the previous file to `config.json.bak`.
- Changes made by hand are picked up live.
- `SSH_SHELL_CONFIG=/path/file.json` uses a different file (handy for testing).

## Example

```json
{
  "appearance": { "accent": "verdigris", "shape": "cut", "chamfer": 1.25 },
  "meridian": { "position": "bottom", "showVolumePercent": true },
  "atlas": { "previews": false },
  "weather": { "latitude": 50.06, "longitude": 19.94, "locationName": "Kraków" },
  "commands": { "terminal": ["kitty"], "lock": ["hyprlock"] }
}
```

## Reference

| Option | Type | Default | Notes |
|---|---|---|---|
| **appearance** | | | |
| `mode` | `dark` `light` `auto` | `dark` | Obsidian / Vellum / by hour |
| `appIcons` | bool | **false** | opt-in desktop icons; off keeps Launcher, Lens and Atlas from loading icon-theme assets |
| `accent` | `argent` `brass` `ember` `verdigris` `cobalt` `oxblood` `custom` | `argent` | |
| `customAccent` | `#rrggbb` | `#c9bfa9` | used when accent is `custom` |
| `shape` | `round` `cut` | `round` | rounded islands, or the chamfered survey silhouette |
| `shine` | bool | true | soft light along the top edge of rounded surfaces |
| `opacity` | 0.5–1 | 0.9 | plate translucency (pair with compositor blur) |
| `animationScale` | 0–2 | 1 | 0 disables animation |
| `fontUi` / `fontDisplay` / `fontMono` | text | Inter / Inter Display / JetBrains Mono | |
| `fontScale` | 0.8–1.4 | 1.08 | slightly larger default for at-a-glance legibility |
| `chamfer` | 0–2 | 1 | scales the radius or the cut; 0 = square |
| `autoLightFrom` / `autoDarkFrom` | 0–23 | 7 / 19 | for `mode: auto` |
| **meridian** | | | |
| `position` | `top` `bottom` | `top` | |
| `style` | `island` `flush` | `island` | island floats inset from the edges; flush fills the screen edge |
| `height` | 26–52 | 34 | |
| `monitors` | list of output names | `[]` (all) | |
| `showMinimap` `showRow` `showTitle` `showTray` | bool | true | |
| `showTicks` | bool | false | the ruler-tick edge; only drawn by the flush style |
| `showBatteryPercent` / `showVolumePercent` | bool | true / false | |
| **lens** | | | |
| `enabled` | bool | true | |
| `dim` | 0–0.95 | 0.6 | backdrop dim |
| `showSignals` `showMedia` `showInstruments` | bool | true | |
| **atlas** | | | |
| `enabled` | bool | true | Infinite Desktop |
| `previews` | bool | true | one-shot window captures |
| `maxPreviews` | 0–64 | 16 | capture budget around the selection: up to 6 for the selected cell, the rest split over its 8 neighbours; 0 disables |
| `autoPlace` | bool | true | map workspaces reached natively |
| `carryFollows` | bool | true | follow a carried window |
| `traverseToast` | bool | true | |
| `cellWidth` | 140–420 | 232 | Atlas cell size at zoom 1 |
| **launcher** | `maxResults` 4–30 (8), `showCategories` (true), `recentCount` 0–20 (5) | | |
| **notifications** | | | |
| `enabled` | bool | true | be the notification daemon (restart to apply) |
| `position` | `top-right` `top-left` `bottom-right` `bottom-left` `top-center` | `top-right` | |
| `timeout` | 1000–60000 ms | 5500 | critical notifications stay until dismissed |
| `doNotDisturb` | bool | false | quiet mode |
| `historyLimit` | 5–500 | 80 | |
| `maxPopups` | 1–10 | 4 | |
| `persistHistory` | bool | **false** | stores notification text on disk |
| **osd** | `enabled` (true), `timeout` 400–6000 ms (1300) | | |
| **clock** | `format24h` (true), `showSeconds` (false), `showDate` (true), `weekStartsMonday` (true) | | |
| **weather** | | | |
| `enabled` | bool | true | |
| `provider` | `open-meteo` `none` | `open-meteo` | Open-Meteo needs no key |
| `latitude` / `longitude` | number or `null` | `null` | weather is off until set; SSH never geolocates |
| `locationName` | text | `""` | display only |
| `units` | `metric` `imperial` | `metric` | |
| `refreshMinutes` | 10–360 | 30 | |
| **commands** (argv lists, never run through a shell) | | | |
| `lock` | | `["loginctl","lock-session"]` | |
| `suspend` / `reboot` / `poweroff` | | `["loginctl","suspend"]` … | work with systemd-logind and elogind |
| `terminal` | | `["foot"]` | |
| **shortcuts** (used to *generate* compositor binds) | | | |
| `lens` `launcher` `atlas` `instruments` `power` | `"MODS, KEY"` | `SUPER, SPACE` … | |
| `traverse` / `carry` | modifiers | `SUPER ALT` / `SUPER ALT SHIFT` | combined with arrows |

## Keybinds

SSH does not grab keys. Settings → Keys generates a block for your compositor
from the `shortcuts` options; paste it into your Hyprland or Niri config.

## Import / export

Settings → Themes exports the `appearance` section to
`~/.config/ssh-shell/themes/<name>.json` and imports presets or your own files.
To move a whole configuration, copy `config.json`; to move your map, copy
`~/.local/state/ssh-shell/atlas.json`.