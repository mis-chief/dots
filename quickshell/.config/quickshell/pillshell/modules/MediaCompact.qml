import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// One-line media view for the resting pill; fits the strip the pill reserves.
Item {
    readonly property var p: Media.player

    RowLayout {
        anchors { fill: parent; leftMargin: 6; rightMargin: 12 }
        spacing: 8

        ClippingRectangle {
            visible: art.status === Image.Ready
            Layout.preferredWidth: 22
            Layout.preferredHeight: 22
            radius: 11
            color: Config.track
            Image {
                id: art
                anchors.fill: parent
                source: p?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(44, 44)
                asynchronous: true
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: art.status === Image.Ready ? 0 : 6
            text: [p?.trackTitle, p?.trackArtist].filter(s => s).join(" — ")
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        IconButton {
            size: 16
            name: p?.isPlaying ? "pause" : "play"
            color: Config.accent
            onClicked: p?.togglePlaying()
        }
    }
}
