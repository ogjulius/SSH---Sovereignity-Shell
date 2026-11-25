import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components

// A focused app finder: fast search at left, a quiet inspector at right.
// Application icon-theme assets are opt-in; the default uses SSH glyphs.
FocusScope {
    id: l
    implicitWidth: 760
    implicitHeight: col.implicitHeight + Theme.s5 * 2
    focus: true

    property string category: "all"
    property int current: 0
    readonly property int recentShown: field.text.trim().length === 0 && category === "all" ? Math.min(Config.launcher.recentCount, Apps.recent(Config.launcher.recentCount).length) : 0
    readonly property var results: {
        Apps.index; Apps.usage;
        const max = Config.launcher.maxResults;
        if (recentShown === 0) return Apps.search(field.text, category, max);
        const recent = Apps.recent(recentShown);
        const ids = recent.map(e => e.id);
        return recent.concat(Apps.search("", "all", max + recent.length).filter(e => ids.indexOf(e.id) < 0)).slice(0, max);
    }
    readonly property var selected: current >= 0 && current < results.length ? results[current] : null
    readonly property int resultHeight: Math.max(240, Math.min(352, Math.min(results.length, 8) * 44))
    onResultsChanged: current = 0

    function launch(entry) {
        if (!entry) return;
        Apps.launch(entry);
        Surfaces.close();
    }
    function move(step) {
        if (results.length === 0) return;
        current = Math.max(0, Math.min(results.length - 1, current + step));
        resultList.positionViewAtIndex(current, ListView.Contain);
    }
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
        anchors { fill: parent; margins: Theme.s5 }
        spacing: Theme.s3

        RowLayout {
            Layout.fillWidth: true
            Label { role: "micro"; faint: true; text: "OPEN AN APP" }
            Item { Layout.fillWidth: true }
            Label { role: "data"; text: l.results.length + " RESULTS"; color: Theme.textDim }
        }

        Field {
            id: field
            Layout.fillWidth: true
            large: true
            placeholder: "Type an app name or keyword"
            focus: true
            input.focus: true
            onAccepted: l.launch(l.selected)
            input.Keys.onDownPressed: l.move(1)
            input.Keys.onUpPressed: l.move(-1)
            input.Keys.onTabPressed: l.cycleCategory(1)
            input.Keys.onBacktabPressed: l.cycleCategory(-1)
        }

        Flow {
            Layout.fillWidth: true
            visible: Config.launcher.showCategories
            spacing: Theme.s1
            Repeater {
                model: Apps.categories
                Pressable {
                    id: chip
                    required property var modelData
                    readonly property bool on: l.category === modelData.key
                    width: chipLabel.implicitWidth + Theme.s4
                    height: 26
                    highlighted: on
                    activeFocusOnTab: false
                    onClicked: l.category = modelData.key
                    Label {
                        id: chipLabel
                        anchors.centerIn: parent
                        role: "micro"
                        text: chip.modelData.label
                        color: chip.on ? Theme.accent : Theme.textDim
                    }
                }
            }
        }

        Rule { Layout.fillWidth: true }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: l.resultHeight
            spacing: Theme.s4

            Item {
                id: resultsPane
                Layout.fillWidth: true
                Layout.fillHeight: true
                ListView {
                    id: resultList
                    anchors.fill: parent
                    visible: l.results.length > 0
                    clip: true
                    interactive: true
                    model: l.results
                    currentIndex: l.current
                    highlightMoveDuration: 0
                    delegate: ListRow {
                        required property var modelData
                        required property int index
                        width: resultList.width
                        current: index === l.current
                        activeFocusOnTab: false
                        iconSource: Apps.iconPath(modelData.icon)
                        glyph: Apps.glyphFor(modelData)
                        title: modelData.name
                        subtitle: modelData.genericName || modelData.comment || ""
                        hint: index === l.current ? "ENTER" : ""
                        onClicked: l.launch(modelData)
                        onHoveredChanged: if (hovered) l.current = index
                    }
                }
                Rectangle {
                    visible: l.results.length > 8
                    anchors { right: parent.right; top: parent.top; bottom: parent.bottom }
                    width: 2
                    color: Theme.line
                    Rectangle {
                        width: parent.width
                        height: Math.max(24, parent.height * resultList.visibleArea.heightRatio)
                        y: parent.height * resultList.visibleArea.yPosition
                        color: Theme.accent
                    }
                }
                ColumnLayout {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Theme.s5 * 2, 300)
                    visible: l.results.length === 0
                    spacing: Theme.s2
                    Icon { Layout.alignment: Qt.AlignHCenter; name: "search"; size: 22; color: Theme.textFaint }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        role: "lead"
                        text: field.text.trim().length ? "No matching apps" : "No apps to show"
                    }
                    Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        role: "caption"
                        faint: true
                        text: field.text.trim().length ? "Try a shorter name or another keyword." : "Type above to search your installed applications."
                    }
                }
            }

            Rectangle { Layout.fillHeight: true; width: 1; color: Theme.line }

            Plate {
                id: inspector
                Layout.preferredWidth: 224
                Layout.fillHeight: true
                cut: Theme.cutM
                color: Theme.surface(Theme.sunken)
                border: Theme.line

                ColumnLayout {
                    anchors { fill: parent; margins: Theme.s4 }
                    spacing: Theme.s3
                    RowLayout {
                        Layout.fillWidth: true
                        Icon { name: l.selected ? Apps.glyphFor(l.selected) : "grid"; size: 17; color: Theme.accent }
                        Label { Layout.fillWidth: true; role: "micro"; faint: true; text: l.selected && l.selected.categories && l.selected.categories.length ? l.selected.categories[0].toUpperCase() : "APP DETAILS"; elide: Text.ElideRight }
                    }
                    Label {
                        Layout.fillWidth: true
                        role: "title"
                        text: l.selected ? l.selected.name : "Find something"
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    Label {
                        Layout.fillWidth: true
                        role: "caption"
                        faint: true
                        text: l.selected ? (l.selected.genericName || l.selected.comment || "Installed application") : "Search by name or category."
                        wrapMode: Text.WordWrap
                        maximumLineCount: 4
                        elide: Text.ElideRight
                    }
                    Item { Layout.fillHeight: true }
                    Rule { Layout.fillWidth: true }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.s2
                        Label { role: "micro"; text: "↵"; color: Theme.accent }
                        Label { Layout.fillWidth: true; role: "caption"; faint: true; text: l.selected ? "Launch selected app" : "Choose a result" }
                    }
                }
            }
        }

        Rule { Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.s5
            Label { role: "micro"; faint: true; text: "↑ ↓  MOVE" }
            Label { role: "micro"; faint: true; text: "TAB  FILTER" }
            Label { role: "micro"; faint: true; text: "ENTER  OPEN" }
            Item { Layout.fillWidth: true }
            Label { role: "micro"; faint: true; text: "ESC  CLOSE" }
        }
    }
}
