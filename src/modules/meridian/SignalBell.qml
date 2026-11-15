import QtQuick
import qs.themes
import qs.services
import qs.components

Pressable {
    id: s
    signal activated
    implicitWidth: 30
    highlighted: Surfaces.isOpen("signals")
    onClicked: activated()
    onRightClicked: Notifs.setDnd(!Notifs.dnd)
    Icon { anchors.centerIn: parent; name: Notifs.dnd ? "bellOff" : "bell"; size: 15; color: Notifs.dnd ? Theme.textFaint : Theme.text }
    Rectangle {
        visible: Notifs.unread > 0 && !Notifs.dnd
        width: 5; height: 5
        color: Theme.accent
        anchors { right: parent.right; top: parent.top; rightMargin: 7; topMargin: 8 }
    }
}
