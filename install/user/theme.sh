# Setup user theme folder and seed the default only when no theme exists yet.
mkdir -p ~/.config/kestrel/themes

if [[ ! -s $HOME/.local/state/kestrel/current/theme.name ]]; then
  # iso-chroot and provision-owner both run without a live session to notify.
  if [[ ${KESTREL_SETUP_CONTEXT:-runtime} != "runtime" ]]; then
    KESTREL_THEME_HEADLESS=1 kestrel-theme-set "Titan Light"
    rm -f ~/.config/chromium/SingletonLock # otherwise archiso owns the Chromium singleton
  else
    kestrel-theme-set "Titan Light"
  fi
fi
kestrel-theme-set-pi --activate

mkdir -p ~/.config/btop/themes
ln -snf "$HOME/.local/state/kestrel/current/theme/btop.theme" ~/.config/btop/themes/current.theme
