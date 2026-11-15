import QtQuick
import qs.themes
import qs.services
import qs.components

// A 5×3 window onto the Atlas around the cursor. Filled = occupied,
// outlined = bound but empty, dot = open territory, accent = here.
Pressable {
    id: mm
    property var screen
    readonly property int cols: 5
    readonly property int rows: 3
    readonly property int cell: 7
    readonly property int gap: 3
    implicitWidth: cols * cell + (cols - 1) * gap + 8
    implicitHeight: rows * cell + (rows - 1) * gap + 8
    onClicked: Surfaces.toggle("atlas", mm.screen)

    Grid {
        anchors.centerIn: parent
        columns: mm.cols
        spacing: mm.gap
        Repeater {
            model: mm.cols * mm.rows
            Item {
                id: c
                required property int index
                readonly property int gx: Atlas.cursor.x + (index % mm.cols) - 2
                readonly property int gy: Atlas.cursor.y + Math.floor(index / mm.cols) - 1
                readonly property bool here: gx === Atlas.cursor.x && gy === Atlas.cursor.y
                readonly property var bound: Atlas.cell(gx, gy)
                readonly property int count: Atlas.windowCount(gx, gy)
                width: mm.cell; height: mm.cell
                Rectangle {
                    anchors.fill: parent
                    visible: c.here || (c.bound !== null && c.bound.ref !== undefined)
                    color: c.here ? Theme.accent : (c.count > 0 ? Theme.textDim : "transparent")
                    border.width: c.here || c.count > 0 ? 0 : 1
                    border.color: Theme.lineStrong
                }
                Rectangle {
                    visible: !c.here && !(c.bound !== null && c.bound.ref !== undefined)
                    anchors.centerIn: parent
                    width: 1; height: 1
                    color: Theme.textFaint
                }
            }
        }
    }
}
