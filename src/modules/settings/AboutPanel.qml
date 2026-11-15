import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors

ColumnLayout {
    spacing: Theme.s4
    RowLayout {
        spacing: Theme.s5
        Icon { name: "sigil"; size: 48; color: Theme.accent; weight: 1.25 }
        ColumnLayout {
            spacing: 0
            Label { role: "heading"; text: "SSH — Sovereignity Shell" }
            Label { role: "caption"; dim: true; text: "A brand new feeling of your Hyprland/Niri powered distribution." }
            Label { role: "micro"; faint: true; text: Version.version + " · " + Version.codename }
        }
    }
    SectionMark { Layout.fillWidth: true; text: "Diagnostics" }
    Repeater {
        model: [
            ["Compositor", Compositor.displayName + (Compositor.connected ? " · connected" : " · not connected")],
            ["Workspaces / windows", Compositor.workspaces.length + " / " + Compositor.windows.length],
            ["Notification daemon", Notifs.serving ? "SSH" : "not SSH (another daemon or disabled)"],
            ["Audio", Audio.ready ? Audio.sinkName : "PipeWire not ready"],
            ["Network", Net.available ? Net.label : "NetworkManager unavailable"],
            ["Bluetooth", Bt.label],
            ["Backlight", Brightness.available ? Brightness.device : "none / brightnessctl missing"],
            ["Battery", Power.hasBattery ? Power.stateLabel : "none"],
            ["Config file", Paths.configFile],
            ["Atlas state", Paths.atlasFile]
        ]
        RowLayout {
            required property var modelData
            Layout.fillWidth: true
            Label { role: "caption"; faint: true; text: modelData[0]; Layout.preferredWidth: 180 }
            Label { role: "caption"; text: modelData[1]; Layout.fillWidth: true }
        }
    }
    SectionMark { Layout.fillWidth: true; text: "Config issues"; visible: Config.warnings.length > 0 || Config.loadError.length > 0 }
    Label { visible: Config.loadError.length > 0; Layout.fillWidth: true; role: "caption"; color: Theme.critical; text: Config.loadError; wrapMode: Text.WordWrap }
    Repeater {
        model: Config.warnings
        Label { required property var modelData; Layout.fillWidth: true; role: "data"; color: Theme.caution; text: modelData; wrapMode: Text.WordWrap }
    }
}
