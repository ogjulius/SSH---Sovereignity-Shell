import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components
import "../../utilities/Fmt.js" as Fmt

// The Almanac: time, calendar, weather, system load and media in one
// ledger. Sampling and weather fetches only run while it is open.
FocusScope {
    id: al
    implicitWidth: 560
    implicitHeight: grid.implicitHeight + Theme.s5 * 2
    focus: true

    Component.onCompleted: { Stats.acquire(); Weather.acquire(); }
    Component.onDestruction: { Stats.releaseDemand(); Weather.releaseDemand(); }

    property int monthOffset: 0
    Keys.onLeftPressed: monthOffset--
    Keys.onRightPressed: monthOffset++

    Plate { anchors.fill: parent; cut: Theme.cutL; color: Theme.surface(Theme.plate); border: Theme.lineStrong; shine: true }

    GridLayout {
        id: grid
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s5 }
        columns: 2
        columnSpacing: Theme.s6
        rowSpacing: Theme.s5

        // ── Time ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 236
            Layout.alignment: Qt.AlignTop
            spacing: Theme.s2
            Label { role: "micro"; faint: true; text: "Local time" }
            Label { role: "display"; text: Time.time; font.pixelSize: Theme.sizeDisplay * 1.15 }
            Label { role: "caption"; dim: true; text: Time.longDate }
            Item { Layout.preferredHeight: Theme.s4 }
            Weather_ { Layout.fillWidth: true }
        }

        // ── Calendar ──────────────────────────────────────────────────
        MonthGrid { Layout.fillWidth: true; Layout.alignment: Qt.AlignTop; offset: al.monthOffset; onShift: d => al.monthOffset += d }

        // ── Load ──────────────────────────────────────────────────────
        ColumnLayout {
            Layout.columnSpan: 2
            Layout.fillWidth: true
            spacing: Theme.s3
            SectionMark { Layout.fillWidth: true; index: "02"; text: "Load" }
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s6
                Meter { glyph: "cpu"; title: "CPU"; value: Stats.cpu; detail: Fmt.percent(Stats.cpu); history: Stats.cpuHistory }
                Meter { glyph: "memory"; title: "Memory"; value: Stats.mem; detail: Fmt.bytes(Stats.memUsed) }
                Meter { glyph: "thermo"; title: "Temp"; value: Stats.temp > 0 ? Math.min(1, Stats.temp / 100) : 0; detail: Stats.temp > 0 ? Math.round(Stats.temp) + "°C" : "—" }
            }
        }

        // ── Media ─────────────────────────────────────────────────────
        MediaStrip { Layout.columnSpan: 2; Layout.fillWidth: true; visible: Media.active }
    }

    component Weather_: ColumnLayout {
        spacing: Theme.s2
        SectionMark { Layout.fillWidth: true; index: "01"; text: "Weather" }
        Label {
            visible: !Weather.configured
            Layout.fillWidth: true
            wrapMode: Text.WordWrap; maximumLineCount: 3
            role: "caption"; faint: true
            text: Config.weather.provider === "none" || !Config.weather.enabled ? "Weather is turned off." : "Set a location in Settings → Almanac to see weather. SSH never geolocates you."
        }
        RowLayout {
            visible: Weather.configured && Weather.current !== null
            spacing: Theme.s4
            Icon { name: Weather.current ? Weather.current.glyph : "cloud"; size: 28; color: Theme.accent }
            ColumnLayout {
                spacing: 0
                Label { role: "heading"; text: Weather.current ? Weather.current.temp + Weather.unit : "" }
                Label { role: "caption"; dim: true; text: Weather.current ? Weather.current.label + (Config.weather.locationName ? " · " + Config.weather.locationName : "") : "" }
            }
        }
        RowLayout {
            visible: Weather.configured && Weather.daily.length > 0
            spacing: Theme.s4
            Repeater {
                model: Weather.daily.slice(1, 5)
                ColumnLayout {
                    required property var modelData
                    spacing: 1
                    Label { role: "micro"; faint: true; text: modelData.day }
                    Icon { name: modelData.glyph; size: 14; color: Theme.textDim }
                    Label { role: "data"; text: modelData.max + "°"; font.pixelSize: Theme.sizeCaption }
                }
            }
        }
        Label { visible: Weather.error.length > 0; role: "caption"; faint: true; text: Weather.error }
    }
}