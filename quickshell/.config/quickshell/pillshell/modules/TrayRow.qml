import Quickshell
import Quickshell.Services.SystemTray
import QtQuick
import "../config"
import "../services"

// Status-notifier icons (ProtonVPN, Discord, Steam, nm-applet...).
// Left click: activate (usually opens the window). Right click: menu. Middle click: secondary action.
Row {
    id: root
    spacing: 6

    signal menuRequested(var item)

    Repeater {
        model: SystemTray.items

        delegate: Rectangle {
            id: cell
            required property var modelData   // SystemTrayItem

            width: 36
            height: 36
            radius: 12
            color: area.containsMouse ? Config.track : "transparent"

            Image {
                id: img
                anchors.centerIn: parent
                width: 20
                height: 20
                sourceSize: Qt.size(40, 40)
                source: cell.modelData.icon
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {   // fallback when an app gives no usable icon
                anchors.centerIn: parent
                visible: img.status !== Image.Ready
                text: (cell.modelData.title || cell.modelData.id || "?").charAt(0).toUpperCase()
                color: Config.fg
                font.family: Config.font
                font.pixelSize: 14
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                onClicked: m => {
                    const it = cell.modelData
                    if (m.button === Qt.MiddleButton) {
                        it.secondaryActivate()
                    } else if (m.button === Qt.RightButton || it.onlyMenu) {
                        if (it.hasMenu) root.menuRequested(it)
                    } else {
                        it.activate()
                        PillState.close()
                    }
                }
            }
        }
    }
}
