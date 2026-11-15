pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "Schema.js" as Schema

// Centralised, validated configuration.
//
// `user` holds only what the user has explicitly chosen (sparse tree).
// `o` holds the merged, validated result every module binds to.
// The file is never written unless the user changes something, and the
// first write of each session backs up the previous file to config.json.bak.
Singleton {
    id: root

    property var user: ({})
    property var o: Schema.defaults()
    property var warnings: []
    property bool loaded: false
    property string loadError: ""

    // Convenience accessors, so bindings read like prose.
    readonly property var appearance: o.appearance
    readonly property var meridian: o.meridian
    readonly property var lens: o.lens
    readonly property var atlas: o.atlas
    readonly property var launcher: o.launcher
    readonly property var notifications: o.notifications
    readonly property var osd: o.osd
    readonly property var clock: o.clock
    readonly property var weather: o.weather
    readonly property var commands: o.commands
    readonly property var shortcuts: o.shortcuts

    property bool _backedUp: false
    property bool _selfWrite: false
    // Set when the file exists but cannot be parsed: SSH will not write over it.
    property bool writeLocked: false

    function apply(tree) {
        const r = Schema.merge(tree);
        o = r.value;
        warnings = r.warnings;
        if (r.warnings.length > 0)
            console.warn("[ssh] config: " + r.warnings.length + " issue(s):\n  " + r.warnings.join("\n  "));
    }

    function get(path) {
        let n = o;
        for (const part of path.split(".")) {
            if (n === undefined || n === null) return undefined;
            n = n[part];
        }
        return n;
    }

    function set(path, value) {
        const spec = Schema.specAt(path);
        if (!spec) { console.warn("[ssh] config: unknown option " + path); return false; }
        const why = Schema.check(spec, value);
        if (why) { console.warn("[ssh] config: " + path + ": " + why); return false; }
        user = Schema.setPath(user, path, value);
        apply(user);
        saveTimer.restart();
        return true;
    }

    function reset(path) {
        const spec = Schema.specAt(path);
        if (spec) set(path, spec.d);
    }

    function exportTree() { return JSON.stringify(user, null, 2); }

    function save() {
        if (writeLocked) {
            console.warn("[ssh] config: not saving, " + Paths.configFile + " could not be parsed. Fix or move it first.");
            return;
        }
        if (!_backedUp && file.loaded) {
            Quickshell.execDetached(["cp", "-f", "--", Paths.configFile, Paths.configFile + ".bak"]);
            _backedUp = true;
        }
        Paths.ensure(Paths.configDir);
        _selfWrite = true;
        file.setText(JSON.stringify(user, null, 2) + "\n");
    }

    Timer { id: saveTimer; interval: 400; onTriggered: root.save() }

    FileView {
        id: file
        path: Paths.configFile
        watchChanges: true
        atomicWrites: true
        printErrors: false
        property bool loaded: false

        onFileChanged: {
            if (root._selfWrite) { root._selfWrite = false; return; }
            reload();
        }
        onLoaded: {
            loaded = true;
            const raw = text();
            if (raw.trim().length === 0) { root.user = {}; root.apply({}); root.loaded = true; return; }
            try {
                const parsed = JSON.parse(raw);
                root.user = (parsed && typeof parsed === "object" && !Array.isArray(parsed)) ? parsed : {};
                root.loadError = "";
                root.writeLocked = false;
            } catch (e) {
                // Keep running on defaults; never overwrite a file we could not parse.
                root.loadError = "config.json is not valid JSON: " + e.message;
                root.writeLocked = true;
                saveTimer.stop();
                console.warn("[ssh] " + root.loadError + " (running on defaults; the file was not modified)");
                root.user = {};
            }
            root.apply(root.user);
            root.loaded = true;
        }
        onLoadFailed: err => {
            // Missing file is the normal first-run case.
            root.user = {};
            root.apply({});
            root.loaded = true;
        }
    }
}
