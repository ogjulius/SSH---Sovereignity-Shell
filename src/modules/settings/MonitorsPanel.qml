import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.components

// Which outputs get a Meridian. Empty selection = all outputs.
ColumnLayout {
    spacing: Theme.s3
    SectionMark { Layout.fillWidth: true; text: "Outputs" }
    Repeater {
        model: Quickshell.screens
        RowLayout {
            id: mr
            required property var modelData
            readonly property var list: Config.meridian.monitors
            readonly property bool on: list.length === 0 || list.indexOf(modelData.name) >= 0
            Layout.fillWidth: true
            Icon { name: "monitor"; size: 14; color: Theme.textDim }
            Label { role: "body"; text: mr.modelData.name }
            Label { role: "micro"; faint: true; text: mr.modelData.width + "×" + mr.modelData.height; Layout.fillWidth: true }
            Toggle {
                checked: mr.on
                onToggled: v => {
                    let names = mr.list.length === 0 ? Quickshell.screens.map(s => s.name) : mr.list.slice();
                    if (v && names.indexOf(mr.modelData.name) < 0) names.push(mr.modelData.name);
                    if (!v) names = names.filter(n => n !== mr.modelData.name);
                    if (names.length === 0) return; // never leave every output without a Meridian
                    if (names.length === Quickshell.screens.length) names = [];
                    Config.set("meridian.monitors", names);
                }
            }
        }
    }
}
