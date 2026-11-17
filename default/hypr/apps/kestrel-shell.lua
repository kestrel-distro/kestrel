-- Window and layer rules for the Kestrel Quickshell surfaces. The
-- shell-wide bar / menu / popouts are layer-shell.

-- Keep the bar instant: no layer-shell fade/slide animation.
hl.layer_rule({ match = { namespace = "kestrel-bar" }, no_anim = true, animation = "none" })

-- Launcher, image selector, emojis, clipboard overlays, the OSD, reminders, the
-- Wi-Fi QR code and keyboard-driven panels should pop without compositor layer
-- animations. Overlays open as soon as their scale is ready, without a
-- compositor fade or slide. Panels keep their own QML opacity transition
-- for normal open/close, and skip it for panel handoff.
hl.layer_rule({ match = { namespace = "^(kestrel-launcher|kestrel-menu|kestrel-image-selector|kestrel-emojis|kestrel-clipboard|kestrel-keyboard-panel|kestrel-osd|kestrel-reminders|kestrel-network-qr)$" }, no_anim = true, animation = "none" })

-- The launcher card is translucent paper: frost only what is inside it.
-- ignore_alpha keeps the compositor blur off the transparent surround (the
-- full-output layer reserves room for the card and its shadow).
hl.layer_rule({ match = { namespace = "^kestrel-launcher$" }, blur = true, ignore_alpha = 0.05 })

-- Keep the shell background layer instant; it fades itself.
hl.layer_rule({ match = { namespace = "^kestrel-background$" }, no_anim = true, animation = "none" })

-- Dev gallery is the main shell workbench; open it maximized like
-- SUPER+ALT+F so component previews have the whole workspace.
o.window({ class = "^org.quickshell$", title = "^Kestrel shell – dev gallery$" }, { maximize = true })
