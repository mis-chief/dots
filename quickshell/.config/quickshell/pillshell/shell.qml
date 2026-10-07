import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import QtQuick
import "config"
import "services"
import "modules"

ShellRoot {
    // Singletons are lazy; referencing them here makes sure they start at launch.
    // SystemTray registers the tray on D-Bus; apps that start minimized to tray
    // (ProtonVPN...) need it there at login, not when the control center first opens.
    readonly property var keepAlive: [Audio, Brightness, Notifs, Media, Workspaces, SystemTray.items]

    Variants {
        model: Quickshell.screens.filter(s =>
            Config.monitor === "" ? s === Quickshell.screens[0] : s.name === Config.monitor)

        Pill {
            required property var modelData
            screen: modelData
        }
    }

    // qs -c pillshell ipc call launcher toggle
    IpcHandler {
        target: "launcher"
        function toggle(): void { PillState.toggle("launcher") }
    }

    // qs -c pillshell ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"
        function toggle(): void { PillState.toggle("clipboard") }
    }

    // qs -c pillshell ipc call control toggle
    IpcHandler {
        target: "control"
        function toggle(): void { PillState.toggle("control") }
    }

    // qs -c pillshell ipc call media toggle
    IpcHandler {
        target: "media"
        function toggle(): void {
            if (PillState.mode === "media") Media.hide()
            else Media.show()
        }
    }

    // qs -c pillshell ipc call power toggle
    IpcHandler {
        target: "power"
        function toggle(): void { PillState.toggle("power") }
    }

    // qs -c pillshell ipc call osd brightness up|down
    IpcHandler {
        target: "osd"
        function brightness(dir: string): void { Brightness.change(dir) }
    }
}
