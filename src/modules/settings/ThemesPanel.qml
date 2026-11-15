import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.themes
import qs.configuration
import qs.components
import "../../configuration/Schema.js" as Schema

// Theme = the `appearance` section as a standalone JSON file.
// Presets ship with SSH; your own themes live in ~/.config/ssh-shell/themes.
ColumnLayout {
    id: tp
    spacing: Theme.s4
    property string status: ""

    function applyTheme(obj) {
        const a = obj && obj.appearance ? obj.appearance : obj;
        if (!a || typeof a !== "object") { status = "Not a theme file."; return; }
        let applied = 0, skipped = 0;
        for (const k in Schema.tree.appearance) {
            if (!(k in a)) continue;
            if (Config.set("appearance." + k, a[k])) applied++; else skipped++;
        }
        status = "Applied " + applied + " setting(s)" + (skipped ? ", skipped " + skipped + " invalid" : "") + ".";
    }

    FileView {
        id: reader
        printErrors: false
        onLoaded: { try { tp.applyTheme(JSON.parse(text())); } catch (e) { tp.status = "Could not parse theme: " + e.message; } }
        onLoadFailed: tp.status = "Could not read theme file."
    }
    FileView { id: writer; atomicWrites: true }

    SectionMark { Layout.fillWidth: true; index: "A"; text: "Presets" }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3
        Repeater {
            model: FolderListModel { folder: "file://" + Quickshell.shellDir + "/themes/presets"; nameFilters: ["*.json"]; showDirs: false }
            Pressable {
                required property string fileName
                required property string filePath
                width: pl.implicitWidth + Theme.s6; height: 30
                onClicked: { reader.path = ""; reader.path = filePath; }
                Label { id: pl; anchors.centerIn: parent; role: "caption"; text: fileName.replace(/\.json$/, "").replace(/-/g, " ") }
            }
        }
    }

    SectionMark { Layout.fillWidth: true; index: "B"; text: "Yours" }
    Flow {
        Layout.fillWidth: true
        spacing: Theme.s3
        Repeater {
            model: FolderListModel { id: mine; folder: "file://" + Paths.themesDir; nameFilters: ["*.json"]; showDirs: false }
            Pressable {
                required property string fileName
                required property string filePath
                width: ml.implicitWidth + Theme.s6; height: 30
                onClicked: { reader.path = ""; reader.path = filePath; }
                Label { id: ml; anchors.centerIn: parent; role: "caption"; text: fileName.replace(/\.json$/, "") }
            }
        }
        Label { visible: mine.count === 0; role: "caption"; faint: true; text: "No saved themes yet." }
    }

    SectionMark { Layout.fillWidth: true; index: "C"; text: "Export current" }
    RowLayout {
        Layout.fillWidth: true
        Field { id: nameField; Layout.fillWidth: true; icon: "pencil"; placeholder: "Theme name"; onAccepted: tp.save() }
        Pressable {
            width: el.implicitWidth + Theme.s6; height: 30
            onClicked: tp.save()
            Label { id: el; anchors.centerIn: parent; role: "caption"; text: "Export"; color: Theme.accent }
        }
    }
    function save() {
        const name = nameField.text.trim().replace(/[^A-Za-z0-9 _.-]/g, "").slice(0, 48);
        if (!name) { status = "Give the theme a name (letters, digits, - _ .)."; return; }
        Paths.ensure(Paths.themesDir);
        writer.path = Paths.themesDir + "/" + name + ".json";
        writer.setText(JSON.stringify({ name: name, ssh: Version.version, appearance: Config.o.appearance }, null, 2) + "\n");
        status = "Saved to " + writer.path;
        nameField.text = "";
    }
    Label { Layout.fillWidth: true; visible: tp.status.length > 0; role: "caption"; dim: true; text: tp.status; wrapMode: Text.WordWrap }
}
