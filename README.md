# oku config

My machines, described for [oku](https://github.com/y3owk1n/oku): the packages,
the program configs, the theme, the macOS settings and the secrets.

oku is a cross-platform package manager with no central registry. It uses TOML
manifests, a lockfile and an immutable store, and it applies a change all the
way or not at all.

## Layout

| Path | What it holds |
|---|---|
| `oku.toml` | The lists to include, one per OS under a `when`, the node of the npm packages, my variables, the Forest Ink theme and `[env]` |
| `oku.lock` | Resolved versions and hashes. oku writes it, change it with oku commands only |
| `lists/packages.toml` | Packages and fonts for every OS, prebuilt or built from source, grouped by what they are for |
| `lists/apps.toml` | Desktop apps for more than one OS, written from the Homebrew cask data |
| `lists/files.toml` | Program configs for every OS: links, fixed text, templates and the SSH key |
| `lists/ai.toml` | Agent skills and instructions, linked into three tools |
| `lists/darwin.toml` | What macOS alone gets: apps, the window tools, the system-scope apps, configs and `[host]` |
| `lists/macos.toml` | 202 macOS settings, included from `lists/darwin.toml` |
| `lists/linux.toml`, `lists/windows.toml` | What Linux or Windows alone gets |
| `packages/` | My own package manifests |
| `files/` | The configs and templates that `lists/files.toml` and `lists/ai.toml` place |
| `secrets/` | The sops file with my SSH key. Only ciphertext |
| `bootstrap/macos.sh` | What needs root on a new Mac. I run it once, by hand |
| `bootstrap/linux.sh` | The system packages that the source builds need, for apt, dnf and pacman |

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

4. Set a GitHub token. About 20 packages ask the GitHub API for their newest
   release, and an anonymous machine reaches the rate limit:

   ```sh
   export GITHUB_TOKEN=<a token with no scopes>
   ```

5. Look before applying. A dry run checks everything and changes nothing:

   ```sh
   oku sync --dry-run --yes
   ```

   `--yes` approves the install step of the five npm packages. Without it oku
   asks for each one.

6. Apply it. The first sync downloads about 9 GB and compiles about thirty
   packages, so it takes a while:

   ```sh
   oku sync --yes
   ```

7. Run `oku sync --system` for the system-scope apps and services in
   `lists/darwin.toml`: Tailscale, and the Karabiner driver and daemon
   that kanata needs.

   Then run `bootstrap/macos.sh`. It asks before each group: host name,
   firewall, time zone, login window, Touch ID for sudo, fish as the login
   shell, and turning on the Karabiner driver.

8. Once, by hand: `bat cache --build`, `gh auth login`, `atuin login`. Grant
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

3. `oku sync --yes`. oku skips `lists/darwin.toml`, with the macOS apps and
   settings in it, because `oku.toml` includes it under `when = { os = "darwin" }`.

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
  add it to `lists/packages.toml`. One that only macOS gets goes in
  `lists/darwin.toml`, with no `when`.
- A config file: put it under `files/<program>/` and add an entry to
  `lists/files.toml`, or to the OS list when one OS alone gets it. Name a
  template `.tmpl`. A value that differs by OS goes under `[vars]` in each OS
  list, as `neru-shell` does.
- A macOS setting: add the key under its domain in `lists/macos.toml`. Check the
  type on a Mac that has it with `defaults read-type <domain> <key>`. A float
  needs a decimal point.
- An agent skill: see `files/skills/add-skill/SKILL.md`.
- A secret: edit `secrets/secrets.yaml` with `sops`, then name the value in a
  `secret` entry or under `[secrets]`.
