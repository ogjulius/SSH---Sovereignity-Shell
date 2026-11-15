import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.components
import qs.compositors
import "Keybinds.js" as KB

// SSH does not grab keys itself: your compositor owns keybinds. This panel
// generates the binding block for Hyprland or Niri from your choices.
ColumnLayout {
    spacing: Theme.s4
    property string target: Compositor.kind === "niri" ? "niri" : (Compositor.backend && Compositor.backend.lua ? "hyprland-lua" : "hyprland")
    readonly property string snippet: KB.generate(target, Config.shortcuts)

    Label { Layout.fillWidth: true; role: "caption"; faint: true; wrapMode: Text.WordWrap
        text: "In the Sovereignity Shell login sessions these keys are bound automatically; a key your compositor config already uses keeps its own action. Elsewhere, paste the generated block into your compositor config (also `ssh-shell keybinds <target>`). SSH never edits compositor files." }
    OptionRow { Layout.fillWidth: true; opt: ({ path: "session.keybinds", label: "Bind automatically in SSH sessions" }) }
    Repeater {
        model: ["lens", "launcher", "atlas", "instruments", "power", "traverse", "carry"]
        OptionRow {
            required property var modelData
            Layout.fillWidth: true
            opt: ({ path: "shortcuts." + modelData, label: ({ lens: "Lens", launcher: "Launcher", atlas: "Atlas", instruments: "Instruments", power: "Power menu", traverse: "Travel modifier (+ arrows)", carry: "Carry modifier (+ arrows)" })[modelData] })
        }
    }
    RowLayout {
        spacing: Theme.s2
        Repeater {
            model: ["hyprland", "hyprland-lua", "niri"]
            Pressable {
                required property var modelData
                width: tl.implicitWidth + Theme.s5; height: 26
                highlighted: parent.parent.target === modelData
                onClicked: parent.parent.target = modelData
                Label { id: tl; anchors.centerIn: parent; role: "micro"; text: modelData }
            }
        }
        Item { Layout.fillWidth: true }
        Pressable {
            width: cl.implicitWidth + Theme.s5; height: 26
            onClicked: { Quickshell.clipboardText = parent.parent.snippet; cl.text = "Copied"; }
            Label { id: cl; anchors.centerIn: parent; role: "micro"; text: "Copy"; color: Theme.accent }
        }
    }
    Item {
        Layout.fillWidth: true
        implicitHeight: code.implicitHeight + Theme.s5 * 2
        Plate { anchors.fill: parent; cut: Theme.cutS; color: Theme.sunken }
        TextEdit {
            id: code
            x: Theme.s5; y: Theme.s5
            width: parent.width - Theme.s5 * 2
            readOnly: true; selectByMouse: true
            text: parent.parent.snippet
            color: Theme.textDim
            font.family: Theme.fontMono; font.pixelSize: Theme.sizeCaption
            wrapMode: TextEdit.NoWrap
        }
    }
}
