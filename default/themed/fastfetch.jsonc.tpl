// Load with --load-config examples/2.jsonc
// Note that you must replace the image path to an existing image to display it.

{
    "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
    "logo": {
        "type": "file",
        "source": "~/.config/kestrel/branding/about.txt",
        "color": {
            "1": "#{{ accent_strip }}"
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
            "outputColor": "#{{ muted_strip }}"
        },
        {
            "type": "title",
            "keyWidth": 10
        },
        {
            "type": "custom",
            "format": "└{$1}{$1}┘",
            "outputColor": "#{{ muted_strip }}"
        },
        {
            "type": "custom",
            "format": " {#{{ muted_strip }}}  {#{{ red_strip }}}  {#{{ green_strip }}}  {#{{ yellow_strip }}}  {#{{ blue_strip }}}  {#{{ magenta_strip }}}  {#{{ cyan_strip }}}  {#{{ foreground_strip }}}  {#{{ light_foreground_strip }}}  {#{{ bright_foreground_strip }}}       {#{{ light_foreground_strip }}}  {#{{ foreground_strip }}}  {#{{ cyan_strip }}}  {#{{ magenta_strip }}}  {#{{ blue_strip }}}  {#{{ yellow_strip }}}  {#{{ green_strip }}}  {#{{ red_strip }}}  {#{{ muted_strip }}}"
        },
        {
            "type": "custom",
            "format": "┌{$1}{$1}┐",
            "outputColor": "#{{ muted_strip }}"
        },
        {
            "type": "command",
            "key": "{icon} OS",
            "keyColor": "#{{ yellow_strip }}",
            "text": "echo \"Kestrel $(kestrel-version) $(uname -m)\""
        },
        {
            "type": "command",
            "key": "│ ├",
            "keyColor": "#{{ yellow_strip }}",
            "text": "echo \"Kestrel $(uname -r)\""
        },
        {
            "type": "packages",
            "key": "│ ├󰏖",
            "keyColor": "#{{ yellow_strip }}"
        },
        {
            "type": "shell",
            "key": "│ └",
            "keyColor": "#{{ yellow_strip }}"
        },
        {
            "type": "wm",
            "key": " DE/WM",
            "keyColor": "#{{ blue_strip }}"
        },
        {
            "type": "lm",
            "key": "│ ├󰧨",
            "keyColor": "#{{ blue_strip }}"
        },
        {
            "type": "wmtheme",
            "key": "│ ├󰉼",
            "keyColor": "#{{ blue_strip }}"
        },
        {
            "type": "icons",
            "key": "│ ├󰀻",
            "keyColor": "#{{ blue_strip }}"
        },
        {
            "type": "terminal",
            "key": "│ ├",
            "keyColor": "#{{ blue_strip }}"
        },
        {
            "type": "wallpaper",
            "key": "│ └󰸉",
            "keyColor": "#{{ blue_strip }}"
        },
        {
            "type": "host",
            "key": "󰌢 PC",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "cpu",
            "key": "│ ├󰻠",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "gpu",
            "key": "│ ├󰍛",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "disk",
            "key": "│ ├",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "memory",
            "key": "│ ├󰑭",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "swap",
            "key": "│ ├󰓡",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "uptime",
            "key": "│ ├󰅐",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "display",
            "key": "│ └󰍹",
            "keyColor": "#{{ green_strip }}"
        },
        {
            "type": "sound",
            "key": " SND",
            "keyColor": "#{{ cyan_strip }}"
        },
        {
            "type": "player",
            "key": "│ ├󰥠",
            "keyColor": "#{{ cyan_strip }}"
        },
        {
            "type": "media",
            "key": "│ └󰝚",
            "keyColor": "#{{ cyan_strip }}"
        },
        {
            "type": "custom",
            "format": "└{$1}{$1}┘",
            "outputColor": "#{{ muted_strip }}"
        },
        "break",
        {
            "type": "custom",
            "format": " {#{{ muted_strip }}}  {#{{ red_strip }}}  {#{{ green_strip }}}  {#{{ yellow_strip }}}  {#{{ blue_strip }}}  {#{{ magenta_strip }}}  {#{{ cyan_strip }}}  {#{{ foreground_strip }}}  {#{{ light_foreground_strip }}}  {#{{ bright_foreground_strip }}}       {#{{ light_foreground_strip }}}  {#{{ foreground_strip }}}  {#{{ cyan_strip }}}  {#{{ magenta_strip }}}  {#{{ blue_strip }}}  {#{{ yellow_strip }}}  {#{{ green_strip }}}  {#{{ red_strip }}}  {#{{ muted_strip }}}"
        }
    ]
}
