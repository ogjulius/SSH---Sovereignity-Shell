import QtQuick
import QtQuick.Layouts
import qs.themes
import qs.components
import qs.compositors

RowLayout {
    readonly property var w: Compositor.focusedWindow
    spacing: Theme.s3
    Label { role: "micro"; faint: true; text: parent.w ? parent.w.appId : ""; visible: text.length > 0 }
    Label { role: "caption"; dim: true; text: parent.w ? parent.w.title : ""; Layout.maximumWidth: 520 }
}
