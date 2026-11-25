import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components

// Meridian content, independent of its window so it can be rendered and
// tested on its own. `barWindow` is the hosting window (for menus).
//
// Three styles, all laying out the same three zones — position, focus,
// instruments:
//   island — one floating plate carrying every zone
//   pills  — a plate per zone, separated by the backdrop
//   flush  — a full-width strip with the ruler-tick edge
Item {
    id: bar
    property var screen
    property var barWindow
    property string style: Config.meridian.style
    readonly property bool island: style === "island"
    readonly property bool pills: style === "pills"
    readonly property bool flush: style === "flush"
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
        visible: bar.flush
        color: Theme.surface(Theme.plate)
    }
    Rule {
        visible: bar.flush
        anchors { left: parent.left; right: parent.right; bottom: bar.atTop ? parent.bottom : undefined; top: bar.atTop ? undefined : parent.top }
    }
    Ticks {
        visible: Config.meridian.showTicks && bar.flush
        anchors { left: parent.left; right: parent.right; bottom: bar.atTop ? parent.bottom : undefined; top: bar.atTop ? undefined : parent.top; bottomMargin: 1; topMargin: 1 }
        height: 5
        fromBottom: bar.atTop
        color: Qt.alpha(Theme.lineStrong, 0.7)
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: bar.flush ? Theme.s3 : Theme.s4
            rightMargin: bar.flush ? Theme.s3 : Theme.s4
            bottomMargin: bar.flush && bar.atTop ? 3 : 0
            topMargin: bar.flush && !bar.atTop ? 3 : 0
        }
        // Separate islands need a visible gap; a single plate does not.
        spacing: bar.pills ? Theme.s3 : Theme.s4

        // ── Position ──────────────────────────────────────────────────
        BarZone {
            pill: bar.pills
            Layout.fillHeight: true
            IconButton {
                icon: "sigil"; iconSize: 17
                tint: Surfaces.isOpen("lens") ? Theme.accent : Theme.text
                onClicked: Surfaces.toggle("lens", bar.screen)
                onRightClicked: Surfaces.toggle("launcher", bar.screen)
            }
            Position { screen: bar.screen; Layout.fillHeight: true }
            Minimap { visible: Config.meridian.showMinimap && Atlas.enabled; Layout.alignment: Qt.AlignVCenter; screen: bar.screen }
            CellRow { visible: Config.meridian.showRow && Atlas.enabled; Layout.fillHeight: true }
        }

        // ── Focus ─────────────────────────────────────────────────────
        Rule { visible: !bar.pills; vertical: true; Layout.fillHeight: true; Layout.topMargin: 8; Layout.bottomMargin: 8 }
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // In `pills` the title gets its own shrink-to-fit island, so it
            // never has to be read straight off the wallpaper.
            BarZone {
                pill: bar.pills
                anchors.centerIn: parent
                height: parent.height
                width: Math.min(implicitWidth, parent.width)
                visible: Config.meridian.showTitle && (!bar.pills || hasTitle)
                readonly property bool hasTitle: title.implicitWidth > 0
                FocusTitle { id: title; Layout.fillWidth: true }
            }
        }
        Rule { visible: !bar.pills; vertical: true; Layout.fillHeight: true; Layout.topMargin: 8; Layout.bottomMargin: 8 }

        // ── Instruments ───────────────────────────────────────────────
        BarZone {
            pill: bar.pills
            Layout.fillHeight: true
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
}
