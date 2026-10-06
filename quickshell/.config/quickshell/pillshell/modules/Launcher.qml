import Quickshell
import QtQuick
import "../config"
import "../services"

Item {
    id: root

    // "> cmd" runs a shell command; anything else searches apps.
    readonly property bool cmdMode: input.text.startsWith(">")
    readonly property var results: cmdMode ? [] : Apps.search(input.text)

    function run() {
        if (cmdMode) {
            const cmd = input.text.slice(1).trim()
            if (cmd !== "") Quickshell.execDetached(["sh", "-c", cmd])
        } else {
            results[list.currentIndex]?.execute()
        }
        PillState.close()
    }

    Component.onCompleted: input.forceActiveFocus()

    Item {
        id: field
        anchors { top: parent.top; left: parent.left; right: parent.right; margins: 20 }
        height: 44

        Text {
            visible: input.text === ""
            anchors.verticalCenter: parent.verticalCenter
            text: "Search apps, or type > to run a command"
            color: Config.dim
            font.family: Config.font
            font.pixelSize: 16
        }

        TextInput {
            id: input
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; right: parent.right }
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 16
            clip: true
            onTextChanged: list.currentIndex = 0

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Down) { list.incrementCurrentIndex(); event.accepted = true }
                else if (event.key === Qt.Key_Up) { list.decrementCurrentIndex(); event.accepted = true }
                else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { root.run(); event.accepted = true }
                else if (event.key === Qt.Key_Escape) { PillState.close(); event.accepted = true }
            }
        }

        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Config.track
        }
    }

    ListView {
        id: list
        anchors { top: field.bottom; bottom: parent.bottom; left: parent.left; right: parent.right; margins: 12 }
        clip: true
        spacing: 2
        currentIndex: 0
        highlightMoveDuration: 0

        model: ScriptModel { values: root.results }

        delegate: Rectangle {
            required property var modelData
            required property int index
            width: list.width
            height: 40
            radius: 14
            color: ListView.isCurrentItem ? Config.track : "transparent"

            Row {
                anchors { fill: parent; leftMargin: 10 }
                spacing: 12

                Image {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24; height: 24
                    sourceSize: Qt.size(24, 24)
                    source: Quickshell.iconPath(modelData.icon, true)
                        || Quickshell.iconPath("application-x-executable")
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.name
                    color: Config.fg
                    font.family: Config.font
                    font.pixelSize: 14
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: { list.currentIndex = index; root.run() }
            }
        }
    }
}
