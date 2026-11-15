import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components
import "../settings/Keybinds.js" as KB

// First-run hint: points at the cheatsheet key once. Gone for good after it
// is dismissed (×) or the cheatsheet is opened; stored as
// firstRun.cheatsheetHint in the config, so it never nags.
RowLayout {
    id: h
    readonly property string keys: KB.pretty(Config.keybinds.cheatsheet)
    visible: Config.loaded && Config.firstRun.cheatsheetHint
    spacing: 0
    Pressable {
        Layout.fillHeight: true
        implicitWidth: label.implicitWidth + Theme.s4
        onClicked: Surfaces.open("cheatsheet")
        Label {
            id: label
            anchors.centerIn: parent
            role: "micro"
            color: Theme.accent
            text: h.keys === "unbound" ? "Keys: ssh-shell keybinds list" : "Keys · " + h.keys
        }
    }
    IconButton {
        icon: "close"; iconSize: 11
        tint: Theme.textFaint
        onClicked: Config.set("firstRun.cheatsheetHint", false)
    }
}
