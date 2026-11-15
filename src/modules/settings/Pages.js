.pragma library
// Settings pages. Each option names a schema path; the control is chosen
// from the schema type, so Settings can never drift from what Config
// accepts. `special` entries render bespoke panels.

var pages = [
    { key: "appearance", title: "Appearance", glyph: "swatch", items: [
        { special: "accent" },
        { path: "appearance.mode", label: "Ground", help: "Obsidian (dark), Vellum (light), or switch by time of day." , labels: { dark: "Obsidian", light: "Vellum", auto: "By time" } },
        { path: "appearance.opacity", label: "Surface opacity", help: "Pair with a compositor blur rule for frosted surfaces." },
        { path: "appearance.chamfer", label: "Chamfer", help: "Size of the cut corners. 0 gives square plates." },
        { path: "appearance.animationScale", label: "Motion", help: "0 disables animation entirely." },
        { path: "appearance.fontScale", label: "Text size" },
        { path: "appearance.fontUi", label: "Interface font" },
        { path: "appearance.fontDisplay", label: "Display font" },
        { path: "appearance.fontMono", label: "Data font" },
        { path: "appearance.autoLightFrom", label: "Vellum from (hour)" },
        { path: "appearance.autoDarkFrom", label: "Obsidian from (hour)" }
    ]},
    { key: "meridian", title: "Meridian", glyph: "minus", items: [
        { path: "meridian.position", label: "Edge" },
        { path: "meridian.height", label: "Height" },
        { path: "meridian.showTicks", label: "Ruler ticks" },
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
        { path: "atlas.maxPreviews", label: "Preview budget", help: "Captures allowed around the selection: up to 6 for the selected cell, the rest shared by its neighbours." },
        { path: "atlas.cellWidth", label: "Cell size" },
        { special: "collections" }
    ]},
    { key: "lens", title: "Lens", glyph: "lens", items: [
        { path: "lens.enabled", label: "Sovereign Space" },
        { path: "lens.dim", label: "Backdrop dim" },
        { path: "lens.showMedia", label: "Media" },
        { path: "lens.showSignals", label: "Recent signals" },
        { path: "lens.showInstruments", label: "Instruments" }
    ]},
    { key: "signals", title: "Signals", glyph: "bell", items: [
        { path: "notifications.enabled", label: "Notification daemon", help: "Takes effect on restart. Turn off if you use another daemon." },
        { path: "notifications.doNotDisturb", label: "Quiet" },
        { path: "notifications.position", label: "Popup position" },
        { path: "notifications.timeout", label: "Popup time (ms)" },
        { path: "notifications.maxPopups", label: "Popups at once" },
        { path: "notifications.historyLimit", label: "History length" },
        { path: "notifications.persistHistory", label: "Keep history across restarts", help: "Stores notification text on disk. Off by default." },
        { path: "osd.enabled", label: "On-screen display" },
        { path: "osd.timeout", label: "OSD time (ms)" }
    ]},
    { key: "almanac", title: "Almanac", glyph: "calendar", items: [
        { path: "clock.format24h", label: "24-hour clock" },
        { path: "clock.showSeconds", label: "Seconds" },
        { path: "clock.showDate", label: "Date in Meridian" },
        { path: "clock.weekStartsMonday", label: "Week starts Monday" },
        { path: "weather.enabled", label: "Weather" },
        { path: "weather.provider", label: "Provider", help: "Open-Meteo needs no account or key." },
        { path: "weather.latitude", label: "Latitude" },
        { path: "weather.longitude", label: "Longitude" },
        { path: "weather.locationName", label: "Place name" },
        { path: "weather.units", label: "Units" },
        { path: "weather.refreshMinutes", label: "Refresh (minutes)" }
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
