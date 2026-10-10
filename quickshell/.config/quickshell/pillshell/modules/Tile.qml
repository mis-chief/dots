import QtQuick
import "../config"

// Square-ish toggle used in the control center. Icon via `name` (Glyphs.map) or `code`,
// with an optional caption underneath.
Item {
    id: root
    property string name
    property int code: 0
    property bool active: false
    property string label
    signal clicked()
    signal rightClicked()

    implicitHeight: face.height + (label !== "" ? caption.implicitHeight + 6 : 0)

    Rectangle {
        id: face
        width: parent.width
        height: 52
        radius: 18
        color: root.active ? Config.accent : Config.track
        Behavior on color { ColorAnimation { duration: 140 } }

        Icon {
            anchors.centerIn: parent
            name: root.name
            code: root.code
            color: root.active ? Config.bg : Config.fg
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
        }
    }

    Text {
        id: caption
        visible: root.label !== ""
        anchors { top: face.bottom; topMargin: 6 }
        width: parent.width
        text: root.label
        color: Config.dim
        font.family: Config.font
        font.pixelSize: 10
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
    }
}
