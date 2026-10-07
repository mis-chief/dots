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
    // Reserve the idle pill's strip so windows tile below it instead of underneath.
    exclusiveZone: Config.topMargin * 2 + 32
    color: "transparent"
    mask: Region { item: pill }  // clicks outside the pill fall through

    WlrLayershell.namespace: "pill"
    // Top sits under fullscreen windows, so the resting pill and popups hide there.
    // Modes the user opened on purpose move to Overlay and still show.
    WlrLayershell.layer: grabsIn(PillState.mode) ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: (PillState.mode === "launcher" || PillState.mode === "clipboard" || PillState.mode === "power")
        ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // Click-away-to-close applies to the modes the user opened on purpose.
    readonly property bool grabbing: grabsIn(PillState.mode)

    // The grab is armed slightly after every mode change, not just the first open.
    // Opening a mode (the click, or the keyboard focus switching to Exclusive for the
    // launcher and power menu) can make Hyprland clear a grab that is already active,
    // which would close the pill straight away.
    function grabsIn(m) { return m === "launcher" || m === "clipboard" || m === "control" || m === "power" }

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
            media:    PillState.timed ? [380, 72, 26] : [320, 32, 16],
            osd:      [260, 44, 22],
            notif:    [380, 84, 28],
            launcher: [520, 400, 28],
            clipboard: [520, 400, 28],
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
        Slot { mode: "power";    sourceComponent: PowerMenu {} }
    }
}
