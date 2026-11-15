import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors
import "../../utilities/Fmt.js" as Fmt

// Instruments: SSH's control centre. Keys for binary state, gauges for
// continuous state, and one expandable detail drawer at a time.
// Every control maps to a real system interface; unavailable hardware
// is shown as unavailable, never faked.
FocusScope {
    id: ins
    implicitWidth: 392
    implicitHeight: col.implicitHeight + Theme.s5 * 2
    focus: true

    property string drawer: ""   // "wifi" | "bt" | "sink" | "source" | ""
    function openDrawer(d) { drawer = drawer === d ? "" : d; Net.scan(drawer === "wifi"); Bt.discover(drawer === "bt"); }
    Component.onDestruction: { Net.scan(false); Bt.discover(false); }

    Plate {
        anchors.fill: parent
        cut: Theme.cutL
        color: Theme.surface(Theme.plate)
        border: Theme.lineStrong
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s5 }
        spacing: Theme.s5

        // ── Header ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s3
            ColumnLayout {
                spacing: 0
                Label { role: "micro"; faint: true; text: "Instruments" }
                Label { role: "lead"; text: Power.hasBattery ? Fmt.percent(Power.level) + " · " + Power.stateLabel : Compositor.displayName }
            }
            Item { Layout.fillWidth: true }
            IconButton { icon: "gear"; onClicked: { Surfaces.close(); SettingsHub.open(); } }
            IconButton { icon: "lock"; onClicked: { Surfaces.close(); Quickshell.execDetached(Config.commands.lock); } }
            IconButton { icon: "power"; onClicked: Surfaces.open("power") }
        }

        // ── Keys ──────────────────────────────────────────────────────
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            columnSpacing: Theme.s3
            rowSpacing: Theme.s3
            Key {
                Layout.fillWidth: true
                icon: Net.wifiEnabled ? Net.glyph : "wifiOff"
                label: "Wi-Fi"
                detail: Net.wiredUp ? "wired" : (Net.activeWifi ? Net.activeWifi.name : (Net.wifiEnabled ? "on" : "off"))
                active: Net.wifiEnabled
                available: Net.available && Net.wifiHardware
                onClicked: Net.setWifi(!Net.wifiEnabled)
                onRightClicked: ins.openDrawer("wifi")
            }
            Key {
                Layout.fillWidth: true
                icon: Bt.enabled ? "bluetooth" : "bluetoothOff"
                label: "Bluetooth"
                detail: Bt.label
                active: Bt.enabled
                available: Bt.available
                onClicked: Bt.setEnabled(!Bt.enabled)
                onRightClicked: ins.openDrawer("bt")
            }
            Key {
                Layout.fillWidth: true
                icon: Notifs.dnd ? "moon" : "bell"
                label: "Quiet"
                detail: Notifs.dnd ? "on" : "off"
                active: Notifs.dnd
                onClicked: Notifs.setDnd(!Notifs.dnd)
            }
            Key {
                Layout.fillWidth: true
                icon: Audio.micMuted ? "micOff" : "mic"
                label: "Microphone"
                detail: !Audio.hasMic ? "none" : (Audio.micMuted ? "muted" : "live")
                active: Audio.hasMic && !Audio.micMuted
                available: Audio.hasMic
                onClicked: Audio.toggleMic()
            }
            Key {
                Layout.fillWidth: true
                icon: Power.profile === 0 ? "leaf" : (Power.profile === 2 ? "flame" : "gauge")
                label: "Profile"
                detail: Power.profileName(Power.profile)
                active: Power.profile !== 1
                onClicked: {
                    const list = Power.profiles;
                    Power.setProfile(list[(list.indexOf(Power.profile) + 1) % list.length]);
                }
            }
            Key {
                Layout.fillWidth: true
                icon: "atlas"
                label: "Atlas"
                detail: Atlas.enabled ? Atlas.label(Atlas.cursor.x, Atlas.cursor.y) : "off"
                active: Atlas.enabled
                available: Compositor.kind !== "none"
                onClicked: Surfaces.open("atlas")
            }
        }

        // ── Gauges ────────────────────────────────────────────────────
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.s4
            Gauge {
                icon: Audio.muted ? "speakerMute" : "speaker"
                title: "Output"
                detail: Audio.sinkName
                value: Audio.volume
                muted: Audio.muted
                available: Audio.ready
                onMoved: v => Audio.setVolume(v)
                onIconClicked: Audio.toggleMute()
                onDetailClicked: ins.openDrawer("sink")
            }
            Gauge {
                visible: Audio.hasMic
                icon: Audio.micMuted ? "micOff" : "mic"
                title: "Input"
                detail: Audio.sourceName
                value: Audio.micVolume
                muted: Audio.micMuted
                onMoved: v => Audio.setMicVolume(v)
                onIconClicked: Audio.toggleMic()
                onDetailClicked: ins.openDrawer("source")
            }
            Gauge {
                visible: Brightness.available
                icon: "sun"
                title: "Brightness"
                detail: Brightness.device
                value: Brightness.value
                onMoved: v => Brightness.set(v)
            }
        }

        // ── Drawer ────────────────────────────────────────────────────
        Drawer {
            Layout.fillWidth: true
            visible: ins.drawer !== ""
            kind: ins.drawer
        }

        // ── Footer: battery & session ─────────────────────────────────
        Rule { Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s4
            Label { role: "micro"; faint: true; text: Net.connectivity.length ? Net.connectivity : Net.label }
            Item { Layout.fillWidth: true }
            Label { role: "micro"; faint: true; visible: Power.hasBattery && Power.timeLeft.length > 0; text: Power.timeLeft + (Power.charging ? " to full" : " left") }
            Label { role: "micro"; faint: true; visible: Power.health > 0; text: "health " + Fmt.percent(Power.health) }
        }
    }
}
