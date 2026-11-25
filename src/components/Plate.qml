import QtQuick
import QtQuick.Shapes
import qs.themes

// The fundamental SSH surface. Two readings of the same plate, chosen by
// `appearance.shape`:
//
//   round — a rounded island with an optional light along its top edge.
//           Drawn as a plain Rectangle: no Shape node, no curve renderer.
//   cut   — the chamfered silhouette: top-left and bottom-right corners cut
//           by default. Any corner can be cut independently.
//
// `cut` carries the geometry budget for whichever reading is active, so call
// sites keep passing Theme.cutS / cutM / cutL and never branch on the shape.
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
    // A soft light along the top edge: only on a rounded island, and only
    // worth drawing on a real surface, never on a hover wash.
    property bool shine: false

    Loader {
        anchors.fill: parent
        sourceComponent: Theme.rounded ? roundC : cutC
    }

    Component {
        id: roundC
        Rectangle {
            radius: plate.cut
            color: plate.color
            border.color: plate.borderWidth > 0 ? plate.border : "transparent"
            border.width: plate.borderWidth
            Rectangle {
                anchors.fill: parent
                visible: plate.shine && Theme.shine
                radius: parent.radius
                color: "transparent"
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, Theme.dark ? 0.05 : 0.28) }
                    GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, 0) }
                }
            }
        }
    }

    Component {
        id: cutC
        Shape {
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
}
