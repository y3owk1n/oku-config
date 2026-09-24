# Packages that did not move to oku

One line each: the package, why it is not in a list, and what to do. Most of
what was here has moved since: the apps came from the Homebrew cask data
(`lists/apps.toml`), and the tools with no macOS program from upstream are built
from source, the way their Homebrew formulae do it (`lists/built.toml`,
`lists/rust-built.toml`, `lists/built-media.toml`).

## Covered by macOS itself

- git: macOS ships `/usr/bin/git` with the Command Line Tools, which a bare machine installs with `xcode-select --install`. The source builds need those tools anyway. Use the system git.
- ssh: macOS ships OpenSSH. Nothing to install.
- python3 (for the mimi tiling layouts): `/usr/bin/python3` comes with the Command Line Tools. Point the layout at it, or check that `python3` on PATH finds it.
- less: macOS ships `/usr/bin/less`. Nothing to install.
- reattach-to-user-namespace (tmux.nix): not needed since macOS 10.10 with a current tmux. The tmux config no longer uses it.

## Needs an installer that oku never runs

- tailscale: the standalone build is a `.pkg` that installs a system extension through its install scripts. `bootstrap/macos.sh` says how to install it.
- karabiner driver for kanata: a system driver from a `.pkg` with install scripts, needs root. `bootstrap/macos.sh` downloads it, checks its sha256 and installs it.

## Not moved yet

- hunspell en_US dictionary and the extension and flag settings of Brave (brave.nix): they need a managed policy file, which is not a package. Brave itself is in `lists/apps.toml`.
- pam_reattach and pam-watchid: they gave Touch ID inside tmux and Apple Watch unlock for sudo. Both build from source, and both go in `/usr/local/lib/pam`, which needs root, so they belong in bootstrap/ once there is a manifest for them.
- nvs, jankyborders: disabled in the Nix config, skipped.

## Moved, with a limit to know about

- The source builds need the Command Line Tools on the machine first, and they compile on the first sync. A build cache (`oku cache`) would let a new machine download the results.
- eza: no man pages, because upstream writes them in markdown and converts them with pandoc.
- Most source builds follow upstream, so `oku update` takes a new release: xz, gifsicle, luarocks, coreutils, brotli, lz4, zstd, jpeg-turbo, jpegoptim, btop, eza, imagemagick, openjpeg, cmake, libpng, libtiff, pkgconf, libwebp-lib and pngquant. pngquant gets each version's sha256 from crates.io, and xz and pkgconf from GitHub. oku pins the digest of a source archive in `oku.lock` the first time it downloads it.
- lua, freetype, fontconfig, optipng, ghostscript and poppler hold a fixed version, each for a reason that the top of its manifest gives. Take a newer one by editing `value` and `sha256` there.
- mole: built from source, because the release holds the two Go helpers only. The tree sits in `libexec/mole` and `bin/mole` links to it. `mo update` and `mo remove` have no use here, take a new version with `oku update mole`.
- coreutils: every program has a `g` prefix, such as `gls` and `gdate`, so none takes the place of a macOS tool.
- ghostscript: built with its bundled libraries, without X11, cups and tesseract.
- discord, whatsapp, orbstack, brave, firefox, affinity, virtualbuddy, ghostty: each follows its vendor's versions, and the top of its manifest says from where. Each app also updates itself in `~/Applications`, and oku replaces that copy on the next `oku update` of the package. Turn the app's own updates off where it lets you.
- orbstack: `orb`, `orbctl`, `docker`, `docker-compose`, `docker-buildx`, `docker-credential-osxkeychain` and `kubectl` come from the store copy of the app, so they stay at the store version until `oku update`. oku does not run the postflight step of the cask, and OrbStack finishes its own setup on first launch.
- fish as the login shell: oku installs fish, but `/etc/shells` and `chsh` need root. `bootstrap/macos.sh` does it. The path is `~/.local/share/oku/profiles/global/current/bin/fish`.
- kanata: installed as a program only. It needs root and the Karabiner driver, so it has no oku service.
- mimi, neru, skhd: macOS asks for Accessibility permission again after each update, because the program moves to a new store path. The same happened with Nix. Their services find the other oku programs by name, because oku puts the profile first on the PATH of a service.
- ffmpeg and ffprobe: the static builds of the ffmpeg-static project, a third party. The macOS arm64 build reports ffmpeg 6.0 under the tag b6.1.1. A source build would replace it.
- devbox: installs, but it drives nix, so it only works on a machine that still has nix.
- ast-grep: only `ast-grep` is linked, not the short name `sg`.
- ghostty: set `auto-update = off` so the app does not replace itself behind oku.
- asr, cmd, diagnose: my own scripts. They are in `files/bin/` and linked into `~/.local/bin` by `lists/files.toml`.
