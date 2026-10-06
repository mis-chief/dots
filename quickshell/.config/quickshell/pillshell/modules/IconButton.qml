import QtQuick
import "../config"

Item {
    id: root
    property alias name: icon.name
    property alias code: icon.code
    property alias color: icon.color
    property alias size: icon.size
    signal clicked()

    implicitWidth: icon.implicitWidth
    implicitHeight: icon.implicitHeight

    Icon { id: icon }
    MouseArea {
        anchors { fill: parent; margins: -8 }   // generous hit area
        onClicked: root.clicked()
    }
}
