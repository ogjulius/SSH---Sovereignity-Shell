pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// MPRIS players. `player` is the one SSH shows: the playing one if any,
// else the user's last pick, else the first.
Singleton {
    id: m
    readonly property var players: Mpris.players.values.filter(p => p.canControl)
    property string pinned: ""
    readonly property var player: {
        const list = players;
        if (list.length === 0) return null;
        const pin = list.find(p => p.dbusName === pinned);
        const playing = list.find(p => p.isPlaying);
        return playing || pin || list[0];
    }
    readonly property bool active: player !== null
    readonly property bool playing: player ? player.isPlaying : false
    readonly property string title: player ? (player.trackTitle || player.identity) : ""
    readonly property string artist: player ? (player.trackArtist || "") : ""
    readonly property string album: player ? (player.trackAlbum || "") : ""
    // Only local or http(s) artwork; data URLs from some players are skipped.
    readonly property string art: player && player.trackArtUrl && /^(file|https?):/.test(player.trackArtUrl) ? player.trackArtUrl : ""

    function cycle() {
        const list = players;
        if (list.length < 2 || !player) return;
        const i = list.indexOf(player);
        pinned = list[(i + 1) % list.length].dbusName;
    }
}
