import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import qs.themes
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

// Detail lists for the Instruments: Wi-Fi networks, Bluetooth devices,
// audio endpoints. Shows at most 7 rows; the rest scroll.
ColumnLayout {
    id: d
    property string kind: ""
    spacing: Theme.s2

    property string pskFor: ""   // network name awaiting a passphrase

    SectionMark {
        Layout.fillWidth: true
        index: "»"
        text: ({ wifi: "Networks", bt: "Devices", sink: "Outputs", source: "Inputs" })[d.kind] || ""
    }

    ListView {
        id: list
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 7 * 40)
        clip: true
        interactive: contentHeight > height
        boundsBehavior: Flickable.StopAtBounds
        model: d.kind === "wifi" ? Net.wifiNetworks : (d.kind === "bt" ? Bt.devices : (d.kind === "sink" ? Audio.sinks : (d.kind === "source" ? Audio.sources : [])))
        delegate: ListRow {
            required property var modelData
            width: list.width
            glyph: d.kind === "wifi" ? (modelData.signalStrength > 0.66 ? "wifi" : (modelData.signalStrength > 0.33 ? "wifiMid" : "wifiLow"))
                 : (d.kind === "bt" ? "bluetooth" : (d.kind === "sink" ? "speaker" : "mic"))
            title: d.kind === "wifi" ? modelData.name : (d.kind === "bt" ? (modelData.name || modelData.address) : (modelData.description || modelData.nickname || modelData.name))
            subtitle: {
                if (d.kind === "wifi") return modelData.connected ? "Connected" : (modelData.known ? "Saved" : (modelData.security === WifiSecurityType.Open ? "Open" : "Secured"));
                if (d.kind === "bt") return modelData.connected ? ("Connected" + (modelData.batteryAvailable ? " · " + Fmt.percent(modelData.battery) : "")) : (modelData.paired ? "Paired" : "Available");
                return "";
            }
            current: d.kind === "wifi" ? modelData.connected : (d.kind === "bt" ? modelData.connected : (d.kind === "sink" ? modelData === Audio.sink : modelData === Audio.source))
            hint: d.kind === "wifi" && modelData.stateChanging ? "…" : ""
            onClicked: {
                if (d.kind === "wifi") {
                    if (modelData.connected) modelData.disconnect();
                    else if (modelData.known || modelData.security === WifiSecurityType.Open) modelData.connect();
                    else d.pskFor = modelData.name;
                } else if (d.kind === "bt") Bt.toggleDevice(modelData);
                else if (d.kind === "sink") Audio.useSink(modelData);
                else if (d.kind === "source") Audio.useSource(modelData);
            }
            onRightClicked: if (d.kind === "wifi" && modelData.known) modelData.forget()
        }
    }

    // Passphrase entry for a new secured network.
    RowLayout {
        Layout.fillWidth: true
        visible: d.kind === "wifi" && d.pskFor.length > 0
        spacing: Theme.s3
        Field {
            id: psk
            Layout.fillWidth: true
            icon: "lock"
            placeholder: "Passphrase for " + d.pskFor
            input.echoMode: TextInput.Password
            onAccepted: {
                const net = Net.wifiNetworks.find(n => n.name === d.pskFor);
                if (net && text.length > 0) net.connectWithPsk(text);
                text = ""; d.pskFor = "";
            }
            onVisibleChanged: if (visible) focusInput()
        }
        IconButton { icon: "close"; onClicked: { psk.text = ""; d.pskFor = ""; } }
    }

    Label {
        visible: list.count === 0
        Layout.fillWidth: true
        role: "caption"; faint: true
        text: d.kind === "wifi" ? (Net.wifiEnabled ? "Scanning…" : "Wi-Fi is off") : (d.kind === "bt" ? (Bt.enabled ? "Searching for devices…" : "Bluetooth is off") : "No devices")
    }
}
