import Quickshell
import QtQuick
import "../config"
import "../services"

Item {
    // The clock only ticks while this view exists (i.e. while the pill is idle).
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        anchors.centerIn: parent
        spacing: 12

        Row {   // hidden on machines without a battery
            visible: Battery.present
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4
            Icon {
                anchors.verticalCenter: parent.verticalCenter
                size: 16
                code: Glyphs.battery(Battery.percent, Battery.charging)
                color: Battery.charging ? Config.accent : (Battery.low ? Config.warn : Config.fg)
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Battery.percent + "%"
                color: Config.dim
                font.family: Config.font
                font.pixelSize: 11
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Qt.formatDateTime(clock.date, "hh:mm")
            color: Config.fg
            font.family: Config.font
            font.pixelSize: 14
            font.weight: Font.Medium
        }
    }
}
