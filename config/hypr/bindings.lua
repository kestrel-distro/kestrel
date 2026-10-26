-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   kestrel menu keybindings --print

-- To disable every Kestrel default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.kestrel"), then add
-- only the bindings you want below:
--   kestrel_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   kestrel_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "footclient -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "kestrel-capture-screenshot")
-- o.bind("SUPER + PERIOD", nil, { panel = "kestrel.emojis" })
