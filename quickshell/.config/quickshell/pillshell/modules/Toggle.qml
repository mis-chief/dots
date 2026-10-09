import QtQuick
import "../config"

// On/off switch in the header of the Wi-Fi and Bluetooth pages.
Rectangle {
    id: root
    property bool on: false
    signal clicked()

    implicitWidth: 40
    implicitHeight: 22
    radius: 11
    color: on ? Config.accent : Config.track
    Behavior on color { ColorAnimation { duration: 140 } }

    Rectangle {
        y: 3
        x: root.on ? root.width - width - 3 : 3
        width: 16
        height: 16
        radius: 8
        color: root.on ? Config.bg : Config.fg
        Behavior on x { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors { fill: parent; margins: -8 }   // generous hit area
        onClicked: root.clicked()
    }
}
