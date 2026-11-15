import QtQuick
import qs.themes

Pressable {
    id: b
    property string icon: "dots"
    property real iconSize: 16
    property color tint: highlighted ? Theme.accent : Theme.text
    implicitWidth: iconSize + Theme.s4
    implicitHeight: iconSize + Theme.s4

    Icon { anchors.centerIn: parent; name: b.icon; size: b.iconSize; color: b.tint }
}
