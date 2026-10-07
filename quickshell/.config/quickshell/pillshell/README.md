# pillshell

A dynamic-island style pill for Hyprland, built on Quickshell. One pill at the top of the screen
that expands for notifications, media, volume/brightness, workspaces, the control center,
the app launcher, and the power menu.

## Install

    sudo pacman -S ttf-jetbrains-mono ttf-jetbrains-mono-nerd brightnessctl \
                   networkmanager upower power-profiles-daemon
    systemctl enable --now power-profiles-daemon   # don't run TLP or auto-cpufreq alongside it
    cp -r pillshell ~/.config/quickshell/pillshell
    qs -c pillshell

Quit mako, dunst, or swaync first: only one notification daemon can run at a time.

## Hyprland config (Lua, 0.55+)

    local qs = "qs -c pillshell ipc call "

    hl.on("hyprland.start", function()
        hl.exec_cmd("qs -c pillshell")
    end)

    hl.bind("SUPER + SPACE",     hl.dsp.exec_cmd(qs .. "launcher toggle"))
    hl.bind("SUPER + C",         hl.dsp.exec_cmd(qs .. "control toggle"))
    hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(qs .. "power toggle"))

    hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
    hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),        { locked = true, repeating = true })
    hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),       { locked = true })
    hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd(qs .. "osd brightness up"),   { locked = true, repeating = true })
    hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(qs .. "osd brightness down"), { locked = true, repeating = true })

Optional blur, if you make the pill translucent:

    hl.layer_rule({ match = { namespace = "pill" }, blur = true, ignore_alpha = 0.1 })

## Using it

**Idle pill:** battery and clock. Left click opens the launcher, right click the control center.
It reserves a 48px strip at the top of the screen, so windows tile below it.

**Fullscreen:** the pill and its popups (volume, brightness, workspaces, notifications) are hidden
under a fullscreen window. The launcher, control center, and power menu still open over it.

**Launcher:** type to search apps, arrows to move, Enter to launch, Esc to close.
Start with `>` to run a shell command instead.

**Control center:** volume and brightness sliders (tap the speaker to mute), then five toggles:
Wi-Fi, Bluetooth, Do not disturb, power profile (tap to cycle saver / balanced / performance),
and the power menu. Below that: a stats line (CPU, memory, uptime, and battery draw with time
left; polled only while the control center is open), tray icons, the media card, and notifications
(tap one to dismiss, trash to clear all). Click outside to close.

**Tray:** left click opens the app, right click shows its menu inside the pill, middle click sends
its secondary action. The tray is registered as soon as the shell starts. An app launched before
that won't find it, so if one that should start minimized to tray shows its window at login,
start it after the tray exists:

    hl.exec_cmd("sh -c 'gdbus wait --session org.kde.StatusNotifierWatcher && protonvpn-app'")

**Media:** while something is playing the pill shows the track on one line (art, title, artist,
play/pause). On pause the full card with prev/next shows briefly, then the pill goes back to the
clock. Clicks work as on the idle pill: left opens the launcher, right the control center. To hide the
track until the next one, use `qs -c pillshell ipc call media toggle`.

**Popups:** volume, brightness, and workspace switches pop up briefly. Workspace switches show one
dot per workspace, with the current one stretched. Notifications pop up unless Do not disturb is on.

**Power menu:** Sleep, Restart, Power off. Restart and Power off need a second click within
3 seconds. Sleep doesn't lock the screen yet.

## IPC

    qs -c pillshell ipc call launcher toggle
    qs -c pillshell ipc call control toggle
    qs -c pillshell ipc call power toggle
    qs -c pillshell ipc call media toggle
    qs -c pillshell ipc call osd brightness up|down

## Layout

    shell.qml               entry point and IPC handlers
    config/Config.qml       colors, fonts, timings, monitor
    config/Glyphs.qml       Nerd Font icon code points
    services/PillState.qml  which mode the pill is in, and what may interrupt what
    services/               Apps, Audio, Battery, Brightness, Media, Network,
                            Notifs, Power, Workspaces
    modules/Pill.qml        the window, pill sizes per mode, click-away handling
    modules/                one view per mode (IdleView, MediaView, MediaCompact, Osd,
                            NotifView, Launcher, ControlCenter, PowerMenu) plus shared parts
                            (Icon, IconButton, Tile, PillSlider, Slot, StatsRow, TrayRow,
                            TrayMenu, WorkspaceDots)

To change an icon, edit its code point in `config/Glyphs.qml` (see nerdfonts.com/cheat-sheet).
To change a pill size, edit the `dims` table in `modules/Pill.qml`.
