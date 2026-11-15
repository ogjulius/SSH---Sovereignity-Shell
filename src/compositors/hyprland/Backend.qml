import QtQuick
import Quickshell
import Quickshell.Hyprland

// Hyprland backend, built on Quickshell's native Hyprland IPC module
// (request socket + event socket2). Updates are event-driven and coalesced
// into one rebuild per frame burst.
Item {
    id: b

    property bool connected: Hyprland.workspaces !== null
    property var workspaces: []
    property var windows: []
    property string focusedWorkspaceRef: Hyprland.focusedWorkspace ? "id:" + Hyprland.focusedWorkspace.id : ""
    property string focusedWindowId: Hyprland.activeToplevel ? b.addr(Hyprland.activeToplevel.address) : ""
    property string focusedOutput: Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
    readonly property var caps: ({ numericIds: true, namedWorkspaces: true, geometry: true, previews: true })

    function addr(a) {
        if (!a) return "";
        return a.indexOf("0x") === 0 ? a : "0x" + a;
    }

    function rebuild() {
        const ws = [];
        for (const w of Hyprland.workspaces.values) {
            if (w.id <= 0) continue; // special / scratch workspaces are not map territory
            ws.push({
                ref: "id:" + w.id, id: w.id, name: w.name, idx: w.id,
                output: w.monitor ? w.monitor.name : "",
                active: w.active, focused: w.focused, urgent: w.urgent,
                windows: w.toplevels ? w.toplevels.values.length : 0
            });
        }
        ws.sort((a, b) => a.id - b.id);
        const wins = [];
        for (const t of Hyprland.toplevels.values) {
            const o = t.lastIpcObject || {};
            const at = o.at || [0, 0], size = o.size || [0, 0];
            const mon = t.monitor;
            wins.push({
                id: b.addr(t.address),
                title: t.title || o.title || "",
                appId: o["class"] || o.initialClass || "",
                workspaceRef: t.workspace ? "id:" + t.workspace.id : "",
                focused: t.activated,
                floating: !!o.floating,
                // geometry relative to the window's monitor
                x: at[0] - (mon ? mon.x : 0), y: at[1] - (mon ? mon.y : 0),
                w: size[0], h: size[1],
                monW: mon ? mon.width / (mon.scale || 1) : 1920,
                monH: mon ? mon.height / (mon.scale || 1) : 1080,
                handle: t.wayland
            });
        }
        workspaces = ws;
        windows = wins;
    }

    Timer { id: coalesce; interval: 24; onTriggered: b.rebuild() }
    Timer { id: geomCoalesce; interval: 60; onTriggered: Hyprland.refreshToplevels() }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            const n = event.name;
            if (n === "openwindow" || n === "movewindow" || n === "movewindowv2" || n === "changefloatingmode" || n === "windowtitlev2")
                geomCoalesce.restart();
            coalesce.restart();
        }
    }
    Connections { target: Hyprland.workspaces; function onValuesChanged() { coalesce.restart(); } }
    Connections { target: Hyprland.toplevels; function onValuesChanged() { coalesce.restart(); } }

    function refreshGeometry() { Hyprland.refreshToplevels(); coalesce.restart(); }

    // ── Dispatch ───────────────────────────────────────────────────────
    // Hyprland ≥ 0.55 can run a Lua config, in which case dispatch takes a
    // Lua expression (hl.dsp.*) instead of the classic "name args" string.
    // Both syntaxes were verified against Hyprland 0.57.2; see
    // docs/COMPOSITOR_SUPPORT.md.
    readonly property bool lua: Hyprland.usingLua

    function luaStr(s) { return "\"" + String(s).replace(/\\/g, "\\\\").replace(/"/g, "\\\"") + "\""; }
    // Workspace argument: integer id, or "name:<label>".
    function wsClassic(ref) { return ref.indexOf("id:") === 0 ? ref.slice(3) : "name:" + ref.slice(5); }
    function wsLua(ref) { return ref.indexOf("id:") === 0 ? String(parseInt(ref.slice(3))) : luaStr("name:" + ref.slice(5)); }
    function addrOk(id) { return /^0x[0-9a-fA-F]+$/.test(id); }

    function focusRef(ref, create) {
        Hyprland.dispatch(lua ? "hl.dsp.focus({ workspace = " + wsLua(ref) + " })" : "workspace " + wsClassic(ref));
    }
    function moveWindowTo(windowId, ref, follow, create) {
        if (!addrOk(windowId)) return;
        if (lua) Hyprland.dispatch("hl.dsp.window.move({ workspace = " + wsLua(ref) + ", window = " + luaStr("address:" + windowId) + ", follow = " + (follow ? "true" : "false") + " })");
        else Hyprland.dispatch((follow ? "movetoworkspace " : "movetoworkspacesilent ") + wsClassic(ref) + ",address:" + windowId);
    }
    function focusWindow(id) {
        if (!addrOk(id)) return;
        Hyprland.dispatch(lua ? "hl.dsp.focus({ window = " + luaStr("address:" + id) + " })" : "focuswindow address:" + id);
    }
    function closeWindow(id) {
        if (!addrOk(id)) return;
        Hyprland.dispatch(lua ? "hl.dsp.window.close({ window = " + luaStr("address:" + id) + " })" : "closewindow address:" + id);
    }
    function quit() { Hyprland.dispatch(lua ? "hl.dsp.exit()" : "exit"); }

    Component.onCompleted: { Hyprland.refreshToplevels(); rebuild(); }
}
