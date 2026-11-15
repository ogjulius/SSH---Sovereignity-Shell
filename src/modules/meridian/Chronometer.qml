import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components

Pressable {
    id: c
    signal activated
    implicitWidth: row.implicitWidth + Theme.s4
    highlighted: Surfaces.isOpen("almanac")
    onClicked: activated()
    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s3
        Label { role: "micro"; dim: true; text: Time.date; visible: Config.clock.showDate }
        Label { role: "data"; text: Time.time; font.weight: Font.DemiBold; font.pixelSize: Theme.sizeBody }
    }
}
