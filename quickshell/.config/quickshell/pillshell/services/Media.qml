pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../config"

Singleton {
    id: root

    // The playing player if there is one, otherwise the first available.
    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? ps[0] ?? null
    }

    // `media toggle` (IPC) hides the popup until the track or play state changes.
    property bool dismissed: false
    readonly property bool active: player !== null && player.isPlaying && !dismissed
    // Deferred so that, on pause, the brief "paused" popup is requested first and
    // the pill doesn't collapse to idle and re-expand.
    onActiveChanged: Qt.callLater(() => { PillState.restMode = root.active ? "media" : "idle" })

    property bool ready: false   // ignore brief popups while players register at startup
    Timer { running: true; interval: 2500; onTriggered: root.ready = true }

    // Brief popup, used when not playing (pause, or a track change while paused).
    function pop() {
        if (!ready || !player) return
        PillState.request("media", Config.mediaMs)
    }

    function hide() {
        dismissed = true
        PillState.close()
    }

    function show() {
        dismissed = false
        if (player && !player.isPlaying) pop()
    }

    Connections {
        target: root.player ?? null
        function onTrackTitleChanged() {
            if (!root.player?.trackTitle) return
            root.dismissed = false
            if (!root.active) root.pop()
        }
        function onIsPlayingChanged() {
            if (root.player?.isPlaying) root.dismissed = false
            else root.pop()
        }
    }
}
