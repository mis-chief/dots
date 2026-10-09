import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

// The player pill: art, title and artist, play/pause.
// Under the mouse the pill widens and previous / skip slide out of play/pause.
Item {
    id: root
    readonly property var p: Media.player

    // 0..1, how far the pill has widened. Taken from its width as it animates, so the
    // buttons move with the pill and play/pause stays put on screen.
    readonly property real reveal: Math.max(0, Math.min(1, (width - PillState.mediaWidth) / PillState.mediaHoverExtra))

    RowLayout {
        anchors { fill: parent; leftMargin: 8; rightMargin: 16 }
        spacing: 10

        ClippingRectangle {
            visible: art.status === Image.Ready
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: Config.track
            Image {
                id: art
                anchors.fill: parent
                source: p?.trackArtUrl ?? ""
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(56, 56)
                asynchronous: true
            }
        }

        Text {
            Layout.fillWidth: true
            Layout.leftMargin: art.status === Image.Ready ? 0 : 8
            text: [p?.trackTitle, p?.trackArtist].filter(s => s).join(" — ")
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        Item {
            Layout.preferredWidth: 16 + root.reveal * PillState.mediaHoverExtra
            Layout.preferredHeight: 16

            IconButton {
                visible: root.reveal > 0   // hidden ones must not take clicks meant for play/pause
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -root.reveal * PillState.mediaHoverExtra / 2
                opacity: root.reveal
                size: 14
                name: "prev"
                onClicked: p?.previous()
            }
            IconButton {
                visible: root.reveal > 0
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.reveal * PillState.mediaHoverExtra / 2
                opacity: root.reveal
                size: 14
                name: "next"
                onClicked: p?.next()
            }
            IconButton {
                anchors.centerIn: parent
                size: 16
                name: p?.isPlaying ? "pause" : "play"
                color: Config.accent
                onClicked: p?.togglePlaying()
            }
        }
    }
}
