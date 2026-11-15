import QtQuick
import qs.themes

// Base for every clickable surface: hover/press washes, keyboard activation,
// focus ring. Content goes inside as children.
Item {
    id: p
    signal clicked(var mouse)
    signal rightClicked
    signal middleClicked

    property bool enabled_: true
    property bool hovered: area.containsMouse
    property bool pressed: area.pressed
    property bool highlighted: false
    property bool showWash: true
    property real cut: Theme.cutS
    property alias cursorShape: area.cursorShape
    property alias acceptedButtons: area.acceptedButtons

    activeFocusOnTab: true
    opacity: enabled_ ? 1 : 0.4

    Keys.onReturnPressed: if (enabled_) clicked(null)
    Keys.onSpacePressed: if (enabled_) clicked(null)

    Plate {
        anchors.fill: parent
        visible: p.showWash && (p.hovered || p.pressed || p.highlighted || p.activeFocus)
        cut: p.cut
        color: p.pressed ? Theme.press : (p.highlighted ? Theme.accentWash : Theme.hover)
        border: p.activeFocus ? Theme.accent : "transparent"
        borderWidth: p.activeFocus ? 1 : 0
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: p.enabled_
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: mouse => {
            if (mouse.button === Qt.RightButton) p.rightClicked();
            else if (mouse.button === Qt.MiddleButton) p.middleClicked();
            else p.clicked(mouse);
        }
    }
}
