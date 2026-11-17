-- Shared helpers for Hyprland Lua configuration.

local paths = require("default.hypr.paths")

o = o or {}

local function shell_quote(value)
  return "'" .. tostring(value):gsub("'", "'\\''") .. "'"
end

o.shell_quote = shell_quote

local function file_exists(path)
  local file = io.open(path, "r")
  if file then
    file:close()
    return true
  end

  return false
end

-- Hyprland reaps its own children, so os.execute() can't retrieve an exit status
-- from inside the compositor. Read a marker off stdout instead.
function o.shell_succeeds(command)
  -- Subshell, so the redirection covers every command rather than binding to
  -- the last one and letting an earlier one write its own OK into the pipe.
  local pipe = io.popen("( " .. command .. " ) >/dev/null 2>&1 && echo OK")
  if not pipe then
    return false
  end

  local output = pipe:read("*a") or ""
  pipe:close()

  return output:find("OK", 1, true) ~= nil
end

function o.cmd_present(command)
  if command:find("/", 1, true) then
    return file_exists(command)
  end

  local path = os.getenv("PATH") or "/usr/local/bin:/usr/bin"
  for directory in (path .. ":"):gmatch("([^:]*):") do
    if file_exists((directory ~= "" and directory or ".") .. "/" .. command) then
      return true
    end
  end

  return false
end

function o.cmd_missing(command)
  return not o.cmd_present(command)
end

-- The global shortcuts the shell registers, read from the same list it reads.
local shell_shortcuts = nil

local function shell_shortcut_registered(name)
  if not shell_shortcuts then
    shell_shortcuts = {}
    local file = io.open(paths.kestrel_path .. "/default/kestrel/shortcuts", "r")
    if file then
      for line in file:lines() do
        local kind, target = line:match("^(%a+)%s+(%S+)%s*$")
        if kind then
          shell_shortcuts[kind .. "." .. target] = true
        end
      end
      file:close()
    end
  end

  return shell_shortcuts[name] == true
end

-- Reach the shell through its global shortcut when it registers one, so the
-- keypress spawns nothing. Anything else runs the command as before.
local function shell_dispatcher(kind, target, command)
  local name = kind .. "." .. target
  if shell_shortcut_registered(name) then
    return hl.dsp.global("kestrel:" .. name)
  end

  return command
end

local function command_from(value, description)
  if type(value) ~= "table" then
    return value
  end

  if value.kestrel then
    return "kestrel-launch-" .. value.kestrel
  elseif value.launcher then
    return shell_dispatcher("launcher", value.launcher, "kestrel-shell shell toggle kestrel.launcher '{}'")
  elseif value.menu then
    return shell_dispatcher("menu", value.menu, "kestrel-menu toggle " .. shell_quote(value.menu))
  elseif value.panel then
    return shell_dispatcher("panel", value.panel, "kestrel-shell shell toggle " .. shell_quote(value.panel))
  elseif value.audio then
    return shell_dispatcher("audio", value.audio, "kestrel-audio-output-volume " .. shell_quote(value.audio))
  elseif value.brightness then
    local step = value.brightness == "raise" and "+5%" or "5%-"
    return shell_dispatcher("brightness", value.brightness, "kestrel-brightness-display " .. step)
  elseif value.ipc then
    local target, method = value.ipc:match("^([^.]+)%.(.+)$")
    return shell_dispatcher("ipc", value.ipc, "kestrel-shell " .. shell_quote(target) .. " " .. shell_quote(method))
  elseif value.focus and value.launch then
    return o.launch_sole(value.focus, value.launch)
  elseif value.launch then
    return o.launch(value.launch)
  elseif value.webapp then
    if value.focus then
      return o.launch_webapp_sole(description, value.webapp)
    else
      return o.launch_webapp(value.webapp)
    end
  elseif value.tui then
    if value.focus then
      return "kestrel-launch-or-focus-tui " .. shell_quote(value.tui)
    else
      return "kestrel-launch-tui " .. shell_quote(value.tui)
    end
  end

  return value
end

function o.preinstalled_bindings_enabled()
  if _G.kestrel_preinstalled_bindings ~= nil then
    return _G.kestrel_preinstalled_bindings == true
  end

  return not file_exists((os.getenv("HOME") or "") .. "/.local/state/kestrel/preinstalls-removed")
end

function o.bind(keys, description, dispatcher, options)
  local opts = options or {}

  if description then
    opts.description = description
  end

  dispatcher = command_from(dispatcher, description)

  if type(dispatcher) == "string" then
    dispatcher = hl.dsp.exec_cmd(dispatcher)
  end

  hl.bind(keys, dispatcher, opts)
end

function o.rebind(keys, description, dispatcher, options)
  hl.unbind(keys)
  o.bind(keys, description, dispatcher, options)
end

function o.launch(command)
  return "uwsm-app -- " .. command
end

-- The command each function bind stands for, so the keybindings menu can still
-- run a bind that Hyprland only reports as Lua.
o.bind_commands = {}

-- Hand the launcher the focused window's pid, which it would otherwise ask
-- Hyprland for, to open the new terminal in that terminal's directory.
function o.launch_terminal()
  local function launch()
    local window = hl.get_active_window()
    if window and window.pid then
      hl.exec_cmd("kestrel-launch-terminal --pid=" .. window.pid)
    else
      hl.exec_cmd("kestrel-launch-terminal")
    end
  end

  o.bind_commands[launch] = "kestrel-launch-terminal"
  return launch
end

function o.exec_on_start(command)
  hl.on("hyprland.start", function()
    hl.exec_cmd(command)
  end)
end

function o.launch_on_start(command)
  o.exec_on_start(o.launch(command))
end

function o.launch_webapp(url)
  return "kestrel-launch-webapp " .. shell_quote(url)
end

function o.launch_webapp_sole(name, url)
  return "kestrel-launch-or-focus-webapp " .. shell_quote(name) .. " " .. shell_quote(url)
end

function o.launch_sole(match, command)
  return "kestrel-launch-or-focus " .. shell_quote(match) .. " " .. shell_quote(o.launch(command))
end

function o.bind_toggle(keys, description, toggle, options)
  o.bind(keys, description, "kestrel-toggle-" .. toggle, options)
end

function o.notify(message)
  return "kestrel-notification-send -u low " .. shell_quote(message)
end

function o.window(match, rules)
  rules.match = rules.match or {}

  if type(match) == "string" then
    rules.match.class = match
  else
    for key, value in pairs(match) do
      rules.match[key] = value
    end
  end

  hl.window_rule(rules)
end

-- Opt a window in to Kestrel's standard active/inactive transparency.
function o.transparent_window(match, opacity)
  o.window(match, { opacity = opacity or "0.985 0.96" })
end
