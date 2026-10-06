import Quickshell
import QtQuick
import "../config"
import "../services"

Item {
    id: root

    property string armed: ""    // destructive action waiting for a second click

    Component.onCompleted: forceActiveFocus()
    Keys.onEscapePressed: PillState.close()

    Timer { id: disarm; interval: 3000; onTriggered: root.armed = "" }

    function trigger(key, needsConfirm) {
        if (needsConfirm && armed !== key) {   // first click arms, second click runs
            armed = key
            disarm.restart()
            return
        }
        const verb = { sleep: "suspend", restart: "reboot", poweroff: "poweroff" }[key]
        PillState.close()
        Quickshell.execDetached(["systemctl", verb])
    }

    component Action: Rectangle {
        id: btn
        property string key
        property string label
        property string glyph
        property bool needsConfirm: false
        readonly property bool isArmed: root.armed === key

        width: 96
        height: 84
        radius: 22
        color: isArmed ? Config.warn : (hit.containsMouse ? Qt.lighter(Config.track, 1.35) : Config.track)
        Behavior on color { ColorAnimation { duration: 120 } }

        Column {
            anchors.centerIn: parent
            spacing: 8
            Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: btn.glyph
                size: 26
                color: btn.isArmed ? Config.bg : Config.fg
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: btn.isArmed ? "Confirm" : btn.label
                color: btn.isArmed ? Config.bg : Config.dim
                font.family: Config.font
                font.pixelSize: 11
            }
        }

        MouseArea {
            id: hit
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.trigger(btn.key, btn.needsConfirm)
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 16
        Action { key: "sleep";    label: "Sleep";     glyph: "sleep" }
        Action { key: "restart";  label: "Restart";   glyph: "restart"; needsConfirm: true }
        Action { key: "poweroff"; label: "Power off"; glyph: "power"; needsConfirm: true }
    }
}
