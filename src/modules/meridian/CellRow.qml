import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.services
import qs.components

// The cells of the current row, as numbered stops. This is the classic
// workspace indicator, re-read as one line of the map.
Row {
    id: rowView
    spacing: 0
    readonly property var stops: {
        Atlas.revision;
        const b = Atlas.bounds(0);
        const y = Atlas.cursor.y;
        const out = [];
        const from = Math.min(b.minX, Atlas.cursor.x), to = Math.max(b.maxX, Atlas.cursor.x);
        for (let x = from; x <= to && out.length < 12; x++) {
            const c = Atlas.cell(x, y);
            if ((c && c.ref) || x === Atlas.cursor.x) out.push(x);
        }
        return out;
    }
    Repeater {
        model: rowView.stops
        Pressable {
            id: stop
            required property var modelData
            readonly property bool here: modelData === Atlas.cursor.x
            readonly property int count: Atlas.windowCount(modelData, Atlas.cursor.y)
            readonly property var ws: Atlas.workspaceAt(modelData, Atlas.cursor.y)
            width: 26; height: rowView.height
            highlighted: here
            onClicked: Atlas.goto(modelData, Atlas.cursor.y)
            Label {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -1
                role: "data"
                text: Atlas.label(stop.modelData, Atlas.cursor.y).replace(/[0-9−]+$/, "")
                color: stop.here ? Theme.text : (stop.count > 0 ? Theme.textDim : Theme.textFaint)
                font.weight: stop.here ? Font.DemiBold : Font.Normal
            }
            Rectangle { // occupancy / here marker
                anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 4 }
                width: stop.here ? 14 : (stop.count > 0 ? 4 : 0)
                height: 2
                color: stop.ws && stop.ws.urgent ? Theme.critical : (stop.here ? Theme.accent : Theme.textFaint)
                Behavior on width { enabled: Theme.animate; NumberAnimation { duration: Theme.durStd; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveSpatial } }
            }
        }
    }
}
