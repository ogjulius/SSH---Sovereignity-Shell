.pragma library
// Formatting helpers shared by every module.

function pad2(n) { return n < 10 ? "0" + n : String(n); }

function percent(v) { return Math.round(Math.max(0, Math.min(1, v)) * 100) + "%"; }

function duration(seconds) {
    if (!isFinite(seconds) || seconds <= 0) return "";
    var h = Math.floor(seconds / 3600);
    var m = Math.floor((seconds % 3600) / 60);
    return h > 0 ? h + "h " + pad2(m) + "m" : m + "m";
}

function mediaTime(seconds) {
    if (!isFinite(seconds) || seconds < 0) return "0:00";
    var s = Math.floor(seconds);
    var h = Math.floor(s / 3600);
    var m = Math.floor((s % 3600) / 60);
    var r = s % 60;
    return h > 0 ? h + ":" + pad2(m) + ":" + pad2(r) : m + ":" + pad2(r);
}

function bytes(n) {
    var u = ["B", "KiB", "MiB", "GiB", "TiB"];
    var i = 0;
    while (n >= 1024 && i < u.length - 1) { n /= 1024; i++; }
    return (i === 0 ? n : n.toFixed(n < 10 ? 1 : 0)) + " " + u[i];
}

function relativeTime(ms, now) {
    var d = Math.max(0, Math.round((now - ms) / 1000));
    if (d < 45) return "now";
    if (d < 3600) return Math.round(d / 60) + "m";
    if (d < 86400) return Math.round(d / 3600) + "h";
    return Math.round(d / 86400) + "d";
}

// Strips the small markup subset notifications may carry, for plain display.
function plain(s) {
    if (!s) return "";
    return String(s).replace(/<[^>]*>/g, "").replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">").replace(/&quot;/g, "\"").replace(/&#39;/g, "'");
}

var ROMAN = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"];
function roman(n) { return n >= 1 && n <= 12 ? ROMAN[n - 1] : String(n); }
