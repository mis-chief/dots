import Quickshell
import Quickshell.Networking as Nm   // aliased: it has a type named Network, like our service
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// Wi-Fi networks. Opened by right-clicking the Wi-Fi tile in the control center.
// Click a network to connect (asks for a password if one is needed); click the
// connected one, or right-click a saved one, for Disconnect / Forget.
Item {
    id: root

    property var selected: null     // network whose extra line is showing
    property string panel: ""       // "actions" | "password"
    property var asked: null        // network the last typed password was for
    property var noted: null        // network with a message next to it
    property string message: ""

    readonly property string emptyText: !Network.device ? "No Wi-Fi adapter"
        : !Network.wifiOn ? "Wi-Fi is off"
        : Network.networks.length === 0 ? "Looking for networks…" : ""

    function back() { PillState.request("control", 0) }

    function open(n, which) {
        selected = n
        panel = which
        if (which !== "password") root.forceActiveFocus()
    }
    function collapse() { open(null, "") }

    function note(n, text) { noted = n; message = text }

    function connect(n, psk) {
        collapse()
        note(null, "")
        asked = psk ? n : null
        Network.connect(n, psk)
    }

    function activate(n) {
        if (n.connected) open(n, selected === n ? "" : "actions")
        else if (n.stateChanging) return
        else if (!n.known && Network.isEnterprise(n)) note(n, "Not supported")
        // A new network that takes a password: ask first instead of failing once to find out.
        else if (!n.known && Network.takesPassword(n)) open(n, "password")
        else connect(n)
    }

    Connections {
        target: Network
        function onFailed(n, reason) {
            if (reason === Nm.ConnectionFailReason.NoSecrets && !Network.isEnterprise(n)) {
                // Either the password just typed was wrong, or the saved one no longer works.
                root.open(n, "password")
                root.note(n, root.asked === n ? "Wrong password" : "Password needed")
            } else {
                root.note(n, reason === Nm.ConnectionFailReason.WifiAuthTimeout ? "Timed out"
                    : reason === Nm.ConnectionFailReason.WifiNetworkLost ? "Out of range" : "Failed")
            }
        }
        // The selected network can drop out of range while its line is open.
        function onNetworksChanged() {
            if (root.selected && !Network.networks.includes(root.selected)) root.collapse()
        }
    }

    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: selected ? collapse() : back()

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
                text: "Wi-Fi"
                color: Config.fg
                font.family: Config.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }
            Toggle {
                visible: Network.device !== null
                on: Network.wifiOn
                onClicked: Network.toggleWifi()
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

            model: ScriptModel { values: Network.wifiOn ? Network.networks : [] }

            delegate: Column {
                id: entry
                required property var modelData   // WifiNetwork
                readonly property bool open: root.selected === modelData && root.panel !== ""
                width: list.width
                opacity: !modelData.known && Network.isEnterprise(modelData) ? 0.4 : 1

                ListRow {
                    width: parent.width
                    code: Glyphs.wifi(true, true, entry.modelData.signalStrength * 100)
                    label: entry.modelData.name
                    selected: entry.open
                    note: root.noted === entry.modelData ? root.message
                        : entry.modelData.state === Nm.ConnectionState.Connecting ? "Connecting…"
                        : entry.modelData.state === Nm.ConnectionState.Disconnecting ? "Disconnecting…"
                        : entry.modelData.known && !entry.modelData.connected ? "Saved" : ""
                    noteColor: root.noted === entry.modelData ? Config.warn : Config.dim
                    onClicked: root.activate(entry.modelData)
                    onRightClicked: {
                        if (entry.modelData.known) root.open(entry.modelData, entry.open ? "" : "actions")
                    }

                    Icon {
                        visible: !Network.isOpen(entry.modelData)
                        name: "lock"
                        size: 14
                        color: Config.dim
                    }
                    Icon {
                        visible: entry.modelData.connected
                        name: "check"
                        size: 16
                        color: Config.accent
                    }
                }

                Row {   // Disconnect / Connect, Forget
                    visible: entry.open && root.panel === "actions"
                    leftPadding: 40
                    topPadding: 4
                    bottomPadding: 8
                    spacing: 8
                    Chip {
                        text: entry.modelData.connected ? "Disconnect" : "Connect"
                        onClicked: {
                            const n = entry.modelData
                            if (n.connected) { root.collapse(); n.disconnect() }
                            else root.connect(n)
                        }
                    }
                    Chip {
                        visible: entry.modelData.known
                        text: "Forget"
                        warn: true
                        onClicked: {
                            const n = entry.modelData
                            root.collapse()
                            n.forget()
                        }
                    }
                }

                Loader {   // password field, created on demand so it starts empty and focused
                    active: entry.open && root.panel === "password"
                    visible: active
                    width: parent.width
                    sourceComponent: Item {
                        height: 48

                        Rectangle {
                            anchors { fill: parent; leftMargin: 40; topMargin: 4; bottomMargin: 8 }
                            radius: 14
                            color: Config.track

                            Text {
                                visible: psk.text === ""
                                anchors { verticalCenter: parent.verticalCenter; left: psk.left }
                                text: "Password, then Enter"
                                color: Config.dim
                                font.family: Config.font
                                font.pixelSize: 13
                            }
                            TextInput {
                                id: psk
                                anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                                verticalAlignment: TextInput.AlignVCenter
                                color: Config.fg
                                font.family: Config.font
                                font.pixelSize: 13
                                echoMode: TextInput.Password
                                clip: true
                                Component.onCompleted: forceActiveFocus()

                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                        event.accepted = true
                                        // WPA passwords are 8 to 63 characters; shorter can't be right.
                                        if (text.length < 8) root.note(entry.modelData, "Too short")
                                        else root.connect(entry.modelData, text)   // closes this field
                                    } else if (event.key === Qt.Key_Escape) {
                                        event.accepted = true
                                        root.collapse()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
