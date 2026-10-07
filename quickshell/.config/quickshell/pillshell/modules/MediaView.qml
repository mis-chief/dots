import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    readonly property var p: Media.player

    RowLayout {
        anchors { fill: parent; margins: 12; rightMargin: 20 }
        spacing: 12

        Image {
            Layout.preferredWidth: 48
            Layout.preferredHeight: 48
            source: p?.trackArtUrl ?? ""
            fillMode: Image.PreserveAspectCrop
            sourceSize: Qt.size(96, 96)
            asynchronous: true
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1
            Text {
                Layout.fillWidth: true
                text: p?.trackTitle ?? ""
                color: Config.fg
                font.family: Config.font
                font.pixelSize: 13
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
            Text {
                Layout.fillWidth: true
                text: p?.trackArtist ?? ""
                color: Config.dim
                font.family: Config.font
                font.pixelSize: 11
                elide: Text.ElideRight
            }
        }

        Row {
            spacing: 16
            Layout.alignment: Qt.AlignVCenter
            IconButton { size: 16; name: "prev"; onClicked: p?.previous() }
            IconButton {
                size: 18
                name: p?.isPlaying ? "pause" : "play"
                color: Config.accent
                onClicked: p?.togglePlaying()
            }
            IconButton { size: 16; name: "next"; onClicked: p?.next() }
        }
    }
}
