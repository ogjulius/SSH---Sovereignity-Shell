import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors

// One cell of the Atlas canvas. Delegates are recycled: the canvas keeps a
// fixed pool and re-targets each one to new coordinates as the view pans.
Item {
    id: cell
    property int gx: 0
    property int gy: 0
    property bool selected: false
    property bool previewAllowed: false
    // Preview budget (atlas.maxPreviews) shared over the 3×3 neighbourhood:
    // the selected cell takes up to 6, the eight neighbours split the rest.
    readonly property int previewBudget: {
        const max = Config.atlas.maxPreviews;
        if (!previewAllowed || max <= 0) return 0;
        return selected ? Math.min(6, max) : Math.floor(Math.max(0, max - 6) / 8);
    }
    signal pick
    signal enter

    readonly property var data_: Atlas.cell(gx, gy)
    readonly property bool bound: data_ !== null && data_.ref !== undefined
    readonly property bool here: gx === Atlas.cursor.x && gy === Atlas.cursor.y
    readonly property var ws: bound ? Compositor.workspace(data_.ref) : null
    readonly property var wins: bound ? Compositor.windowsOn(data_.ref) : []
    readonly property string name: data_ && data_.name ? data_.name : ""

    readonly property bool claimed: bound || name.length > 0

    Plate {
        anchors.fill: parent
        visible: cell.claimed || cell.selected || cell.here
        cut: Theme.cutM
        color: cell.selected ? Theme.raised : (cell.claimed ? Theme.surface(Theme.plate) : "transparent")
        border: cell.here ? Theme.accent : (cell.selected ? Theme.text : (cell.bound ? Theme.line : Qt.alpha(Theme.line, 0.6)))
        borderWidth: cell.here || cell.selected ? 1.5 : 1
    }

    // Unclaimed territory: a single centred cross, like a survey marker.
    Item {
        visible: !cell.claimed
        anchors.centerIn: parent
        width: 9; height: 9
        Rectangle { anchors.centerIn: parent; width: 9; height: 1; color: cell.selected ? Theme.textDim : Theme.lineStrong }
        Rectangle { anchors.centerIn: parent; width: 1; height: 9; color: cell.selected ? Theme.textDim : Theme.lineStrong }
    }

    // Header: coordinate · name · window count
    RowLayout {
        id: head
        visible: cell.claimed || cell.selected || cell.here
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s3 }
        spacing: Theme.s3
        Label { role: "micro"; text: Atlas.label(cell.gx, cell.gy); color: cell.here ? Theme.accent : Theme.textFaint; font.weight: cell.here ? Font.DemiBold : Font.Normal }
        Label { Layout.fillWidth: true; role: "caption"; text: cell.name; dim: !cell.selected }
        Label { role: "micro"; faint: true; visible: cell.here; text: "here" }
        Label { role: "micro"; faint: true; visible: cell.wins.length > 0; text: cell.wins.length }
        Rectangle { visible: cell.ws !== null && cell.ws.urgent; width: 5; height: 5; color: Theme.critical }
    }

    // Body: proportional window map (geometry-capable backends) or app list.
    Loader {
        anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; margins: Theme.s3; topMargin: Theme.s2 }
        active: cell.wins.length > 0
        sourceComponent: stageC
    }

    Component { id: stageC
    Item {
        id: stage
        clip: true

        Repeater {
            model: Compositor.caps.geometry ? cell.wins : []
            Item {
                id: tile
                required property var modelData
                required property int index
                readonly property real sx: stage.width / Math.max(1, modelData.monW)
                readonly property real sy: stage.height / Math.max(1, modelData.monH)
                x: Math.max(0, modelData.x * sx)
                y: Math.max(0, modelData.y * sy)
                width: Math.max(10, Math.min(stage.width - x, modelData.w * sx))
                height: Math.max(8, Math.min(stage.height - y, modelData.h * sy))
                z: modelData.floating ? 2 : 1

                Rectangle {
                    anchors.fill: parent
                    color: Theme.sunken
                    border.color: modelData.focused ? Theme.accent : Theme.lineStrong
                    border.width: 1
                }
                Loader {
                    anchors { fill: parent; margins: 1 }
                    active: Config.atlas.previews && Compositor.caps.previews && tile.modelData.handle !== null && tile.index < cell.previewBudget
                    sourceComponent: ScreencopyView {
                        captureSource: tile.modelData.handle
                        live: false
                        constraintSize: Qt.size(tile.width * 2, tile.height * 2)
                    }
                }
                Loader {
                    anchors.centerIn: parent
                    readonly property real sz: Math.min(22, tile.height - 6, tile.width - 6)
                    active: sz >= 10 && Config.appearance.appIcons
                    sourceComponent: IconImage { implicitSize: parent ? parent.sz : 16; source: Apps.iconFor(tile.modelData.appId); opacity: 0.9 }
                }
                // Drag a window tile onto another cell to move the window.
                Drag.active: dragArea.drag.active
                Drag.keys: ["ssh-window"]
                Drag.mimeData: ({ "text/plain": tile.modelData.id })
                Drag.hotSpot.x: width / 2
                Drag.hotSpot.y: height / 2
                property string windowId: modelData.id
                MouseArea {
                    id: dragArea
                    anchors.fill: parent
                    drag.target: tile
                    cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                    onReleased: { tile.Drag.drop(); tile.x = Qt.binding(() => Math.max(0, tile.modelData.x * tile.sx)); tile.y = Qt.binding(() => Math.max(0, tile.modelData.y * tile.sy)); }
                    onDoubleClicked: { Compositor.focusWindow(tile.modelData.id); Surfaces.close(); }
                }
            }
        }
        Flow {
            visible: !Compositor.caps.geometry
            anchors.fill: parent
            spacing: Theme.s2
            Repeater {
                model: Compositor.caps.geometry ? [] : cell.wins.slice(0, 12)
                Loader { required property var modelData; active: Config.appearance.appIcons; sourceComponent: IconImage { implicitSize: 20; source: Apps.iconFor(modelData.appId) } }
            }
        }
    }
    }

    DropArea {
        anchors.fill: parent
        keys: ["ssh-window"]
        onDropped: drop => { if (drop.source && drop.source.windowId) Atlas.carryTo(drop.source.windowId, cell.gx, cell.gy, false); }
        Rectangle { anchors.fill: parent; visible: parent.containsDrag; color: Theme.accentWash; border.color: Theme.accent }
    }

    TapHandler { onTapped: cell.pick(); onDoubleTapped: cell.enter() }
}