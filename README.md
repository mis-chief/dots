# dots

My Hyprland setup: a Lua-configured Hyprland, hypridle/hyprlock, and **pillshell**, a
dynamic-island style top bar built on [Quickshell](https://quickshell.org).

The repo is laid out as [GNU Stow](https://www.gnu.org/software/stow/) packages, each one
mirroring `$HOME`:

| Package        | What it contains                                                              |
| -------------- | ----------------------------------------------------------------------------- |
| `hypr-common`  | `hyprland.lua` (look & feel, keybinds, window rules), `hypridle.conf`, `hyprlock.conf` |
| `hypr-desktop` | Desktop-only `monitor.lua`, `input.lua` (flat accel), `autostart.lua`         |
| `hypr-laptop`  | Laptop-only `monitor.lua` (2880x1800@120, VRR), `input.lua` (3-finger workspace swipe), `autostart.lua`, `hyprpaper.conf` |
| `quickshell`   | The `pillshell` Quickshell config ([its own README](quickshell/.config/quickshell/pillshell/README.md)) |

Install `hypr-common` plus **one** of `hypr-desktop` or `hypr-laptop` — they provide the
same filenames (`monitor.lua`, `input.lua`, `autostart.lua`) that `hyprland.lua` `require`s.

## Requirements

- **Hyprland 0.55 or newer** — the config uses the Lua format (`hyprland.lua`), not `hyprland.conf`.
- Arch Linux (or an Arch-based distro). Package names below are for `pacman`; adjust them for
  other distros.

## Dependencies

### Core (both machines)

| Package | Used for |
| --- | --- |
| `hyprland` | Compositor (≥ 0.55) |
| `quickshell` | Runs pillshell (`qs -c pillshell`) — bar, launcher, notifications, OSD, clipboard UI, control center, power menu |
| `hypridle` | Idle handling: lock at 5 min, screen off at 5.5 min, suspend at 10 min |
| `hyprlock` | Lock screen |
| `hyprpolkitagent` | Polkit authentication agent (started as a user service) |
| `xdg-desktop-portal-hyprland` | Screen sharing / portals (recommended alongside Hyprland) |
| `kitty` | Terminal (`SUPER + Q`) |
| `superfile` | Terminal file manager, run as `kitty -e spf` (`SUPER + E`) |
| `pipewire`, `wireplumber`, `pipewire-pulse` | Audio; `wpctl` drives the volume keys and pillshell's audio service |
| `brightnessctl` | Backlight control for the brightness keys / OSD |
| `networkmanager` | `nmcli` powers pillshell's Wi-Fi status and toggle |
| `bluez`, `bluez-utils` | Bluetooth toggle in the control center |
| `upower` | Battery status |
| `power-profiles-daemon` | Power-profile toggle (don't run TLP or auto-cpufreq alongside it) |
| `cliphist`, `wl-clipboard` | Clipboard history (`wl-paste --watch cliphist store`) and the clipboard picker |
| `grim`, `slurp` | Region screenshot to clipboard (`SUPER + =`) |
| `ttf-jetbrains-mono`, `ttf-jetbrains-mono-nerd` | UI font and Nerd Font icons (pillshell, hyprlock) |
| `flatpak` | Runs ProtonVPN at login |

### Laptop only

| Package | Used for |
| --- | --- |
| `hyprpaper` | Wallpaper (the desktop uses Waywallen instead) |

### Not from the repos

These are referenced by path or app ID in the config and must be installed by hand:

| App | Where | Used for |
| --- | --- | --- |
| ProtonVPN | Flatpak: `com.protonvpn.www` | Autostarted on both machines |
| Helium browser | AppImage at `~/AppImages/helium.appimage` | `SUPER + B` |
| Waywallen | AppImage at `~/AppImages/waywallen.appimage` | Desktop wallpaper (autostarted with `--no-ui`) |

> The keybind and autostart entries use the absolute path `/home/aidan/AppImages/...`.
> Change these in `hyprland.lua` and `hypr-desktop/.config/hypr/autostart.lua` if your
> username differs.

## Install

```sh
# 1. Packages
sudo pacman -S --needed \
    hyprland quickshell hypridle hyprlock hyprpolkitagent xdg-desktop-portal-hyprland \
    kitty superfile \
    pipewire wireplumber pipewire-pulse \
    brightnessctl networkmanager bluez bluez-utils upower power-profiles-daemon \
    cliphist wl-clipboard grim slurp \
    ttf-jetbrains-mono ttf-jetbrains-mono-nerd \
    flatpak stow

# Laptop only
sudo pacman -S --needed hyprpaper

# 2. Services
sudo systemctl enable --now NetworkManager bluetooth power-profiles-daemon

# 3. ProtonVPN
flatpak install flathub com.protonvpn.www

# 4. Dotfiles
git clone https://github.com/mis-chief/dots.git ~/dots
cd ~/dots
stow hypr-common quickshell
stow hypr-desktop   # or: stow hypr-laptop
```

If `~/.config/hypr` already has files with the same names, move them out of the way first
or Stow will refuse to overwrite them.

Then place the AppImages in `~/AppImages/` and, on the laptop, put a wallpaper where
`hyprpaper.conf` expects it (`~/wallpapers/...`) or point it at your own image.

Only one notification daemon can run at a time, so uninstall or disable mako, dunst or
swaync — pillshell provides notifications.

## Keybinds

| Keys | Action |
| --- | --- |
| `SUPER + Space` | App launcher |
| `SUPER + R` | Clipboard history |
| `SUPER + Q` | Terminal (kitty) |
| `SUPER + E` | File manager (superfile) |
| `SUPER + B` | Browser (Helium) |
| `SUPER + C` | Close window |
| `SUPER + V` | Toggle floating |
| `SUPER + J` | Toggle split (dwindle) |
| `SUPER + =` | Screenshot a region to the clipboard |
| `SUPER + 1–9` | Switch workspace |
| `SUPER + SHIFT + 1–9` | Move window to workspace |
| `SUPER + arrows` | Move focus |
| `SUPER + LMB / RMB drag` | Move / resize window |
| Volume / brightness keys | Adjust, with the pillshell OSD |

Left-click the pill for the launcher, right-click it for the control center. See the
[pillshell README](quickshell/.config/quickshell/pillshell/README.md) for everything else it
does and its IPC commands.

## License

[MIT](LICENSE)
