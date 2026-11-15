import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

// Network, audio, bluetooth and battery as one instrument cluster.
// Scroll over it to change volume.
Pressable {
    id: r
    signal activated
    implicitWidth: row.implicitWidth + Theme.s4
    highlighted: Surfaces.isOpen("instruments")
    onClicked: activated()

    WheelHandler {
        onWheel: event => Audio.step(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Theme.s4
        Icon { name: Net.glyph; size: 15; color: Net.kind === "none" ? Theme.textFaint : Theme.text; visible: Net.available }
        Icon { name: "bluetooth"; size: 15; visible: Bt.enabled; color: Bt.connected.length > 0 ? Theme.accent : Theme.textDim }
        RowLayout {
            spacing: Theme.s2
            Icon { name: Audio.muted ? "speakerMute" : (Audio.volume < 0.34 ? "speakerLow" : "speaker"); size: 15; color: Audio.muted ? Theme.textFaint : Theme.text }
            Label { role: "data"; text: Fmt.percent(Audio.volume); visible: Config.meridian.showVolumePercent; dim: true }
        }
        Icon { name: "micOff"; size: 15; color: Theme.caution; visible: Audio.hasMic && Audio.micMuted }
        BatteryGlyph { visible: Power.hasBattery }
        Label { role: "data"; text: Fmt.percent(Power.level); visible: Power.hasBattery && Config.meridian.showBatteryPercent; color: Power.low ? Theme.critical : Theme.textDim }
    }
}
