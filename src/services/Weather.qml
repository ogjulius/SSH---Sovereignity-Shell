pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.configuration

// Weather with pluggable providers. Fetches only when something is
// watching (`demand` > 0) and the cache is stale. The default provider,
// Open-Meteo, needs no API key; SSH never ships credentials.
//
// Location must be configured explicitly (weather.latitude/longitude):
// SSH does not geolocate users by IP.
Singleton {
    id: w

    property int demand: 0
    property bool loading: false
    property string error: ""
    property var current: null        // { temp, code, wind, humidity, label, glyph }
    property var daily: []            // [{ day, max, min, code, glyph }]
    property double fetchedAt: 0

    readonly property bool configured: Config.weather.enabled && Config.weather.provider !== "none" && Config.weather.latitude !== null && Config.weather.longitude !== null
    readonly property string unit: Config.weather.units === "imperial" ? "°F" : "°C"

    // WMO weather interpretation codes → label + SSH glyph
    function describe(code) {
        if (code === 0) return ["Clear", "sun"];
        if (code <= 2) return ["Partly cloudy", "cloud"];
        if (code === 3) return ["Overcast", "cloud"];
        if (code <= 48) return ["Fog", "fog"];
        if (code <= 67 || (code >= 80 && code <= 82)) return ["Rain", "rain"];
        if (code <= 77 || code === 85 || code === 86) return ["Snow", "snow"];
        if (code >= 95) return ["Thunderstorm", "storm"];
        return ["Unknown", "cloud"];
    }

    function acquire() { demand++; maybeFetch(); }
    function releaseDemand() { demand = Math.max(0, demand - 1); }
    function maybeFetch() {
        if (!configured || loading) return;
        if (Date.now() - fetchedAt < Config.weather.refreshMinutes * 60000 && current) return;
        fetch();
    }

    function url() {
        const c = Config.weather;
        const imperial = c.units === "imperial";
        return "https://api.open-meteo.com/v1/forecast?latitude=" + c.latitude + "&longitude=" + c.longitude
            + "&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=5"
            + (imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "");
    }

    function fetch() {
        loading = true;
        error = "";
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            w.loading = false;
            if (xhr.status !== 200) { w.error = "Weather unavailable (" + (xhr.status || "offline") + ")"; return; }
            try {
                const d = JSON.parse(xhr.responseText);
                const cd = w.describe(d.current.weather_code);
                w.current = { temp: Math.round(d.current.temperature_2m), code: d.current.weather_code,
                              wind: Math.round(d.current.wind_speed_10m), humidity: d.current.relative_humidity_2m,
                              label: cd[0], glyph: cd[1] };
                const days = [];
                for (let i = 0; i < d.daily.time.length; i++) {
                    const dd = w.describe(d.daily.weather_code[i]);
                    days.push({ day: Qt.formatDate(new Date(d.daily.time[i] + "T12:00:00"), "ddd"),
                                max: Math.round(d.daily.temperature_2m_max[i]), min: Math.round(d.daily.temperature_2m_min[i]),
                                glyph: dd[1], label: dd[0] });
                }
                w.daily = days;
                w.fetchedAt = Date.now();
            } catch (e) { w.error = "Weather response unreadable"; }
        };
        xhr.open("GET", url());
        xhr.send();
    }
}
