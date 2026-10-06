pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Thin wrapper over nmcli. Event-driven where possible:
// `nmcli monitor` is a long-lived process that costs nothing while idle, and signal
// strength (which has no event) is only polled once a minute while Wi-Fi is on.
Singleton {
    id: root

    property bool wifiOn: false
    property int signal: 0                       // 0-100, 0 when not connected
    readonly property bool connected: signal > 0

    function refresh() { radio.running = true }

    function toggleWifi() {
        wifiOn = !wifiOn
        toggler.command = ["nmcli", "radio", "wifi", wifiOn ? "on" : "off"]
        toggler.running = true
    }

    Process {
        id: radio
        command: ["nmcli", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.wifiOn = text.trim() === "enabled"
                if (root.wifiOn) scan.running = true
                else root.signal = 0
            }
        }
    }

    Process {
        id: scan   // reads cached scan results, does not trigger a new scan
        command: ["nmcli", "-t", "-f", "ACTIVE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/^yes:(\d+)$/m)
                root.signal = m ? parseInt(m[1]) : 0
            }
        }
    }

    Process { id: toggler; onExited: debounce.restart() }

    Process {   // connection events (connect, disconnect, radio toggled)
        running: true
        command: ["nmcli", "monitor"]
        stdout: SplitParser { onRead: debounce.restart() }
    }

    Timer { id: debounce; interval: 800; onTriggered: root.refresh() }
    Timer { running: root.wifiOn; interval: 60000; repeat: true; onTriggered: root.refresh() }

    Connections {
        target: PillState
        function onModeChanged() { if (PillState.mode === "control") root.refresh() }
    }

    Component.onCompleted: refresh()
}
