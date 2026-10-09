pragma Singleton
import Quickshell
import QtQuick

Singleton {
    // "" = first screen. Set to a monitor name (e.g. "DP-1") to pin the pill.
    readonly property string monitor: ""

    // Gap above the pill. Hyprland leaves its own gap (general:gaps_out) between the pill's
    // strip and the windows, so set this to the same number to centre the pill between them.
    readonly property int topMargin: 10
    readonly property int pillHeight: 44     // clock, player, volume / brightness / workspace
    readonly property int osdMs: 900
    readonly property int notifMs: 4000
    readonly property int notifKeep: 50      // notifications kept in the control center
    readonly property int mediaMs: 3000

    readonly property color bg: "#000000"
    readonly property color fg: "#ececf1"
    readonly property color dim: "#8b8b98"
    readonly property color track: "#26262e"
    readonly property color accent: "#d8a8e6"
    readonly property color warn: "#f2a48b"
    readonly property string font: "JetBrains Mono"
    // Needs a Nerd Font for icons: sudo pacman -S ttf-jetbrains-mono-nerd
    readonly property string iconFont: "JetBrainsMono Nerd Font"
}
