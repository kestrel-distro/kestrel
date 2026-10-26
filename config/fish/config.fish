# Kestrel environment for fish. Scripts and aliases stay in bash; fish only
# needs the same KESTREL_PATH/PATH and tool integrations as default/bash.
set -g fish_greeting

if test -f /etc/kestrel.conf
    set -gx KESTREL_PATH (sed -n 's/^KESTREL_PATH=//p' /etc/kestrel.conf | tail -1)
end
set -q KESTREL_PATH[1]; or set -gx KESTREL_PATH /usr/share/kestrel

if test "$KESTREL_PATH" != /usr/share/kestrel
    fish_add_path --global --move --prepend "$KESTREL_PATH/bin"
end

# mise wrappers must precede the tool directories they dispatch to.
set -l data_dir $MISE_DATA_DIR
set -q data_dir[1]; or set data_dir $XDG_DATA_HOME
set -q data_dir[1]; or set data_dir $HOME/.local/share
if test -d "$data_dir/mise/command-wrappers/bin"
    fish_add_path --global --move --prepend "$data_dir/mise/command-wrappers/bin"
end

fish_add_path --global --append "$HOME/.local/share/mise/shims" "$HOME/.local/bin"

if status is-interactive
    command -q mise; and mise activate fish | source
    command -q starship; and starship init fish | source
    command -q zoxide; and zoxide init fish | source
    command -q fzf; and fzf --fish | source
end
