import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.services
import qs.components

// A month as a coordinate grid: week numbers on the left edge like a map's
// row labels, today marked with the accent plate.
ColumnLayout {
    id: m
    property int offset: 0
    signal shift(int d)
    spacing: Theme.s3

    readonly property date base: { const n = Time.now; return new Date(n.getFullYear(), n.getMonth() + offset, 1); }
    readonly property bool monday: Config.clock.weekStartsMonday
    readonly property var cells: {
        const first = base;
        const lead = monday ? (first.getDay() + 6) % 7 : first.getDay();
        const start = new Date(first.getFullYear(), first.getMonth(), 1 - lead);
        const out = [];
        for (let i = 0; i < 42; i++) out.push(new Date(start.getFullYear(), start.getMonth(), start.getDate() + i));
        return out;
    }
    function isoWeek(d) {
        const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
        const day = t.getUTCDay() || 7;
        t.setUTCDate(t.getUTCDate() + 4 - day);
        const y0 = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
        return Math.ceil(((t - y0) / 86400000 + 1) / 7);
    }

    RowLayout {
        Layout.fillWidth: true
        Label { role: "lead"; text: Qt.formatDate(m.base, "MMMM"); }
        Label { role: "data"; faint: true; text: Qt.formatDate(m.base, "yyyy") }
        Item { Layout.fillWidth: true }
        IconButton { icon: "chevronLeft"; iconSize: 13; onClicked: m.shift(-1) }
        IconButton { icon: "target"; iconSize: 13; visible: m.offset !== 0; onClicked: m.shift(-m.offset) }
        IconButton { icon: "chevronRight"; iconSize: 13; onClicked: m.shift(1) }
    }

    GridLayout {
        columns: 8
        columnSpacing: 0
        rowSpacing: 0
        Label { role: "micro"; faint: true; text: "wk"; Layout.preferredWidth: 26; Layout.preferredHeight: 20 }
        Repeater {
            model: m.monday ? ["M", "T", "W", "T", "F", "S", "S"] : ["S", "M", "T", "W", "T", "F", "S"]
            Label { required property var modelData; role: "micro"; faint: true; text: modelData; Layout.preferredWidth: 32; horizontalAlignment: Text.AlignHCenter; Layout.preferredHeight: 20 }
        }
        Repeater {
            model: 48
            Item {
                id: cell
                required property int index
                readonly property bool weekCol: index % 8 === 0
                readonly property int di: index - Math.floor(index / 8) - 1
                readonly property date d: weekCol ? m.cells[Math.floor(index / 8) * 7] : m.cells[di]
                readonly property bool inMonth: d.getMonth() === m.base.getMonth()
                readonly property bool today: !weekCol && d.toDateString() === Time.now.toDateString()
                Layout.preferredWidth: weekCol ? 26 : 32
                Layout.preferredHeight: 26
                Plate {
                    visible: cell.today
                    anchors.centerIn: parent
                    width: 26; height: 22
                    cut: Theme.cutS
                    color: Theme.accent; borderWidth: 0
                }
                Label {
                    anchors.centerIn: parent
                    role: cell.weekCol ? "micro" : "data"
                    text: cell.weekCol ? m.isoWeek(cell.d) : cell.d.getDate()
                    color: cell.today ? Theme.accentInk : (cell.weekCol ? Theme.textFaint : (cell.inMonth ? Theme.text : Theme.textFaint))
                    font.weight: cell.today ? Font.DemiBold : Font.Normal
                    opacity: cell.inMonth || cell.weekCol ? 1 : 0.5
                }
            }
        }
    }
}
