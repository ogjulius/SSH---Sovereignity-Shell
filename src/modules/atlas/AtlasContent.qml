import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components
import qs.compositors
import "../../utilities/Fmt.js" as Fmt

// The Atlas — Infinite Desktop overview.
//
// A recycled pool of cell delegates is laid over an unbounded integer grid.
// Panning re-targets delegates; it never creates or destroys them. Window
// previews are captured once (not live) and only for the selected cell's
// neighbourhood, so cost stays flat no matter how large the map grows.
FocusScope {
    id: at
    focus: true

    property int selX: Atlas.cursor.x
    property int selY: Atlas.cursor.y
    property real zoom: 1
    property bool renaming: false
    property bool renamingCollection: false

    readonly property real cw: Config.atlas.cellWidth * zoom
    readonly property real ch: cw * 9 / 16
    readonly property real gap: Math.round(22 * zoom)
    readonly property real pitchX: cw + gap
    readonly property real pitchY: ch + gap

    // View centre in cell units; animated toward the selection.
    property real viewX: selX
    property real viewY: selY
    Behavior on viewX { enabled: Theme.animate; NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveSpatial } }
    Behavior on viewY { enabled: Theme.animate; NumberAnimation { duration: Theme.durSpatial; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.curveSpatial } }

    readonly property int poolCols: Math.ceil(canvas.width / pitchX) + 3
    readonly property int poolRows: Math.ceil(canvas.height / pitchY) + 3
    readonly property int baseX: Math.floor(viewX) - Math.floor(poolCols / 2)
    readonly property int baseY: Math.floor(viewY) - Math.floor(poolRows / 2)

    Component.onCompleted: Compositor.refreshGeometry()

    function move(dx, dy) { selX += dx; selY += dy; }
    function go() { Atlas.goto(selX, selY); Surfaces.close(); }
    function carryHere() {
        if (!Compositor.focusedWindowId) return;
        Atlas.carryTo(Compositor.focusedWindowId, selX, selY, false);
    }
    function home() { selX = Atlas.cursor.x; selY = Atlas.cursor.y; }

    Keys.onPressed: e => {
        if (renaming || renamingCollection) return;
        const shift = e.modifiers & Qt.ShiftModifier;
        switch (e.key) {
        case Qt.Key_Left: case Qt.Key_H: move(-1, 0); break;
        case Qt.Key_Right: case Qt.Key_L: move(1, 0); break;
        case Qt.Key_Up: case Qt.Key_K: move(0, -1); break;
        case Qt.Key_Down: case Qt.Key_J: move(0, 1); break;
        case Qt.Key_Return: case Qt.Key_Enter: go(); break;
        case Qt.Key_M: carryHere(); break;
        case Qt.Key_R: renaming = true; break;
        case Qt.Key_Home: case Qt.Key_0: home(); break;
        case Qt.Key_Tab: Atlas.cycleCollection(1); home(); break;
        case Qt.Key_Backtab: Atlas.cycleCollection(-1); home(); break;
        case Qt.Key_N: if (shift) { Atlas.switchCollection(Atlas.addCollection("")); renamingCollection = true; } break;
        case Qt.Key_Plus: case Qt.Key_Equal: zoom = Math.min(1.8, zoom + 0.15); break;
        case Qt.Key_Minus: zoom = Math.max(0.55, zoom - 0.15); break;
        case Qt.Key_Delete: if (Atlas.windowCount(selX, selY) === 0) Atlas.release(selX, selY); break;
        default: return;
        }
        e.accepted = true;
    }

    Rectangle { anchors.fill: parent; color: Theme.surface(Theme.void_) }

    // ── Header ────────────────────────────────────────────────────────
    RowLayout {
        id: header
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s6 }
        spacing: Theme.s5
        Icon { name: "atlas"; size: 20; color: Theme.accent }
        ColumnLayout {
            spacing: 0
            Label { role: "micro"; faint: true; text: "Atlas · infinite desktop" }
            Label { role: "title"; text: Atlas.current.name }
        }
        Item { Layout.preferredWidth: Theme.s5 }
        Row {
            spacing: Theme.s1
            Repeater {
                model: Atlas.collections
                Pressable {
                    id: tab
                    required property var modelData
                    required property int index
                    readonly property bool on: modelData.id === Atlas.current.id
                    width: tabRow.implicitWidth + Theme.s5; height: 28
                    highlighted: on
                    activeFocusOnTab: false
                    onClicked: { Atlas.switchCollection(modelData.id); at.home(); }
                    RowLayout {
                        id: tabRow
                        anchors.centerIn: parent
                        spacing: Theme.s2
                        Label { role: "micro"; text: Fmt.roman(tab.index + 1); color: tab.on ? Theme.accent : Theme.textFaint }
                        Label { role: "caption"; text: tab.modelData.name; color: tab.on ? Theme.text : Theme.textDim }
                    }
                }
            }
            IconButton { icon: "plus"; iconSize: 13; activeFocusOnTab: false; onClicked: { Atlas.switchCollection(Atlas.addCollection("")); at.home(); at.renamingCollection = true; } }
        }
        Item { Layout.fillWidth: true }
        ColumnLayout {
            spacing: 0
            Label { Layout.alignment: Qt.AlignRight; role: "micro"; faint: true; text: "selected" }
            Label { Layout.alignment: Qt.AlignRight; role: "data"; text: Atlas.label(at.selX, at.selY) + "  (" + at.selX + ", " + at.selY + ")"; color: Theme.accent }
        }
        IconButton { icon: "close"; activeFocusOnTab: false; onClicked: Surfaces.close() }
    }

    // ── Canvas ────────────────────────────────────────────────────────
    Item {
        id: canvas
        anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: footer.top; topMargin: Theme.s6 + 18; bottomMargin: Theme.s4; leftMargin: 36 }
        clip: true

        Repeater {
            model: at.poolCols * at.poolRows
            AtlasCell {
                required property int index
                gx: at.baseX + (index % at.poolCols)
                gy: at.baseY + Math.floor(index / at.poolCols)
                x: canvas.width / 2 + (gx - at.viewX) * at.pitchX - at.cw / 2
                y: canvas.height / 2 + (gy - at.viewY) * at.pitchY - at.ch / 2
                width: at.cw
                height: at.ch
                selected: gx === at.selX && gy === at.selY
                previewAllowed: Math.abs(gx - at.selX) <= 1 && Math.abs(gy - at.selY) <= 1 && at.zoom >= 0.85
                onPick: { at.selX = gx; at.selY = gy; at.forceActiveFocus(); }
                onEnter: { at.selX = gx; at.selY = gy; at.go(); }
            }
        }

        WheelHandler {
            acceptedModifiers: Qt.ControlModifier
            onWheel: e => at.zoom = Math.max(0.55, Math.min(1.8, at.zoom + (e.angleDelta.y > 0 ? 0.1 : -0.1)))
        }
        WheelHandler {
            acceptedModifiers: Qt.NoModifier
            onWheel: e => at.move(0, e.angleDelta.y > 0 ? -1 : 1)
        }
        WheelHandler {
            acceptedModifiers: Qt.ShiftModifier
            onWheel: e => at.move(e.angleDelta.y > 0 ? -1 : 1, 0)
        }
    }

    // ── Rulers: column letters above, row numbers left (outside the clip) ──
    Item {
        anchors { left: canvas.left; right: canvas.right; bottom: canvas.top; bottomMargin: Theme.s2 }
        height: 14
        clip: true
        Repeater {
            model: at.poolCols
            Label {
                required property int index
                readonly property int gx: at.baseX + index
                x: canvas.width / 2 + (gx - at.viewX) * at.pitchX - at.cw / 2
                width: at.cw
                horizontalAlignment: Text.AlignHCenter
                role: "micro"; color: gx === at.selX ? Theme.accent : Theme.textFaint
                text: Atlas.label(gx, 0).replace(/[0-9−]+$/, "")
            }
        }
    }
    Item {
        anchors { right: canvas.left; top: canvas.top; bottom: canvas.bottom; rightMargin: Theme.s2 }
        width: 28
        clip: true
        Repeater {
            model: at.poolRows
            Label {
                required property int index
                readonly property int gy: at.baseY + index
                width: 28
                horizontalAlignment: Text.AlignRight
                y: canvas.height / 2 + (gy - at.viewY) * at.pitchY - 7
                role: "micro"; color: gy === at.selY ? Theme.accent : Theme.textFaint
                text: gy < 0 ? "−" + Math.abs(gy) : String(gy + 1)
            }
        }
    }

    // ── Footer: rename line / key legend / honesty note ───────────────
    Item {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.s6 }
        height: 34

        Field {
            id: renameField
            visible: at.renaming || at.renamingCollection
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            width: 360
            icon: "pencil"
            placeholder: at.renamingCollection ? "Name this collection" : "Name cell " + Atlas.label(at.selX, at.selY)
            onVisibleChanged: if (visible) { text = at.renamingCollection ? Atlas.current.name : Atlas.cellName(at.selX, at.selY); focusInput(); input.selectAll(); }
            onAccepted: {
                if (at.renamingCollection) Atlas.renameCollection(Atlas.current.id, text);
                else Atlas.rename(at.selX, at.selY, text);
                at.renaming = false; at.renamingCollection = false;
                at.forceActiveFocus();
            }
            input.Keys.onEscapePressed: e => { at.renaming = false; at.renamingCollection = false; at.forceActiveFocus(); e.accepted = true; }
        }

        Row {
            visible: !renameField.visible
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            spacing: Theme.s5
            Repeater {
                model: [["←↑↓→", "select"], ["↵", "go"], ["M", "move window here"], ["R", "name"], ["Tab", "collection"], ["shift N", "new collection"], ["+ −", "zoom"], ["Del", "forget empty cell"]]
                Row {
                    required property var modelData
                    spacing: Theme.s2
                    Label { role: "micro"; text: modelData[0]; color: Theme.text }
                    Label { role: "micro"; faint: true; text: modelData[1] }
                }
            }
        }
        Label {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            role: "micro"; faint: true
            text: Compositor.displayName + " · " + Compositor.workspaces.length + (Compositor.workspaces.length === 1 ? " live workspace" : " live workspaces") + " · map kept by SSH"
        }
    }
}
