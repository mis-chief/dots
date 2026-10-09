pragma Singleton
import Quickshell
import QtQuick
import "../config"

// Single source of truth for what the pill is showing.
// A request can only replace the current mode if its rank is equal or higher.
// When a timed or closed mode ends, the pill settles into `restMode`
// ("idle", or "media" while something is playing).
Singleton {
    property string mode: "idle"
    property string restMode: "idle"
    property string osdKind: "volume"   // "volume" | "brightness" | "workspace"
    property bool hovered: false        // the mouse is over the pill

    // The player pill widens under the mouse to make room for previous / skip:
    // two more buttons at a 28px pitch. Centred, so play/pause stays where it was.
    // The volume / brightness / workspace popup uses the same width, so it doesn't
    // resize the pill while something is playing.
    readonly property int mediaWidth: 320
    readonly property int mediaHoverExtra: 56

    // Everything that differs per mode. To add a mode: add a row here, a Slot for its
    // view in modules/Pill.qml, and (if it has a keybind) an IpcHandler in shell.qml.
    //   rank      what may interrupt what (see above)
    //   size      [width, height, radius] of the pill. The resting pill and the brief
    //             popups share one height (`bar`); only the width changes between them.
    //   opened    the user opened it on purpose: click-away closes it, and it is
    //             drawn over fullscreen windows
    //   keyboard  takes keyboard focus while open
    readonly property var modes: ({
        idle:      { rank: 0, size: bar(Battery.present ? 138 : 96),            opened: false, keyboard: false },
        media:     { rank: 1, size: bar(mediaWidth + (hovered ? mediaHoverExtra : 0)), opened: false, keyboard: false },
        osd:       { rank: 2, size: bar(mediaWidth),                           opened: false, keyboard: false },
        notif:     { rank: 3, size: [380, 84, 28],                             opened: false, keyboard: false },
        control:   { rank: 4, size: [440, 520, 28],                            opened: true,  keyboard: false },
        // Pages of the control center: same rank and size, so it can switch to them and back.
        wifi:      { rank: 4, size: [440, 520, 28],                            opened: true,  keyboard: true },
        bluetooth: { rank: 4, size: [440, 520, 28],                            opened: true,  keyboard: true },
        launcher:  { rank: 5, size: [520, 400, 28],                            opened: true,  keyboard: true },
        clipboard: { rank: 5, size: [520, 400, 28],                            opened: true,  keyboard: true },
        power:     { rank: 5, size: [360, 124, 28],                            opened: true,  keyboard: true }
    })
    readonly property var current: modes[mode]

    readonly property bool resting: mode === "idle" || mode === "media"

    function bar(width) { return [width, Config.pillHeight, Config.pillHeight / 2] }

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
