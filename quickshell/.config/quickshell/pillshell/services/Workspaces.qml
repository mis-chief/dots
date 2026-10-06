pragma Singleton
import Quickshell
import Quickshell.Hyprland
import QtQuick
import "../config"

// Driven by Hyprland's event socket; nothing polls.
Singleton {
    id: root

    readonly property int active: Hyprland.focusedWorkspace?.id ?? 1

    // Workspaces that exist, plus the focused one. Special workspaces (id <= 0) are skipped.
    readonly property var ids: {
        const s = new Set([active])
        for (const w of Hyprland.workspaces.values) if (w.id > 0) s.add(w.id)
        return Array.from(s).sort((a, b) => a - b)
    }

    property bool ready: false   // no popup for the initial workspace report at startup
    Timer { running: true; interval: 1500; onTriggered: root.ready = true }

    // The dots only appear when you switch workspaces, so the idle pill stays short.
    onActiveChanged: {
        if (!ready) return
        PillState.osdKind = "workspace"
        PillState.request("osd", Config.osdMs)
    }
}
