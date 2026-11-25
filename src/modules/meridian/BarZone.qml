import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.components

// One zone of the Meridian. In the `pills` style each zone carries its own
// plate and padding, so the bar reads as separate islands; in `island` and
// `flush` the zone is transparent and only lays its children out in a row.
Item {
    id: g
    property bool pill: false
    readonly property int pad: pill ? Theme.s4 : 0
    default property alias content: inner.data

    implicitWidth: inner.implicitWidth + pad * 2
    implicitHeight: inner.implicitHeight

    Plate {
        anchors.fill: parent
        visible: g.pill
        cut: Theme.cutM
        color: Theme.surface(Theme.plate)
        border: Theme.lineStrong
        shine: true
    }

    RowLayout {
        id: inner
        anchors { fill: parent; leftMargin: g.pad; rightMargin: g.pad }
        spacing: Theme.s4
    }
}
