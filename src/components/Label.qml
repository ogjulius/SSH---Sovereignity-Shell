import QtQuick
import qs.themes

// Typographic roles. Use `role` instead of picking sizes by hand.
//   micro    – mono, uppercase, tracked: section marks, coordinates
//   data     – mono figures: clocks, percentages, values
//   caption  – secondary UI text
//   body     – default UI text
//   lead     – emphasised UI text
//   title    – panel titles
//   heading  – large titles
//   display  – hero numerals (clock)
Text {
    id: label
    property string role: "body"
    property bool dim: false
    property bool faint: false

    color: faint ? Theme.textFaint : (dim ? Theme.textDim : Theme.text)
    font.family: role === "micro" || role === "data" ? Theme.fontMono : (role === "display" || role === "heading" ? Theme.fontDisplay : Theme.fontUi)
    font.pixelSize: ({
        micro: Theme.sizeMicro, data: Theme.sizeCaption, caption: Theme.sizeCaption,
        body: Theme.sizeBody, lead: Theme.sizeLead, title: Theme.sizeTitle,
        heading: Theme.sizeHeading, display: Theme.sizeDisplay
    })[role] || Theme.sizeBody
    font.weight: role === "display" ? Font.Light : (role === "title" || role === "heading" ? Font.DemiBold : (role === "lead" ? Font.Medium : Font.Normal))
    font.capitalization: role === "micro" ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: role === "micro" ? Theme.trackingMicro : (role === "display" ? -1 : 0)
    font.features: role === "data" || role === "display" ? { "tnum": 1 } : {}
    elide: Text.ElideRight
    verticalAlignment: Text.AlignVCenter
    textFormat: Text.PlainText
}
