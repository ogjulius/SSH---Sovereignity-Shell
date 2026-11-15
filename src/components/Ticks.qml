import QtQuick
import QtQuick.Shapes
import qs.themes

// Ruler ticks: the Meridian's signature edge. One Shape node regardless of
// width; the path string is rebuilt only when the width changes.
Item {
    id: ticks
    property real step: 8
    property int majorEvery: 8
    property real minorLength: 2
    property real majorLength: 5
    property bool fromBottom: false
    property color color: Theme.lineStrong

    implicitHeight: majorLength

    function build() {
        let d = "";
        const n = Math.floor(width / step);
        for (let i = 0; i <= n; i++) {
            const x = Math.round(i * step) + 0.5;
            const len = (i % majorEvery === 0) ? majorLength : minorLength;
            d += fromBottom ? ("M" + x + " " + height + " V" + (height - len) + " ")
                            : ("M" + x + " 0 V" + len + " ");
        }
        return d.length ? d : "M0 0";
    }

    Shape {
        anchors.fill: parent
        ShapePath {
            strokeColor: ticks.color
            strokeWidth: 1
            fillColor: "transparent"
            capStyle: ShapePath.FlatCap
            PathSvg { path: ticks.width > 0 ? ticks.build() : "M0 0" }
        }
    }
}
