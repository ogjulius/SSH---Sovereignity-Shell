// Baseline for scripts/benchmark.sh: the smallest useful Quickshell config
// (one layer-shell bar with a text item). SSH's overhead is measured
// against this, not against zero.
import QtQuick
import Quickshell
ShellRoot {
    PanelWindow {
        anchors { left: true; right: true; top: true }
        implicitHeight: 34
        color: "#111113"
        Text { anchors.centerIn: parent; text: "baseline"; color: "white"; font.family: "Inter" }
    }
}
