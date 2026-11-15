import QtQuick
import qs.themes

// A gauge-like slider: hairline track with quarter ticks, an accent fill
// and a vertical needle. Supports drag, click, wheel and keyboard.
Item {
    id: s
    property real value: 0          // 0..1
    property real step: 0.05
    property bool muted: false
    signal moved(real value)

    implicitHeight: 22
    implicitWidth: 200
    activeFocusOnTab: true

    function emit(v) { moved(Math.max(0, Math.min(1, v))); }

    Keys.onLeftPressed: emit(value - step)
    Keys.onRightPressed: emit(value + step)
    Keys.onDownPressed: emit(value - step)
    Keys.onUpPressed: emit(value + step)

    readonly property real trackY: height / 2

    Rectangle { // track
        x: 0; y: s.trackY - 1
        width: s.width; height: 2
        color: Theme.sunken
        border.color: Theme.line; border.width: 0
    }
    Repeater { // quarter ticks
        model: 5
        Rectangle {
            required property int index
            x: Math.round(index * (s.width - 1) / 4)
            y: s.trackY + 4
            width: 1; height: index % 2 === 0 ? 4 : 2
            color: Theme.lineStrong
        }
    }
    Rectangle { // fill
        x: 0; y: s.trackY - 1
        height: 2
        width: Math.max(0, Math.min(1, s.value)) * s.width
        color: s.muted ? Theme.textFaint : Theme.accent
    }
    Rectangle { // needle
        width: 2; height: 14
        y: s.trackY - 7
        x: Math.max(0, Math.min(1, s.value)) * (s.width - width)
        color: s.muted ? Theme.textFaint : (area.pressed || s.activeFocus ? Theme.text : Theme.accent)
    }

    MouseArea {
        id: area
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        preventStealing: true
        onPressed: mouse => { s.forceActiveFocus(); s.emit(mouse.x / s.width); }
        onPositionChanged: mouse => { if (pressed) s.emit(mouse.x / s.width); }
        onWheel: wheel => s.emit(s.value + (wheel.angleDelta.y > 0 ? s.step : -s.step))
    }
}
