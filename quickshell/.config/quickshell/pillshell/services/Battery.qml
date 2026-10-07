pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import QtQuick

// UPower is D-Bus event driven: no polling.
Singleton {
    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev?.isPresent ?? false
    readonly property int percent: Math.round((dev?.percentage ?? 0) * 100)   // percentage is 0..1
    readonly property bool charging: present && !UPower.onBattery             // plugged in
    readonly property bool low: present && !charging && percent <= 15
    // Draw (or charge rate) in watts, and seconds until empty (or full while charging).
    readonly property real watts: Math.abs(dev?.changeRate ?? 0)
    readonly property int secondsLeft: (charging ? dev?.timeToFull : dev?.timeToEmpty) ?? 0
}
