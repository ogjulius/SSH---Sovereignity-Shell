import QtQuick
import QtQuick.Shapes
import qs.themes

// The fundamental SSH surface: a plate with chamfered (cut) corners.
// By default the top-left and bottom-right corners are cut — the SSH
// signature silhouette. Any corner can be cut independently.
Item {
    id: plate

    property color color: Theme.surface(Theme.plate)
    property color border: Theme.line
    property real borderWidth: Theme.hair
    property real cut: Theme.cutM
    property real cutTL: cut
    property real cutTR: 0
    property real cutBR: cut
    property real cutBL: 0

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: plate.color
            strokeColor: plate.borderWidth > 0 ? plate.border : "transparent"
            strokeWidth: plate.borderWidth
            joinStyle: ShapePath.MiterJoin
            PathPolyline {
                readonly property real w: plate.width
                readonly property real h: plate.height
                readonly property real o: plate.borderWidth / 2
                path: [
                    Qt.point(o + plate.cutTL, o),
                    Qt.point(w - o - plate.cutTR, o),
                    Qt.point(w - o, o + plate.cutTR),
                    Qt.point(w - o, h - o - plate.cutBR),
                    Qt.point(w - o - plate.cutBR, h - o),
                    Qt.point(o + plate.cutBL, h - o),
                    Qt.point(o, h - o - plate.cutBL),
                    Qt.point(o, o + plate.cutTL),
                    Qt.point(o + plate.cutTL, o)
                ]
            }
        }
    }
}
