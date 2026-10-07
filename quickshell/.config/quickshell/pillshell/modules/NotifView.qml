import QtQuick
import "../config"
import "../services"

Item {
    readonly property var n: Notifs.current

    // Left click: open it in its app (or dismiss if it can't). Right click: dismiss.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => {
            const n = Notifs.current
            if (m.button === Qt.RightButton || !Notifs.activate(n)) n?.dismiss()
            PillState.close()
        }
    }

    Column {
        anchors { fill: parent; margins: 16 }
        spacing: 3

        Text {
            text: n?.appName ?? ""
            color: Config.dim
            font.family: Config.font
            font.pixelSize: 11
        }
        Text {
            width: parent.width
            text: n?.summary ?? ""
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
        Text {
            width: parent.width
            text: n?.body ?? ""
            color: Config.fg
            opacity: 0.8
            font.family: Config.font
            font.pixelSize: 12
            elide: Text.ElideRight
            maximumLineCount: 2
            wrapMode: Text.Wrap
        }
    }
}
