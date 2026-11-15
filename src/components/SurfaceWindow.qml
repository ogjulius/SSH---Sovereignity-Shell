import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.themes
import qs.services

// The one window type every SSH surface uses.
//
// One lifecycle: created lazily by Surfaces, enters with the shared motion
// (fade + 6px settle), exits the same way, then asks Surfaces to destroy it.
// One set of rules: Esc closes, clicking outside closes, keyboard focus is
// exclusive while open. Surfaces differ only in placement and content.
PanelWindow {
    id: win

    required property string name
    property Component content
    property real dim: 0
    // "center" | "top" (launcher-like) | "anchor" (below a bar item) | "fill"
    property string placement: "center"
    property bool coverBar: false

    readonly property bool shown: Surfaces.active === name
    property real progress: 0
    readonly property var anchorRect: Surfaces.anchorRect
    readonly property alias contentItem: loader.item

    screen: {
        for (const s of Quickshell.screens) if (s.name === Surfaces.screenName) return s;
        return Quickshell.screens[0];
    }
    anchors { left: true; right: true; top: true; bottom: true }
    exclusionMode: coverBar ? ExclusionMode.Ignore : ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ssh-" + name
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    Behavior on progress {
        enabled: Theme.animate
        NumberAnimation { duration: win.shown ? Theme.durStd : Theme.durMicro + 30; easing.type: Easing.BezierSpline; easing.bezierCurve: win.shown ? Theme.curveEnter : Theme.curveExit }
    }
    onProgressChanged: if (!shown && progress <= 0) Surfaces.release(name)
    onShownChanged: if (!shown && !Theme.animate) Surfaces.release(name)
    Component.onCompleted: progress = Qt.binding(() => win.shown ? 1 : 0)

    Rectangle {
        anchors.fill: parent
        color: Theme.void_
        opacity: win.dim * win.progress
    }
    MouseArea {
        anchors.fill: parent
        onClicked: Surfaces.close(win.name)
    }

    FocusScope {
        id: host
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: Surfaces.close(win.name)

        Loader {
            id: loader
            focus: true
            sourceComponent: win.content
            opacity: win.progress
            transform: Translate { y: (1 - win.progress) * (win.placement === "anchor" ? -6 : 8) }
            x: {
                if (!item) return 0;
                if (win.placement === "anchor") {
                    // Without a bar anchor (opened by keybind/IPC), sit at the right edge
                    // where the Meridian's instrument cluster lives.
                    if (!win.anchorRect) return host.width - item.width - Theme.s3;
                    const want = win.anchorRect.x + win.anchorRect.w / 2 - item.width / 2;
                    return Math.max(Theme.s3, Math.min(want, host.width - item.width - Theme.s3));
                }
                if (win.placement === "fill") return 0;
                return Math.round((host.width - item.width) / 2);
            }
            y: {
                if (!item) return 0;
                if (win.placement === "anchor") return Theme.s3;
                if (win.placement === "top") return Math.round(host.height * 0.16);
                if (win.placement === "fill") return 0;
                return Math.round((host.height - item.height) / 2);
            }
            width: win.placement === "fill" ? host.width : (item ? item.implicitWidth : 0)
            height: win.placement === "fill" ? host.height : (item ? item.implicitHeight : 0)
            // Report the content rectangle, relative to this surface's window, for
            // tooling such as scripts/capture-screenshots.sh (`ssh-shell shell rect`).
            // The window's own screen position comes from the compositor.
            function publishRect() {
                if (!win.shown || !item) return;
                const p = mapToItem(null, 0, 0);
                Surfaces.contentRect = { x: Math.round(p.x), y: Math.round(p.y), w: Math.round(width), h: Math.round(height) };
            }
            onXChanged: publishRect()
            onYChanged: publishRect()
            onWidthChanged: publishRect()
            onHeightChanged: publishRect()
            onLoaded: publishRect()
            // Swallow clicks inside content so they don't close the surface.
            MouseArea { anchors.fill: parent; z: -1; onClicked: {} }
        }
    }
}
