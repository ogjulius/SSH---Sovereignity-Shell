import QtQuick
import QtQuick.Shapes
import qs.themes
import "../themes/Icons.js" as Icons

// Renders a glyph from themes/Icons.js. Stroke weight stays visually
// constant regardless of size.
Item {
    id: icon

    property string name: "dots"
    property real size: 16
    property color color: Theme.text
    property real weight: 1.5
    property bool filled: false

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        scale: icon.size / 24
        transformOrigin: Item.TopLeft
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            strokeColor: icon.color
            strokeWidth: icon.weight * 24 / Math.max(1, icon.size)
            fillColor: icon.filled ? icon.color : "transparent"
            capStyle: ShapePath.SquareCap
            joinStyle: ShapePath.MiterJoin
            PathSvg { path: Icons.p[icon.name] || Icons.p.dots }
        }
    }
}
