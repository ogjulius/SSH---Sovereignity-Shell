import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.themes
import qs.configuration
import qs.services
import qs.components
import "Pages.js" as Pages

// Settings: a regular application window (tiles, floats, can be moved to
// any workspace). Every change is validated and saved immediately.
FloatingWindow {
    id: win
    title: "SSH Settings"
    implicitWidth: 920
    implicitHeight: 640
    minimumSize: Qt.size(720, 480)
    color: Theme.plate
    onClosed: SettingsHub.close()
    onVisibleChanged: if (!visible) SettingsHub.close()

    readonly property var page: Pages.pages.find(p => p.key === SettingsHub.page) || Pages.pages[0]
    readonly property Item body: rootItem   // grabbable root (used by the render harness)

    Item {
        id: rootItem
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: SettingsHub.close()

        // ── Sidebar ───────────────────────────────────────────────────
        Rectangle {
            id: side
            width: 212
            anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
            color: Theme.sunken
            Rule { vertical: true; anchors { right: parent.right; top: parent.top; bottom: parent.bottom } }
            ColumnLayout {
                anchors { fill: parent; margins: Theme.s5 }
                spacing: Theme.s1
                RowLayout {
                    spacing: Theme.s3
                    Layout.bottomMargin: Theme.s5
                    Icon { name: "sigil"; size: 22; color: Theme.accent }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Label { Layout.fillWidth: true; role: "title"; text: "Sovereignity" }
                        Label { Layout.fillWidth: true; role: "micro"; faint: true; text: "v" + Version.version }
                    }
                }
                Repeater {
                    model: Pages.pages
                    Pressable {
                        id: nav
                        required property var modelData
                        required property int index
                        readonly property bool on: win.page.key === modelData.key
                        Layout.fillWidth: true
                        implicitHeight: 32
                        highlighted: on
                        onClicked: SettingsHub.page = modelData.key
                        RowLayout {
                            anchors { fill: parent; leftMargin: Theme.s4; rightMargin: Theme.s4 }
                            spacing: Theme.s4
                            Label { role: "micro"; faint: true; text: String(nav.index + 1).padStart(2, "0") }
                            Icon { name: nav.modelData.glyph; size: 14; color: nav.on ? Theme.accent : Theme.textDim }
                            Label { Layout.fillWidth: true; role: "body"; text: nav.modelData.title; color: nav.on ? Theme.text : Theme.textDim }
                        }
                    }
                }
                Item { Layout.fillHeight: true }
                Label {
                    Layout.fillWidth: true
                    visible: Config.warnings.length > 0 || Config.loadError.length > 0
                    role: "caption"; color: Theme.caution; wrapMode: Text.WordWrap
                    text: Config.loadError.length > 0 ? "config.json could not be read; changes will not be saved." : Config.warnings.length + " config issue(s) — see About"
                }
            }
        }

        // ── Page ──────────────────────────────────────────────────────
        Flickable {
            id: flick
            anchors { left: side.right; right: parent.right; top: parent.top; bottom: parent.bottom }
            contentHeight: body.implicitHeight + Theme.s7 * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            ColumnLayout {
                id: body
                x: Theme.s7; y: Theme.s7
                // Keep labels and controls close on wide (tiled) windows.
                width: Math.min(flick.width - Theme.s7 * 2, 860)
                spacing: Theme.s5
                ColumnLayout {
                    spacing: 0
                    Label { role: "micro"; faint: true; text: String(Pages.pages.indexOf(win.page) + 1).padStart(2, "0") + " / " + String(Pages.pages.length).padStart(2, "0") }
                    Label { role: "heading"; text: win.page.title }
                }
                Rule { Layout.fillWidth: true }
                Repeater {
                    model: win.page.items
                    Loader {
                        required property var modelData
                        Layout.fillWidth: true
                        sourceComponent: modelData.special ? ({ accent: accentC, collections: collectionsC, keys: keysC, themes: themesC, about: aboutC, monitors: monitorsC })[modelData.special] : optionC
                        property var opt: modelData
                    }
                }
            }
        }
    }

    Component { id: optionC; OptionRow { opt: parent ? parent.opt : ({}) } }
    Component { id: accentC; AccentPicker {} }
    Component { id: collectionsC; CollectionsPanel {} }
    Component { id: keysC; KeysPanel {} }
    Component { id: themesC; ThemesPanel {} }
    Component { id: aboutC; AboutPanel {} }
    Component { id: monitorsC; MonitorsPanel {} }
}
