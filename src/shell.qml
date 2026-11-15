//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configuration
import qs.services
import qs.compositors
import qs.modules.meridian
import qs.modules.launcher
import qs.modules.instruments
import qs.modules.almanac
import qs.modules.signals
import qs.modules.power
import qs.modules.lens
import qs.modules.atlas
import qs.modules.osd
import qs.modules.settings
import "modules/settings/Keybinds.js" as Keybinds

// SSH — Sovereignity Shell.
//
// Always resident: the Meridian (one per screen) and the services it reads.
// Everything else is created on demand by a LazyLoader and destroyed after
// it closes. See docs/ARCHITECTURE.md.
ShellRoot {
    id: root

    // ── Resident ──────────────────────────────────────────────────────
    Variants {
        model: Quickshell.screens.filter(s => Config.meridian.monitors.length === 0 || Config.meridian.monitors.indexOf(s.name) >= 0)
        Meridian {}
    }

    // ── Surfaces (one open at a time; see services/Surfaces.qml) ──────
    LazyLoader { active: Surfaces.loaded.lens === true && Config.lens.enabled; Lens {} }
    LazyLoader { active: Surfaces.loaded.atlas === true && Atlas.enabled; AtlasSurface {} }
    LazyLoader { active: Surfaces.loaded.launcher === true; Launcher {} }
    LazyLoader { active: Surfaces.loaded.instruments === true; Instruments {} }
    LazyLoader { active: Surfaces.loaded.almanac === true; Almanac {} }
    LazyLoader { active: Surfaces.loaded.signals === true; Signals {} }
    LazyLoader { active: Surfaces.loaded.power === true; PowerMenu {} }
    LazyLoader { active: SettingsHub.shown; SettingsWindow {} }

    // Disabled surfaces must not leave a dangling "active" state.
    Connections {
        target: Surfaces
        function onActiveChanged() {
            if ((Surfaces.active === "lens" && !Config.lens.enabled) || (Surfaces.active === "atlas" && !Atlas.enabled))
                Surfaces.close();
        }
    }

    // ── Transient overlays ────────────────────────────────────────────
    LazyLoader { active: Notifs.popups.length > 0; Toasts {} }

    property string osdKind: ""
    property bool settled: false        // ignore the burst of change signals at startup
    Timer { interval: 2500; running: true; onTriggered: root.settled = true }
    Timer { id: osdTimer; interval: Config.osd.timeout; onTriggered: root.osdKind = "" }
    function showOsd(kind) {
        if (!settled || !Config.osd.enabled || Surfaces.active === "instruments") return;
        osdKind = kind;
        osdTimer.restart();
    }
    Connections { target: Audio; function onVolumeEvent() { root.showOsd("volume"); } }
    Connections { target: Brightness; function onChangedByUser() { root.showOsd("brightness"); } }
    LazyLoader { active: root.osdKind !== ""; Osd { kind: root.osdKind } }

    property bool traverseShown: false
    Timer { id: traverseTimer; interval: 1100; onTriggered: root.traverseShown = false }
    Connections {
        target: Atlas
        function onTraversed() {
            if (!Config.atlas.traverseToast || Surfaces.active === "atlas" || Surfaces.active === "lens") return;
            root.traverseShown = true;
            traverseTimer.restart();
        }
    }
    LazyLoader { active: root.traverseShown; TraverseToast {} }

    // ── IPC: `ssh-shell <target> <function> [args]` ───────────────────
    // (wrapper for `qs -p <path> ipc call ...`). Bind these in your compositor.
    IpcHandler {
        target: "lens"
        function toggle(): void { Surfaces.toggle("lens"); }
        function open(): void { Surfaces.open("lens"); }
        function close(): void { Surfaces.close(); }
    }
    IpcHandler {
        target: "launcher"
        function toggle(): void { Surfaces.toggle("launcher"); }
    }
    IpcHandler {
        target: "atlas"
        function toggle(): void { Surfaces.toggle("atlas"); }
        function traverse(direction: string): void { Atlas.traverse(direction); }
        function carry(direction: string): void { Atlas.carry(direction); }
        function goto(x: int, y: int): void { Atlas.goto(x, y); }
        function collection(step: int): void { Atlas.cycleCollection(step); }
        function where(): string { return Atlas.current.name + " " + Atlas.label(Atlas.cursor.x, Atlas.cursor.y); }
    }
    IpcHandler {
        target: "panel"
        // instruments | almanac | signals | power
        function toggle(name: string): void { Surfaces.toggle(name); }
        function close(): void { Surfaces.close(); }
    }
    IpcHandler {
        target: "audio"
        function up(): void { Audio.step(0.05); }
        function down(): void { Audio.step(-0.05); }
        function mute(): void { Audio.toggleMute(); }
        function mic(): void { Audio.toggleMic(); root.showOsd("mic"); }
    }
    IpcHandler {
        target: "brightness"
        function up(): void { Brightness.step(0.05); }
        function down(): void { Brightness.step(-0.05); }
    }
    IpcHandler {
        target: "notifications"
        function quiet(): void { Notifs.setDnd(!Notifs.dnd); }
        function clear(): void { Notifs.clearAll(); }
    }
    IpcHandler {
        target: "settings"
        function open(): void { SettingsHub.open(); }
        function toggle(): void { SettingsHub.toggle(); }
    }
    IpcHandler {
        target: "shell"
        // Machine-readable status, used by scripts/benchmark and bug reports.
        function status(): string {
            return JSON.stringify({
                compositor: Compositor.kind, connected: Compositor.connected,
                workspaces: Compositor.workspaces.length, windows: Compositor.windows.length,
                focus: { workspace: Compositor.focusedWorkspaceRef, window: Compositor.focusedWindowId, output: Compositor.focusedOutput },
                surface: Surfaces.active, loaded: Object.keys(Surfaces.loaded),
                atlas: { enabled: Atlas.enabled, collection: Atlas.current.name, cursor: Atlas.cursor, collections: Atlas.collections.length },
                notifications: { serving: Notifs.serving, history: Notifs.history.length, popups: Notifs.popups.length, dnd: Notifs.dnd },
                configWarnings: Config.warnings.length, configError: Config.loadError
            });
        }
        function open(surface: string): void { Surfaces.open(surface); }
        // Keybind block for your compositor from the `shortcuts` options:
        // target = hyprland | hyprland-lua | niri
        function keybinds(target: string): string { return Keybinds.generate(target, Config.shortcuts); }
        // Content geometry of the open surface, relative to its window, as
        // "x,y WxH". Add the window's position (hyprctl layers / niri msg) for screen coordinates.
        function rect(): string {
            const r = Surfaces.contentRect;
            return Surfaces.active && r ? r.x + "," + r.y + " " + r.w + "x" + r.h : "";
        }
    }
}
