import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import qs.themes

// A list entry with optional app icon or glyph, primary/secondary text and
// a trailing hint. Used for apps, windows, networks, devices, results.
Pressable {
    id: r
    property string iconSource: ""     // themed icon path (image)
    property string glyph: ""          // SSH glyph name (vector)
    property string title: ""
    property string subtitle: ""
    property string hint: ""
    property bool current: false
    highlighted: current
    implicitHeight: subtitle.length > 0 ? 44 : 32

    RowLayout {
        anchors { fill: parent; leftMargin: Theme.s4; rightMargin: Theme.s4 }
        spacing: Theme.s4
        Item {
            Layout.preferredWidth: 22; Layout.preferredHeight: 22
            visible: r.iconSource.length > 0 || r.glyph.length > 0
            IconImage {
                anchors.fill: parent
                visible: r.iconSource.length > 0
                source: r.iconSource
                asynchronous: true
                implicitSize: 22
            }
            Icon {
                anchors.centerIn: parent
                visible: r.iconSource.length === 0 && r.glyph.length > 0
                name: r.glyph || "dots"; size: 16
                color: r.current ? Theme.accent : Theme.textDim
            }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Label { Layout.fillWidth: true; text: r.title; role: "body"; color: r.current ? Theme.text : Theme.text }
            Label { Layout.fillWidth: true; text: r.subtitle; role: "caption"; faint: true; visible: r.subtitle.length > 0 }
        }
        Label { text: r.hint; role: "micro"; faint: true; visible: r.hint.length > 0 }
    }
    Rectangle { // current marker
        visible: r.current
        width: 2; height: parent.height - 12
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        color: Theme.accent
    }
}
