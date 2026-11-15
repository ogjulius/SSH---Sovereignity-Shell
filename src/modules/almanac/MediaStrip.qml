import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

// MPRIS player strip: artwork, metadata, transport, progress.
// Position updates tick only while this strip exists and the player plays.
ColumnLayout {
    id: ms
    property bool compact: false
    spacing: Theme.s3
    readonly property var p: Media.player

    Timer {
        running: ms.visible && ms.p !== null && ms.p.isPlaying
        interval: 1000; repeat: true
        onTriggered: if (ms.p) ms.p.positionChanged()
    }

    SectionMark { Layout.fillWidth: true; index: "03"; text: ms.p ? ms.p.identity : "Media"; visible: !ms.compact }
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.s4
        Item {
            Layout.preferredWidth: ms.compact ? 44 : 56; Layout.preferredHeight: Layout.preferredWidth
            Plate { anchors.fill: parent; cut: Theme.cutS; color: Theme.sunken }
            Image {
                anchors.fill: parent; anchors.margins: 1
                source: Media.art
                sourceSize.width: 112; sourceSize.height: 112   // bounded decode
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                visible: status === Image.Ready
            }
            Icon { anchors.centerIn: parent; name: "note"; size: 18; color: Theme.textFaint; visible: Media.art.length === 0 }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { Layout.fillWidth: true; role: "lead"; text: Media.title }
            Label { Layout.fillWidth: true; role: "caption"; dim: true; text: [Media.artist, Media.album].filter(x => x).join(" — ") }
        }
        IconButton { icon: "prev"; iconSize: 14; enabled_: ms.p && ms.p.canGoPrevious; onClicked: ms.p.previous() }
        IconButton { icon: Media.playing ? "pause" : "play"; iconSize: 16; highlighted: Media.playing; enabled_: ms.p && ms.p.canTogglePlaying; onClicked: ms.p.togglePlaying() }
        IconButton { icon: "next"; iconSize: 14; enabled_: ms.p && ms.p.canGoNext; onClicked: ms.p.next() }
        IconButton { icon: "layers"; iconSize: 13; visible: Media.players.length > 1; onClicked: Media.cycle() }
    }
    RowLayout {
        Layout.fillWidth: true
        visible: ms.p !== null && ms.p.lengthSupported && ms.p.length > 0
        spacing: Theme.s3
        Label { role: "data"; faint: true; text: ms.p ? Fmt.mediaTime(ms.p.position) : "" }
        InstrumentSlider {
            Layout.fillWidth: true
            value: ms.p && ms.p.length > 0 ? ms.p.position / ms.p.length : 0
            step: 0.02
            onMoved: v => { if (ms.p && ms.p.canSeek) ms.p.position = v * ms.p.length; }
        }
        Label { role: "data"; faint: true; text: ms.p ? Fmt.mediaTime(ms.p.length) : "" }
    }
}
