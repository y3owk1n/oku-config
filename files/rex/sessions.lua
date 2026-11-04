-- The presets of the session picker on ctrl+b ctrl+b, like the sessions in
-- sesh.toml. path takes ~. Rex types command into a new session's shell,
-- once. The picker runs preview beside the preset, with {} as its path.

local presets = {
  command = "ls",
  preview = "eza --tree --level=1 --color=always --group-directories-first -a {}",

  { name = "home (~)", path = "~" },
  { name = "downloads", path = "~/Downloads" },
  { name = "dot config", path = "~/.config" },
  { name = "oku config", path = "~/.config/oku" },
  { name = "neovim config", path = "~/.config/oku/files/nvim" },
  {
    name = "rex config",
    path = "~/.config/oku/files/rex",
    preview = "bat --color=always ~/.config/oku/files/rex/init.lua",
    command = "fude init.lua",
  },
  {
    name = "neru config",
    path = "~/.config/oku/files/neru",
    preview = "bat --color=always ~/.config/oku/files/neru/config.toml.tmpl",
    command = "fude config.toml.tmpl",
  },
}

function presets.find(name)
  for _, p in ipairs(presets) do
    if p.name == name then return p end
  end
end

return presets
