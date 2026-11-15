import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs.themes
import qs.configuration
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

// On-screen display for volume, mic and brightness. Lives only while
// visible (LazyLoader in shell.qml), input-transparent.
PanelWindow {
    id: osd
    required property string kind     // "volume" | "brightness" | "mic"
    screen: Surfaces.targetScreen()
    anchors.bottom: true
    margins.bottom: Math.round((screen ? screen.height : 1080) * 0.09)
    implicitWidth: 280
    implicitHeight: 52
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "ssh-osd"
    mask: Region {}

    readonly property real value: kind === "brightness" ? Brightness.value : (kind === "mic" ? Audio.micVolume : Audio.volume)
    readonly property bool muted: kind === "volume" ? Audio.muted : (kind === "mic" ? Audio.micMuted : false)
    readonly property string glyph: kind === "brightness" ? "sun" : (kind === "mic" ? (muted ? "micOff" : "mic") : (muted ? "speakerMute" : (value < 0.34 ? "speakerLow" : "speaker")))

    Plate {
        anchors.fill: parent
        cut: Theme.cutM
        color: Theme.surface(Theme.plate)
        border: Theme.lineStrong
    }
    RowLayout {
        anchors { fill: parent; leftMargin: Theme.s5; rightMargin: Theme.s5 }
        spacing: Theme.s4
        Icon { name: osd.glyph; size: 18; color: osd.muted ? Theme.textFaint : Theme.text }
        InstrumentSlider { Layout.fillWidth: true; value: Math.min(1, osd.value); muted: osd.muted; enabled: false }
        Label { role: "data"; text: osd.muted ? "MUTE" : Fmt.percent(osd.value); Layout.preferredWidth: 38; horizontalAlignment: Text.AlignRight; dim: true }
    }
}
