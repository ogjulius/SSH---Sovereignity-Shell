import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.themes
import qs.services
import qs.components

// Shown briefly after keyboard traversal: a 3×3 window onto the map that
// slides in the direction of travel, so movement is felt, not just seen.
PanelWindow {
    id: tt
    screen: Surfaces.targetScreen()
    anchors.bottom: true
    margins.bottom: Math.round((screen ? screen.height : 1080) * 0.12)
    implicitWidth: 236
    implicitHeight: 128
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ssh-traverse"
    mask: Region {}

    readonly property var d: Atlas.delta(Atlas.lastDirection)
    property real slide: 1
    Component.onCompleted: slide = 0
    Behavior on slide { enabled: Theme.animate; NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveSpatial } }
    Connections { target: Atlas; function onTraversed() { tt.slide = 1; tt.slide = 0; } }

    Plate { anchors.fill: parent; cut: Theme.cutM; color: Theme.surface(Theme.plate); border: Theme.lineStrong; shine: true }
    RowLayout {
        anchors { fill: parent; margins: Theme.s4 }
        spacing: Theme.s4
        Item {
            Layout.preferredWidth: 3 * 22 + 2 * 4
            Layout.preferredHeight: 3 * 13 + 2 * 4
            clip: true
            Grid {
                x: tt.d[0] * tt.slide * 26
                y: tt.d[1] * tt.slide * 17
                columns: 3; spacing: 4
                Repeater {
                    model: 9
                    Rectangle {
                        required property int index
                        readonly property int gx: Atlas.cursor.x + index % 3 - 1
                        readonly property int gy: Atlas.cursor.y + Math.floor(index / 3) - 1
                        readonly property bool here: index === 4
                        readonly property var c: Atlas.cell(gx, gy)
                        width: 22; height: 13
                        color: here ? Theme.accent : (Atlas.windowCount(gx, gy) > 0 ? Theme.textFaint : "transparent")
                        border.width: here ? 0 : 1
                        border.color: c && c.ref ? Theme.lineStrong : Qt.alpha(Theme.line, 0.7)
                    }
                }
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { role: "micro"; faint: true; text: Atlas.current.name }
            Label { role: "heading"; text: Atlas.label(Atlas.cursor.x, Atlas.cursor.y); color: Theme.accent }
            Label { Layout.fillWidth: true; role: "caption"; dim: true; text: Atlas.cellName(Atlas.cursor.x, Atlas.cursor.y) || (Atlas.windowCount(Atlas.cursor.x, Atlas.cursor.y) + " windows") }
        }
    }
}