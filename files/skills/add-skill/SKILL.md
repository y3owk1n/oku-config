---
name: add-skill
description: "Add a skill repo or a local skill to the oku configuration."
---

# Add Skill

The config repo is `~/.config/oku`. Three places control all skills:

- `files/skills/<name>/` holds each local skill
- `packages/skills-<source>.toml` pins one external skill repo to one commit
- `lists/ai.toml` lists the packages and links every skill into the three targets, one entry per skill

The targets are `~/.claude/skills`, `~/.agents/skills` and `~/.config/opencode/skills`. Each entry names the first as its key and the other two in `also`. oku writes the links. Nothing else installs a skill.

`lists/ai.toml` is a local include, which oku reads as it is. After an edit of it `oku sync` applies it, and resolves and locks a package that is new to the list.

## Local skill

1. Create `files/skills/<name>/SKILL.md`. The frontmatter `name:` must equal the directory name.
2. Add one entry to `[files]` in `lists/ai.toml`, under the local skills:

```toml
"{{home}}/.claude/skills/<name>" = { link = "../files/skills/<name>", also = ["{{home}}/.agents/skills/<name>", "{{config}}/opencode/skills/<name>"] }
```

3. Run `oku sync`.

The link points at the directory in the repo. A later edit of the skill shows at once, with no sync. Only a new, renamed or removed skill needs an `oku sync`.

What goes inside the file is `/writing-for-agents`: the description, the hierarchy, the completion criterion. It ships `writing-for-agents/CHECKS.md`, which catches a name that does not match its directory and a list out of step with disk.

## From a GitHub repo

### 1. Find the skill path

Clone and list the SKILL.md files:

```
cd /tmp && git clone --depth 1 <repo-url> && find <repo> -name 'SKILL.md'
```

Note the path of each skill directory from the repo root, such as `skills/foo` or `pstack/skills/foo`. The `find` output is the source of truth. Note the default branch too, with `git -C <repo> branch --show-current`.

### 2. Write the package

Copy an existing `packages/skills-<source>.toml` to a new name. Change `name`, `description` and `homepage`, the repo URL in `[version] repo` and in `[build] source`, and `branch` when the default branch is not `main`.

The package follows that branch. `oku.lock` records the commit, and `oku update skills-<source>` takes the newest one. The build step copies the repo into the package and nothing goes on `PATH`.

Check it with `oku manifest lint packages/skills-<source>.toml`.

### 3. List the package and link the skills

In `lists/ai.toml`, add the package under `[packages]`:

```toml
skills-<source> = "../packages/skills-<source>.toml"
```

Add one entry under `[files]` for each skill you want, under the external skills:

```toml
"{{home}}/.claude/skills/<prefix>_<skill>" = { link = "{{pkg.skills-<source>}}/<path-to-skill>", also = ["{{home}}/.agents/skills/<prefix>_<skill>", "{{config}}/opencode/skills/<prefix>_<skill>"] }
```

Skill id format: `<prefix>_<skill>`, such as `cursor_unslop`. The prefix names the source. One repo with two skill directories gets two prefixes, as `cursor` and `cursor-team-kit` do. A skill is only installed when it has a link entry. The rest of the repo stays in the store, unused.

### 4. Apply and verify

```
oku sync
ls ~/.claude/skills/<prefix>_<skill>/SKILL.md
```

oku refuses a target path that exists and that it did not write. Move that path away, then run it again. It also stops on a link whose source does not exist, and names it.

## Update an external repo

`oku sync` keeps the commit that `oku.lock` records. `oku outdated` shows which repos have a newer one, and `oku update skills-<source>` takes it. The links follow the new version. Read the diff of the skills you use first, because their text goes into your context every session.

## Skill sources

Browse at [skills.sh](https://skills.sh/) or see `SOURCES.md` for recommended repos.

## Completion

Done when: the skill directory or the package file exists, `lists/ai.toml` links the skill into all three targets, and `oku sync` has run. Checkable: `ls ~/.claude/skills/<id>/SKILL.md ~/.agents/skills/<id>/SKILL.md ~/.config/opencode/skills/<id>/SKILL.md` prints three paths.
