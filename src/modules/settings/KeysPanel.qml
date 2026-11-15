import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors
import "Keybinds.js" as KB

// Every SSH keybind: the key (a schema option, editable), the CLI verb it runs
// and what it does, from the table in Keybinds.js. Outside the SSH login
// sessions the compositor owns keybinds, so the panel also generates the
// block to paste for Hyprland (classic or Lua) or Niri. See docs/KEYBINDS.md.
ColumnLayout {
    spacing: Theme.s4
    property string target: Compositor.kind === "niri" ? "niri" : (Compositor.backend && Compositor.backend.lua ? "hyprland-lua" : "hyprland")
    readonly property string snippet: KB.generate(target, Config.keybinds)

    Label { Layout.fillWidth: true; role: "caption"; faint: true; wrapMode: Text.WordWrap
        text: "In the Sovereignity Shell login sessions these keys are bound automatically; a key your compositor config already uses keeps its own action. Elsewhere, paste the generated block into your compositor config (also `ssh-shell keybinds <target>`). SSH never edits compositor files." }
    OptionRow { Layout.fillWidth: true; opt: ({ path: "session.keybinds", label: "Bind automatically in SSH sessions" }) }
    Repeater {
        // Static rows (labels, verbs): editing a key must not rebuild the list.
        model: KB.table({}).filter(r => r.action !== "close")
        OptionRow {
            required property var modelData
            Layout.fillWidth: true
            opt: ({ path: "keybinds." + modelData.action, label: modelData.label,
                    help: modelData.description + " · " + modelData.verb + (modelData.action === "traverse" || modelData.action === "carry" ? " (modifiers only)" : "") })
        }
    }
    Label { Layout.fillWidth: true; role: "caption"; faint: true; wrapMode: Text.WordWrap
        text: "Keys use Hyprland notation, \"MODS, KEY\" (e.g. SUPER SHIFT, ESCAPE). Leave a field empty to unbind it. Esc always closes the open SSH surface." }
    OptionRow { Layout.fillWidth: true; opt: ({ path: "firstRun.cheatsheetHint", label: "Cheatsheet hint in the Meridian", help: "Shown until dismissed or the cheatsheet is opened." }) }
    Pressable {
        width: oc.implicitWidth + Theme.s5; height: 26
        onClicked: Surfaces.open("cheatsheet")
        Label { id: oc; anchors.centerIn: parent; role: "micro"; text: "Open cheatsheet"; color: Theme.accent }
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
