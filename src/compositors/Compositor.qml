pragma Singleton
import QtQuick
import Quickshell

// The one compositor interface the UI talks to.
//
// Backends live in compositors/<name>/Backend.qml and are loaded on demand,
// so Hyprland's module is never initialised under Niri and vice versa.
// Every backend exposes the same normalised model:
//
//   workspaces: [{ ref, id, name, idx, output, active, focused, urgent, windows }]
//   windows:    [{ id, title, appId, workspaceRef, focused, floating, x, y, w, h, handle }]
//   focusedWorkspaceRef, focusedWindowId, focusedOutput, connected
//   caps: { numericIds, namedWorkspaces, geometry, previews }
//
// and actions: focusRef(ref, create), moveWindowTo(windowId, ref, follow, create),
// focusWindow(id), closeWindow(id), quit().
//
// References are strings: "id:<n>" or "name:<label>". See docs/COMPOSITOR_SUPPORT.md.
Singleton {
    id: c

    readonly property string kind: {
        const forced = Quickshell.env("SSH_SHELL_COMPOSITOR");
        if (forced === "hyprland" || forced === "niri" || forced === "none") return forced;
        if (Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")) return "hyprland";
        if (Quickshell.env("NIRI_SOCKET")) return "niri";
        return "none";
    }
    readonly property string displayName: kind === "hyprland" ? "Hyprland" : (kind === "niri" ? "Niri" : "Unsupported compositor")

    readonly property var backend: loader.item
    readonly property bool connected: backend ? backend.connected : false
    readonly property var workspaces: backend ? backend.workspaces : []
    readonly property var windows: backend ? backend.windows : []
    readonly property string focusedWorkspaceRef: backend ? backend.focusedWorkspaceRef : ""
    readonly property string focusedWindowId: backend ? backend.focusedWindowId : ""
    readonly property string focusedOutput: backend ? backend.focusedOutput : ""
    readonly property var caps: backend ? backend.caps : ({ numericIds: false, namedWorkspaces: false, geometry: false, previews: false })

    readonly property var focusedWindow: {
        const id = focusedWindowId;
        if (!id) return null;
        for (const w of windows) if (w.id === id) return w;
        return null;
    }

    function workspace(ref) {
        for (const w of workspaces) if (w.ref === ref) return w;
        return null;
    }
    function windowsOn(ref) { return windows.filter(w => w.workspaceRef === ref); }
    function liveNumericIds() {
        const out = [];
        for (const w of workspaces) if (w.ref.indexOf("id:") === 0) out.push(parseInt(w.ref.slice(3)));
        return out;
    }

    function focusRef(ref, create) { if (backend) backend.focusRef(ref, !!create); }
    function moveWindowTo(windowId, ref, follow, create) { if (backend) backend.moveWindowTo(windowId, ref, !!follow, !!create); }
    function focusWindow(id) { if (backend) backend.focusWindow(id); }
    function closeWindow(id) { if (backend) backend.closeWindow(id); }
    function quit() { if (backend) backend.quit(); }
    function refreshGeometry() { if (backend && backend.refreshGeometry) backend.refreshGeometry(); }

    Loader {
        id: loader
        active: c.kind !== "none"
        source: c.kind === "hyprland" ? "hyprland/Backend.qml" : (c.kind === "niri" ? "niri/Backend.qml" : "")
        onStatusChanged: if (status === Loader.Error) console.warn("[ssh] compositor backend failed to load for " + c.kind)
    }

    Component.onCompleted: {
        if (kind === "none") console.warn("[ssh] no supported compositor detected (Hyprland or Niri). Workspace features are disabled.");
        else console.info("[ssh] compositor backend: " + kind);
    }
}
