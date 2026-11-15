pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU / memory / temperature sampling from /proc and /sys. Runs only while
// a view holds demand (dashboard open), so idle SSH does zero sampling.
Singleton {
    id: s
    property int demand: 0
    property real cpu: 0          // 0..1
    property real mem: 0          // 0..1
    property double memUsed: 0    // bytes
    property double memTotal: 0
    property real temp: -1        // °C, -1 unknown
    property var cpuHistory: []   // last 30 samples
    property var _prev: null

    function acquire() { demand++; sample(); }
    function releaseDemand() { demand = Math.max(0, demand - 1); }

    function sample() {
        stat.reload(); meminfo.reload();
        if (thermal.path) thermal.reload();
    }

    Timer { interval: 2000; repeat: true; running: s.demand > 0; onTriggered: s.sample() }

    FileView {
        id: stat
        path: "/proc/stat"
        onLoaded: {
            const f = text().split("\n")[0].split(/\s+/).slice(1).map(Number);
            const idle = f[3] + (f[4] || 0);
            const total = f.reduce((a, b) => a + b, 0);
            if (s._prev) {
                const dt = total - s._prev.total, di = idle - s._prev.idle;
                s.cpu = dt > 0 ? Math.max(0, Math.min(1, 1 - di / dt)) : 0;
                s.cpuHistory = s.cpuHistory.concat([s.cpu]).slice(-30);
            }
            s._prev = { total: total, idle: idle };
        }
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
        onLoaded: {
            const t = text();
            const get = k => { const m = t.match(new RegExp("^" + k + ":\\s+(\\d+)", "m")); return m ? parseInt(m[1]) * 1024 : 0; };
            s.memTotal = get("MemTotal");
            s.memUsed = s.memTotal - get("MemAvailable");
            s.mem = s.memTotal > 0 ? s.memUsed / s.memTotal : 0;
        }
    }
    // First thermal zone of type x86_pkg_temp / cpu / acpitz, discovered once.
    FileView {
        id: thermal
        path: ""
        printErrors: false
        onLoaded: { const v = parseInt(text()); s.temp = isNaN(v) ? -1 : v / 1000; }
    }
    Process {
        running: true
        command: ["sh", "-c", "for z in /sys/class/thermal/thermal_zone*; do t=$(cat \"$z/type\" 2>/dev/null); case \"$t\" in x86_pkg_temp|cpu*|k10temp|acpitz) echo \"$z/temp\"; exit 0;; esac; done"]
        stdout: StdioCollector { onStreamFinished: { const p = text.trim(); if (p) thermal.path = p; } }
    }
}
