# oku config

My machines, described for [oku](https://github.com/y3owk1n/oku): the packages,
the program configs, the theme, the macOS settings and the secrets. It replaces
my nix-darwin and home-manager setup.

oku is a cross-platform package manager with no central registry. It uses TOML
manifests, a lockfile and an immutable store, and it applies a change all the
way or not at all.

## Layout

| Path | What it holds |
|---|---|
| `oku.toml` | The lists to include, my variables, the Forest Ink theme and the SSH key entry |
| `oku.lock` | Resolved versions and hashes. oku writes it, change it with oku commands only |
| `config.toml` | The node that npm packages run with |
| `lists/packages.toml` | Packages with a prebuilt download, and the fonts |
| `lists/apps.toml` | macOS apps, written from the Homebrew cask data |
| `lists/built.toml`, `lists/rust-built.toml`, `lists/built-media.toml` | Tools that oku builds from source |
| `lists/files.toml` | Program configs: links, fixed text and templates |
| `lists/ai.toml` | Agent skills and instructions, linked into three tools |
| `lists/macos.toml` | 202 macOS settings. Skipped on other systems |
| `packages/` | My own package manifests |
| `files/` | The configs and templates that `lists/files.toml` and `lists/ai.toml` place |
| `secrets/` | The sops file with my SSH key. Only ciphertext |
| `bootstrap/macos.sh` | What needs root on a new Mac. I run it once, by hand |
| `bootstrap/linux.sh` | The system packages that the source builds need, for apt, dnf and pacman |

Each list has a notes file beside it: `lists/packages-todo.md` (what did not
move and why), `lists/files-notes.md`, `lists/ai-notes.md` and
`lists/macos-notes.md`.

## A new Mac

1. Install the Command Line Tools, which the source builds need:

   ```sh
   xcode-select --install
   ```

   Then install oku. The nightly build has everything this config uses:

   ```sh
   curl -fsSL https://raw.githubusercontent.com/y3owk1n/oku/main/install.sh | OKU_VERSION=nightly sh
   ```

   Add the hook line it prints to the shell startup file, and open a new shell.

2. Copy the age key to `~/.config/sops/age/keys.txt`, mode `0600`. Without it
   the sync stops at the SSH key, before it changes anything.

3. Clone this repo:

   ```sh
   git clone git@github.com:y3owk1n/oku-config.git ~/.config/oku
   ```

   A new machine has no SSH key yet, so use the https URL there.

4. If the user name is not `kylewong`, edit one line: `NewWindowTargetPath` in
   `lists/macos.toml`.

5. Set a GitHub token. About 20 packages ask the GitHub API for their newest
   release, and an anonymous machine reaches the rate limit:

   ```sh
   export GITHUB_TOKEN=<a token with no scopes>
   ```

6. Look before applying. A dry run checks everything and changes nothing:

   ```sh
   oku sync --dry-run --yes
   ```

   `--yes` approves the install step of the five npm packages. Without it oku
   asks for each one.

7. Apply it. The first sync downloads about 9 GB and compiles about thirty
   packages, so it takes a while:

   ```sh
   oku sync --yes
   ```

8. Run `bootstrap/macos.sh`. It asks before each group: host name, firewall,
   time zone, login window, Touch ID for sudo, fish as the login shell, the
   Karabiner driver that kanata needs.

9. Once, by hand: `bat cache --build`, `gh auth login`, `atuin login`. Grant
   Accessibility to mimi, neru and skhd when macOS asks.

`oku rollback` goes back one generation: packages, files, settings and
secrets together.

## A new Linux machine

Debian, Ubuntu or Fedora. Everything but neru was built and run on Debian 12
and Fedora 44, arm64. `bootstrap/linux.sh` also knows pacman, which was never
run. neru was built on Debian 13. It needs Debian 13, Ubuntu 24.04 or Fedora,
because older releases have no libei, and the script says what to do there.

1. Install oku, copy the age key and clone this repo, as in steps 1 to 3 above.
   The Command Line Tools step does not apply.

2. Install what the source builds take from the system:

   ```sh
   sh ~/.config/oku/bootstrap/linux.sh
   ```

3. `oku sync --yes`. oku skips the macOS apps, the macOS settings in
   `lists/macos.toml` and every entry with `when = { os = "darwin" }`.

`oku.lock` pins the Linux downloads too, because `[lock] platforms` in
`oku.toml` names them. That includes what the Go, Rust and npm builds download:
oku pins those from the Mac. So a Linux machine installs from the lock that the
Mac wrote, and `oku sync --locked` proves it.

After the first sync run the bootstrap script again. It now finds fish and
makes it the login shell, which needs your password once for `chsh`. Then run
`neru services install` once. oku runs neru as a
service on macOS alone, because on Linux the daemon has to wait for the
graphical session, and neru's own unit does that.

Known limits on Linux:

- On a machine that systemd does not run, such as a container, oku installs
  everything and skips the atuin service with one notice.
- tree-sitter's download needs glibc 2.39, so Debian 13 or Ubuntu 24.04.

## Daily use

```sh
oku sync             # apply an edit of any file here
oku sync --dry-run   # see what an edit would do
oku update           # take newer versions and rewrite oku.lock
oku rollback         # go back one generation
oku doctor           # check the setup, including the age key
```

Edit a config under `files/` that is a `link` (nvim, kanata, fish, the agent
files) and it is live at once. Edit a `.tmpl` or a list and run `oku sync`.

## The theme

`[vars.theme]` in `oku.toml` holds the sixteen base16 colours. Every `.tmpl`
under `files/` uses them as `{{theme.base00}}` and so on. Change a colour, run
`oku sync`, and ghostty, tmux, fish, starship, lazygit, bat, btop, mimi, neru,
opencode and the nvim palette file render again in one generation. Then run
`bat cache --build` and restart the terminal.

## Adding things

- A package: `oku add github:owner/repo`, or write `packages/<name>.toml` and
  add it to `lists/packages.toml`.
- A config file: put it under `files/<program>/` and add an entry to
  `lists/files.toml`. Name a template `.tmpl`.
- A macOS setting: add the key under its domain in `lists/macos.toml`. Check the
  type on a Mac that has it with `defaults read-type <domain> <key>`. A float
  needs a decimal point.
- An agent skill: see `files/skills/add-skill/SKILL.md`.
- A secret: edit `secrets/secrets.yaml` with `sops`, then name the value in a
  `secret` entry or under `[secrets]`.

## What did not move

`lists/packages-todo.md` has the full list. In short: Tailscale and the
Karabiner driver need an installer, which `bootstrap/macos.sh` covers. The
policy settings of Brave and the two PAM modules for Touch ID in tmux have no
manifest yet. macOS ships git, ssh, python3 and less.

The tools with no macOS program from upstream are built from source, the way
their Homebrew formulae do it: eza, pngquant, gifsicle, optipng, jpegoptim,
brotli, xz, zstd, lua 5.1, luarocks, GNU coreutils with a `g` prefix, btop, mole,
ghostscript, imagemagick and poppler. They need the Command Line Tools
(`xcode-select --install`) and they compile on the first sync.
