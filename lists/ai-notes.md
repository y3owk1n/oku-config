# Notes on lists/ai.toml

`ai.toml` replaces `modules/home/packages/skills.nix` and the skills, memory and
agent parts of `modules/home/packages/common-ai.nix` from the Nix config.

## What it places

- 25 skills in each of `~/.claude/skills`, `~/.agents/skills` and
  `~/.config/opencode/skills`. 14 are local, from `files/skills/`. 11 come from
  five packages, `packages/skills-<source>.toml`.
- `~/.claude/CLAUDE.md` and `~/.claude/agents/quick.md`, as links to
  `files/claude/`. Their content is the bytes Nix generated on 2026-09-21.
- The ids are the ones Nix used: the bare name for a local skill, and
  `<prefix>_<skill>` for an external one, such as `cursor-team-kit_deslop`.

## What differs from the Nix result

- A local skill is a link into this repo. An edit shows at once. Under Nix it
  was a read-only copy in the store and needed a rebuild.
- An external skill is a link into the oku store, at
  `<data>/oku/store/skills-<source>-<version>-<hash>/pkg/<path>`. Nix copied each
  skill directory into a bundle. The content is the same, checked with
  `diff -r` for all 11.
- The whole repo tarball is unpacked in the store, not only the skills
  directory. shadcn-ui/ui is the large one, a 21 MB download.
- Each package says `data = true`, so it only holds files and puts nothing on
  `PATH`.
- Nix wrote `.agent-skills-managed.json` into each target directory. oku needs
  no marker, because its generation records what it wrote. Delete the three
  files after the move.
- `~/.claude/skills/synced` is not from Nix. The app writes it itself and fills
  it with skills from the account. oku does not list it and leaves it alone.
  The list links single skills, never the whole `skills` directory, so that
  `synced` keeps working.
- `CLAUDE.md` and `quick.md` are plain files now. In Nix they were the `context`
  text and the `agents.quick` text inside `common-ai.nix`.
- Not moved: `~/.claude/settings.json` and `~/.claude/plugins`, which Nix never
  managed, and the rest of `programs.claude-code` and `programs.opencode`
  (settings, packages). Those belong to other lists.
- The Nix repo has an `AI_NOTES.md` that describes the skill workflow as a
  whole. It was not moved. `writing-for-agents/SKILL.md` still names it.

## Skill text that changed

- `files/skills/add-skill/SKILL.md` is rewritten for oku.
- `files/skills/find-skills/SKILL.md`: four sentences that named the flake
  input, `just rebuild` and `skills.nix` now name `lists/ai.toml`.
- `files/skills/writing-for-agents/SKILL.md` and `CHECKS.md`: the enable-list
  rule, the install pointer, and checks 1, 6 and 7 now read `lists/ai.toml`.
  The checks run from `~/.config/oku/files`.
- Other Nix words in the skills are examples in prose, such as
  `hosts/default.nix` in `prd/TEMPLATES.md`. They stay.

## Manual steps for the move

1. Add `"./lists/ai.toml"` to `include` in `oku.toml`.
2. Turn the Nix modules off first, or remove their links by hand. oku refuses a
   path that exists and that it did not write, and names it. The paths are the
   25 links in each of the three skill directories, `~/.claude/CLAUDE.md` and
   `~/.claude/agents/quick.md`. Keep `~/.claude/skills/synced`.
3. Run `oku sync`. A new include needs no `oku update`. A later edit of
   `lists/ai.toml` does.
4. Delete `.agent-skills-managed.json` from the three skill directories.
5. Check: `ls ~/.claude/skills/*/SKILL.md | wc -l` prints 25 plus the `synced`
   ones, and the other two directories print 25.

## Versions and updates

All five packages fix one commit, the one `flake.lock` pinned, as
`[version] value = "<date>-<short commit>"`. `oku update` never moves them.
That is on purpose:

- `cursor/plugins`, `anthropics/skills` and `emilkowalski/skills` have no tags
  and no releases. oku has no version source that follows a branch. `git-tags`
  and `github-releases` find nothing there.
- `JuliusBrussee/caveman` has `v` tags and `shadcn-ui/ui` has `shadcn@` tags, so
  `from = "git-tags"` would work for them. It was not used. The pinned commits
  are 25 and 283 commits ahead of the newest tag, so a tag would install older
  text than Nix did. A discovered version also has no `sha256` in the package
  file, only the digest `oku.lock` pins at the first download.
- A skill is text that goes into every session. A fixed commit means it changes
  only when you change it and have read the diff.

### Update an external skill repo

Each `packages/skills-<source>.toml` follows the main branch of its repo, and
`oku.lock` records the commit.

1. `oku update skills-<source>` takes the newest commit. `oku outdated` shows
   which repos have one.
2. oku stops when a linked skill is gone upstream and names the link. Remove or
   fix that entry.

### Add a skill

`files/skills/add-skill/SKILL.md` has the steps for a local skill and for a new
repo. In short: three link entries per skill in `lists/ai.toml`, one per target,
then `oku update`. A change of `lists/ai.toml` always needs `oku update`, not
`oku sync`, because `oku.lock` pins the content of an included list.
