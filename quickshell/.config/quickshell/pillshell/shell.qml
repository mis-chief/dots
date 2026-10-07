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
        function toggle(): void {
            if (PillState.mode === "launcher") PillState.close()
            else PillState.request("launcher", 0)
        }
    }

    // qs -c pillshell ipc call clipboard toggle
    IpcHandler {
        target: "clipboard"
        function toggle(): void {
            if (PillState.mode === "clipboard") PillState.close()
            else PillState.request("clipboard", 0)
        }
    }

    // qs -c pillshell ipc call control toggle
    IpcHandler {
        target: "control"
        function toggle(): void {
            if (PillState.mode === "control") PillState.close()
            else PillState.request("control", 0)
        }
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
        function toggle(): void {
            if (PillState.mode === "power") PillState.close()
            else PillState.request("power", 0)
        }
    }

    // qs -c pillshell ipc call osd brightness up|down
    IpcHandler {
        target: "osd"
        function brightness(dir: string): void { Brightness.change(dir) }
    }
}
