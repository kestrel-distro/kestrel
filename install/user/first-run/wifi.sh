notify_wifi() {
  kestrel-notification-send -u critical -g 󰖩 "Setup Wi-Fi" "Click to configure the wireless network." \
    --exec kestrel-shell shell toggle kestrel.network
}

announce_network() {
  # Ethernet is still negotiating DHCP when the session starts, so probing
  # right away calls a working machine offline. NetworkManager reports startup
  # complete once it has tried every connection it could auto-activate, which
  # is the first moment the answer means anything.
  nm-online -q -s -t 30

  # -x takes that answer as it stands rather than waiting out the timeout, so
  # a laptop with nothing to connect to gets prompted immediately.
  if ! nm-online -q -x -t 30; then
    notify_wifi
  fi
}

# Detached, so a slow or absent connection never holds up the rest of first run.
announce_network &
