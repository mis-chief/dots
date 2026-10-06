import QtQuick
import "../config"

// Square-ish toggle used in the control center. Icon via `name` (Glyphs.map) or `code`.
Rectangle {
    id: root
    property string name
    property int code: 0
    property bool active: false
    signal clicked()

    implicitHeight: 52
    radius: 18
    color: active ? Config.accent : Config.track
    Behavior on color { ColorAnimation { duration: 140 } }

    Icon {
        anchors.centerIn: parent
        name: root.name
        code: root.code
        color: root.active ? Config.bg : Config.fg
    }

    MouseArea { anchors.fill: parent; onClicked: root.clicked() }
}
