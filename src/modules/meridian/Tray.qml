import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.themes
import qs.components

// StatusNotifierItem tray. Icons are drawn desaturated until hovered so
// third-party colour doesn't break the Meridian's palette.
Row {
    id: tray
    property var barWindow
    spacing: 0
    Repeater {
        model: SystemTray.items
        Pressable {
            id: item
            required property var modelData
            width: 26; height: tray.height
            onClicked: modelData.onlyMenu && modelData.hasMenu && tray.barWindow ? menu.open() : modelData.activate()
            onRightClicked: if (modelData.hasMenu && tray.barWindow) menu.open()
            onMiddleClicked: modelData.secondaryActivate()
            IconImage {
                anchors.centerIn: parent
                implicitSize: 15
                source: item.modelData.icon
                opacity: item.hovered ? 1 : 0.8
            }
            QsMenuAnchor {
                id: menu
                // anchor.window must be a real window; the render harness has none
                menu: item.modelData.menu
                anchor.window: tray.barWindow
                anchor.rect.x: item.mapToItem(null, 0, 0).x
                anchor.rect.y: tray.barWindow ? tray.barWindow.height : 0
                anchor.rect.width: item.width
                anchor.rect.height: 1
            }
        }
    }
}
