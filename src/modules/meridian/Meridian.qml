import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.configuration
import qs.themes

// The Meridian: SSH's bar. Two readings, from `meridian.style`:
//   island — a floating strip, inset from the screen edges
//   flush  — a full-width instrument strip with the ruler-tick edge
// Left: position (sigil, collection, coordinate, minimap, row).
// Centre: the focused window. Right: instruments, signals, time.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property bool top: Config.meridian.position === "top"
    readonly property bool island: Config.meridian.style === "island"
    // The gap an island leaves to the screen edges; flush keeps none.
    readonly property int gap: island ? Math.max(4, Theme.gap) : 0

    anchors { left: true; right: true; top: win.top; bottom: !win.top }
    margins { left: win.gap; right: win.gap }
    implicitHeight: Config.meridian.height + win.gap
    exclusiveZone: Config.meridian.height + win.gap
    color: "transparent"
    WlrLayershell.namespace: "ssh-meridian"
    WlrLayershell.layer: WlrLayer.Top

    MeridianContent {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            bottom: parent.bottom
            topMargin: win.top ? win.gap : 0
            bottomMargin: win.top ? 0 : win.gap
        }
        screen: win.screen
        barWindow: win
        island: win.island
    }
}
