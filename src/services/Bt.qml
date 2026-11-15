pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth via Quickshell.Bluetooth (BlueZ over D-Bus).
Singleton {
    id: b
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: available && adapter.enabled
    readonly property var devices: available && adapter.devices ? adapter.devices.values.slice().sort((x, y) => (y.connected - x.connected) || (y.paired - x.paired) || x.name.localeCompare(y.name)) : []
    readonly property var connected: devices.filter(d => d.connected)
    readonly property string label: !available ? "Unavailable" : (!enabled ? "Off" : (connected.length > 0 ? connected[0].name : "On"))

    function setEnabled(on) { if (adapter) adapter.enabled = on; }
    function discover(on) { if (adapter && adapter.enabled) adapter.discovering = on; }
    function toggleDevice(d) { if (d.connected) d.disconnect(); else d.connect(); }
}
