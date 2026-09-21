---
name: add-skill
description: "Add a skill repo or a local skill to the oku configuration."
---

# Add Skill

The config repo is `~/.config/oku`. Three places control all skills:

- `files/skills/<name>/` holds each local skill
- `packages/skills-<source>.toml` pins one external skill repo to one commit
- `lists/ai.toml` lists the packages and links every skill into the three targets

The targets are `~/.claude/skills`, `~/.agents/skills` and `~/.config/opencode/skills`. oku writes the links. Nothing else installs a skill.

`lists/ai.toml` is an included list, and `oku.lock` pins its content. After an edit of it `oku sync` stops with "the included list changed", and `oku update` accepts it. `oku update` with no name also moves every package that follows its upstream, so read what it prints.

## Local skill

1. Create `files/skills/<name>/SKILL.md`. The frontmatter `name:` must equal the directory name.
2. Add three entries to `[files]` in `lists/ai.toml`, one per target:

```toml
"{{home}}/.claude/skills/<name>" = { link = "../files/skills/<name>" }
"{{home}}/.agents/skills/<name>" = { link = "../files/skills/<name>" }
"{{config}}/opencode/skills/<name>" = { link = "../files/skills/<name>" }
```

3. Run `oku update`.

The link points at the directory in the repo. A later edit of the skill shows at once, with no sync. Only a new, renamed or removed skill needs an `oku update`.

What goes inside the file is `/writing-for-agents`: the description, the hierarchy, the completion criterion. It ships `writing-for-agents/CHECKS.md`, which catches a name that does not match its directory and a list out of step with disk.

## From a GitHub repo

### 1. Find the skill path

Clone and list the SKILL.md files:

```
cd /tmp && git clone --depth 1 <repo-url> && find <repo> -name 'SKILL.md'
```

Note the path of each skill directory from the repo root, such as `skills/foo` or `pstack/skills/foo`. The `find` output is the source of truth. Note the commit too, with `git -C <repo> rev-parse HEAD`.

### 2. Hash the tarball

```
oku manifest hash https://github.com/<owner>/<repo>/archive/<commit>.tar.gz
```

It prints the `sha256` line.

### 3. Write the package

Copy an existing `packages/skills-<source>.toml` to a new name. Change `name`, `description`, `homepage`, the `url` and the `sha256`. Set `[version] value` to `<date>-<short commit>`, the commit's day in UTC, such as `2026.09.15-85e8e23`.

Keep `data = true`. It tells oku that the package only holds files, so nothing goes on `PATH`.

Check it with `oku manifest lint packages/skills-<source>.toml`.

### 4. List the package and link the skills

In `lists/ai.toml`, add the package under `[packages]`:

```toml
skills-<source> = "../packages/skills-<source>.toml"
```

Add three entries under `[files]` for each skill you want, one per target:

```toml
"{{home}}/.claude/skills/<prefix>_<skill>" = { link = "{{pkg.skills-<source>}}/<path-to-skill>" }
"{{home}}/.agents/skills/<prefix>_<skill>" = { link = "{{pkg.skills-<source>}}/<path-to-skill>" }
"{{config}}/opencode/skills/<prefix>_<skill>" = { link = "{{pkg.skills-<source>}}/<path-to-skill>" }
```

Skill id format: `<prefix>_<skill>`, such as `cursor_unslop`. The prefix names the source. One repo with two skill directories gets two prefixes, as `cursor` and `cursor-team-kit` do. A skill is only installed when it has link entries. The rest of the repo stays in the store, unused.

### 5. Apply and verify

```
oku update
ls ~/.claude/skills/<prefix>_<skill>/SKILL.md
```

oku refuses a target path that exists and that it did not write. Move that path away, then run it again. It also stops on a link whose source does not exist, and names it.

## Update an external repo

The commit is fixed, so `oku update` never moves it. To take a newer commit, change the commit in `url`, the `sha256` and the `[version] value` in the package file, then run `oku update skills-<source>`. `oku sync` refuses a package file that changed since `oku.lock` was written, and `oku update` accepts it. The links follow the new version. Read the diff of the skills you use first, because their text goes into your context every session.

## Skill sources

Browse at [skills.sh](https://skills.sh/) or see `SOURCES.md` for recommended repos.

## Completion

Done when: the skill directory or the package file exists, `lists/ai.toml` links the skill into all three targets, and `oku update` has run. Checkable: `ls ~/.claude/skills/<id>/SKILL.md ~/.agents/skills/<id>/SKILL.md ~/.config/opencode/skills/<id>/SKILL.md` prints three paths.
