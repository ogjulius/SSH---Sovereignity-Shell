import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.components
import "../../themes/Palettes.js" as P

// Accent swatches drawn as chamfered plates, previewing each accent on the
// current ground.
ColumnLayout {
    spacing: Theme.s3
    Label { role: "body"; text: "Accent" }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3
        Repeater {
            model: ["argent", "brass", "ember", "verdigris", "cobalt", "oxblood", "custom"]
            Pressable {
                id: sw
                required property var modelData
                readonly property bool on: Config.appearance.accent === modelData
                readonly property string hex: P.accent(modelData, Theme.dark, Config.appearance.customAccent)
                width: 96; height: 60
                showWash: false
                onClicked: Config.set("appearance.accent", modelData)
                Plate {
                    anchors.fill: parent
                    cut: Theme.cutM
                    color: Theme.sunken
                    border: sw.on ? Theme.accent : (sw.hovered ? Theme.lineStrong : Theme.line)
                    borderWidth: sw.on ? 1.5 : 1
                }
                Plate { x: 10; y: 10; width: 28; height: 18; cut: Theme.cutS; color: sw.hex; borderWidth: 0 }
                Label { anchors { left: parent.left; bottom: parent.bottom; margins: 10 } role: "micro"; text: sw.modelData; color: sw.on ? Theme.text : Theme.textDim }
            }
        }
    }
    RowLayout {
        visible: Config.appearance.accent === "custom"
        OptionRow { Layout.fillWidth: true; opt: ({ path: "appearance.customAccent", label: "Custom accent", help: "#rrggbb" }) }
    }
}
