import QtQuick
import "../services"

// A pill content area that only exists while its mode is active.
Loader {
    property string mode
    anchors.fill: parent
    active: PillState.mode === mode
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 180 } }
}
