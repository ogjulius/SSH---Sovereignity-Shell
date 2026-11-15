import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.themes
import qs.configuration
import qs.services
import qs.components

// Notification popups. The window exists only while there is something to
// show, and its input region covers only the cards.
PanelWindow {
    id: t
    readonly property string pos: Config.notifications.position
    readonly property bool atTop: pos.indexOf("top") === 0
    screen: {
        for (const s of Quickshell.screens) if (s.name === Surfaces.targetScreen()?.name) return s;
        return Quickshell.screens[0];
    }
    anchors {
        top: t.atTop; bottom: !t.atTop
        right: t.pos.indexOf("right") >= 0
        left: t.pos.indexOf("left") >= 0
    }
    margins { top: Theme.s3; bottom: Theme.s3; left: Theme.s3; right: Theme.s3 }
    implicitWidth: 372
    implicitHeight: stack.implicitHeight
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ssh-toasts"
    exclusionMode: ExclusionMode.Normal

    ColumnLayout {
        id: stack
        width: parent.width
        spacing: Theme.s3
        Repeater {
            model: Notifs.popups
            NotificationCard {
                id: card
                required property var modelData
                required property int index
                record: modelData
                popup: true
                Layout.fillWidth: true
                opacity: 0
                Component.onCompleted: opacity = 1
                Behavior on opacity { enabled: Theme.animate; NumberAnimation { duration: Theme.durStd } }
                Timer {
                    running: !card.critical && !hoverWatch.hovered
                    interval: Config.notifications.timeout
                    onTriggered: Notifs.dropPopup(card.record.id)
                }
                HoverHandler { id: hoverWatch }
            }
        }
    }
}
