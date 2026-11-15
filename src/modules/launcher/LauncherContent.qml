import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components

// The launcher: a compact plate with a query line, category stops and a
// ranked result list. Arrow keys move, Enter launches, Tab cycles category.
FocusScope {
    id: l
    implicitWidth: 600
    implicitHeight: col.implicitHeight + Theme.s5 * 2
    focus: true

    property string category: "all"
    property int current: 0
    // Empty query in "All": recently launched apps first (launcher.recentCount),
    // then everything else by frecency and name.
    readonly property int recentShown: field.text.trim().length === 0 && category === "all" ? Math.min(Config.launcher.recentCount, Apps.recent(Config.launcher.recentCount).length) : 0
    readonly property var results: {
        Apps.index; Apps.usage;
        const max = Config.launcher.maxResults;
        if (recentShown === 0) return Apps.search(field.text, category, max);
        const recent = Apps.recent(recentShown);
        const ids = recent.map(e => e.id);
        return recent.concat(Apps.search("", "all", max + recent.length).filter(e => ids.indexOf(e.id) < 0)).slice(0, max);
    }
    onResultsChanged: current = 0

    function launch(entry) { Apps.launch(entry); Surfaces.close(); }
    function cycleCategory(step) {
        const cats = Apps.categories;
        const i = cats.findIndex(c => c.key === category);
        category = cats[(i + step + cats.length) % cats.length].key;
    }

    Plate {
        anchors.fill: parent
        cut: Theme.cutL
        color: Theme.surface(Theme.plate)
        border: Theme.lineStrong
    }

    ColumnLayout {
        id: col
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Theme.s5 }
        spacing: Theme.s4

        RowLayout {
            Layout.fillWidth: true
            Label { role: "micro"; faint: true; text: "Launch" }
            Item { Layout.fillWidth: true }
            Label { role: "micro"; faint: true; text: l.results.length + " / " + Apps.index.length }
        }

        Field {
            id: field
            Layout.fillWidth: true
            large: true
            placeholder: "Find an application"
            focus: true
            input.focus: true
            onAccepted: if (l.results.length > 0) l.launch(l.results[l.current])
            input.Keys.onDownPressed: l.current = Math.min(l.results.length - 1, l.current + 1)
            input.Keys.onUpPressed: l.current = Math.max(0, l.current - 1)
            input.Keys.onTabPressed: l.cycleCategory(1)
            input.Keys.onBacktabPressed: l.cycleCategory(-1)
        }

        Flow {
            Layout.fillWidth: true
            visible: Config.launcher.showCategories
            spacing: 0
            Repeater {
                model: Apps.categories
                Pressable {
                    id: chip
                    required property var modelData
                    readonly property bool on: l.category === modelData.key
                    width: chipLabel.implicitWidth + Theme.s4
                    height: 22
                    highlighted: on
                    activeFocusOnTab: false
                    onClicked: l.category = modelData.key
                    Label { id: chipLabel; anchors.centerIn: parent; role: "micro"; text: chip.modelData.label; color: chip.on ? Theme.accent : Theme.textDim }
                }
            }
        }

        Rule { Layout.fillWidth: true }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Repeater {
                model: l.results
                ListRow {
                    required property var modelData
                    required property int index
                    Layout.fillWidth: true
                    current: index === l.current
                    activeFocusOnTab: false
                    iconSource: Apps.iconPath(modelData.icon)
                    title: modelData.name
                    subtitle: modelData.genericName || modelData.comment || ""
                    hint: index === l.current ? "↵" : (index < l.recentShown ? "recent" : "")
                    onClicked: l.launch(modelData)
                    onHoveredChanged: if (hovered) l.current = index
                }
            }
            Label {
                visible: l.results.length === 0
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                horizontalAlignment: Text.AlignHCenter
                role: "caption"; faint: true
                text: "Nothing matches. Unclaimed territory."
            }
        }
    }
}
