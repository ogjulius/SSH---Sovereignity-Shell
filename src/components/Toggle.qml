import QtQuick
import qs.themes

// The SSH switch: a shuttle in a hairline channel. Round grounds give a
// pill channel and a round shuttle; chamfer keeps the original square pair.
Pressable {
    id: tg
    property bool checked: false
    signal toggled(bool value)
    showWash: false
    implicitWidth: 34
    implicitHeight: 18
    onClicked: toggled(!checked)

    Rectangle {
        anchors.fill: parent
        radius: Theme.rounded ? height / 2 : 0
        color: tg.checked ? Theme.accentWash : Theme.sunken
        border.color: tg.checked ? Theme.accent : (tg.hovered || tg.activeFocus ? Theme.lineStrong : Theme.line)
        border.width: 1
    }
    Rectangle {
        id: shuttle
        width: parent.height - 6
        height: width
        y: 3
        radius: Theme.rounded ? width / 2 : 0
        x: tg.checked ? parent.width - width - 3 : 3
        color: tg.checked ? Theme.accent : Theme.textFaint
        Behavior on x { enabled: Theme.animate; NumberAnimation { duration: Theme.durStd; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveSpatial } }
        Behavior on color { enabled: Theme.animate; ColorAnimation { duration: Theme.durStd } }
    }
}
