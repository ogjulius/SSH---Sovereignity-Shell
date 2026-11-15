import QtQuick
import qs.themes
import qs.services
import qs.components

// Battery drawn as an instrument: outline plus a proportional fill.
Item {
    implicitWidth: 20; implicitHeight: 15
    Icon { anchors.centerIn: parent; name: "battery"; size: 20; color: Power.low ? Theme.critical : Theme.textDim; weight: 1.25 }
    Rectangle {
        x: 5.3; y: 5.75
        height: 3.8
        width: Math.max(1, 11.6 * Power.level)
        color: Power.low ? Theme.critical : (Power.charging ? Theme.accent : Theme.text)
    }
    Icon { visible: Power.charging; anchors.centerIn: parent; anchors.horizontalCenterOffset: -1; name: "bolt"; size: 11; color: Theme.plate; filled: true; weight: 1 }
}
