# oku config

My personal [oku](https://github.com/y3owk1n/oku) configuration: the packages I install and the manifests that describe them.

oku is a cross-platform package manager with no central registry. It uses TOML manifests, a lockfile, and an immutable store.

## Layout

- `oku.toml`: the packages to install, each pointing at a manifest
- `oku.lock`: resolved versions and hashes. Written by oku, change it with oku commands only
- `packages/`: my own package manifests

## Usage

Clone to `~/.config/oku`, then:

```sh
oku sync      # make the profile match oku.toml at the versions in oku.lock
oku update    # re-resolve packages and rewrite oku.lock
oku rollback  # switch back to an earlier generation
```

## Adding a package

1. Write a manifest in `packages/<name>.toml`.
2. Run `oku add ./packages/<name>.toml`.
3. Commit `oku.toml` and `oku.lock`.

`oku add` also takes other refs, with an optional `@version`:

```sh
oku add https://host/pkg.toml
oku add github:owner/repo
oku add github:owner/repo#name
oku add git+https://host/repo#path/pkg.toml
oku add alias/name    # a package in a source, see `oku source`
```

## Packages

| Name | Description |
| --- | --- |
| nvim | Neovim nightly |
