pragma Singleton
import Quickshell
import Quickshell.Services.Pipewire
import QtQuick
import "../config"

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    property bool ready: false   // ignore the burst of changes at startup

    function setVolume(v) { if (sink?.audio) sink.audio.volume = Math.max(0, Math.min(1, v)) }
    function toggleMute() { if (sink?.audio) sink.audio.muted = !sink.audio.muted }

    PwObjectTracker { objects: [root.sink] }
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { root.pop() }
        function onMutedChanged() { root.pop() }
    }

    // Ignored automatically while the control center is open (higher rank).
    function pop() {
        if (!ready) return
        PillState.osdKind = "volume"
        PillState.request("osd", Config.osdMs)
    }
}
