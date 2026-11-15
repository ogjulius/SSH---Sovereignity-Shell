pragma Singleton
import QtQuick
import Quickshell
import qs.configuration
import "../utilities/Fmt.js" as Fmt

// One clock for the whole shell. Minute precision unless seconds are shown.
Singleton {
    id: t
    SystemClock { id: clk; precision: Config.clock.showSeconds ? SystemClock.Seconds : SystemClock.Minutes }
    readonly property date now: clk.date
    readonly property string time: {
        const d = now;
        let h = d.getHours();
        const suffix = Config.clock.format24h ? "" : (h >= 12 ? " PM" : " AM");
        if (!Config.clock.format24h) h = h % 12 || 12;
        return (Config.clock.format24h ? Fmt.pad2(h) : h) + ":" + Fmt.pad2(d.getMinutes()) + (Config.clock.showSeconds ? ":" + Fmt.pad2(d.getSeconds()) : "") + suffix;
    }
    readonly property string date: Qt.formatDate(now, "ddd d MMM")
    readonly property string longDate: Qt.formatDate(now, "dddd, d MMMM yyyy")
}
