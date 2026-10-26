#!/bin/bash

# Register the Kestrel package repository and trust its signing key.
#
# Used by the installer.
# Idempotent: safe to run repeatedly.

set -euo pipefail

KESTREL_PATH="${KESTREL_PATH:-/usr/share/kestrel}"
KESTREL_REPO_URL="${KESTREL_REPO_URL:-https://kestrel-distro.github.io/packages/}"

key_src="$KESTREL_PATH/default/pacman/kestrel.gpg"
key_dst=/etc/pacman.d/kestrel.gpg
conf=/etc/pacman.conf

as_root() {
  if (( EUID == 0 )); then
    "$@"
  else
    sudo "$@"
  fi
}

# Nothing to do until the repository's signing key ships with the distribution.
if [[ ! -f $key_src ]]; then
  echo "kestrel-repo: no signing key at $key_src; repository not enabled" >&2
  exit 0
fi

# 1. Repository entry, only if absent.
if ! grep -q '^\[kestrel\]' "$conf"; then
  as_root tee -a "$conf" >/dev/null <<EOF

# Kestrel's own packages: hyprland-kestrel, quickshell-kestrel, linux-kestrel.
# Distinct names that conflict with the Arch packages, so Arch cannot overwrite
# them. Signed with the Kestrel packaging key in /etc/pacman.d/kestrel.gpg.
[kestrel]
SigLevel = Required
Server = $KESTREL_REPO_URL
EOF
fi

# 2. Install and locally sign the key, if not already trusted.
if [[ ! -f $key_dst ]] || ! cmp -s "$key_src" "$key_dst"; then
  as_root install -Dm644 "$key_src" "$key_dst"
fi

fpr="$(as_root gpg --with-colons --show-keys "$key_dst" | awk -F: '/^fpr:/ { print $10; exit }')"
if [[ -n $fpr ]] && ! as_root pacman-key --list-keys "$fpr" >/dev/null 2>&1; then
  as_root pacman-key --add "$key_dst" >/dev/null
  as_root pacman-key --lsign-key "$fpr" >/dev/null
fi
