pragma Singleton
import Quickshell
import QtQuick

// Single source of truth for what the pill is showing.
// A request can only replace the current mode if its rank is equal or higher.
// When a timed or closed mode ends, the pill settles into `restMode`
// ("idle", or "media" while something is playing).
Singleton {
    property string mode: "idle"
    property string restMode: "idle"
    property string osdKind: "volume"   // "volume" | "brightness" | "workspace"

    readonly property var rank: ({ idle: 0, media: 1, osd: 2, notif: 3, control: 4, launcher: 5, clipboard: 5, power: 5 })
    readonly property bool resting: mode === "idle" || mode === "media"
    // True while the current mode is a timed popup (e.g. the media card on pause).
    readonly property bool timed: revert.running

    function settle() { mode = restMode }

    // ms > 0: settle after that long. ms = 0: stay until close().
    function request(m, ms) {
        if (rank[m] < rank[mode]) return
        mode = m
        if (ms > 0) { revert.interval = ms; revert.restart() }
        else revert.stop()
    }

    function close() {
        revert.stop()
        settle()
    }

    // Follow the resting mode, but never cut a timed popup short.
    onRestModeChanged: {
        if (mode === "idle" && restMode === "media") mode = "media"
        else if (mode === "media" && restMode === "idle" && !revert.running) mode = "idle"
    }

    Timer { id: revert; onTriggered: PillState.settle() }
}
