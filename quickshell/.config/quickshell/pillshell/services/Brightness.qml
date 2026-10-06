pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick
import "../config"

Singleton {
    id: root

    property real value: 0          // 0..1
    property bool showOnRead: false
    property int target: -1         // latest slider value waiting to be written

    // Keybind path: step, then read back and show the OSD.
    function change(dir) {
        root.showOnRead = true
        setter.command = ["brightnessctl", "set", dir === "up" ? "5%+" : "5%-"]
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
        setter.command = ["brightnessctl", "set", t + "%"]
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
        command: ["brightnessctl", "-m"]   // device,class,current,percent,max
        stdout: StdioCollector {
            onStreamFinished: {
                const parts = text.trim().split(",")
                root.value = parseInt(parts[3]) / 100
                if (root.showOnRead) {
                    root.showOnRead = false
                    PillState.osdKind = "brightness"
                    PillState.request("osd", Config.osdMs)
                }
            }
        }
    }

    Component.onCompleted: getter.running = true
}
