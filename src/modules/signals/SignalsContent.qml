import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.services
import qs.components

// Signals: notification history, grouped by sender.
FocusScope {
    id: sc
    implicitWidth: 392
    implicitHeight: Math.min(640, col.implicitHeight + Theme.s5 * 2)
    focus: true
    Component.onCompleted: Notifs.markRead()

    Plate { anchors.fill: parent; cut: Theme.cutL; color: Theme.surface(Theme.plate); border: Theme.lineStrong }

    ColumnLayout {
        id: col
        anchors { fill: parent; margins: Theme.s5 }
        spacing: Theme.s4
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                spacing: 0
                Label { role: "micro"; faint: true; text: "Signals" }
                Label { role: "lead"; text: Notifs.history.length === 0 ? "All quiet" : Notifs.history.length + (Notifs.history.length === 1 ? " notification" : " notifications") }
            }
            Item { Layout.fillWidth: true }
            Label { role: "micro"; faint: true; text: "Quiet" }
            Toggle { checked: Notifs.dnd; onToggled: v => Notifs.setDnd(v) }
            IconButton { icon: "trash"; visible: Notifs.history.length > 0; onClicked: Notifs.clearAll() }
        }
        Label {
            visible: !Notifs.serving
            Layout.fillWidth: true
            wrapMode: Text.WordWrap
            role: "caption"; faint: true
            text: "SSH is not the notification daemon in this session (another daemon owns org.freedesktop.Notifications, or notifications are disabled)."
        }
        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: list.implicitHeight
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: list
                width: parent.width
                spacing: Theme.s4
                Repeater {
                    model: Notifs.groups
                    ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: Theme.s2
                        SectionMark { Layout.fillWidth: true; text: modelData.app; index: String(modelData.items.length).padStart(2, "0") }
                        Repeater {
                            model: modelData.items.slice(0, 6)
                            NotificationCard { required property var modelData; record: modelData; Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }
}
