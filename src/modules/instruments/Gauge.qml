import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.components
import "../../utilities/Fmt.js" as Fmt

ColumnLayout {
    id: g
    property string icon: "speaker"
    property string title: ""
    property string detail: ""
    property real value: 0
    property bool muted: false
    property bool available: true
    signal moved(real v)
    signal iconClicked
    signal detailClicked
    Layout.fillWidth: true
    spacing: Theme.s2
    opacity: available ? 1 : 0.45

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.s3
        IconButton { icon: g.icon; iconSize: 15; tint: g.muted ? Theme.textFaint : Theme.text; implicitWidth: 24; implicitHeight: 24; onClicked: g.iconClicked() }
        Label { role: "caption"; text: g.title; font.weight: Font.Medium }
        Pressable {
            Layout.fillWidth: true
            implicitHeight: 22
            showWash: hovered
            onClicked: g.detailClicked()
            Label { anchors { fill: parent; leftMargin: Theme.s2; rightMargin: Theme.s2 } role: "caption"; faint: true; text: g.detail }
        }
        Label { role: "data"; text: Fmt.percent(g.value); dim: true; Layout.preferredWidth: 36; horizontalAlignment: Text.AlignRight }
    }
    InstrumentSlider {
        Layout.fillWidth: true
        Layout.leftMargin: 30
        value: g.value
        muted: g.muted
        onMoved: v => g.moved(v)
    }
}
