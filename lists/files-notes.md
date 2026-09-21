# Notes for lists/files.toml

## Before the first sync

oku refuses a path that exists and that it did not write. Every path of
`files.toml` is a home-manager symlink today, so remove home-manager's links
first (switch home-manager off, or delete the links). These need a look:

- `~/.config/nvim` and `~/.config/kanata` point into `~/nix-system-config-v2`.
  The copies in `files/nvim` and `files/kanata` are now the source of truth.
  Edits made in the old repo after 2026-09-21 are not in the copies.
- `~/.config/fish/functions`, `~/.config/mimi/tiling` are directories of
  home-manager links. Remove the whole directory, oku links the directory.
- `~/.config/fish/fish_variables` is your own file. Keep it.
- `~/.gitconfig` must not exist, or git ignores `~/.config/git/config`.
  home-manager deleted it on every switch. oku does not.
- `~/.config/direnv/lib/hm-nix-direnv.sh` and `~/.config/stylix/palette.html`
  are not ported. Delete them with the rest.

## After the first sync

1. `bat cache --build`, once, and again whenever the theme changes. bat reads
   themes and syntaxes from its cache only.
2. `chmod 700 ~/.ssh` if oku created the directory (it creates it as 0755).
3. `gh auth login`. `~/.config/gh/hosts.yml` holds a token and is not migrated.
4. `atuin login` and `atuin sync` on a new machine.
5. Set fish as the login shell:
   add `~/.local/share/oku/profiles/global/current/bin/fish` to `/etc/shells`,
   then `chsh -s` that path. nix-darwin did this before.
6. Restart tmux (`tmux kill-server`), ghostty, mimi, neru and skhd so that they
   read the new files.
7. nvim: the first start reinstalls plugins from `nvim-pack-lock.json`.

## Differences from the Nix result

### fish
- `config.fish` and `functions/` are links, edit them in `files/fish`.
  The theme part is `conf.d/theme.fish`, rendered from the theme variables:
  fzf colours, `UTS_COLOR_*`, `NVS_COLOR_*` and the fish syntax colours.
- Dropped: hm-session-vars, the home-manager completions path, the Nix man
  paths, `GTK2_RC_FILES`, `TERMINFO_DIRS`, `STARSHIP_CONFIG` (it was the default).
- The base16-fish script also sent escape codes that set the 22 terminal palette
  colours. That part needs colours as `0c/14/10`, which a template cannot
  derive, so it is dropped. ghostty sets the same palette from its own theme
  file. In another terminal the named colours follow that terminal.
  The syntax colours are now global variables, not universal ones.
- Session variables are set once per login tree, guarded by an exported
  variable, like home-manager did. So a shell inside tmux keeps tmux's `TERM`.
- `SHELL` is the fish of the oku profile.
- Every tool init is skipped when the tool is missing, so a machine without
  the packages still gets a working shell.
- direnv: `nix-direnv` is gone. `use flake` and `use nix` in an `.envrc`
  fall back to direnv's slow built-in versions.

### git
- `core.autocrlf`, `core.commitgraph`, `core.compression`, `core.preloadindex`
  and `core.whitespace` are in `git.nix`, but on macOS the `//` merge replaced
  the whole `core` set with the darwin one, so they never reached the generated
  config. The port has them, as the module meant. Remove the `[core]` block in
  `files/git/config.tmpl` to get today's behaviour back.
- The darwin keys (`core.fsmonitor`, `core.untrackedcache`,
  `feature.manyFiles`) are in `config-darwin`, which the main config includes
  and which only macOS gets. git skips a missing include.
- gh, difft and git-lfs are named by their oku profile path. All three must be
  in the package list, or git fails on credentials, `git diff` and lfs repos.
- `gpg.ssh.program` is dropped. git then runs the `ssh-keygen` on PATH, which
  is the one of macOS or of the distro.
- Signing needs `~/.ssh/id_ed25519`, which the secrets list places.

### ssh
- `UseKeychain yes` is in `config-darwin`, included from the main config.
  ssh skips an Include that matches no file, so both Includes are safe on Linux.
- On Linux home-manager ran `ssh-agent` as a service. Nothing does that here.

### tmux
- `reattach-to-user-namespace` is dropped, with its `default-command`. tmux has
  not needed it since 2.6, and macOS since 10.10 lets `pbcopy` and `pbpaste`
  work inside tmux. Copy uses `set-clipboard on` (OSC 52) anyway. Panes now
  start `default-shell` as a login shell, which is tmux's default.
- vim-tmux-navigator is vendored: `files/tmux/vim-tmux-navigator.tmux` is the
  one script of the plugin at commit e41c431a0c7b7388ae7ba341f01a0d217eb3a432,
  the pin of `pkgs/overrides.nix`, with its licence beside it. It is a link,
  because a rendered file has no execute bit. To bump it, replace the file.
- The colours are `theme.conf`, the base16 tmux template with theme variables.
- `default-shell` is the fish of the oku profile. If fish is not installed,
  tmux ignores the line and uses `$SHELL`.

### sesh
- The sessions that opened `*.nix` modules now open the files in
  `~/.config/oku/files`. "yabai config" is dropped, `yabai.nix` no longer exists.
- "start kanata" still runs `just kanata` in `~/nix-system-config-v2`. Move
  that recipe when the Nix repo goes away. It is:
  start the Karabiner VirtualHIDDevice daemon with sudo, then
  `sudo kanata -n -c ~/.config/kanata/config.kbd`.

### bat
- The ghostty syntax file came from the ghostty package. It is vendored as
  `files/bat/syntaxes/ghostty.sublime-syntax` and does not follow ghostty updates.

### btop
- `btop.conf` stays read-only, as under home-manager, so btop cannot save
  settings that you change inside it.

### atuin
- The config enables the daemon, but nothing starts it. home-manager made a
  launchd agent for `atuin daemon`. Add a service for it, or set
  `daemon.enabled = false`. The `asr` package is not part of this list.

### neru, mimi, skhd
- The apps, their launchd agents and the ad-hoc codesign step belong to the
  package and service lists, not to this one.
- neru: `exec_shell` is `/bin/dash`, the macOS value. The Nix module used
  `/bin/sh` on Linux. A template has no conditionals, so change it by hand there.
- neru: `font_family = "JetBrainsMonoNLNFP-Bold"` is a PostScript name and not
  the `font` variable, so it stays literal.
- skhd is a link, not a template, because its own `{{1}}` syntax would need an
  escape in every macro.
- jankyborders and nvs are disabled in the Nix config and are not ported. The
  `NVS_COLOR_*` variables are kept, the Nix config set them anyway.

### nvim
- `lua/colorscheme.lua` reads `~/.config/stylix/palette.json`. oku renders that
  file from the theme variables, under the same path.
- `lua/lsp.lua` points nixd at `~/nix-system-config-v2`. Harmless without Nix.
- The language servers and formatters of `nvim.nix` belong to the package list.

### Literal colours that are not theme variables
- `#00000000` (transparent text) in neru. Not a theme colour.
- `#B3{{theme.base02}}` in mimi works, the alpha prefix is plain text.
- No file in this list needed an `r,g,b` or a `0xff` form. jankyborders would,
  and it is disabled.

### Not ported
- `~/.config/gh/hosts.yml`, the private ssh key, the sops age key: secrets.
- `~/.claude`, `~/.agents`, opencode skills: another list.
- Browser, Raycast and extension configs in `config/` of the Nix repo.
