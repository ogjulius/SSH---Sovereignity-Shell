.pragma library
// Settings pages. Each option names a schema path; the control is chosen
// from the schema type, so Settings can never drift from what Config
// accepts. `special` entries render bespoke panels.
//
// Optional per-option keys:
//   unit — suffix for numeric readouts ("%" renders value × 100)
//   when — { path, is }: the row is shown only while that option has that value

var pages = [
    { key: "appearance", title: "Appearance", glyph: "swatch", items: [
        { special: "accent" },
        { path: "appearance.mode", label: "Ground", help: "Obsidian (dark), Vellum (light), or switch by time of day." , labels: { dark: "Obsidian", light: "Vellum", auto: "By time" } },
        { path: "appearance.appIcons", label: "Application icons", help: "Off by default to avoid loading icon-theme assets. Turn on for app icons in the Launcher, Lens and Atlas." },
        { path: "appearance.shape", label: "Shape", help: "Round islands, or the chamfered plates of the original survey silhouette.", labels: { round: "Round", cut: "Chamfer" } },
        { path: "appearance.shine", label: "Edge light", help: "A soft light along the top edge of rounded surfaces.", when: { path: "appearance.shape", is: "round" } },
        { path: "appearance.opacity", label: "Surface opacity", help: "Pair with a compositor blur rule for frosted surfaces.", unit: "%" },
        { path: "appearance.chamfer", label: "Corner size", help: "Scales the radius or the cut. 0 gives square plates.", unit: "×" },
        { path: "appearance.animationScale", label: "Motion", help: "0 disables animation entirely.", unit: "×" },
        { path: "appearance.fontScale", label: "Text size", unit: "×" },
        { path: "appearance.fontUi", label: "Interface font" },
        { path: "appearance.fontDisplay", label: "Display font" },
        { path: "appearance.fontMono", label: "Data font" },
        { path: "appearance.autoLightFrom", label: "Vellum from", help: "Hour of day the light ground takes over.", unit: " h", when: { path: "appearance.mode", is: "auto" } },
        { path: "appearance.autoDarkFrom", label: "Obsidian from", help: "Hour of day the dark ground takes over.", unit: " h", when: { path: "appearance.mode", is: "auto" } }
    ]},
    { key: "meridian", title: "Meridian", glyph: "minus", items: [
        { path: "meridian.position", label: "Edge" },
        { path: "meridian.style", label: "Style", help: "Pills give each zone its own island; island carries them all on one plate; flush fills the screen edge and can show the ruler ticks.", labels: { pills: "Pills", island: "Island", flush: "Flush" } },
        { path: "meridian.height", label: "Height", unit: " px" },
        { path: "meridian.showTicks", label: "Ruler ticks", when: { path: "meridian.style", is: "flush" } },
        { path: "meridian.showMinimap", label: "Minimap" },
        { path: "meridian.showRow", label: "Row stops", help: "The cells of your current Atlas row, as workspace indicators." },
        { path: "meridian.showTitle", label: "Focused window" },
        { path: "meridian.showTray", label: "Tray" },
        { path: "meridian.showBatteryPercent", label: "Battery percentage" },
        { path: "meridian.showVolumePercent", label: "Volume percentage" },
        { special: "monitors" }
    ]},
    { key: "atlas", title: "Atlas", glyph: "atlas", items: [
        { path: "atlas.enabled", label: "Infinite Desktop", help: "SSH keeps a spatial map of your workspaces. The compositor's own workspaces keep working as usual." },
        { path: "atlas.autoPlace", label: "Auto-place new workspaces", help: "Workspaces you open with native keybinds get a place on the map." },
        { path: "atlas.carryFollows", label: "Follow carried windows" },
        { path: "atlas.traverseToast", label: "Show position on travel" },
        { path: "atlas.previews", label: "Window previews", help: "Captured once when the Atlas opens, only around the selection." },
        { path: "atlas.maxPreviews", label: "Preview budget", help: "Captures allowed around the selection: up to 6 for the selected cell, the rest shared by its neighbours.", when: { path: "atlas.previews", is: true } },
        { path: "atlas.cellWidth", label: "Cell size", unit: " px" },
        { special: "collections" }
    ]},
    { key: "lens", title: "Lens", glyph: "lens", items: [
        { path: "lens.enabled", label: "Sovereign Space" },
        { path: "lens.dim", label: "Backdrop dim", unit: "%" },
        { path: "lens.showMedia", label: "Media" },
        { path: "lens.showSignals", label: "Recent signals" },
        { path: "lens.showInstruments", label: "Instruments" }
    ]},
    { key: "signals", title: "Signals", glyph: "bell", items: [
        { path: "notifications.enabled", label: "Notification daemon", help: "Takes effect on restart. Turn off if you use another daemon." },
        { path: "notifications.doNotDisturb", label: "Quiet" },
        { path: "notifications.position", label: "Popup position" },
        { path: "notifications.timeout", label: "Popup time", unit: " ms" },
        { path: "notifications.maxPopups", label: "Popups at once" },
        { path: "notifications.historyLimit", label: "History length" },
        { path: "notifications.persistHistory", label: "Keep history across restarts", help: "Stores notification text on disk. Off by default." },
        { path: "osd.enabled", label: "On-screen display" },
        { path: "osd.timeout", label: "OSD time", unit: " ms", when: { path: "osd.enabled", is: true } }
    ]},
    { key: "almanac", title: "Almanac", glyph: "calendar", items: [
        { path: "clock.format24h", label: "24-hour clock" },
        { path: "clock.showSeconds", label: "Seconds" },
        { path: "clock.showDate", label: "Date in Meridian" },
        { path: "clock.weekStartsMonday", label: "Week starts Monday" },
        { path: "weather.enabled", label: "Weather" },
        { path: "weather.provider", label: "Provider", help: "Open-Meteo needs no account or key.", when: { path: "weather.enabled", is: true } },
        { path: "weather.latitude", label: "Latitude", when: { path: "weather.enabled", is: true } },
        { path: "weather.longitude", label: "Longitude", when: { path: "weather.enabled", is: true } },
        { path: "weather.locationName", label: "Place name", when: { path: "weather.enabled", is: true } },
        { path: "weather.units", label: "Units", when: { path: "weather.enabled", is: true } },
        { path: "weather.refreshMinutes", label: "Refresh", unit: " min", when: { path: "weather.enabled", is: true } }
    ]},
    { key: "keys", title: "Keys", glyph: "keyboard", items: [ { special: "keys" } ] },
    { key: "commands", title: "Commands", glyph: "terminal", items: [
        { path: "commands.terminal", label: "Terminal" },
        { path: "commands.lock", label: "Lock" },
        { path: "commands.suspend", label: "Suspend" },
        { path: "commands.reboot", label: "Restart" },
        { path: "commands.poweroff", label: "Power off" }
    ]},
    { key: "themes", title: "Themes", glyph: "layers", items: [ { special: "themes" } ] },
    { key: "about", title: "About", glyph: "sigil", items: [ { special: "about" } ] }
];