import QtQuick
import "../config"

// Small text button, used for the per-row actions in the Wi-Fi and Bluetooth lists.
Rectangle {
    id: root
    property alias text: label.text
    property bool warn: false
    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: 14
    color: hit.containsMouse ? Config.dim : Config.track

    Text {
        id: label
        anchors.centerIn: parent
        color: hit.containsMouse ? Config.bg : root.warn ? Config.warn : Config.fg
        font.family: Config.font
        font.pixelSize: 12
    }

    MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; onClicked: root.clicked() }
}
