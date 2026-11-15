pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

// PipeWire audio: default sink/source volume, mute, device selection.
Singleton {
    id: a

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: Pipewire.ready && sink !== null

    readonly property real volume: sink && sink.audio ? sink.audio.volume : 0
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property real micVolume: source && source.audio ? source.audio.volume : 0
    readonly property bool micMuted: source && source.audio ? source.audio.muted : false
    readonly property bool hasMic: source !== null

    readonly property string sinkName: sink ? (sink.description || sink.nickname || sink.name) : "No output"
    readonly property string sourceName: source ? (source.description || source.nickname || source.name) : "No input"

    // Hardware endpoints only (no streams).
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream && n.audio && n.name.indexOf(".monitor") < 0)

    signal volumeEvent   // fired on any user-perceivable change, for the OSD

    PwObjectTracker { objects: [a.sink, a.source] }

    Connections {
        target: a.sink ? a.sink.audio : null
        function onVolumeChanged() { a.volumeEvent(); }
        function onMutedChanged() { a.volumeEvent(); }
    }

    function setVolume(v) {
        if (!sink || !sink.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1.5, v));
    }
    function step(d) { setVolume(volume + d); }
    function toggleMute() { if (sink && sink.audio) sink.audio.muted = !sink.audio.muted; }
    function setMicVolume(v) { if (source && source.audio) { source.audio.muted = false; source.audio.volume = Math.max(0, Math.min(1.5, v)); } }
    function toggleMic() { if (source && source.audio) source.audio.muted = !source.audio.muted; }
    function useSink(node) { Pipewire.preferredDefaultAudioSink = node; }
    function useSource(node) { Pipewire.preferredDefaultAudioSource = node; }
}
