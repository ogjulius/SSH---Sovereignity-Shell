import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components
import "../settings/Keybinds.js" as KB

// Every SSH keybind with its command, from the same table the compositor
// blocks are generated from, so it can never disagree with them.
FocusScope {
    id: cs
    focus: true
    implicitWidth: grid.implicitWidth + Theme.s6 * 2
    implicitHeight: col.implicitHeight + Theme.s6 * 2
    readonly property var rows: KB.table(Config.keybinds)

    // Seeing the cheatsheet once is what the first-run hint asks for.
    // Deferred: never change config while a surface is being constructed.
    Component.onCompleted: if (Config.firstRun.cheatsheetHint) Qt.callLater(() => Config.set("firstRun.cheatsheetHint", false))

    Plate { anchors.fill: parent; cut: Theme.cutL; color: Theme.surface(Theme.plate); border: Theme.lineStrong }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Theme.s5
        RowLayout {
            Layout.fillWidth: true
            Label { role: "title"; text: "Keys" }
            Item { Layout.fillWidth: true }
            Label { role: "micro"; faint: true; text: "Esc to close · change in Settings → Keys" }
        }
        GridLayout {
            id: grid
            columns: 3
            columnSpacing: Theme.s5
            rowSpacing: Theme.s2
            // Three cells per row: keys · action · command.
            Repeater {
                model: cs.rows.length * 3
                delegate: Label {
                    required property int index
                    readonly property var row: cs.rows[Math.floor(index / 3)]
                    readonly property int column: index % 3
                    role: column === 0 ? "data" : (column === 1 ? "body" : "caption")
                    color: column === 0 ? (row.keys === "unbound" ? Theme.textFaint : Theme.accent) : (column === 2 ? Theme.textFaint : Theme.text)
                    text: column === 0 ? row.keys : (column === 1 ? row.label : row.verb)
                }
            }
        }
    }
}
