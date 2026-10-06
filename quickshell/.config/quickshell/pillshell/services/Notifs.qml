pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import "../config"

Singleton {
    id: root

    property var current: null
    property var pending: []
    property bool dnd: false

    // server.trackedNotifications feeds the control center's notification stack.
    readonly property alias server: server

    function clearAll() {
        server.trackedNotifications.values.slice().forEach(n => n.dismiss())
    }

    NotificationServer {
        id: server
        bodySupported: true
        imageSupported: true
        actionsSupported: true
        onNotification: n => {
            n.tracked = true   // always kept for the control center, even in DND
            // No popup in DND, or while the control center already shows it live.
            if (root.dnd || PillState.mode === "control") return
            root.pending = root.pending.concat([n])
            // Interrupt idle / media / osd; wait if the launcher or another popup is up.
            if (PillState.rank[PillState.mode] < PillState.rank.notif) root.next()
        }
    }

    function next() {
        if (pending.length === 0) return
        current = pending[0]
        pending = pending.slice(1)
        PillState.request("notif", Config.notifMs)
    }

    // When the pill settles (idle or media), show whatever was waiting.
    Connections {
        target: PillState
        function onModeChanged() { if (PillState.resting) root.next() }
    }
}
