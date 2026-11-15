pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Networking

// Network state via Quickshell.Networking (NetworkManager backend).
Singleton {
    id: n

    readonly property bool available: Networking.backend !== NetworkBackendType.None
    readonly property var devices: Networking.devices ? Networking.devices.values : []
    readonly property var wifi: devices.find(d => d.type === DeviceType.Wifi) || null
    readonly property var wired: devices.find(d => d.type === DeviceType.Wired) || null
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardware: Networking.wifiHardwareEnabled

    readonly property var wifiNetworks: wifi && wifi.networks ? wifi.networks.values.slice().sort((x, y) => (y.connected - x.connected) || (y.signalStrength - x.signalStrength)) : []
    readonly property var activeWifi: wifiNetworks.find(w => w.connected) || null
    readonly property bool wiredUp: wired !== null && wired.connected

    readonly property string kind: wiredUp ? "wired" : (activeWifi ? "wifi" : "none")
    readonly property real strength: activeWifi ? activeWifi.signalStrength : 0
    readonly property string label: wiredUp ? "Wired" : (activeWifi ? activeWifi.name : (wifiEnabled ? "Disconnected" : "Wi-Fi off"))
    readonly property string glyph: {
        if (kind === "wired") return "ethernet";
        if (kind === "wifi") return strength > 0.66 ? "wifi" : (strength > 0.33 ? "wifiMid" : "wifiLow");
        return "wifiOff";
    }
    readonly property string connectivity: {
        switch (Networking.connectivity) {
        case NetworkConnectivity.Full: return "Online";
        case NetworkConnectivity.Limited: return "Limited";
        case NetworkConnectivity.Portal: return "Captive portal";
        case NetworkConnectivity.None: return "Offline";
        }
        return "";
    }

    function setWifi(on) { Networking.wifiEnabled = on; }
    function scan(on) { if (wifi) wifi.scannerEnabled = on; }
}
