import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.configuration
import qs.components
import "../../configuration/Schema.js" as Schema

// A schema-driven option: picks its control from the option's type.
Item {
    id: row
    required property var opt
    readonly property var spec: Schema.specAt(opt.path)
    readonly property var value: { Config.o; return Config.get(opt.path); }
    readonly property bool isDefault: spec ? JSON.stringify(spec.d) === JSON.stringify(value) : true
    // Numeric readout with its unit, so a slider never shows a bare "1.00".
    readonly property string unit: row.opt.unit || ""
    readonly property string shownValue: {
        if (!spec || value === undefined || value === null) return "";
        if (unit === "%") return Math.round(value * 100) + "%";
        if (spec.t === "int") return value + unit;
        return Number(value).toFixed(2) + unit;
    }
    // Anchored (not RowLayout) so the control column is identical on every row.
    implicitHeight: Math.max(labels.implicitHeight, control.implicitHeight, 26)
    implicitWidth: 640

    ColumnLayout {
        id: labels
        anchors { left: parent.left; right: control.left; rightMargin: Theme.s6; verticalCenter: parent.verticalCenter }
        spacing: 1
        RowLayout {
            spacing: Theme.s2
            Label { role: "body"; text: row.opt.label }
            Rectangle { visible: !row.isDefault; width: 4; height: 4; color: Theme.accent }
        }
        Label { Layout.fillWidth: true; visible: !!row.opt.help; role: "caption"; faint: true; text: row.opt.help || ""; wrapMode: Text.WordWrap; maximumLineCount: 3 }
    }

    Loader {
        id: control
        width: 300
        anchors { right: reset.left; rightMargin: Theme.s3; verticalCenter: parent.verticalCenter }
        sourceComponent: !row.spec ? null : ({ bool: toggleC, enum: choiceC, num: numC, int: numC, str: textC, color: textC, numOrNull: textC, argv: textC, strlist: textC })[row.spec.t]
        onLoaded: item.width = Qt.binding(() => control.width)
    }
    IconButton {
        id: reset
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        icon: "restart"; iconSize: 12
        opacity: row.isDefault ? 0 : 1
        enabled_: !row.isDefault
        onClicked: Config.reset(row.opt.path)
    }

    Component { id: toggleC
        Item { implicitHeight: 22
            Toggle { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; checked: row.value === true; onToggled: v => Config.set(row.opt.path, v) } }
    }
    Component { id: choiceC
        Flow {
            layoutDirection: Qt.RightToLeft
            spacing: Theme.s1
            Repeater {
                model: row.spec.v.slice().reverse()
                Pressable {
                    id: ch
                    required property var modelData
                    readonly property bool on: row.value === modelData
                    width: cl.implicitWidth + Theme.s5; height: 24
                    highlighted: on
                    onClicked: Config.set(row.opt.path, modelData)
                    Label { id: cl; anchors.centerIn: parent; role: "caption"; text: row.opt.labels && row.opt.labels[ch.modelData] ? row.opt.labels[ch.modelData] : ch.modelData; color: ch.on ? Theme.accent : Theme.textDim }
                }
            }
        }
    }
    Component { id: numC
        RowLayout {
            spacing: Theme.s4
            readonly property real lo: row.spec.min
            readonly property real hi: row.spec.max
            InstrumentSlider {
                Layout.fillWidth: true
                value: (row.value - parent.lo) / (parent.hi - parent.lo)
                step: row.spec.t === "int" ? 1 / Math.max(1, parent.hi - parent.lo) : 0.02
                onMoved: v => {
                    let n = parent.lo + v * (parent.hi - parent.lo);
                    n = row.spec.t === "int" ? Math.round(n) : Math.round(n * 100) / 100;
                    Config.set(row.opt.path, n);
                }
            }
            Label { role: "data"; text: row.shownValue; Layout.preferredWidth: 56; horizontalAlignment: Text.AlignRight; dim: true }
        }
    }
    Component { id: textC
        Field {
            icon: ""
            readonly property string shown: row.spec.t === "argv" || row.spec.t === "strlist" ? (row.value || []).join(" ") : (row.value === null ? "" : String(row.value))
            text: shown
            placeholder: row.spec.t === "numOrNull" ? "not set" : (row.spec.t === "strlist" ? "all (space-separated names)" : "")
            onAccepted: commit()
            input.onActiveFocusChanged: if (!input.activeFocus && text !== shown) commit()
            function commit() {
                const t = row.spec.t;
                let v = text.trim();
                if (t === "numOrNull") v = v === "" ? null : Number(v);
                else if (t === "argv") v = v.split(/\s+/).filter(x => x.length);
                else if (t === "strlist") v = v.length ? v.split(/\s+/) : [];
                if (!Config.set(row.opt.path, v)) text = Qt.binding(() => shown);
            }
        }
    }
}
