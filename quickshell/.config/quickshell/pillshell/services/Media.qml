pragma Singleton
import Quickshell
import Quickshell.Services.Mpris
import QtQuick
import "../config"

Singleton {
    id: root

    // The playing player if there is one, otherwise the one that played last (so a
    // pause doesn't jump to some other idle player), otherwise the first available.
    property var last: null
    readonly property var player: {
        const ps = Mpris.players.values
        return ps.find(p => p.isPlaying) ?? (ps.includes(last) ? last : null) ?? ps[0] ?? null
    }
    onPlayerChanged: if (player?.isPlaying) last = player

    // `media toggle` (IPC) hides the popup until the track or play state changes.
    property bool dismissed: false
    readonly property bool active: player !== null && player.isPlaying && !dismissed
    // Deferred so that, on pause, the brief "paused" popup is requested first and
    // the pill doesn't collapse to idle and re-expand.
    onActiveChanged: Qt.callLater(() => { PillState.restMode = root.active ? "media" : "idle" })

    property bool ready: false   // ignore brief popups while players register at startup
    Timer { running: true; interval: 2500; onTriggered: root.ready = true }

    // Keeps the player pill up for a moment when not playing (pause, or a track change
    // while paused) before the pill goes back to the clock.
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
            if (root.player?.isPlaying) { root.dismissed = false; root.last = root.player }
            else root.pop()
        }
    }
}
