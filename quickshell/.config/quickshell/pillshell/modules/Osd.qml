import QtQuick
import QtQuick.Layouts
import "../config"
import "../services"

Item {
    readonly property bool isVolume: PillState.osdKind === "volume"
    readonly property bool isWorkspace: PillState.osdKind === "workspace"
    readonly property real value: isVolume ? Audio.volume : Brightness.value

    WorkspaceDots {
        visible: isWorkspace
        anchors.centerIn: parent
    }

    RowLayout {
        visible: !isWorkspace
        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
        spacing: 12

        Icon {
            code: isVolume ? Glyphs.volume(Audio.volume, Audio.muted) : Glyphs.brightness(Brightness.value)
            color: isVolume && Audio.muted ? Config.dim : Config.fg
        }

        Rectangle {
            Layout.fillWidth: true
            height: 6
            radius: 3
            color: Config.track

            Rectangle {
                height: parent.height
                radius: 3
                color: Audio.muted && isVolume ? Config.dim : Config.accent
                width: parent.width * Math.max(0, Math.min(1, value))
                Behavior on width { NumberAnimation { duration: 80 } }
            }
        }

        Text {
            text: Math.round(value * 100) + "%"
            color: Config.dim
            font.family: Config.font
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: 38
        }
    }
}
