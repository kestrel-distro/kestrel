-- Hyprland polls cursor.invisible, so its first frames need a blank cursor too.
function kestrel_startup_cursor_restore(loaded)
  if not kestrel_startup_cursor_pending then return end
  local cursor = kestrel_startup_cursor
  if loaded then
    kestrel_startup_cursor_pending = false
    hl.config({ cursor = cursor.config })
    if cursor.config.enable_hyprcursor and cursor.hyprcursor then
      hl.exec_cmd("hyprctl setcursor " .. o.shell_quote(cursor.hyprcursor) .. " " .. cursor.size)
    end
  elseif not cursor.restoring then
    cursor.restoring = true
    -- Restore the saved cursor config (invisible = false) first and
    -- unconditionally. The compositor cursor must return even when the theme
    -- cannot be switched: gating this on `hyprctl setcursor` succeeding left
    -- `cursor.invisible` set, and the pointer hidden, for the whole session
    -- whenever the theme was not loadable at reveal time.
    --
    -- The keyword is applied synchronously. A setcursor that lands while the
    -- compositor still considers the cursor hidden is dropped (setCursorFromName
    -- returns early without loading the theme), leaving the blank startup cursor
    -- in place for the rest of the session.
    hl.config({ cursor = cursor.config })
    hl.exec_cmd("hyprctl keyword cursor:invisible false >/dev/null 2>&1; "
      .. "hyprctl setcursor " .. o.shell_quote(cursor.xcursor) .. " " .. cursor.size
      .. " || hyprctl setcursor Adwaita " .. cursor.size
      .. " || true; hyprctl eval 'kestrel_startup_cursor_restore(true)'")
  end
end

hl.on("config.reloaded", function()
  if kestrel_startup_cursor_pending == nil then
    -- Config updates in an existing compositor must not hide its pointer.
    kestrel_startup_cursor_pending = #hl.get_monitors() == 0
    if kestrel_startup_cursor_pending then
      local hyprcursor = hl.get_config("cursor.enable_hyprcursor")
      kestrel_startup_cursor = {
        config = {
          invisible = hl.get_config("cursor.invisible"),
          enable_hyprcursor = hyprcursor,
          sync_gsettings_theme = hl.get_config("cursor.sync_gsettings_theme"),
        },
        hyprcursor = os.getenv("HYPRCURSOR_THEME"),
        size = tonumber((hyprcursor and os.getenv("HYPRCURSOR_SIZE")) or os.getenv("XCURSOR_SIZE")) or 24,
        path = os.getenv("XCURSOR_PATH") or "~/.local/share/icons:~/.icons:/usr/share/icons:/usr/share/pixmaps",
        -- Never restore the blank startup theme itself.
        xcursor = (os.getenv("XCURSOR_THEME") ~= "kestrel-startup" and os.getenv("XCURSOR_THEME")) or "Adwaita",
      }
      if kestrel_startup_cursor.size <= 0 then kestrel_startup_cursor.size = 24 end
      hl.env("XCURSOR_PATH", os.getenv("KESTREL_PATH") .. "/default/hypr/cursors:" .. kestrel_startup_cursor.path)
      hl.env("XCURSOR_THEME", "kestrel-startup")
    end
  end
  if kestrel_startup_cursor_pending then
    -- Keep the temporary cursor private to the compositor, including GSettings.
    hl.config({ cursor = { invisible = true, enable_hyprcursor = false, sync_gsettings_theme = false } })
    hl.timer(function() kestrel_startup_cursor_restore() end, { timeout = 15000, type = "oneshot" })
  end
end)
