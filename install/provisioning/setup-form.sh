# The setup form: every question Kestrel asks a human to describe their machine
# — keyboard, account, hostname, timezone — plus the rules those answers are
# checked against. Shared by the two places that ask them: the ISO configurator's
# user step and this package's first-boot owner setup
# (kestrel-provision-owner). Sourced by both, so the copies cannot drift the way
# the keyboard list already did.
#
# Every prompt reports one of three statuses, and both callers read them the
# same way:
#
#   0    field is set, move on
#   1    end of input (stdin closed), unwind to the start of the form
#   130  Ctrl+C, a per-caller side channel (the installer arms deferred
#        provisioning or toggles encryption; first-boot setup offers a reboot)
#
# The prompts are plain bash reads. gum's text input used to panic on a
# terminal that had not been sized yet (0x0 pty -> negative width), which
# silently froze the installer at the first question.
#
# Callers supply `notice <message> <seconds>` for validation feedback, and set
# the variables these prompts write: keyboard, keyboard_label, username,
# password, password_confirmation, full_name, email_address, hostname, timezone.

KESTREL_FORM_BACK=1
KESTREL_FORM_SIGNAL=130

# The English layouts lead, then everything else alphabetically.
KESTREL_KEYBOARD_LAYOUTS=$'English (US)|us
English (UK)|uk
English (US, Dvorak)|dvorak
English (US, Colemak)|colemak
Azerbaijani|azerty
Belarusian|by
Belgian|be-latin1
Bulgarian|bg-cp1251
Croatian|croat
Czech|cz
Danish|dk-latin1
Dutch|nl
Estonian|et
Finnish|fi
French|fr
French (Canada)|cf
French (Switzerland)|fr_CH
Georgian|ge
German|de
German (Switzerland)|de_CH-latin1
Greek|gr
Hebrew|il
Hungarian|hu
Icelandic|is-latin1
Irish|ie
Italian|it
Japanese|jp106
Kazakh|kazakh
Kyrgyz|kyrgyz
Lao|la-latin1
Latvian|lv
Lithuanian|lt
Macedonian|mk-utf
Norwegian|no-latin1
Polish|pl
Portuguese|pt-latin1
Portuguese (Brazil)|br-abnt2
Romanian|ro
Russian|ru
Serbian|sr-latin
Slovak|sk-qwertz
Slovenian|slovene
Spanish|es
Spanish (Latin American)|la-latin1
Swedish|sv-latin1
Tajik|tj_alt-UTF8
Turkish|trq
Ukrainian|ua'

KESTREL_USERNAME_PATTERN='^[a-z_][a-z0-9_-]*[$]?$'
KESTREL_RESERVED_USERNAMES='^(root|bin|daemon|mail|ftp|http|nobody|dbus|systemd-coredump|systemd-network|systemd-oom|systemd-journal-remote|systemd-resolve|systemd-timesync|tss|uuidd|alpm|git|avahi|cups|cups-browsed|lp|_talkd|polkitd|rtkit|qemu|brltty|gluster|rpc|libvirt-qemu|pcscd|nvidia-persistenced|sddm)$'
KESTREL_HOSTNAME_PATTERN='^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
KESTREL_HOSTNAME_DEFAULT='kestrel'

# Ctrl+C must come back as status 130 instead of killing the installer, so the
# callers' deferred/encryption side channels keep working.
KESTREL_FORM_INTERRUPTED=0
trap 'KESTREL_FORM_INTERRUPTED=1' INT

# Installer targets are empty, so any account is fair game; first-boot setup
# overrides this because its machine already has users.
kestrel_username_taken() { return 1; }

# kestrel_read_line <prompt> <variable> [silent]
#
# Read with a one-second timeout instead of blocking: a trapped SIGINT does not
# make `read` return until more input arrives, so polling is what lets Ctrl+C
# reach the caller's status-130 handling. Partial input survives a timeout.
kestrel_read_line() {
  local prompt=$1 __var=$2 silent=${3:-}
  local value="" chunk status
  KESTREL_FORM_INTERRUPTED=0
  printf '%s' "$prompt" >&2
  while true; do
    if [[ -n $silent ]]; then
      IFS= read -rs -t 1 chunk && status=0 || status=$?
    else
      IFS= read -r -t 1 chunk && status=0 || status=$?
    fi
    value+=$chunk
    ((KESTREL_FORM_INTERRUPTED)) && { printf '\n' >&2; return "$KESTREL_FORM_SIGNAL"; }
    ((status == 0)) && break
    ((status > 128)) || { printf '\n' >&2; return "$status"; }
  done
  [[ -n $silent ]] && printf '\n' >&2
  printf -v "$__var" '%s' "$value"
}

