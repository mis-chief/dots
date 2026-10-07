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

    // Everything that differs per mode. To add a mode: add a row here, a Slot for its
    // view in modules/Pill.qml, and (if it has a keybind) an IpcHandler in shell.qml.
    //   rank      what may interrupt what (see above)
    //   size      [width, height, radius] of the pill
    //   opened    the user opened it on purpose: click-away closes it, and it is
    //             drawn over fullscreen windows
    //   keyboard  takes keyboard focus while open
    readonly property var modes: ({
        idle:      { rank: 0, size: [Battery.present ? 138 : 96, 32, 16],      opened: false, keyboard: false },
        media:     { rank: 1, size: timed ? [380, 72, 26] : [320, 32, 16],     opened: false, keyboard: false },
        osd:       { rank: 2, size: [260, 44, 22],                             opened: false, keyboard: false },
        notif:     { rank: 3, size: [380, 84, 28],                             opened: false, keyboard: false },
        control:   { rank: 4, size: [440, 520, 28],                            opened: true,  keyboard: false },
        launcher:  { rank: 5, size: [520, 400, 28],                            opened: true,  keyboard: true },
        clipboard: { rank: 5, size: [520, 400, 28],                            opened: true,  keyboard: true },
        power:     { rank: 5, size: [360, 124, 28],                            opened: true,  keyboard: true }
    })
    readonly property var current: modes[mode]

    readonly property bool resting: mode === "idle" || mode === "media"
    // True while the current mode is a timed popup (e.g. the media card on pause).
    readonly property bool timed: revert.running

    function settle() { mode = restMode }

    // ms > 0: settle after that long. ms = 0: stay until close().
    function request(m, ms) {
        if (!modes[m]) { console.warn("PillState: unknown mode", m); return }
        if (modes[m].rank < modes[mode].rank) return
        mode = m
        if (ms > 0) { revert.interval = ms; revert.restart() }
        else revert.stop()
    }

    function close() {
        revert.stop()
        settle()
    }

    // For keybinds: open the mode, or close it if it is already showing.
    function toggle(m) {
        if (mode === m) close()
        else request(m, 0)
    }

    // Follow the resting mode, but never cut a timed popup short.
    onRestModeChanged: {
        if (mode === "idle" && restMode === "media") mode = "media"
        else if (mode === "media" && restMode === "idle" && !revert.running) mode = "idle"
    }

    Timer { id: revert; onTriggered: PillState.settle() }
}
