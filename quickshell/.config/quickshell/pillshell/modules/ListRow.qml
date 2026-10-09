import QtQuick
import QtQuick.Layouts
import "../config"

// One line in the Wi-Fi and Bluetooth lists: icon, label, a dim note, then
// whatever the caller puts inside (small status icons).
Rectangle {
    id: root
    property alias name: icon.name
    property alias code: icon.code
    property string label
    property string note
    property color noteColor: Config.dim
    property bool selected: false
    default property alias trailing: extras.data
    signal clicked()
    signal rightClicked()

    height: 40
    radius: 14
    color: hit.containsMouse || selected ? Config.track : "transparent"

    MouseArea {
        id: hit
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: m => m.button === Qt.RightButton ? root.rightClicked() : root.clicked()
    }

    RowLayout {
        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
        spacing: 10

        Icon { id: icon; size: 18 }
        Text {
            Layout.fillWidth: true
            text: root.label
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 13
            elide: Text.ElideRight
        }
        Text {
            visible: text !== ""
            text: root.note
            color: root.noteColor
            font.family: Config.font
            font.pixelSize: 12
        }
        Row {
            id: extras
            spacing: 8
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
