import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../services"

// The window. What each mode needs (size, layer, focus, click-away) comes from the
// table in services/PillState.qml; this file only adds a Slot per mode at the bottom.
PanelWindow {
    id: win

    anchors.top: true
    implicitWidth: 560
    implicitHeight: 560          // must fit the largest mode
    // Reserve the idle pill's strip so windows tile below it instead of underneath.
    exclusiveZone: Config.topMargin * 2 + 32
    color: "transparent"
    mask: Region { item: pill }  // clicks outside the pill fall through

    WlrLayershell.namespace: "pill"
    // Top sits under fullscreen windows, so the resting pill and popups hide there.
    // Modes the user opened on purpose move to Overlay and still show.
    WlrLayershell.layer: PillState.current.opened ? WlrLayer.Overlay : WlrLayer.Top
    // Exclusive until the grab below is armed, then OnDemand. Exclusive takes the keyboard
    // at once, so nothing typed right after opening is lost. But while an Exclusive layer
    // has the keyboard Hyprland does not end the grab on an outside click, so click-away
    // would never fire. Stepping down to OnDemand keeps the focus and lets the grab work.
    WlrLayershell.keyboardFocus: !PillState.current.keyboard ? WlrKeyboardFocus.None
        : grabReady ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.Exclusive

    // Click-away-to-close applies to the modes the user opened on purpose.
    // The grab is armed slightly after every mode change, not just the first open.
    // Opening a mode (the click, or the keyboard focus switching to Exclusive) can make
    // Hyprland clear a grab that is already active, which would close the pill straight away.
    property bool grabReady: false
    Timer { id: armGrab; interval: 150; onTriggered: win.grabReady = true }
    Connections {
        target: PillState
        function onModeChanged() {
            win.grabReady = false
            if (PillState.modes[PillState.mode].opened) armGrab.restart()
            else armGrab.stop()
        }
    }

    HyprlandFocusGrab {
        windows: [win]
        active: PillState.current.opened && win.grabReady
        onCleared: PillState.close()
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.topMargin
        color: Config.bg
        clip: true

        readonly property var dims: PillState.current.size   // [width, height, radius]

        width: dims[0]
        height: dims[1]
        radius: dims[2]

        Behavior on width  { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        // Under the content so popups can handle their own clicks.
        // On the resting pill (idle or media): left click opens the launcher, right click the control center.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => {
                if (!PillState.resting) return
                PillState.request(m.button === Qt.RightButton ? "control" : "launcher", 0)
            }
        }

        Slot { mode: "idle";     sourceComponent: IdleView {} }
        // Full card for the brief popup, one line while resting on a playing track.
        Component { id: mediaCard;    MediaView {} }
        Component { id: mediaCompact; MediaCompact {} }
        Slot { mode: "media";    sourceComponent: PillState.timed ? mediaCard : mediaCompact }
        Slot { mode: "osd";      sourceComponent: Osd {} }
        Slot { mode: "notif";    sourceComponent: NotifView {} }
        Slot { mode: "launcher"; sourceComponent: Launcher {} }
        Slot { mode: "clipboard"; sourceComponent: Clipboard {} }
        Slot { mode: "control";  sourceComponent: ControlCenter {} }
        Slot { mode: "wifi";     sourceComponent: WifiView {} }
        Slot { mode: "bluetooth"; sourceComponent: BluetoothView {} }
        Slot { mode: "power";    sourceComponent: PowerMenu {} }
    }
}
