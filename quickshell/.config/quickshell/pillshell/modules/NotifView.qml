import QtQuick
import "../config"
import "../services"

Item {
    readonly property var n: Notifs.current

    // Click to dismiss.
    MouseArea {
        anchors.fill: parent
        onClicked: {
            Notifs.current?.dismiss()
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
