import QtQuick
import "../config"
import "../services"

// One dot per workspace; the current one stretches into a bar.
Row {
    spacing: 6

    Repeater {
        model: Workspaces.ids

        delegate: Rectangle {
            required property int modelData
            readonly property bool current: modelData === Workspaces.active

            width: current ? 16 : 6
            height: 6
            radius: 3
            color: current ? Config.accent : Config.dim

            Behavior on width { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 180 } }
        }
    }
}
