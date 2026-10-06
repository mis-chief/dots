pragma Singleton
import Quickshell

// Nerd Font (Material Design set, nf-md-*) code points.
// To swap an icon, look it up at nerdfonts.com/cheat-sheet and change the number.
Singleton {
    readonly property var map: ({
        bluetooth:       0xF00AF,
        bluetoothOn:     0xF00B1,  // bluetooth_connect
        bluetoothOff:    0xF00B2,
        moon:            0xF0594,  // weather_night
        bell:            0xF009A,
        trash:           0xF01B4,  // delete
        prev:            0xF04AE,  // skip_previous
        next:            0xF04AD,  // skip_next
        play:            0xF040A,
        pause:           0xF03E4,
        check:           0xF012C,  // checkmark
        back:            0xF0141,  // chevron_left
        chevronRight:    0xF0142,
        power:           0xF0425,
        sleep:           0xF04B2,
        restart:         0xF0709,
        powerSaver:      0xF032A,  // leaf
        balanced:        0xF0F85,  // speedometer_medium
        performance:     0xF04C5   // speedometer
    })

    readonly property var batteryLevel:    [0xF007A, 0xF007B, 0xF007C, 0xF007D, 0xF007E, 0xF007F, 0xF0080, 0xF0081, 0xF0082, 0xF0079]
    readonly property var batteryCharging: [0xF089C, 0xF0086, 0xF0087, 0xF0088, 0xF089D, 0xF0089, 0xF089E, 0xF008A, 0xF008B, 0xF0085]

    function battery(pct, charging) {
        if (!charging && pct < 5) return 0xF0083          // battery_alert
        const i = Math.max(0, Math.min(9, Math.round(pct / 10) - 1))
        return (charging ? batteryCharging : batteryLevel)[i]
    }

    function wifi(on, connected, signal) {
        if (!on) return 0xF05AA                            // wifi_off
        if (!connected) return 0xF092E                     // wifi_strength_off_outline
        if (signal >= 75) return 0xF0928
        if (signal >= 50) return 0xF0925
        if (signal >= 25) return 0xF0922
        return 0xF091F
    }

    function volume(v, muted) {
        if (muted) return 0xF075F                          // volume_mute
        if (v < 0.34) return 0xF057F                       // volume_low
        if (v < 0.67) return 0xF0580                       // volume_medium
        return 0xF057E                                     // volume_high
    }

    function brightness(f) {
        if (f < 0.34) return 0xF00DE
        if (f < 0.67) return 0xF00DF
        return 0xF00E0
    }
}
