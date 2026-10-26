require("default.hypr.startup-cursor")

hl.on("hyprland.start", function()
  -- Applications inherit the user's cursor; only the compositor starts blank.
  if kestrel_startup_cursor_pending then
    hl.env("XCURSOR_PATH", kestrel_startup_cursor.path)
    hl.env("XCURSOR_THEME", kestrel_startup_cursor.xcursor)
  end

  -- Force the cursor theme to load once the compositor is up. This is the
  -- runtime fix verified by hand on the VM (`hyprctl setcursor Adwaita 24`);
  -- doing it here means the pointer is never left on the blank startup cursor
  -- when the scheduled restore misses its window.
  hl.exec_cmd("sleep 1 && hyprctl keyword cursor:invisible false && hyprctl setcursor Adwaita 24")

  -- Slow app launch fix -- set systemd vars before starting session services.
  hl.exec_cmd("systemctl --user import-environment $(env | cut -d'=' -f 1)")
  hl.exec_cmd("dbus-update-activation-environment --systemd --all")

  -- One shared foot server: every terminal is a footclient, so fonts and
  -- glyph caches stay warm across windows.
  hl.exec_cmd("sh -c 'pgrep -f \"foot --server\" >/dev/null || exec foot --server'")

  hl.exec_cmd("kestrel-launch-shell")
  hl.exec_cmd("kestrel-provision-first-run")
  hl.exec_cmd("kestrel-powerprofiles-init")
  hl.exec_cmd(o.launch("kestrel-hyprland-monitor-watch"))
  hl.exec_cmd(o.launch("udiskie --automount --no-notify --no-tray"))

  -- Run post-boot hooks after startup config has loaded.
  hl.exec_cmd("sleep 2 && kestrel-hook post-boot")
end)
