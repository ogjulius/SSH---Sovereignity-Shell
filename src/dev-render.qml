//@ pragma UseQApplication
// Development render harness (not installed).
//
// Renders real SSH components — live services, live compositor data — into
// PNGs without needing an unlocked desktop:
//
//   QT_QPA_PLATFORM=offscreen SSH_SHELL_CONFIG=/nonexistent \
//   SSH_RENDER_OUT=/tmp/out SSH_RENDER="meridian lens atlas" qs -p src/dev-render.qml
//
// Each target is composed over a neutral backdrop with the Meridian on top
// and positioned exactly as SurfaceWindow would place it. Outputs are
// renders of SSH's own QML, not screenshots of a running session; see
// docs/DEVELOPMENT.md for how the two differ.
import QtQuick
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.modules.meridian
import qs.modules.launcher
import qs.modules.instruments
import qs.modules.almanac
import qs.modules.signals
import qs.modules.power
import qs.modules.lens
import qs.modules.atlas

ShellRoot {
    id: root
    readonly property string out: Quickshell.env("SSH_RENDER_OUT") || "/tmp"
    readonly property var modes: (Quickshell.env("SSH_RENDER_MODES") || "dark").split(" ")
    readonly property var targets: (Quickshell.env("SSH_RENDER") || "meridian lens atlas launcher instruments almanac signals power").split(" ").filter(t => t.length)
    property var queue: []
    property string current: ""
    property string mode: "dark"

    readonly property var specs: ({
        meridian: { comp: null, place: "none", dim: 0 },
        launcher: { comp: launcherC, place: "top", dim: 0.25 },
        instruments: { comp: instrumentsC, place: "anchor-right", dim: 0 },
        almanac: { comp: almanacC, place: "anchor-clock", dim: 0 },
        signals: { comp: signalsC, place: "anchor-right", dim: 0 },
        power: { comp: powerC, place: "center", dim: 0.7 },
        lens: { comp: lensC, place: "fill", dim: Config.lens.dim },
        atlas: { comp: atlasC, place: "fill", dim: 0 }
    })

    Component { id: launcherC; LauncherContent {} }
    Component { id: instrumentsC; InstrumentsContent {} }
    Component { id: almanacC; AlmanacContent {} }
    Component { id: signalsC; SignalsContent {} }
    Component { id: powerC; PowerContent {} }
    Component { id: lensC; LensContent {} }
    Component { id: atlasC; AtlasContent {} }

    Component.onCompleted: {
        const q = [];
        for (const m of modes) for (const t of targets) q.push({ mode: m, target: t });
        queue = q;
        step.start();
    }

    Timer {
        id: step
        interval: 900
        onTriggered: {
            if (root.queue.length === 0) { Qt.quit(); return; }
            const job = root.queue[0];
            root.queue = root.queue.slice(1);
            root.mode = job.mode;
            Config.apply({ appearance: { mode: job.mode } });
            root.current = job.target;
            Surfaces.active = job.target === "meridian" ? "" : job.target;
            grab.start();
        }
    }
    Timer {
        id: grab
        interval: 1600
        onTriggered: frame.grabToImage(r => {
            const path = root.out + "/" + root.current + "-" + root.mode + ".png";
            console.log("[render] " + path + " " + r.saveToFile(path));
            step.start();
        })
    }

    FloatingWindow {
        implicitWidth: 1920
        implicitHeight: root.current === "meridian" ? 120 : 1080
        color: "black"

        Item {
            id: frame
            anchors.fill: parent

            // Neutral backdrop standing in for a wallpaper.
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.dark ? "#2a2826" : "#bdb6aa" }
                    GradientStop { position: 1; color: Theme.dark ? "#141312" : "#8f877b" }
                }
            }
            MeridianContent {
                id: bar
                visible: !!root.specs[root.current] && root.specs[root.current].place !== "fill"
                anchors { left: parent.left; right: parent.right; top: parent.top }
                height: Config.meridian.height
            }
            Rectangle {
                anchors.fill: parent
                color: Theme.void_
                opacity: root.specs[root.current] ? root.specs[root.current].dim : 0
            }
            Item {
                id: stage
                anchors { fill: parent; topMargin: root.specs[root.current] && root.specs[root.current].place === "fill" ? 0 : bar.height }
                Loader {
                    id: loader
                    sourceComponent: root.specs[root.current] ? root.specs[root.current].comp : null
                    readonly property string place: root.specs[root.current] ? root.specs[root.current].place : "none"
                    width: place === "fill" ? stage.width : (item ? item.implicitWidth : 0)
                    height: place === "fill" ? stage.height : (item ? item.implicitHeight : 0)
                    x: place === "anchor-right" ? stage.width - width - Theme.s3
                     : place === "anchor-clock" ? stage.width - width - Theme.s3
                     : place === "fill" ? 0 : (stage.width - width) / 2
                    y: place === "top" ? stage.height * 0.16 : (place.indexOf("anchor") === 0 ? Theme.s3 : (place === "fill" ? 0 : (stage.height - height) / 2))
                }
            }
        }
    }
}