# kestrel_choose <header> <item>... -> prints the chosen item on stdout.
kestrel_choose() {
  local header=$1 choice i
  shift
  local -a items=("$@")
  (( ${#items[@]} )) || return 1
  printf '%s\n' "$header" >&2
  for i in "${!items[@]}"; do
    printf '%2d) %s\n' "$((i + 1))" "${items[i]}" >&2
  done
  while true; do
    kestrel_read_line "> " choice || return $?
    if [[ $choice =~ ^[0-9]+$ ]] && ((choice >= 1 && choice <= ${#items[@]})); then
      printf '%s\n' "${items[choice - 1]}"
      return 0
    fi
    printf 'Pick a number from the list.\n' >&2
  done
}

kestrel_prompt_keyboard() {
  local label code choice status
  local -a labels=() codes=()
  while IFS='|' read -r label code; do
    labels+=("$label")
    codes+=("$code")
  done <<<"$KESTREL_KEYBOARD_LAYOUTS"

  choice=$(kestrel_choose "Select keyboard layout:" "${labels[@]}") && status=0 || status=$?
  ((status == 0)) || return "$status"

  keyboard_label=$choice
  local i
  for i in "${!labels[@]}"; do
    if [[ ${labels[i]} == "$choice" ]]; then
      keyboard=${codes[i]}
      break
    fi
  done
  return 0
}

kestrel_prompt_username() {
  local status
  while true; do
    kestrel_read_line "Username (alphanumeric, no spaces): " username || return $?
    if [[ "$username" =~ $KESTREL_USERNAME_PATTERN ]]; then
      if [[ "$username" =~ $KESTREL_RESERVED_USERNAMES ]]; then
        notice "Username is reserved for system" 1
      elif kestrel_username_taken "$username"; then
        notice "That username already exists on this machine" 1
      else
        return 0
      fi
    else
      notice "Username must be alphanumeric with no spaces" 1
    fi
  done
}

kestrel_prompt_password() {
  while true; do
    kestrel_read_line "Password (user + root, and disk encryption when enabled): " password silent || return $?
    kestrel_read_line "Confirm password: " password_confirmation silent || return $?

    if [[ -n "$password" && "$password" == "$password_confirmation" ]]; then
      return 0
    elif [[ -z "$password" ]]; then
      notice "Your password can't be blank!" 1
    else
      notice "Passwords didn't match!" 1
    fi
  done
}

# Both fields are skippable with Return, so an empty value is a real answer.
kestrel_prompt_identity() {
  kestrel_read_line "Full name (git; return to skip): " full_name || return $?
  kestrel_read_line "Email address (git; return to skip): " email_address || return $?
}

kestrel_prompt_hostname() {
  while true; do
    kestrel_read_line "Hostname (letters, digits, dashes; return for 'kestrel'): " hostname || return $?
    if [[ -z $hostname ]]; then
      hostname="$KESTREL_HOSTNAME_DEFAULT"
      return 0
    elif [[ "$hostname" =~ $KESTREL_HOSTNAME_PATTERN ]]; then
      return 0
    else
      notice "Hostname must be 1-63 letters, digits, or dashes, and cannot start or end with a dash" 1
    fi
  done
}

# A fresh machine often hasn't joined a network yet, so the geo guess fails
# often; guard it or a `set -e` caller dies before the fallback.
kestrel_prompt_timezone() {
  local guess input
  guess=$(tzupdate -p 2>/dev/null) || guess=""

  while true; do
    kestrel_read_line "Timezone [${guess:-UTC}]: " input || return $?
    [[ -n $input ]] || input=${guess:-UTC}
    if timedatectl list-timezones | grep -Fxq "$input"; then
      timezone=$input
      return 0
    fi
    notice "Unknown timezone: $input" 1
  done
}

# kestrel_confirm <prompt> -> 0 for yes (Return defaults to yes), 130 on Ctrl+C.
kestrel_confirm() {
  local reply
  kestrel_read_line "$1 [Y/n]: " reply || return $?
  [[ -z $reply || $reply =~ ^[Yy] ]]
}
