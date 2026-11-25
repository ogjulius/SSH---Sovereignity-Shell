pragma Singleton
import QtQuick
import Quickshell
import qs.configuration
import "Palettes.js" as P

// Design tokens. Every visual decision in SSH resolves to a property here;
// modules never hard-code colours, sizes or durations.
Singleton {
    id: t

    // ── Mode ───────────────────────────────────────────────────────────
    SystemClock { id: hourClock; precision: SystemClock.Hours }
    readonly property bool dark: {
        const a = Config.appearance;
        if (a.mode === "light") return false;
        if (a.mode === "dark") return true;
        const h = hourClock.hours;
        const from = a.autoLightFrom, to = a.autoDarkFrom;
        const isLight = from < to ? (h >= from && h < to) : (h >= from || h < to);
        return !isLight;
    }
    readonly property var g: dark ? P.grounds.obsidian : P.grounds.vellum

    // ── Colour ─────────────────────────────────────────────────────────
    readonly property color void_: g.void
    readonly property color plate: g.plate
    readonly property color raised: g.raised
    readonly property color sunken: g.sunken
    readonly property color line: g.line
    readonly property color lineStrong: g.lineStrong
    readonly property color text: g.text
    readonly property color textDim: g.textDim
    readonly property color textFaint: g.textFaint
    readonly property color positive: g.positive
    readonly property color caution: g.caution
    readonly property color critical: g.critical
    readonly property color shadow: g.shadow
    readonly property string accentHex: P.accent(Config.appearance.accent, dark, Config.appearance.customAccent)
    readonly property color accent: accentHex
    // Ink on accent fills: whichever ground text gives better contrast.
    readonly property color accentInk: P.contrast(accentHex, "#111113") >= P.contrast(accentHex, "#f6f3ed") ? "#111113" : "#f6f3ed"
    readonly property color accentWash: Qt.alpha(accent, dark ? 0.14 : 0.16)
    readonly property color hover: Qt.alpha(text, dark ? 0.06 : 0.05)
    readonly property color press: Qt.alpha(text, dark ? 0.10 : 0.09)

    readonly property real opacity: Config.appearance.opacity
    function surface(c) { return Qt.alpha(c, t.opacity); }

    // ── Typography ─────────────────────────────────────────────────────
    // Families are resolved against what is actually installed, so a missing
    // font degrades to a close relative instead of an arbitrary fallback
    // (e.g. only the Nerd Font build of JetBrains Mono is installed).
    readonly property var installedFonts: Qt.fontFamilies()
    function pickFont(preferred, fallbacks) {
        const all = installedFonts;
        const want = [preferred].concat(fallbacks);
        for (const f of want) if (all.indexOf(f) >= 0) return f;
        return preferred;
    }
    readonly property string fontUi: pickFont(Config.appearance.fontUi, ["Inter", "Inter Variable", "Noto Sans", "Cantarell", "DejaVu Sans"])
    readonly property string fontDisplay: pickFont(Config.appearance.fontDisplay, ["Inter Display", "Inter", "Noto Sans", "DejaVu Sans"])
    readonly property string fontMono: pickFont(Config.appearance.fontMono, ["JetBrains Mono", "JetBrainsMono Nerd Font", "JetBrainsMono NF", "JetBrainsMono Nerd Font Mono", "Iosevka", "Noto Sans Mono", "DejaVu Sans Mono"])
    readonly property real fs: Config.appearance.fontScale
    // Scale: micro (mono caps labels) → display.
    readonly property int sizeMicro: Math.round(9.5 * fs)
    readonly property int sizeCaption: Math.round(11 * fs)
    readonly property int sizeBody: Math.round(12.5 * fs)
    readonly property int sizeLead: Math.round(14 * fs)
    readonly property int sizeTitle: Math.round(17 * fs)
    readonly property int sizeHeading: Math.round(24 * fs)
    readonly property int sizeDisplay: Math.round(44 * fs)
    readonly property real trackingMicro: 1.6

    // ── Space (4-point rhythm) ─────────────────────────────────────────
    readonly property int s1: 2
    readonly property int s2: 4
    readonly property int s3: 8
    readonly property int s4: 12
    readonly property int s5: 16
    readonly property int s6: 24
    readonly property int s7: 32
    readonly property int s8: 48

    // ── Geometry: round islands or chamfered plates ────────────────────
    // `shape` decides how a Plate closes its corners; the cut* sizes are the
    // geometry budget for either reading, so call sites never branch.
    readonly property bool rounded: Config.appearance.shape === "round"
    readonly property bool shine: Config.appearance.shine && rounded
    readonly property real chamferScale: Config.appearance.chamfer
    readonly property real cutS: (rounded ? 9 : 4) * chamferScale
    readonly property real cutM: (rounded ? 15 : 8) * chamferScale
    readonly property real cutL: (rounded ? 23 : 14) * chamferScale
    readonly property real hair: 1
    // Gap between an island surface and the screen edge.
    readonly property int gap: rounded ? 8 : 0

    // ── Motion ─────────────────────────────────────────────────────────
    readonly property real motion: Config.appearance.animationScale
    readonly property bool animate: motion > 0
    readonly property int durMicro: Math.round(110 * motion)
    readonly property int durStd: Math.round(190 * motion)
    readonly property int durSpatial: Math.round(320 * motion)
    readonly property int durLong: Math.round(480 * motion)
    // Enter decelerates, exit accelerates, spatial travel is a firm S-curve.
    readonly property list<real> curveEnter: [0.16, 1, 0.3, 1, 1, 1]
    readonly property list<real> curveExit: [0.7, 0, 0.84, 0, 1, 1]
    readonly property list<real> curveSpatial: [0.2, 0, 0, 1, 1, 1]
}
