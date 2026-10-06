import QtQuick
import "../config"

Item {
    id: root
    property real value: 0
    property color fillColor: Config.accent
    signal moved(real v)

    implicitHeight: 28

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 10
        radius: 5
        color: Config.track

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: 5
            color: root.fillColor
        }
    }

    MouseArea {
        anchors.fill: parent
        preventStealing: true
        function set(x) { root.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: m => set(m.x)
        onPositionChanged: m => { if (pressed) set(m.x) }
    }
}
