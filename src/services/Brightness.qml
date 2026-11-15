pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backlight via brightnessctl (works without root through logind/udev
// rules shipped by the brightnessctl package). Read on start and after each
// change SSH makes; no polling.
Singleton {
    id: b
    property bool available: false
    property real value: 0         // 0..1
    property string device: ""
    signal changedByUser

    function refresh() { if (!reader.running) reader.running = true; }
    function set(v) {
        v = Math.max(0.01, Math.min(1, v));
        value = v;
        writer.command = ["brightnessctl", "-q", "set", Math.round(v * 100) + "%"];
        writer.running = true;
        changedByUser();
    }
    function step(d) { set(value + d); }

    Process {
        id: reader
        command: ["brightnessctl", "-m", "-c", "backlight", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                // name,class,current,percent%,max
                const p = text.trim().split("\n")[0].split(",");
                if (p.length >= 5) {
                    b.device = p[0];
                    b.value = parseInt(p[2]) / Math.max(1, parseInt(p[4]));
                    b.available = true;
                }
            }
        }
        onExited: code => { if (code !== 0) b.available = false; }
    }
    Process { id: writer; onExited: reader.running = true }
    Component.onCompleted: refresh()
}
