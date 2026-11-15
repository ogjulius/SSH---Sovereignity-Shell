pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configuration
import "../utilities/Fuzzy.js" as Fuzzy

// Desktop entries + launch frequency. The search index is a flat array of
// pre-lowercased strings, rebuilt only when the entry set changes.
Singleton {
    id: a

    property var usage: ({})   // entry id -> { n: count, t: last launch ms }
    property var index: []

    readonly property var categories: [
        { key: "all", label: "All" },
        { key: "Development", label: "Develop" },
        { key: "Graphics", label: "Graphics" },
        { key: "Network", label: "Internet" },
        { key: "AudioVideo", label: "Media" },
        { key: "Office", label: "Office" },
        { key: "Game", label: "Games" },
        { key: "System", label: "System" },
        { key: "Utility", label: "Utility" }
    ]

    function rebuild() {
        const out = [];
        for (const e of DesktopEntries.applications.values) {
            if (e.noDisplay) continue;
            out.push({
                entry: e, id: e.id,
                name: (e.name || "").toLowerCase(),
                generic: (e.genericName || "").toLowerCase(),
                keywords: (e.keywords || []).join(" ").toLowerCase(),
                exec: (e.execString || "").toLowerCase().split(" ")[0].split("/").pop(),
                cats: e.categories || []
            });
        }
        out.sort((x, y) => x.name.localeCompare(y.name));
        index = out;
    }
    Connections { target: DesktopEntries.applications; function onValuesChanged() { rebuildTimer.restart(); } }
    Timer { id: rebuildTimer; interval: 200; onTriggered: a.rebuild() }

    function frecency(id) {
        const u = usage[id];
        if (!u) return 0;
        const days = (Date.now() - u.t) / 86400000;
        return u.n / (1 + days * 0.25);
    }

    // -> array of DesktopEntry, best first
    function search(query, category, limit) {
        const q = (query || "").trim().toLowerCase();
        const cat = category && category !== "all" ? category : "";
        const scored = [];
        for (const it of index) {
            if (cat && it.cats.indexOf(cat) < 0) continue;
            let s;
            if (q.length === 0) s = 1 + frecency(it.id) * 10;
            else {
                s = Fuzzy.best(q, [it.name, it.generic, it.keywords, it.exec], [1, 0.7, 0.55, 0.6]);
                if (s <= 0) continue;
                s += frecency(it.id) * 20;
            }
            scored.push({ s: s, e: it.entry });
        }
        scored.sort((x, y) => (y.s - x.s) || x.e.name.localeCompare(y.e.name));
        return scored.slice(0, limit || 50).map(x => x.e);
    }

    // appId -> icon path, cached (heuristicLookup is not free).
    property var _iconCache: ({})
    function iconFor(appId) {
        if (!appId) return "";
        const hit = _iconCache[appId];
        if (hit !== undefined) return hit;
        const e = DesktopEntries.heuristicLookup(appId);
        const path = Quickshell.iconPath(e && e.icon ? e.icon : appId.toLowerCase(), true);
        _iconCache[appId] = path || "";
        return path || "";
    }
    function nameFor(appId) {
        const e = appId ? DesktopEntries.heuristicLookup(appId) : null;
        return e ? e.name : appId;
    }

    function recent(n) {
        return index.filter(it => usage[it.id]).sort((x, y) => usage[y.id].t - usage[x.id].t).slice(0, n).map(it => it.entry);
    }

    function launch(entry) {
        if (!entry) return;
        const u = Object.assign({}, usage);
        const prev = u[entry.id] || { n: 0, t: 0 };
        u[entry.id] = { n: prev.n + 1, t: Date.now() };
        usage = u;
        entry.execute();
        save.restart();
    }

    Timer { id: save; interval: 1000; onTriggered: { Paths.ensure(Paths.stateDir); store.setText(JSON.stringify(a.usage)); } }
    FileView {
        id: store
        path: Paths.usageFile
        printErrors: false
        onLoaded: { try { const u = JSON.parse(text()); if (u && typeof u === "object") a.usage = u; } catch (e) {} }
    }
    Component.onCompleted: rebuild()
}
