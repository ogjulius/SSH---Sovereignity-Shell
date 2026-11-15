import QtQuick
import qs.themes

// Single-line text entry used by the launcher, the Lens and settings.
Item {
    id: f
    property alias text: textInput.text
    property alias input: textInput
    property string placeholder: ""
    property string icon: "search"
    property bool large: false
    signal accepted
    implicitHeight: large ? 44 : 30

    function focusInput() { textInput.forceActiveFocus(); }

    Plate {
        anchors.fill: parent
        cut: Theme.cutS
        color: Theme.sunken
        border: textInput.activeFocus ? Qt.alpha(Theme.accent, 0.7) : Theme.line
    }
    Icon {
        id: glyph
        visible: f.icon.length > 0
        anchors { left: parent.left; leftMargin: Theme.s4; verticalCenter: parent.verticalCenter }
        name: f.icon; size: f.large ? 18 : 14
        color: textInput.activeFocus ? Theme.accent : Theme.textFaint
    }
    TextInput {
        id: textInput
        anchors { left: glyph.visible ? glyph.right : parent.left; leftMargin: Theme.s4; right: parent.right; rightMargin: Theme.s4; verticalCenter: parent.verticalCenter }
        color: Theme.text
        selectionColor: Theme.accentWash
        selectedTextColor: Theme.text
        font.family: Theme.fontUi
        font.pixelSize: f.large ? Theme.sizeTitle : Theme.sizeBody
        clip: true
        onAccepted: f.accepted()
        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            visible: textInput.text.length === 0
            text: f.placeholder
            color: Theme.textFaint
            font: textInput.font
            elide: Text.ElideRight
        }
    }
}
