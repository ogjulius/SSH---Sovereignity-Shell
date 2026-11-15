import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

ColumnLayout {
    spacing: Theme.s3
    SectionMark { Layout.fillWidth: true; text: "Collections" }
    Label { Layout.fillWidth: true; role: "caption"; faint: true; wrapMode: Text.WordWrap
        text: "Each collection is its own plane on the map. Removing one forgets its layout; the workspaces themselves stay open." }
    Repeater {
        model: Atlas.collections
        RowLayout {
            id: cr
            required property var modelData
            required property int index
            Layout.fillWidth: true
            spacing: Theme.s4
            Label { role: "micro"; faint: true; text: Fmt.roman(cr.index + 1); Layout.preferredWidth: 28 }
            Field {
                Layout.fillWidth: true
                icon: ""
                text: cr.modelData.name
                onAccepted: Atlas.renameCollection(cr.modelData.id, text)
            }
            Label { role: "micro"; faint: true; text: Object.keys(cr.modelData.cells).length + " cells" }
            IconButton { icon: "trash"; enabled_: Atlas.collections.length > 1; onClicked: Atlas.removeCollection(cr.modelData.id) }
        }
    }
    Pressable {
        implicitWidth: addRow.implicitWidth + Theme.s5; implicitHeight: 28
        onClicked: Atlas.addCollection("")
        RowLayout { id: addRow; anchors.centerIn: parent; spacing: Theme.s2
            Icon { name: "plus"; size: 12; color: Theme.accent }
            Label { role: "caption"; text: "New collection"; color: Theme.accent } }
    }
}
