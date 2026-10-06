pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // "" = first screen. Set to a monitor name (e.g. "DP-1") to pin the pill.
    readonly property string monitor: ""

    readonly property int topMargin: 8
    readonly property int osdMs: 900
    readonly property int notifMs: 4000
    readonly property int mediaMs: 3000

    readonly property color bg: "#000000"
    readonly property color fg: "#ececf1"
    readonly property color dim: "#8b8b98"
    readonly property color track: "#26262e"
    readonly property color accent: "#9ad1c0"
    readonly property color warn: "#f2a48b"
    readonly property string font: "JetBrains Mono"
    // Needs a Nerd Font for icons: sudo pacman -S ttf-jetbrains-mono-nerd
    readonly property string iconFont: "JetBrainsMono Nerd Font"
}
