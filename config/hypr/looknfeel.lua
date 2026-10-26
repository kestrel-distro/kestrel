-- Personal look & feel. Loaded after Kestrel's defaults.

local active_border_color = { colors = { "rgb(8A8A8D)" } }

hl.config({
  general = {
    gaps_in = 4,
    gaps_out = 8,

    col = {
      active_border = active_border_color,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
    },
  },

  decoration = {
    rounding = 0,
  },

  animations = {
    enabled = false,
  },
})

-- Zen never starts fullscreen or maximized.
o.window("^(zen)$", { fullscreen = 0, maximize = 0 })
