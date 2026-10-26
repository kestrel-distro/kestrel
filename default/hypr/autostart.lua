hl.on("hyprland.start", function()
  -- Force the cursor theme to load once the compositor is up. There is no blank
  -- startup theme: leaving Hyprland on one until a restore ran left the pointer
  -- invisible whenever that restore was missed in the VM.
  hl.exec_cmd("sleep 1 && hyprctl keyword cursor:invisible false && hyprctl setcursor Adwaita 24")

  -- Slow app launch fix -- set systemd vars before starting session services.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")


  -- One shared foot server in the terminal class. Wait for the first-run
  -- theme so the included foot palette exists, then let systemd place it.
  hl.exec_cmd("sh -c 'for i in $(seq 1 100); do [ -f \"$HOME/.local/state/kestrel/current/theme/foot.ini\" ] && break; sleep 0.1; done; systemctl --user start foot-server.service || exec foot --server'")

  hl.exec_cmd("kestrel-launch-shell")
  hl.exec_cmd("kestrel-provision-first-run")
  hl.exec_cmd("kestrel-powerprofiles-init")
  hl.exec_cmd(o.launch("kestrel-hyprland-monitor-watch"))
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && kestrel-hook post-boot")
end)
