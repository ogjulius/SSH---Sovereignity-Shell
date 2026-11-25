import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.themes
import qs.services
import qs.components
import qs.compositors

// A neighbouring cell in the Lens compass. Shows where travel would land.
Pressable {
    id: n
    property string dir: "up"
    readonly property var d: Atlas.delta(dir)
    readonly property int gx: Atlas.cursor.x + d[0]
    readonly property int gy: Atlas.cursor.y + d[1]
    readonly property var c: Atlas.cell(gx, gy)
    readonly property var ws: Atlas.workspaceAt(gx, gy)
    readonly property var wins: c && c.ref ? Compositor.windowsOn(c.ref) : []
    showWash: false
    implicitWidth: 196
    implicitHeight: 76
    onClicked: Atlas.traverse(dir)

    Plate {
        anchors.fill: parent
        cut: Theme.cutS
        color: n.hovered ? Theme.raised : Theme.surface(Theme.plate)
        border: n.hovered ? Theme.lineStrong : Theme.line
    }
    ColumnLayout {
        anchors { fill: parent; margins: Theme.s4 }
        spacing: Theme.s1
        RowLayout {
            spacing: Theme.s3
            Icon { name: ({ up: "chevronUp", down: "chevronDown", left: "chevronLeft", right: "chevronRight" })[n.dir]; size: 12; color: Theme.textFaint }
            Label { role: "micro"; color: Theme.textDim; text: Atlas.label(n.gx, n.gy) }
            Item { Layout.fillWidth: true }
            Label { role: "micro"; faint: true; text: "alt " + ({ up: "↑", down: "↓", left: "←", right: "→" })[n.dir] }
        }
        Label { Layout.fillWidth: true; role: "body"; text: n.c && n.c.name ? n.c.name : (n.c && n.c.ref ? "Unnamed" : "Open territory"); dim: !(n.c && n.c.ref) }
        Row {
            spacing: Theme.s2
            Repeater {
                model: n.wins.slice(0, 6)
                IconImage { required property var modelData; implicitSize: 14; source: Apps.iconFor(modelData.appId) }
            }
            Label { role: "micro"; dim: true; visible: n.wins.length === 0; text: n.c && n.c.ref ? "empty" : "claim on arrival" }
        }
    }
}
