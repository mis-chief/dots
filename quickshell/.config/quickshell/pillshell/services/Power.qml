pragma Singleton
import Quickshell
import Quickshell.Services.UPower
import "../config"

// Needs power-profiles-daemon running (systemctl enable --now power-profiles-daemon).
Singleton {
    readonly property int profile: PowerProfiles.profile

    readonly property int iconCode: profile === PowerProfile.PowerSaver ? Glyphs.map.powerSaver
        : profile === PowerProfile.Performance ? Glyphs.map.performance : Glyphs.map.balanced

    function cycle() {
        const order = PowerProfiles.hasPerformanceProfile
            ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
            : [PowerProfile.PowerSaver, PowerProfile.Balanced]
        const i = order.indexOf(PowerProfiles.profile)
        PowerProfiles.profile = order[(i + 1) % order.length]
    }
}
