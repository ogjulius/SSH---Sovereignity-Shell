import QtQuick
import QtQuick.Layouts
import qs.themes

// A quick-toggle tile ("key"): glyph, label, state line. Active keys get
// the accent wash and an accent corner mark rather than a full colour fill.
Pressable {
    id: k
    property string icon: "dots"
    property string label: ""
    property string detail: ""
    property bool active: false
    property bool available: true
    enabled_: available
    showWash: false
    implicitHeight: 72
    implicitWidth: 96

    Plate {
        anchors.fill: parent
        cut: Theme.cutS
        cutTL: 0; cutBR: Theme.cutM
        color: k.active ? Theme.accentWash : (k.hovered || k.activeFocus ? Theme.raised : Theme.sunken)
        border: k.active ? Qt.alpha(Theme.accent, 0.55) : (k.activeFocus ? Theme.accent : Theme.line)
    }
    Rectangle { // corner mark
        visible: k.active
        width: 6; height: 6
        anchors { top: parent.top; right: parent.right; margins: 6 }
        color: Theme.accent
    }
    ColumnLayout {
        anchors { fill: parent; margins: Theme.s4; bottomMargin: Theme.s3 }
        spacing: 0
        Icon { name: k.icon; size: 18; color: k.active ? Theme.accent : Theme.text }
        Item { Layout.fillHeight: true }
        Label { Layout.fillWidth: true; text: k.label; role: "caption"; font.weight: Font.Medium }
        Label { Layout.fillWidth: true; text: k.detail; role: "micro"; faint: true; visible: text.length > 0 }
    }
}
