.pragma library
// Intent sources for the Lens query line. Each returns plain result
// records { kind, title, subtitle, glyph, icon, score, payload } so the
// view can render them uniformly; the Lens decides how to act on them.
.import "../../utilities/Fuzzy.js" as Fuzzy

var COMMANDS = [
    { id: "atlas", title: "Open the Atlas", words: "atlas map infinite desktop overview workspaces", glyph: "atlas" },
    { id: "launcher", title: "Launcher", words: "apps applications launch run", glyph: "grid" },
    { id: "settings", title: "Settings", words: "settings preferences config configure theme", glyph: "gear" },
    { id: "quiet", title: "Toggle quiet mode", words: "dnd do not disturb quiet silence notifications", glyph: "moon" },
    { id: "mute", title: "Toggle mute", words: "mute sound audio volume silence", glyph: "speakerMute" },
    { id: "theme", title: "Switch light / dark", words: "theme light dark mode appearance vellum obsidian", glyph: "swatch" },
    { id: "collection", title: "New collection", words: "new collection plane group atlas", glyph: "layers" },
    { id: "terminal", title: "Terminal", words: "terminal shell console", glyph: "terminal" },
    { id: "lock", title: "Lock session", words: "lock screen session", glyph: "lock" },
    { id: "power", title: "Power menu", words: "power shutdown reboot restart suspend logout leave", glyph: "power" }
];

function commands(q) {
    var out = [];
    for (var i = 0; i < COMMANDS.length; i++) {
        var c = COMMANDS[i];
        var s = Fuzzy.best(q, [c.title.toLowerCase(), c.words], [1, 0.8]);
        if (s > 0) out.push({ kind: "command", title: c.title, subtitle: "Command", glyph: c.glyph, icon: "", score: s * 0.9, payload: c.id });
    }
    return out;
}

function windows(q, wins, labelFor) {
    var out = [];
    for (var i = 0; i < wins.length; i++) {
        var w = wins[i];
        var s = Fuzzy.best(q, [(w.title || "").toLowerCase(), (w.appId || "").toLowerCase()], [1, 0.9]);
        if (s > 0) out.push({ kind: "window", title: w.title || w.appId, subtitle: (w.appId || "window") + " · " + labelFor(w.workspaceRef), glyph: "window", icon: "", appId: w.appId, score: s * 1.05, payload: w.id });
    }
    return out;
}

function cells(q, state, coordLabel) {
    var out = [];
    for (var i = 0; i < state.collections.length; i++) {
        var c = state.collections[i];
        for (var k in c.cells) {
            var cell = c.cells[k];
            if (!cell.name) continue;
            var p = k.split(",");
            var x = parseInt(p[0], 10), y = parseInt(p[1], 10);
            var lbl = coordLabel(x, y);
            var s = Fuzzy.best(q, [cell.name.toLowerCase(), lbl.toLowerCase(), c.name.toLowerCase()], [1, 0.8, 0.5]);
            if (s > 0) out.push({ kind: "cell", title: cell.name, subtitle: c.name + " · " + lbl, glyph: "target", icon: "", score: s, payload: { collection: c.id, x: x, y: y } });
        }
    }
    return out;
}
