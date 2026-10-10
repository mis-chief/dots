# pillshell

A dynamic-island style pill for Hyprland, built on Quickshell. One pill at the top of the screen
that expands for notifications, media, volume/brightness, workspaces, the control center,
the app launcher, clipboard history, and the power menu.

## Install

    sudo pacman -S ttf-jetbrains-mono ttf-jetbrains-mono-nerd brightnessctl \
                   networkmanager upower power-profiles-daemon cliphist wl-clipboard
    systemctl enable --now power-profiles-daemon   # don't run TLP or auto-cpufreq alongside it
    cp -r pillshell ~/.config/quickshell/pillshell
    qs -c pillshell

Needs Quickshell 0.3.2 or newer (`qs --version`): Wi-Fi uses its NetworkManager integration.

Quit mako, dunst, or swaync first: only one notification daemon can run at a time.

## Hyprland config (Lua, 0.55+)

    local qs = "qs -c pillshell ipc call "

    hl.on("hyprland.start", function()
        hl.exec_cmd("qs -c pillshell")
        -- cliphist only records while these run
        hl.exec_cmd("wl-paste --type text --watch cliphist store")
        hl.exec_cmd("wl-paste --type image --watch cliphist store")
    end)

    hl.bind("SUPER + SPACE",     hl.dsp.exec_cmd(qs .. "launcher toggle"))
    hl.bind("SUPER + V",         hl.dsp.exec_cmd(qs .. "clipboard toggle"))
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
It reserves a strip at the top of the screen (its height plus the gap above it), so windows tile
below it. The clock, the player and the volume / brightness / workspace popups are all the same
height, so only the pill's width changes between them. To centre the pill between the screen edge
and your windows, set `topMargin` in `config/Config.qml` to your Hyprland `general:gaps_out`.

**Fullscreen:** the pill and its popups (volume, brightness, workspaces, notifications) are hidden
under a fullscreen window. The launcher, clipboard, control center, and power menu still open over it.

**Launcher:** type to search apps, arrows to move, Enter to launch, Esc to close.
Start with `>` to run a shell command instead.

**Clipboard:** history from cliphist, newest first. Type to filter, arrows to move, Enter (or click)
to copy an entry back to the clipboard, Shift+Delete to remove it, Esc to close. Images show as
thumbnails. Needs the two `wl-paste --watch` lines from the Hyprland config above to record anything.

**Control center:** volume and brightness sliders (tap the speaker to mute), then five toggles:
Wi-Fi, Bluetooth, Do not disturb, power profile (tap to cycle saver / balanced / performance),
and the power menu. Right click the Wi-Fi or Bluetooth toggle to pick a network or device (below).
Each toggle is captioned with its state (network, device, power profile).
Below that: the media card, a stats line (CPU, memory, uptime, and battery draw with time
left; polled only while the control center is open) with the tray icons beside it, and notifications
(left click opens one in its app, right click dismisses it, trash clears all; the newest 50 are
kept). The pill is only as tall as what it is showing, and grows as notifications arrive. Click outside to close. The brightness slider only shows on machines with a backlight.

**Wi-Fi:** right click the Wi-Fi toggle. Networks in range, strongest first after the connected
and saved ones. Click one to connect; a new network that needs a password asks for it (Enter to
connect, Esc to cancel). Click the connected network, or right click a saved one, for
Disconnect / Forget. It scans only while this page is open. Enterprise (802.1X) and hidden
networks are not handled here: set those up once with `nmcli` and they connect from the list.

**Bluetooth:** right click the Bluetooth toggle. Click a device to connect or disconnect; a new
device is paired first. Right click a paired device for Forget. It searches for devices only
while this page is open. Devices that ask for a PIN or passkey can't be paired from here
(use `bluetoothctl`).

Both pages have a switch for the radio, and the arrow or Esc goes back to the control center.

**Tray:** left click opens the app, right click shows its menu inside the pill, middle click sends
its secondary action. The tray is registered as soon as the shell starts. An app launched before
that won't find it, so if one that should start minimized to tray shows its window at login,
start it after the tray exists:

    hl.exec_cmd("sh -c 'gdbus wait --session org.kde.StatusNotifierWatcher && protonvpn-app'")

**Media:** while something is playing the pill shows the track on one line (art, title, artist,
play/pause). With the mouse over it, the pill widens and previous / skip slide out on either side
of play/pause. On pause it stays for a moment, then the pill goes back to the clock. Clicks work as on the idle pill: left opens the launcher, right the control center. To hide the
track until the next one, use `qs -c pillshell ipc call media toggle`.

**Popups:** volume, brightness, and workspace switches pop up briefly. Workspace switches show one
dot per workspace, with the current one stretched. Notifications pop up unless Do not disturb is on:
left click opens the notification in its app, right click dismisses it. Hyprland only raises the
app's window if `misc:focus_on_activate` is on; otherwise it is just marked urgent.

**Power menu:** Sleep, Restart, Power off. Restart and Power off need a second click within
3 seconds. Sleep doesn't lock the screen yet.

## IPC

    qs -c pillshell ipc call launcher toggle
    qs -c pillshell ipc call clipboard toggle
    qs -c pillshell ipc call control toggle
    qs -c pillshell ipc call power toggle
    qs -c pillshell ipc call media toggle
    qs -c pillshell ipc call osd brightness up|down

## Layout

    shell.qml               entry point and IPC handlers
    config/Config.qml       colors, fonts, timings, monitor
    config/Glyphs.qml       Nerd Font icon code points
    services/PillState.qml  which mode the pill is in, plus the table of per-mode settings
                            (rank, size, click-away, keyboard focus)
    services/               Apps, Audio, Battery, Brightness, Media, Network,
                            Notifs, Power, Workspaces
    modules/Pill.qml        the window, and one Slot per mode
    modules/                one view per mode (IdleView, MediaCompact, Osd,
                            NotifView, Launcher, Clipboard, ControlCenter, WifiView,
                            BluetoothView, PowerMenu) plus shared parts
                            (Icon, IconButton, Tile, Toggle, Chip, ListRow, PillSlider, Slot,
                            StatsRow, TrayRow, TrayMenu, WorkspaceDots)

To change an icon, edit its code point in `config/Glyphs.qml` (see nerdfonts.com/cheat-sheet).
To change a pill size, edit the `modes` table in `services/PillState.qml` (the shared height is
`pillHeight` in `config/Config.qml`). To add a mode, add a row
there, a `Slot` in `modules/Pill.qml`, and an `IpcHandler` in `shell.qml` if it needs a keybind.
