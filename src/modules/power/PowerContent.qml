import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors

// Power menu. Destructive actions arm on first press and fire on the
// second, so a stray click can never end a session. Keys 1–5 select.
FocusScope {
    id: pw
    implicitWidth: row.implicitWidth + Theme.s6 * 2
    implicitHeight: col.implicitHeight + Theme.s6 * 2
    focus: true

    property string armed: ""
    property int current: 0
    readonly property var actions: [
        { key: "lock", label: "Lock", glyph: "lock", danger: false },
        { key: "suspend", label: "Suspend", glyph: "suspend", danger: false },
        { key: "logout", label: "Leave", glyph: "logout", danger: true },
        { key: "reboot", label: "Restart", glyph: "restart", danger: true },
        { key: "poweroff", label: "Power off", glyph: "power", danger: true }
    ]

    function fire(a) {
        if (a.danger && armed !== a.key) { armed = a.key; disarm.restart(); return; }
        Surfaces.close();
        if (a.key === "logout") Compositor.quit();
        else Quickshell.execDetached(Config.commands[a.key]);
    }
    Timer { id: disarm; interval: 4000; onTriggered: pw.armed = "" }

    Keys.onLeftPressed: current = (current + actions.length - 1) % actions.length
    Keys.onRightPressed: current = (current + 1) % actions.length
    Keys.onReturnPressed: fire(actions[current])
    Keys.onPressed: e => { const n = e.key - Qt.Key_1; if (n >= 0 && n < actions.length) { current = n; fire(actions[n]); e.accepted = true; } }

    Plate { anchors.fill: parent; cut: Theme.cutL; color: Theme.surface(Theme.plate); border: Theme.lineStrong }

    ColumnLayout {
        id: col
        anchors.centerIn: parent
        spacing: Theme.s5
        Label { Layout.alignment: Qt.AlignHCenter; role: "micro"; faint: true; text: pw.armed ? "Press again to confirm" : "Session" }
        RowLayout {
            id: row
            spacing: Theme.s3
            Repeater {
                model: pw.actions
                Pressable {
                    id: btn
                    required property var modelData
                    required property int index
                    readonly property bool isArmed: pw.armed === modelData.key
                    width: 92; height: 92
                    showWash: false
                    onClicked: { pw.current = index; pw.fire(modelData); }
                    onHoveredChanged: if (hovered) pw.current = index
                    Plate {
                        anchors.fill: parent
                        cut: Theme.cutM
                        color: btn.isArmed ? Qt.alpha(Theme.critical, 0.16) : (pw.current === btn.index ? Theme.raised : Theme.sunken)
                        border: btn.isArmed ? Theme.critical : (pw.current === btn.index ? Theme.accent : Theme.line)
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: Theme.s3
                        Icon { Layout.alignment: Qt.AlignHCenter; name: btn.modelData.glyph; size: 22; color: btn.isArmed ? Theme.critical : (pw.current === btn.index ? Theme.accent : Theme.text) }
                        Label { Layout.alignment: Qt.AlignHCenter; role: "caption"; text: btn.modelData.label }
                    }
                    Label { anchors { top: parent.top; left: parent.left; margins: 6 } role: "micro"; faint: true; text: btn.index + 1 }
                }
            }
        }
    }
}
