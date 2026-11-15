pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configuration
import qs.compositors
import "../modules/settings/Keybinds.js" as KB

// Keybinds inside the Sovereignity Shell login sessions.
//
// Only active when ssh-session started us (SSH_SESSION is set) and
// `session.keybinds` is on. Outside those sessions SSH never touches the
// compositor's bindings; users paste the block from Settings → Keys instead.
//
//   Hyprland  binds are added at runtime (hyprctl eval for Lua configs,
//             hyprctl keyword for classic ones). Any combination the user's
//             own config already binds is skipped, so the user's binds win.
//             Nothing is written to disk; the binds end with the session.
//   Niri      the binds block is written to the file ssh-session includes
//             *before* the user's config in its overlay, so the user's binds
//             win there too. Niri reloads it live.
Singleton {
    id: sb

    readonly property string session: Quickshell.env("SSH_SESSION") || ""
    readonly property bool active: (session === "hyprland" || session === "niri") && session === Compositor.kind && Config.o.session.keybinds
    readonly property string niriFile: Paths.stateDir + "/session/niri-binds.kdl"

    property var applied: []      // Hyprland: specs currently bound by us
    property var skipped: []      // specs left out because the user binds the key
    property string lastError: ""

    readonly property string signature: active ? JSON.stringify(Config.keybinds) : ""
    onSignatureChanged: refresh.restart()
    Timer { id: refresh; interval: 300; onTriggered: sb.apply() }
    Connections { target: Compositor; function onConnectedChanged() { if (Compositor.connected) refresh.restart(); } }

    function apply() {
        if (!active || !Compositor.connected) return;
        if (session === "niri") {
            niriOut.setText("// Written by SSH from its \"keybinds\" options; regenerated at every start.\n" + KB.generate("niri", Config.keybinds) + "\n");
            console.info("[ssh] session keybinds written to " + niriFile);
            return;
        }
        // Hyprland: first remove what we bound before, then look at what the
        // user's config binds, then add the free combinations.
        const lua = Compositor.backend && Compositor.backend.lua;
        if (applied.length > 0) {
            if (lua) run(["hyprctl", "eval", applied.map(KB.hyprlandLuaUnbind).join("\n")]);
            else run(["hyprctl", "--batch", applied.map(KB.hyprlandUnkeyword).join(" ; ")]);
            applied = [];
        }
        pendingList = true;
        if (!runner.running) next();
    }

    function bindFree(taken) {
        const p = KB.partition(KB.specs(Config.keybinds), taken);
        skipped = p.skipped;
        if (p.skipped.length > 0)
            console.info("[ssh] session keybinds: kept your own binding for " + p.skipped.map(b => (b.mods ? b.mods + " " : "") + b.key).join(", "));
        if (p.free.length === 0) return;
        const lua = Compositor.backend && Compositor.backend.lua;
        if (lua) run(["hyprctl", "eval", p.free.map(KB.hyprlandLuaBind).join("\n")]);
        else run(["hyprctl", "--batch", p.free.map(KB.hyprlandKeyword).join(" ; ")]);
        applied = p.free;
        console.info("[ssh] session keybinds: added " + p.free.length + " binding(s) (" + (lua ? "Lua" : "classic") + " config)");
    }

    // One command at a time is plenty: these run once per start or edit.
    property var queue: []
    property bool pendingList: false   // list the user's binds once queued commands finish
    function run(argv) { queue = queue.concat([argv]); if (!runner.running) next(); }
    function next() {
        if (queue.length === 0) {
            if (pendingList && !listBinds.running) { pendingList = false; listBinds.running = true; }
            return;
        }
        runner.command = queue[0];
        queue = queue.slice(1);
        runner.running = true;
    }
    Process {
        id: runner
        stdout: StdioCollector {
            onStreamFinished: {
                const t = text.trim();
                if (t && t !== "ok" && !/^(ok\s*)+$/.test(t)) { sb.lastError = t; console.warn("[ssh] session keybinds: hyprctl said: " + t); }
            }
        }
        onExited: sb.next()
    }
    Process {
        id: listBinds
        command: ["hyprctl", "binds", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let taken = [];
                try { taken = JSON.parse(text); } catch (e) { console.warn("[ssh] session keybinds: cannot read hyprctl binds"); return; }
                sb.bindFree(Array.isArray(taken) ? taken : []);
            }
        }
    }
    FileView {
        id: niriOut
        path: sb.session === "niri" ? sb.niriFile : ""
        atomicWrites: true
        printErrors: false
    }
}
