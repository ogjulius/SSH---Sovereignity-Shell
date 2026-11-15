import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.themes
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

// One notification. Critical urgency gets a left critical rule, never a
// red flood. Clicking the body runs the default action if there is one.
Item {
    id: card
    required property var record
    property bool popup: false
    implicitWidth: 360
    implicitHeight: body.implicitHeight + Theme.s4 * 2
    readonly property bool critical: record.urgency === NotificationUrgency.Critical
    readonly property var defaultAction: record.actions.find(a => a.id === "default") || null
    readonly property var buttons: record.actions.filter(a => a.id !== "default")

    Plate {
        anchors.fill: parent
        cut: Theme.cutM; cutTL: 0
        color: card.popup ? Theme.surface(Theme.plate) : (hover.hovered ? Theme.raised : Theme.sunken)
        border: card.popup ? Theme.lineStrong : Theme.line
    }
    Rectangle { visible: card.critical; width: 2; anchors { left: parent.left; top: parent.top; bottom: parent.bottom; topMargin: 6; bottomMargin: 6 } color: Theme.critical }
    HoverHandler { id: hover }
    TapHandler {
        onTapped: {
            if (card.defaultAction) Notifs.invoke(card.record.id, "default");
            else if (card.popup) Notifs.dropPopup(card.record.id);
        }
    }

    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s4 }
        spacing: Theme.s2
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s3
            IconImage {
                implicitSize: 14
                source: card.record.appIcon ? Quickshell.iconPath(card.record.appIcon, true) : ""
                visible: source.toString().length > 0
            }
            Label { role: "micro"; faint: true; text: card.record.app; Layout.fillWidth: true }
            Label { role: "micro"; faint: true; text: Fmt.relativeTime(card.record.time, Time.now.getTime()) }
            IconButton { icon: "close"; iconSize: 11; implicitWidth: 20; implicitHeight: 20; visible: hover.hovered; onClicked: card.popup ? Notifs.dropPopup(card.record.id) : Notifs.dismiss(card.record.id) }
        }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s4
            Image {
                visible: card.record.image.length > 0 && status === Image.Ready
                source: card.record.image
                sourceSize.width: 96; sourceSize.height: 96
                Layout.preferredWidth: 40; Layout.preferredHeight: 40
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.s1
                Label { Layout.fillWidth: true; role: "lead"; text: Fmt.plain(card.record.summary); wrapMode: Text.WordWrap; maximumLineCount: 2 }
                Label { Layout.fillWidth: true; role: "caption"; dim: true; text: Fmt.plain(card.record.body); wrapMode: Text.WordWrap; maximumLineCount: card.popup ? 3 : 5; visible: text.length > 0 }
            }
        }
        Flow {
            Layout.fillWidth: true
            visible: card.buttons.length > 0 && Notifs.live[card.record.id] !== undefined
            spacing: Theme.s2
            Repeater {
                model: card.buttons
                Pressable {
                    required property var modelData
                    width: al.implicitWidth + Theme.s5; height: 24
                    highlighted: true
                    onClicked: Notifs.invoke(card.record.id, modelData.id)
                    Label { id: al; anchors.centerIn: parent; role: "caption"; text: modelData.text; color: Theme.accent }
                }
            }
        }
    }
}
