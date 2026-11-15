.pragma library
// SSH colour system.
//
// Two grounds: OBSIDIAN (dark) and VELLUM (light). Neutrals are slightly
// warm so the warm-silver accent reads as metal rather than as a hue.
// Accents are deliberately desaturated; SSH never uses neon.

var grounds = {
    obsidian: {
        void: "#0a0a0b",      // deepest backdrop / dims
        plate: "#111113",     // primary surface
        raised: "#18181b",    // hovered / elevated surface
        sunken: "#0d0d0f",    // wells, tracks, inputs
        line: "#26262b",      // hairlines
        lineStrong: "#3a3a41",
        text: "#ece8e1",      // warm silver-white
        textDim: "#a8a39a",
        textFaint: "#6b6760",
        positive: "#8fb59a",
        caution: "#d4b06a",
        critical: "#d6766a",
        shadow: "#000000"
    },
    vellum: {
        void: "#d9d4ca",
        plate: "#f6f3ed",
        raised: "#fdfcf9",
        sunken: "#ebe6dd",
        line: "#d8d2c7",
        lineStrong: "#bdb5a8",
        text: "#1b1a18",
        textDim: "#57534d",
        textFaint: "#8d877e",
        positive: "#3f7a52",
        caution: "#8f6a1d",
        critical: "#a9443a",
        shadow: "#4a4035"
    }
};

// [onDark, onLight]: accents are re-tuned per ground for contrast.
var accents = {
    argent: ["#cfc6b4", "#6e6553"],
    brass: ["#c8a86b", "#7c6224"],
    ember: ["#d08c62", "#9a4f22"],
    verdigris: ["#86ad9e", "#3c6e5d"],
    cobalt: ["#8da0c2", "#3b5583"],
    oxblood: ["#c47a74", "#8a3a33"]
};

function accent(name, dark, custom) {
    if (name === "custom" && custom) return custom;
    var a = accents[name] || accents.argent;
    return dark ? a[0] : a[1];
}

// Relative luminance per WCAG; used to choose ink on accent fills.
function luminance(hex) {
    var h = hex.replace("#", "");
    if (h.length === 8) h = h.slice(2);
    var c = [0, 2, 4].map(function (i) {
        var v = parseInt(h.substr(i, 2), 16) / 255;
        return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4);
    });
    return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2];
}

function contrast(a, b) {
    var la = luminance(a), lb = luminance(b);
    return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}
