import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import qs.themes
import qs.components

// A compact load meter: glyph, value, a segmented bar and optional history trace.
ColumnLayout {
    id: m
    property string glyph: "cpu"
    property string title: ""
    property string detail: ""
    property real value: 0
    property var history: []
    Layout.fillWidth: true
    spacing: Theme.s2

    RowLayout {
        spacing: Theme.s3
        Icon { name: m.glyph; size: 14; color: Theme.textDim }
        Label { role: "micro"; dim: true; text: m.title }
        Item { Layout.fillWidth: true }
        Label { role: "data"; text: m.detail }
    }
    Row { // 20 segments
        Layout.fillWidth: true
        spacing: 2
        Repeater {
            model: 20
            Rectangle {
                required property int index
                width: (parent.width - 19 * 2) / 20
                height: 6
                color: index < Math.round(m.value * 20) ? (index >= 17 ? Theme.critical : (index >= 14 ? Theme.caution : Theme.accent)) : Theme.sunken
            }
        }
    }
    Shape { // history trace
        visible: m.history.length > 1
        Layout.fillWidth: true
        Layout.preferredHeight: 18
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: Qt.alpha(Theme.accent, 0.7)
            strokeWidth: 1
            fillColor: "transparent"
            PathPolyline {
                path: {
                    const h = m.history, w = parent ? m.width : 100, out = [];
                    for (let i = 0; i < h.length; i++) out.push(Qt.point(i * w / 29, 17 - h[i] * 16));
                    return out;
                }
            }
        }
    }
}
