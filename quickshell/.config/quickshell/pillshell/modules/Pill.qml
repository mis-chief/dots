import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick
import "../config"
import "../services"

PanelWindow {
    id: win

    anchors.top: true
    implicitWidth: 560
    implicitHeight: 560          // must fit the largest mode
    exclusiveZone: 0
    color: "transparent"
    mask: Region { item: pill }  // clicks outside the pill fall through

    WlrLayershell.namespace: "pill"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: (PillState.mode === "launcher" || PillState.mode === "power")
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click-away-to-close applies to the modes the user opened on purpose.
    readonly property bool grabbing: grabsIn(PillState.mode)

    // The grab is armed slightly after every mode change, not just the first open.
    // Opening a mode (the click, or the keyboard focus switching to Exclusive for the
    // launcher and power menu) can make Hyprland clear a grab that is already active,
    // which would close the pill straight away.
    function grabsIn(m) { return m === "launcher" || m === "control" || m === "power" }

    property bool grabReady: false
    Timer { id: armGrab; interval: 150; onTriggered: win.grabReady = true }
    Connections {
        target: PillState
        function onModeChanged() {
            win.grabReady = false
            if (win.grabsIn(PillState.mode)) armGrab.restart()
            else armGrab.stop()
        }
    }

    HyprlandFocusGrab {
        windows: [win]
        active: win.grabbing && win.grabReady
        onCleared: PillState.close()
    }

    Rectangle {
        id: pill
        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.topMargin
        color: Config.bg
        clip: true

        // [width, height, radius] per mode
        readonly property var dims: ({
            idle:     [Battery.present ? 138 : 96, 32, 16],
            media:    [380, 72, 26],
            osd:      [260, 44, 22],
            notif:    [380, 84, 28],
            launcher: [520, 400, 28],
            control:  [440, 520, 28],
            power:    [360, 124, 28]
        })[PillState.mode] ?? [96, 32, 16]

        width: dims[0]
        height: dims[1]
        radius: dims[2]

        Behavior on width  { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on height { NumberAnimation { duration: 320; easing.type: Easing.OutBack; easing.overshoot: 1.05 } }
        Behavior on radius { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

        // Under the content so popups can handle their own clicks.
        // On the idle pill: left click opens the launcher, right click the control center.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: m => {
                if (PillState.mode !== "idle") return
                PillState.request(m.button === Qt.RightButton ? "control" : "launcher", 0)
            }
        }

        Slot { mode: "idle";     sourceComponent: IdleView {} }
        Slot { mode: "media";    sourceComponent: MediaView {} }
        Slot { mode: "osd";      sourceComponent: Osd {} }
        Slot { mode: "notif";    sourceComponent: NotifView {} }
        Slot { mode: "launcher"; sourceComponent: Launcher {} }
        Slot { mode: "control";  sourceComponent: ControlCenter {} }
        Slot { mode: "power";    sourceComponent: PowerMenu {} }
    }
}
