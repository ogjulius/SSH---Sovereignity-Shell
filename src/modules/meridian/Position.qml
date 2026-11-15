import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.services
import qs.components
import qs.compositors
import "../../utilities/Fmt.js" as Fmt

// "II · STUDIO   C2  Writing" — where you are on the map.
Pressable {
    id: pos
    property var screen
    readonly property int collIndex: Atlas.collections.findIndex(c => c.id === Atlas.current.id) + 1
    readonly property string cellName: Atlas.cellName(Atlas.cursor.x, Atlas.cursor.y)
    implicitWidth: row.implicitWidth + Theme.s4
    onClicked: Surfaces.toggle("atlas", pos.screen)

    RowLayout {
        id: row
        anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: Theme.s2 }
        spacing: Theme.s3
        Label { role: "micro"; faint: true; text: Atlas.enabled ? Fmt.roman(pos.collIndex) + " · " + Atlas.current.name : Compositor.displayName }
        Label {
            visible: Atlas.enabled
            role: "data"; color: Theme.accent
            text: Atlas.label(Atlas.cursor.x, Atlas.cursor.y)
            font.weight: Font.DemiBold
        }
        Label {
            visible: !Atlas.enabled
            role: "data"
            text: Compositor.workspace(Compositor.focusedWorkspaceRef) ? Compositor.workspace(Compositor.focusedWorkspaceRef).name : "—"
        }
        Label { visible: pos.cellName.length > 0; role: "caption"; dim: true; text: pos.cellName; Layout.maximumWidth: 140 }
    }
}
