pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

Singleton {
    id: root

    property bool available: false  // false on machines without a backlight (desktops)
    property real value: 0          // 0..1
    property bool showOnRead: false
    property int target: -1         // latest slider value waiting to be written

    // Keybind path: step, then read back and show the OSD.
    function change(dir) {
        if (!available) return
        root.showOnRead = true
        setter.command = ["brightnessctl", "-c", "backlight", "set", dir === "up" ? "5%+" : "5%-"]
        setter.running = true
    }

    // Slider path: only one brightnessctl runs at a time; the newest value wins.
    function setFraction(f) {
        value = Math.max(0.01, Math.min(1, f))   // never allow fully black
        target = Math.round(value * 100)
        if (!setter.running) flush()
    }

    function flush() {
        const t = target
        target = -1
        setter.command = ["brightnessctl", "-c", "backlight", "set", t + "%"]
        setter.running = true
    }

    Process {
        id: setter
        onExited: {
            if (root.target >= 0) root.flush()
            else if (root.showOnRead) getter.running = true
        }
    }

    Process {
        id: getter
        command: ["brightnessctl", "-c", "backlight", "-m"]   // device,class,current,percent,max
        stdout: StdioCollector {
            onStreamFinished: {
                const pct = parseInt(text.trim().split(",")[3])
                root.available = !isNaN(pct)
                if (!root.available) return
                root.value = pct / 100
                if (root.showOnRead) {
                    root.showOnRead = false
                    PillState.osdKind = "brightness"
                    PillState.request("osd", Config.osdMs)
                }
            }
        }
    }

    // Something else may have changed the brightness; re-read when the slider is shown.
    Connections {
        target: PillState
        function onModeChanged() { if (PillState.mode === "control") getter.running = true }
    }

    Component.onCompleted: getter.running = true
}
