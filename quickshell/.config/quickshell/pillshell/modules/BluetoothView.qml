import Quickshell
import Quickshell.Bluetooth
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// Bluetooth devices. Opened by right-clicking the Bluetooth tile in the control center.
// Click to connect or disconnect; clicking a new device pairs it first. Right-click
// a paired device for Forget. Devices that ask for a PIN can't be paired from here.
Item {
    id: root

    readonly property var bt: Bluetooth.defaultAdapter
    property var selected: null   // paired device whose Forget line is showing

    // Paired devices always; others only once they have told us their name.
    readonly property var devices: (bt?.devices.values ?? [])
        .filter(d => d.paired || d.deviceName !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))

    readonly property string emptyText: !bt ? "No Bluetooth adapter"
        : !bt.enabled ? "Bluetooth is off"
        : devices.length === 0 ? "Looking for devices…" : ""

    function back() { PillState.request("control", 0) }

    // Discovery runs only while this page is open.
    function discover(on) { if (bt && bt.enabled && bt.discovering !== on) bt.discovering = on }
    Component.onCompleted: { forceActiveFocus(); discover(true) }
    Component.onDestruction: discover(false)
    Connections {
        target: root.bt
        function onEnabledChanged() { root.discover(true) }
    }

    onDevicesChanged: if (selected && !devices.includes(selected)) selected = null
    Keys.onEscapePressed: selected ? selected = null : back()

    ColumnLayout {
        anchors { fill: parent; margins: 20 }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 22   // the switch's height, so nothing moves when it is hidden
            spacing: 10
            IconButton { name: "back"; size: 18; onClicked: root.back() }
            Text {
                Layout.fillWidth: true
                text: "Bluetooth"
                color: Config.fg
                font.family: Config.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Toggle {
                visible: root.bt !== null
                on: root.bt?.enabled ?? false
                onClicked: root.bt.enabled = !root.bt.enabled
            }
        }

        Item {
            visible: root.emptyText !== ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            Text {
                anchors.centerIn: parent
                text: root.emptyText
                color: Config.dim
                font.family: Config.font
                font.pixelSize: 13
            }
        }

        ListView {
            id: list
            visible: root.emptyText === ""
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2

            model: ScriptModel { values: root.bt?.enabled ? root.devices : [] }

            delegate: Column {
                id: entry
                required property var modelData   // BluetoothDevice
                readonly property bool open: root.selected === modelData
                property bool connectWhenPaired: false
                width: list.width

                Connections {
                    target: entry.modelData
                    function onPairedChanged() {
                        if (!entry.modelData.paired || !entry.connectWhenPaired) return
                        entry.connectWhenPaired = false
                        entry.modelData.trusted = true   // lets it reconnect on its own later
                        entry.modelData.connect()
                    }
                    function onPairingChanged() {
                        if (!entry.modelData.pairing && !entry.modelData.paired) entry.connectWhenPaired = false
                    }
                }

                ListRow {
                    width: parent.width
                    name: entry.modelData.connected ? "bluetoothOn" : "bluetooth"
                    label: entry.modelData.name
                    selected: entry.open
                    note: entry.modelData.pairing ? "Pairing…"
                        : entry.modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                        : entry.modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                        : entry.modelData.connected && entry.modelData.batteryAvailable
                            ? Math.round(entry.modelData.battery * 100) + "%"
                        : entry.modelData.paired && !entry.modelData.connected ? "Paired" : ""
                    onClicked: {
                        const d = entry.modelData
                        root.selected = null
                        if (d.pairing) d.cancelPair()
                        else if (d.connected) d.disconnect()
                        else if (d.paired) d.connect()
                        else { entry.connectWhenPaired = true; d.pair() }
                    }
                    onRightClicked: if (entry.modelData.paired) root.selected = entry.open ? null : entry.modelData

                    Icon {
                        visible: entry.modelData.connected
                        name: "check"
                        size: 16
                        color: Config.accent
                    }
                }

                Row {
                    visible: entry.open
                    leftPadding: 40
                    topPadding: 4
                    bottomPadding: 8
                    Chip {
                        text: "Forget"
                        warn: true
                        onClicked: {
                            const d = entry.modelData
                            root.selected = null
                            d.forget()
                        }
                    }
                }
            }
        }
    }
}
