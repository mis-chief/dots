hl.on("hyprland.start", function () 
   hl.exec_cmd("waybar & hypridle")
   hl.exec_cmd("systemctl --user start hyprpolkitagent")
   hl.exec_cmd("hyprpaper")
   hl.exec_cmd("flatpak run com.protonvpn.www")
end)

