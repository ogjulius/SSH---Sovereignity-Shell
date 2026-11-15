import QtQuick
import qs.themes

// A 1px hairline. Horizontal by default.
Rectangle {
    property bool vertical: false
    property bool strong: false
    implicitWidth: vertical ? 1 : 0
    implicitHeight: vertical ? 0 : 1
    color: strong ? Theme.lineStrong : Theme.line
}
