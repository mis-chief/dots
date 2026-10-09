pragma Singleton
import Quickshell
import Quickshell.Networking
import QtQuick

// Wi-Fi through Quickshell's NetworkManager integration (needs Quickshell 0.3.2+).
// Everything here is event-driven. The only active work is scanning, and that
// runs only while the Wi-Fi page is open.
Singleton {
    id: root

    readonly property var device: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null   // null: no Wi-Fi adapter
    readonly property bool wifiOn: Networking.wifiEnabled

    // One entry per SSID. Without a scan this is just the saved networks in range.
    readonly property var networks: (device?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.known - a.known)
            || (b.signalStrength - a.signalStrength) || a.name.localeCompare(b.name))

    readonly property var active: networks.find(n => n.connected) ?? null
    readonly property bool connected: active !== null
    readonly property int signal: active ? Math.round(active.signalStrength * 100) : 0   // 0-100

    // A connection attempt failed. `reason` is a ConnectionFailReason.
    signal failed(var network, int reason)

    function toggleWifi() { Networking.wifiEnabled = !Networking.wifiEnabled }

    function isOpen(n) { return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe }
    function takesPassword(n) {
        return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(n.security)
    }
    // 802.1X and the like need more than a password; those are left to nmcli.
    function isEnterprise(n) {
        return [WifiSecurityType.WpaEap, WifiSecurityType.Wpa2Eap, WifiSecurityType.Wpa3SuiteB192,
                WifiSecurityType.Leap, WifiSecurityType.DynamicWep].includes(n.security)
    }

    property var attempt: null   // { network, wasKnown } for the connection in progress

    function connect(n, psk) {
        attempt = { network: n, wasKnown: n.known }
        if (psk) n.connectWithPsk(psk)
        else n.connect()
    }

    Binding {
        when: root.device !== null
        target: root.device
        property: "scannerEnabled"
        value: root.wifiOn && PillState.mode === "wifi"
    }

    Instantiator {
        model: root.networks
        delegate: Connections {
            required property var modelData
            target: modelData
            function onConnectionFailed(reason) {
                // A failed first attempt can leave a saved profile behind (with the wrong
                // password in it), which would make the network look known. Drop it.
                if (root.attempt?.network === modelData && !root.attempt.wasKnown && modelData.known)
                    modelData.forget()
                root.failed(modelData, reason)
            }
        }
    }
}
