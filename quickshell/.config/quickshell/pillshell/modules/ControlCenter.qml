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
    readonly property int btConnected: Bluetooth.devices.values.filter(d => d.connected).length

    component Txt: Text {
        color: Config.fg
        font.family: Config.font
        font.pixelSize: 13
    }

    ColumnLayout {
        anchors { fill: parent; margins: 20 }
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

        // --- Toggles: five equal tiles ---
        Row {
            id: toggles
            Layout.fillWidth: true
            spacing: 10
            readonly property real tileWidth: (width - spacing * 4) / 5

            Tile {
                width: toggles.tileWidth
                code: Glyphs.wifi(Network.wifiOn, Network.connected, Network.signal)
                active: Network.wifiOn
                onClicked: Network.toggleWifi()
            }
            Tile {
                width: toggles.tileWidth
                code: !root.bt?.enabled ? Glyphs.map.bluetoothOff
                    : root.btConnected > 0 ? Glyphs.map.bluetoothOn : Glyphs.map.bluetooth
                active: root.bt?.enabled ?? false
                onClicked: { if (root.bt) root.bt.enabled = !root.bt.enabled }
            }
            Tile {
                width: toggles.tileWidth
                name: "moon"
                active: Notifs.dnd
                onClicked: Notifs.dnd = !Notifs.dnd
            }
            Tile {   // tap to cycle: power saver, balanced, performance
                width: toggles.tileWidth
                code: Power.iconCode
                active: Power.profile !== PowerProfile.Balanced
                onClicked: Power.cycle()
            }
            Tile {   // opens the power menu
                width: toggles.tileWidth
                name: "power"
                onClicked: PillState.request("power", 0)
            }
        }

        // --- Tray ---
        TrayRow {
            visible: SystemTray.items.values.length > 0
            onMenuRequested: item => root.menuItem = item
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

        // --- Notifications ---
        RowLayout {
            Layout.fillWidth: true
            Icon { name: "bell"; size: 16; color: Config.dim }
            Item { Layout.fillWidth: true }
            IconButton {
                visible: notifList.count > 0
                size: 16
                name: "trash"
                color: Config.accent
                onClicked: Notifs.clearAll()
            }
        }

        Item {   // empty state: a quiet bell
            visible: notifList.count === 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            Icon { anchors.centerIn: parent; name: "bell"; size: 28; color: Config.track }
        }

        ListView {
            id: notifList
            visible: count > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
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

                MouseArea { anchors.fill: parent; onClicked: modelData.dismiss() }   // tap to dismiss
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
