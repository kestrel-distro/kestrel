// Load with --load-config examples/2.jsonc
// Note that you must replace the image path to an existing image to display it.

{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "file",
        "source": "~/.config/kestrel/branding/about.txt",
        "color": {
            "1": "{{ accent }}"
        },
        "padding": {
            "top": 2,
            "right": 6,
            "left": 2
        }
    },
    "display": {
        "separator": " -> ",
        "constants": [
            "──────────────────────────────"
        ]
    },
    "modules": [
        {
            "type": "custom",
            "format": "┌{$1}{$1}┐",
            "outputColor": "{{ muted }}"
        },
        {
            "type": "title",
            "keyWidth": 10
        },
        {
            "type": "custom",
            "format": "└{$1}{$1}┘",
            "outputColor": "{{ muted }}"
        },
        {
            "type": "custom",
            "format": " {#{{ muted_strip }}}  {#{{ red_strip }}}  {#{{ green_strip }}}  {#{{ yellow_strip }}}  {#{{ blue_strip }}}  {#{{ magenta_strip }}}  {#{{ cyan_strip }}}  {#{{ foreground_strip }}}  {#{{ light_foreground_strip }}}  {#{{ bright_foreground_strip }}}       {#{{ light_foreground_strip }}}  {#{{ foreground_strip }}}  {#{{ cyan_strip }}}  {#{{ magenta_strip }}}  {#{{ blue_strip }}}  {#{{ yellow_strip }}}  {#{{ green_strip }}}  {#{{ red_strip }}}  {#{{ muted_strip }}}"
        },
        {
            "type": "custom",
            "format": "┌{$1}{$1}┐",
            "outputColor": "{{ muted }}"
        },
        {
            "type": "command",
            "key": "{icon} OS",
            "keyColor": "{{ yellow }}",
            "text": "echo \"Kestrel $(kestrel-version) $(uname -m)\""
        },
        {
            "type": "command",
            "key": "│ ├",
            "keyColor": "{{ yellow }}",
            "text": "echo \"Kestrel $(uname -r)\""
        },
        {
            "type": "packages",
            "key": "│ ├󰏖",
            "keyColor": "{{ yellow }}"
        },
        {
            "type": "shell",
            "key": "│ └",
            "keyColor": "{{ yellow }}"
        },
        {
            "type": "wm",
            "key": " DE/WM",
            "keyColor": "{{ blue }}"
        },
        {
            "type": "lm",
            "key": "│ ├󰧨",
            "keyColor": "{{ blue }}"
        },
        {
            "type": "wmtheme",
            "key": "│ ├󰉼",
            "keyColor": "{{ blue }}"
        },
        {
            "type": "icons",
            "key": "│ ├󰀻",
            "keyColor": "{{ blue }}"
        },
        {
            "type": "terminal",
            "key": "│ ├",
            "keyColor": "{{ blue }}"
        },
        {
            "type": "wallpaper",
            "key": "│ └󰸉",
            "keyColor": "{{ blue }}"
        },
        {
            "type": "host",
            "key": "󰌢 PC",
            "keyColor": "{{ green }}"
        },
        {
            "type": "cpu",
            "key": "│ ├󰻠",
            "keyColor": "{{ green }}"
        },
        {
            "type": "gpu",
            "key": "│ ├󰍛",
            "keyColor": "{{ green }}"
        },
        {
            "type": "disk",
            "key": "│ ├",
            "keyColor": "{{ green }}"
        },
        {
            "type": "memory",
            "key": "│ ├󰑭",
            "keyColor": "{{ green }}"
        },
        {
            "type": "swap",
            "key": "│ ├󰓡",
            "keyColor": "{{ green }}"
        },
        {
            "type": "uptime",
            "key": "│ ├󰅐",
            "keyColor": "{{ green }}"
        },
        {
            "type": "display",
            "key": "│ └󰍹",
            "keyColor": "{{ green }}"
        },
        {
            "type": "sound",
            "key": " SND",
            "keyColor": "{{ cyan }}"
        },
        {
            "type": "player",
            "key": "│ ├󰥠",
            "keyColor": "{{ cyan }}"
        },
        {
            "type": "media",
            "key": "│ └󰝚",
            "keyColor": "{{ cyan }}"
        },
        {
            "type": "custom",
            "format": "└{$1}{$1}┘",
            "outputColor": "{{ muted }}"
        },
        "break",
        {
            "type": "custom",
            "format": " {#{{ muted_strip }}}  {#{{ red_strip }}}  {#{{ green_strip }}}  {#{{ yellow_strip }}}  {#{{ blue_strip }}}  {#{{ magenta_strip }}}  {#{{ cyan_strip }}}  {#{{ foreground_strip }}}  {#{{ light_foreground_strip }}}  {#{{ bright_foreground_strip }}}       {#{{ light_foreground_strip }}}  {#{{ foreground_strip }}}  {#{{ cyan_strip }}}  {#{{ magenta_strip }}}  {#{{ blue_strip }}}  {#{{ yellow_strip }}}  {#{{ green_strip }}}  {#{{ red_strip }}}  {#{{ muted_strip }}}"
        }
    ]
}
