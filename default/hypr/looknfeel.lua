-- Refer to https://wiki.hypr.land/Configuring/Basics/Variables/

local active_border_color = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 }
local inactive_border_color = "rgba(595959aa)"

hl.config({
  general = {
    gaps_in = 12,
    gaps_out = 18,
    border_size = 2,

    col = {
      active_border = active_border_color,
      inactive_border = inactive_border_color,
    },

    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle",
  },

  decoration = {
    rounding = 0,
    active_opacity = 1,
    inactive_opacity = 0.94,

    -- Hairline depth: a shadow appears only where something floats over
    -- something else, never behind a tiled window.
    shadow = {
      enabled = true,
      range = 45,
      render_power = 4,
      color = 0xd10a0807,
    },

    -- A soft frost behind popouts and layer cards. Tiled windows opt out
    -- below, so the desktop under a moving window never pays for it.
    blur = {
      enabled = true,
      size = 4,
      passes = 1,
      vibrancy = 0.17,
      noise = 0.01,
      new_optimizations = true,
    },
  },

  group = {
    col = {
      border_active = active_border_color,
      border_inactive = inactive_border_color,
    },

    groupbar = {
      font_size = 12,
      font_family = "monospace",
      font_weight_active = "ultraheavy",
      font_weight_inactive = "normal",
      indicator_height = 1,
      indicator_gap = 5,
      height = 22,
      gaps_in = 5,
      gaps_out = 0,
      text_color = "rgb(ffffff)",
      text_color_inactive = "rgba(ffffff90)",
      col = {
        active = "rgba(00000040)",
        inactive = "rgba(00000020)",
      },
      gradients = true,
      gradient_rounding = 0,
      gradient_round_only_edges = false,
    },
  },

  animations = {
    enabled = true,
  },
})

-- Inactive tiles keep their 94% tint but do not blur the animating desktop
-- beneath them; floating glass and layer cards still blur.
hl.window_rule({ name = "opaque-tile-no-blur", match = { float = false }, no_blur = true })

-- Default animations, see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint", { type = "bezier", points = { { 0.23, 1 }, { 0.32, 1 } } })
hl.curve("easeInOutCubic", { type = "bezier", points = { { 0.65, 0.05 }, { 0.36, 1 } } })
hl.curve("linear", { type = "bezier", points = { { 0, 0 }, { 1, 1 } } })
hl.curve("almostLinear", { type = "bezier", points = { { 0.5, 0.5 }, { 0.75, 1.0 } } })
hl.curve("quick", { type = "bezier", points = { { 0.15, 0 }, { 0.1, 1 } } })

hl.animation({ leaf = "global", enabled = true, speed = 10, bezier = "default" })
hl.animation({ leaf = "border", enabled = true, speed = 5.39, bezier = "easeOutQuint" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.79, bezier = "easeOutQuint" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4.1, bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1.49, bezier = "linear", style = "popin 87%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "fade", enabled = true, speed = 3.03, bezier = "quick" })
hl.animation({ leaf = "fadeSwitch", enabled = false })
hl.animation({ leaf = "layers", enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn", enabled = true, speed = 4, bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut", enabled = true, speed = 1.5, bezier = "linear", style = "fade" })
hl.animation({ leaf = "fadeLayersIn", enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "workspaces", enabled = false })

hl.config({
  dwindle = {
    preserve_split = true,
    force_split = 2,
  },

  scrolling = {
    column_width = 0.49,
  },

  master = {
    new_status = "master",
  },

  -- GPU efficiency: direct scanout skips the compositor's copy for a single
  -- fullscreen game/video; new render scheduling triple-buffers only when the
  -- GPU can't keep up. VRR is left to fullscreen only so the desktop doesn't
  -- flicker on mixed-refresh multi-monitor setups.
  render = {
    direct_scanout = 2,
    new_render_scheduling = true,
  },

  misc = {
    disable_hyprland_logo = true,
    disable_splash_rendering = true,
    background_color = "rgb(000000)",
    disable_scale_notification = true,
    focus_on_activate = true,
    anr_missed_pings = 3,
    on_focus_under_fullscreen = 1,
    initial_workspace_tracking = 0,
    vrr = 2,
    -- Let a fresh shell re-acquire the session lock after the lock client
    -- died, so kestrel-restart-shell can recover the LOCK failsafe.
    allow_session_lock_restore = true,
  },

  cursor = {
    hide_on_key_press = true,
    warp_on_change_workspace = 1,
    -- Use the Xcursor theme Kestrel ships (Adwaita). Hyprcursor is off because
    -- no .hlc theme is installed, which would otherwise leave no pointer.
    enable_hyprcursor = false,
  },

  binds = {
    hide_special_on_workspace_change = true,
  },
})
