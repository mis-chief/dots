import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// CPU, memory, uptime and battery draw for the control center.
// A view rather than a service on purpose: the /proc polling below only runs
// while the control center is open, and stops when its Slot unloads this.
RowLayout {
    id: root
    spacing: 6

    property real cpu: -1          // 0..1, -1 until two samples exist
    property real mem: -1          // 0..1
    property int uptime: -1        // seconds
    property var lastCpu: null     // [total, idle] from the previous sample

    function span(s) {
        const d = Math.floor(s / 86400), h = Math.floor(s % 86400 / 3600), m = Math.floor(s % 3600 / 60)
        if (d > 0) return d + "d " + h + "h"
        if (h > 0) return h + "h " + String(m).padStart(2, "0") + "m"
        return m + "m"
    }
    function pct(f) { return f < 0 ? "--" : Math.round(f * 100) + "%" }

    // Each FileView reads once when created; the timers below re-read.
    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            // cpu  user nice system idle iowait irq softirq steal ...
            const f = text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number)
            const total = f.reduce((a, b) => a + b, 0)
            const idle = f[3] + (f[4] || 0)
            const last = root.lastCpu
            if (last && total > last[0]) root.cpu = 1 - (idle - last[1]) / (total - last[0])
            root.lastCpu = [total, idle]
        }
    }
    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            const t = text()
            const total = parseInt(t.match(/^MemTotal:\s+(\d+)/m)?.[1] ?? 0)
            const avail = parseInt(t.match(/^MemAvailable:\s+(\d+)/m)?.[1] ?? 0)
            if (total > 0) root.mem = (total - avail) / total
        }
    }
    FileView {
        id: upFile
        path: "/proc/uptime"
        onLoaded: root.uptime = Math.floor(parseFloat(text()))
    }

    // CPU usage needs two samples, so the second one comes quickly.
    Timer {
        running: true
        repeat: true
        interval: root.cpu < 0 ? 500 : 2000
        onTriggered: { statFile.reload(); memFile.reload() }
    }
    Timer { running: true; repeat: true; interval: 60000; onTriggered: upFile.reload() }

    component Label: Text {
        color: Config.dim
        font.family: Config.font
        font.pixelSize: 11
    }
    component Value: Label { color: Config.fg }

    Label { text: "CPU" }
    Value { text: root.pct(root.cpu); Layout.preferredWidth: 30 }
    Label { text: "MEM" }
    Value { text: root.pct(root.mem); Layout.preferredWidth: 30 }
    Label { text: "UP" }
    Value { text: root.uptime < 0 ? "--" : root.span(root.uptime) }

    Item { Layout.fillWidth: true }

    // From UPower, so event driven. Nothing to show when full on AC (no draw).
    Value {
        visible: Battery.present && Battery.watts > 0
        text: (Battery.charging ? "+" : "") + Battery.watts.toFixed(1) + "W"
            + (Battery.secondsLeft > 0 ? " " + root.span(Battery.secondsLeft) : "")
        color: Battery.charging ? Config.accent : Config.fg
    }
}
