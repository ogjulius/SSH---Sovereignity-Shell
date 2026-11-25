import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components

// Meridian content, independent of its window so it can be rendered and
// tested on its own. `barWindow` is the hosting window (for menus).
Item {
    id: bar
    property var screen
    property var barWindow
    // An island draws itself as a floating plate; a flush strip fills the edge.
    property bool island: Config.meridian.style === "island"
    readonly property bool atTop: Config.meridian.position === "top"

    function anchorFor(item) {
        const p = item.mapToItem(null, 0, 0);
        return { x: p.x, y: bar.atTop ? bar.height : 0, w: item.width };
    }

    Plate {
        anchors.fill: parent
        visible: bar.island
        cut: Theme.cutM
        color: Theme.surface(Theme.plate)
        border: Theme.lineStrong
        shine: true
    }
    Rectangle {
        anchors.fill: parent
        visible: !bar.island
        color: Theme.surface(Theme.plate)
    }
    Rule {
        visible: !bar.island
        anchors { left: parent.left; right: parent.right; bottom: bar.atTop ? parent.bottom : undefined; top: bar.atTop ? undefined : parent.top }
    }
    Ticks {
        visible: Config.meridian.showTicks && !bar.island
        anchors { left: parent.left; right: parent.right; bottom: bar.atTop ? parent.bottom : undefined; top: bar.atTop ? undefined : parent.top; bottomMargin: 1; topMargin: 1 }
        height: 5
        fromBottom: bar.atTop
        color: Qt.alpha(Theme.lineStrong, 0.7)
    }

    RowLayout {
        anchors { fill: parent; leftMargin: bar.island ? Theme.s4 : Theme.s3; rightMargin: bar.island ? Theme.s4 : Theme.s3; bottomMargin: bar.island || !bar.atTop ? 0 : 3; topMargin: bar.island || bar.atTop ? 0 : 3 }
        spacing: Theme.s4

        // ── Position ──────────────────────────────────────────────────
        IconButton {
            id: sigil
            icon: "sigil"; iconSize: 17
            tint: Surfaces.isOpen("lens") ? Theme.accent : Theme.text
            onClicked: Surfaces.toggle("lens", bar.screen)
            onRightClicked: Surfaces.toggle("launcher", bar.screen)
        }
        Position { screen: bar.screen; Layout.fillHeight: true }
        Minimap { visible: Config.meridian.showMinimap && Atlas.enabled; Layout.alignment: Qt.AlignVCenter; screen: bar.screen }
        CellRow { visible: Config.meridian.showRow && Atlas.enabled; Layout.fillHeight: true }

        // ── Focus ─────────────────────────────────────────────────────
        Rule { vertical: true; Layout.fillHeight: true; Layout.topMargin: 8; Layout.bottomMargin: 8 }
        Item { Layout.fillWidth: true; Layout.fillHeight: true
            FocusTitle { anchors.centerIn: parent; width: Math.min(implicitWidth, parent.width); visible: Config.meridian.showTitle }
        }
        Rule { vertical: true; Layout.fillHeight: true; Layout.topMargin: 8; Layout.bottomMargin: 8 }

        // ── Instruments ───────────────────────────────────────────────
        Tray { visible: Config.meridian.showTray; Layout.fillHeight: true; barWindow: bar.barWindow }
        Readouts {
            id: readouts
            Layout.fillHeight: true
            onActivated: Surfaces.toggle("instruments", bar.screen, bar.anchorFor(readouts))
        }
        SignalBell {
            id: bell
            Layout.fillHeight: true
            onActivated: Surfaces.toggle("signals", bar.screen, bar.anchorFor(bell))
        }
        Chronometer {
            id: chrono
            Layout.fillHeight: true
            onActivated: Surfaces.toggle("almanac", bar.screen, bar.anchorFor(chrono))
        }
    }
}
