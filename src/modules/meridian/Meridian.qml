import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.configuration

// The Meridian: SSH's bar. A flush instrument strip, not a floating pill.
// Left: position (sigil, collection, coordinate, minimap, row).
// Centre: the focused window. Right: instruments, signals, time.
// The ruler-tick edge is its signature.
PanelWindow {
    id: win
    required property var modelData
    screen: modelData

    readonly property bool top: Config.meridian.position === "top"
    anchors { left: true; right: true; top: win.top; bottom: !win.top }
    implicitHeight: Config.meridian.height
    exclusiveZone: Config.meridian.height
    color: "transparent"
    WlrLayershell.namespace: "ssh-meridian"
    WlrLayershell.layer: WlrLayer.Top

    MeridianContent {
        anchors.fill: parent
        screen: win.screen
        barWindow: win
    }
}
