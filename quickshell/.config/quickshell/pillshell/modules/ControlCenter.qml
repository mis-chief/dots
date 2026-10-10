import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower
import Quickshell.Services.SystemTray
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    id: root

    property var menuItem: null   // tray item whose menu is showing

    readonly property var bt: Bluetooth.defaultAdapter
    readonly property var btDevice: Bluetooth.devices.values.find(d => d.connected) ?? null

    // The pill hugs the content, up to the full height once notifications pile up.
    // A tray menu covers the whole view, so it gets the full height too.
    readonly property int wantedHeight: menuItem !== null ? PillState.controlMaxHeight
        : Math.min(PillState.controlMaxHeight, col.implicitHeight + 40)
    onWantedHeightChanged: PillState.controlHeight = wantedHeight
    Component.onCompleted: PillState.controlHeight = wantedHeight

    component Txt: Text {
        color: Config.fg
        font.family: Config.font
        font.pixelSize: 13
    }

    ColumnLayout {
        id: col
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
        // Never taller than its content: spare height (while the pill is still growing)
        // would otherwise be shared out between the rows.
        height: Math.min(implicitHeight, parent.height - 40)
        spacing: 14

        // --- Sliders ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 12
            IconButton {   // tap to mute
                code: Glyphs.volume(Audio.volume, Audio.muted)
                color: Audio.muted ? Config.dim : Config.fg
                onClicked: Audio.toggleMute()
            }
            PillSlider {
                Layout.fillWidth: true
                value: Audio.volume
                fillColor: Audio.muted ? Config.dim : Config.accent
                onMoved: v => Audio.setVolume(v)
            }
            Txt {
                text: Math.round(Audio.volume * 100) + "%"
                color: Config.dim
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 42
            }
        }

        RowLayout {
            visible: Brightness.available   // no backlight on a desktop
            Layout.fillWidth: true
            spacing: 12
            Icon { code: Glyphs.brightness(Brightness.value) }
            PillSlider {
                Layout.fillWidth: true
                value: Brightness.value
                onMoved: v => Brightness.setFraction(v)
            }
            Txt {
                text: Math.round(Brightness.value * 100) + "%"
                color: Config.dim
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 42
            }
        }

        // --- Toggles: five equal tiles, each captioned with its state ---
        Row {
            id: toggles
            Layout.fillWidth: true
            spacing: 10
            readonly property real tileWidth: (width - spacing * 4) / 5

            Tile {   // right click: pick a network
                width: toggles.tileWidth
                code: Glyphs.wifi(Network.wifiOn, Network.connected, Network.signal)
                active: Network.wifiOn
                label: Network.connected ? Network.active.name : Network.wifiOn ? "Wi-Fi" : "Off"
                onClicked: Network.toggleWifi()
                onRightClicked: PillState.request("wifi", 0)
            }
            Tile {   // right click: pick a device
                width: toggles.tileWidth
                code: !root.bt?.enabled ? Glyphs.map.bluetoothOff
                    : root.btDevice ? Glyphs.map.bluetoothOn : Glyphs.map.bluetooth
                active: root.bt?.enabled ?? false
                label: !root.bt?.enabled ? "Off" : root.btDevice ? root.btDevice.name : "Bluetooth"
                onClicked: { if (root.bt) root.bt.enabled = !root.bt.enabled }
                onRightClicked: PillState.request("bluetooth", 0)
            }
            Tile {
                width: toggles.tileWidth
                name: "moon"
                active: Notifs.dnd
                label: "Quiet"
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            Tile {   // tap to cycle: power saver, balanced, performance
                width: toggles.tileWidth
                code: Power.iconCode
                active: Power.profile !== PowerProfile.Balanced
                label: Power.profile === PowerProfile.PowerSaver ? "Saver"
                    : Power.profile === PowerProfile.Performance ? "Performance" : "Balanced"
                onClicked: Power.cycle()
            }
            Tile {   // opens the power menu
                width: toggles.tileWidth
                name: "power"
                label: "Power"
                onClicked: PillState.request("power", 0)
            }
        }

        // --- Media ---
        Rectangle {
            visible: Media.player !== null
            Layout.fillWidth: true
            Layout.preferredHeight: 76
            radius: 20
            color: Config.track

            RowLayout {
                anchors { fill: parent; margins: 10 }
                spacing: 12

                Image {
                    Layout.preferredWidth: 56
                    Layout.preferredHeight: 56
                    source: Media.player?.trackArtUrl ?? ""
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(112, 112)
                    asynchronous: true
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Txt {
                        Layout.fillWidth: true
                        text: Media.player?.trackTitle ?? ""
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                    }
                    Txt {
                        Layout.fillWidth: true
                        text: Media.player?.trackArtist ?? ""
                        color: Config.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Row {
                    spacing: 16
                    Layout.alignment: Qt.AlignVCenter
                    IconButton { size: 16; name: "prev"; onClicked: Media.player?.previous() }
                    IconButton {
                        size: 18
                        name: Media.player?.isPlaying ? "pause" : "play"
                        color: Config.accent
                        onClicked: Media.player?.togglePlaying()
                    }
                    IconButton { size: 16; name: "next"; onClicked: Media.player?.next() }
                }
            }
        }

        // --- CPU, memory, uptime, battery draw and time left; tray on the right ---
        // The tray drops to a row of its own when the two don't fit side by side.
        GridLayout {
            id: footer
            Layout.fillWidth: true
            readonly property bool hasTray: SystemTray.items.values.length > 0
            readonly property bool oneRow: hasTray
                && stats.implicitWidth + tray.implicitWidth + columnSpacing <= col.width
            columns: oneRow ? 2 : 1
            columnSpacing: 12
            rowSpacing: 14

            StatsRow {
                id: stats
                Layout.fillWidth: true
                spread: !footer.oneRow
            }
            TrayRow {
                id: tray
                visible: footer.hasTray
                onMenuRequested: item => root.menuItem = item
            }
        }

        // --- Notifications: only there when there are any ---
        RowLayout {
            visible: notifList.count > 0
            Layout.fillWidth: true
            Txt {
                text: notifList.count + (notifList.count === 1 ? " notification" : " notifications")
                color: Config.dim
                font.pixelSize: 11
            }
            Item { Layout.fillWidth: true }
            IconButton {
                size: 16
                name: "trash"
                color: Config.accent
                onClicked: Notifs.clearAll()
            }
        }

        ListView {
            id: notifList
            visible: count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true   // shrinks, and scrolls, once the pill is at full height
            Layout.preferredHeight: count * 58 + Math.max(0, count - 1) * spacing
            clip: true
            spacing: 6

            // newest first
            model: ScriptModel { values: Notifs.server.trackedNotifications.values.slice().reverse() }

            delegate: Rectangle {
                required property var modelData
                width: notifList.width
                height: 58
                radius: 16
                color: Config.track

                Column {
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14; topMargin: 9 }
                    spacing: 2
                    Txt {
                        width: parent.width
                        text: modelData.summary
                        elide: Text.ElideRight
                        font.weight: Font.DemiBold
                    }
                    Txt {
                        width: parent.width
                        text: modelData.body
                        color: Config.dim
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                // Left click: open it in its app (or dismiss if it can't). Right click: dismiss.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: m => {
                        if (m.button === Qt.RightButton || !Notifs.activate(modelData)) modelData.dismiss()
                        else PillState.close()
                    }
                }
            }
        }
    }

    TrayMenu {   // declared last so it draws over the rest
        anchors.fill: parent
        visible: root.menuItem !== null
        item: root.menuItem
        onDismissed: root.menuItem = null
    }
}
