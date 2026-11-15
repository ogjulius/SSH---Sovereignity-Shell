import QtQuick
import QtQuick.Layouts
import qs.themes

// "01 — AUDIO ────────": numbered section marks give every panel the same
// cartographic rhythm.
RowLayout {
    id: mark
    property string index: ""
    property string text: ""
    spacing: Theme.s3

    Label { role: "micro"; faint: true; text: mark.index; visible: mark.index.length > 0 }
    Label { role: "micro"; dim: true; text: mark.text }
    Rule { Layout.fillWidth: true; Layout.alignment: Qt.AlignVCenter }
}
