-- Personal input configuration. Loaded after Kestrel's defaults.

hl.config({
  input = {
    kb_layout = "es",
    -- CapsLock is the compose key; shift:both_capslock_cancel restores Caps
    -- Lock via both Shifts together while keeping misfires harmless.
    kb_options = "compose:caps,shift:both_capslock_cancel",

    repeat_rate = 40,
    repeat_delay = 600,
    numlock_by_default = true,

    scroll_factor = 3,

    accel_profile = "flat",
    sensitivity = 1.5,

    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.4,
    },
  },
})
