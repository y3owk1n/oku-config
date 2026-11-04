-- Rex keys and actions that copy my tmux.conf and sesh.toml. The prefix is
-- ctrl+b, as in tmux.
-- oku links this file and sessions.lua into ~/.config/rex. Rex reads them
-- only on `rex config reload`, and `rex config check` finds mistakes first.

local terminal = "com.superlogical.terminal"
local shell = "com.superlogical.terminal.shell"
local presets = require("sessions")

-- The directory a terminal's shell last reported, as a path. Rex gives it
-- as a file:// URL.
local function block_cwd(block_id)
  local r = rex.block.call(terminal, "pwd", { block_id = block_id })
  if not r or not r.pwd then return nil end
  local path = r.pwd:gsub("^file://[^/]*", "")
  return (path:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function expand(path)
  return (path:gsub("^~", os.getenv("HOME")))
end

-- A floating pane over the middle of the window, like tmux's
-- new-pane -x 90% -y 80% -X 5% -Y 10%. The label is its title, like
-- tmux's -T. With no command it runs a shell.
local function float(ctx, bounds, label, command)
  local options = { cwd = block_cwd(ctx.block_id) }
  if command then options.command = command end
  local _, err = rex.session.new_layer{
    bounds = bounds,
    focus = true,
    layout = rex.layout.block{ flavor = shell, label = label, options = options },
  }
  if err then error(err, 0) end
end

local wide = { 0.05, 0.10, 0.90, 0.80 }

-- vim-tmux-navigator. ctrl+hjkl moves to the next pane, unless the pane
-- runs an editor or fzf, which gets the key. fude tail and fude relay share
-- the editor's name but draw no screen, so the key moves out of them. A
-- floating pane keeps the key, like tmux's new-pane -K, so it reaches
-- lazygit.

local function is_editor(fg)
  local base = (fg.name or ""):lower():gsub("%-wrapped$", ""):gsub("diff$", ""):gsub("^g?%.?", "")
  if base == "fude" then
    local r = fg.pid and rex.exec({ "ps", "-o", "args=", "-p", tostring(fg.pid) })
    local sub = r and r.stdout:match("fude%s+(%S+)")
    return sub ~= "tail" and sub ~= "relay"
  end
  return base == "view" or base == "fzf" or base:match("^l?n?vim?x?$") ~= nil
end

local function is_floating(block_id)
  local view = rex.session.view{}
  for _, w in ipairs(view and view.windows or {}) do
    for _, layer in ipairs(w.layers or {}) do
      for _, b in ipairs(layer.blocks or {}) do
        if b.block_id == block_id then return layer.kind == "floating" end
      end
    end
  end
  return false
end

local function navigate(direction)
  return function(ctx)
    if is_floating(ctx.block_id) then return false end
    local p = rex.block.call(terminal, "process", { block_id = ctx.block_id })
    if p and p.foreground and is_editor(p.foreground) then return false end
    rex.session.focus_direction{ direction = direction, wrap = true }
    return true
  end
end

rex.bind("ctrl+h", navigate("left"))
rex.bind("ctrl+j", navigate("down"))
rex.bind("ctrl+k", navigate("up"))
rex.bind("ctrl+l", navigate("right"))

-- Sessions, like sesh. The picker lists Rex sessions, the presets of
-- sessions.lua and zoxide's directories, and opens the pick through
-- sesh_open. sesh_last goes back to the session the last switch left, like
-- sesh last. It only knows about switches made through these two actions.

local state = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")) .. "/rex-last-session"

local function switch(ctx, session_id)
  if ctx.session_id and ctx.session_id ~= session_id then
    local f = io.open(state, "w")
    if f then
      f:write(ctx.session_id)
      f:close()
    end
  end
  rex.client.queue("session.select", { session_id = session_id })
end

local function session_by(field, value)
  local list = rex.call("session.list")
  for _, s in ipairs(list and list.sessions or {}) do
    if s[field] == value then return s end
  end
end

rex.action{
  name = "sesh_open",
  title = "Open Session",
  description = "Go to a session, or create it from a preset or a directory",
  args = { session_id = "string?", label = "string?", path = "string?" },
  run = function(ctx, args)
    local s = args.session_id and session_by("session_id", args.session_id)
      or args.label and session_by("label", args.label)
    if s then return switch(ctx, s.session_id) end
    if not args.label then error("no session " .. tostring(args.session_id), 0) end

    local preset = presets.find(args.label)
    local options = { cwd = expand(args.path or (preset and preset.path) or "~") }
    local command = preset and preset.command or presets.command
    if command then options.initial_input = command .. "\n" end
    local r, err = rex.call("session.create", {
      label = args.label,
      initial_windows = { { layout = rex.layout.block{ flavor = shell, options = options } } },
    })
    if err then error(err, 0) end
    switch(ctx, r.session_id)
  end,
}

rex.action{
  name = "sesh_last",
  title = "Last Session",
  run = function(ctx)
    local f = io.open(state, "r")
    local id = f and f:read("*l")
    if f then f:close() end
    if not id or not session_by("session_id", id) then error("no last session", 0) end
    switch(ctx, id)
  end,
}

-- The presets, for the picker: name, path with ~ expanded, preview.
rex.action{
  name = "sesh_presets",
  title = "List Session Presets",
  run = function()
    local out = {}
    for _, p in ipairs(presets) do
      out[#out + 1] = { name = p.name, path = expand(p.path), preview = p.preview or presets.preview }
    end
    return { presets = out }
  end,
}

rex.action{
  name = "sesh",
  title = "Sessions",
  description = "Pick a session, a preset or a directory",
  run = function(ctx)
    float(ctx, { 0.10, 0.15, 0.80, 0.70 }, "Sessions", { "rex-sesh" })
  end,
}

rex.action{
  name = "float_lazygit",
  title = "Lazygit",
  run = function(ctx) float(ctx, wide, "Lazygit", { "lazygit" }) end,
}

rex.action{
  name = "float_terminal",
  title = "Floating Terminal",
  run = function(ctx) float(ctx, wide, "Terminal") end,
}

rex.action{
  name = "float_friendly",
  title = "Friendly",
  run = function(ctx) float(ctx, wide, "Friendly", { "friendly" }) end,
}

-- The prefix. tmux's own defaults that I use, then my binds from tmux.conf.
-- ctrl+b never reaches the terminal, as in tmux, where ctrl+b ctrl+b
-- opens sesh.

local function prefix(key, action, args)
  rex.bind("ctrl+b>" .. key, action, args)
end

prefix("c", "client.tab.new")
prefix("n", "client.tab.next")
prefix("p", "client.tab.previous")
for i = 1, 9 do
  prefix(tostring(i), "client.tab.goto", { index = i })
end
prefix(",", "client.tab.rename")
prefix("shift+5", "pane.split", { direction = "right" })
prefix("shift+'", "pane.split", { direction = "down" })
prefix("z", "pane.zoom")
prefix("o", "pane.focus_next")
prefix("shift+1", "pane.move_to_new_tab")
for _, d in ipairs({ "left", "right", "up", "down" }) do
  prefix(d, "pane.focus", { direction = d })
  prefix("ctrl+" .. d, "pane.resize", { direction = d })
end
prefix("s", "session.switch")
prefix("shift+4", "session.rename")
prefix("shift+9", "session.previous")
prefix("shift+0", "session.next")
prefix("shift+;", "client.palette.toggle")

prefix("shift+7", "client.tab.close")
prefix("x", "pane.close")
prefix("shift+l", "sesh_last")
prefix("ctrl+b", "sesh")
prefix("ctrl+g", "float_lazygit")
prefix("ctrl+t", "float_terminal")
prefix("ctrl+d", "float_friendly")
-- The navigator takes ctrl+l, so ctrl+b ctrl+l sends it, as the plugin does.
prefix("ctrl+l", "pane.send_key", { key = "ctrl+l" })
