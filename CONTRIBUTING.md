# Contributing to git-skill

Thanks for wanting to help. This repo bundles **AI-agent skills for Git-host workflows** — each skill is one self-contained `skills/<skill>/SKILL.md` (a markdown behavior contract). The repo also dogfoods its own skills: the procedures below are the ones encoded in `release-sop`, `pr-review`, `changelog-bot`, `issue-triage`, and `hotfix-flow` — when in doubt, read the relevant `SKILL.md`.

## Two hard rules

1. **One skill per directory.** A skill is one self-contained `skills/<name>/SKILL.md` plus optional fixtures. Don't cross-import between skills — they should compose at the AI's runtime, not at file load time. (Worked transcripts and project-specific recipes go under `examples/`, which agents don't load.)
2. **Keep the core ecosystem-agnostic.** The behavior contract (steps, gates, red lines, runbook) is one document; trigger protocol / frontmatter shape / load mechanism are each agent's concern, not the skill's. Don't assume a particular package manager, CI platform, or repo host in the core flow — GitHub / GitLab / Gitea must all work.

## Proposing a new skill

Open an issue first so we can discuss **scope and trigger naming** before you write 150 lines of SKILL.md. New skills get triaged per the `issue-triage` flow; expect a written disposition (`accepted` / `needs-discussion` / `out-of-scope` / …) with a one-line rationale.

A skill ships as: `skills/<name>/SKILL.md` (with `name:` frontmatter so Claude Code auto-loads it), an `examples/<name>-demo.md` worked transcript, a Skills-table row + curl one-liner + trigger table + layout-tree entry in `README.md`, and a `CHANGELOG.md` `[Unreleased]` entry. `install.sh` needs no change — it auto-discovers any `skills/<name>/SKILL.md`.

## Pull requests

`main` is a protected branch — **all changes land via PR** (squash merge, linear history; no direct pushes, no force-pushes). Your PR should clear the gates `pr-review` checks:

- **Title** `type(scope): summary` (e.g. `feat(pr-review): …`, `docs(changelog): …`, `fix(http): …`).
- **Description** with What / Why; link the issue (`closes #N` / `fixes #N`) or say why there isn't one.
- **Tests, CHANGELOG entry, and docs land in the same PR** as the change — no "fix it in a follow-up". (For a SKILL.md / docs-only repo like this one there's no code test suite; the equivalent is `./install.sh --list` still discovering the skill and the SKILL.md `name:` frontmatter being present.)
- **CHANGELOG**: add your entry to `## [Unreleased]` under the right Keep-a-Changelog section (`Added` / `Changed` / `Fixed` / `Security` / a top-level `Breaking`), as a bold-phenomenon bullet with the PR number — see the `changelog-bot` skill for the format. **Don't** put it in a dated `## [X.Y.Z]` section or a tag commit — cutting the dated section is the release step's job (`release-sop`).
- **Breaking changes** go under `Breaking` with a migration line, and the PR description must say so.
- **Anything touching auth / crypto / parsers / dependency bumps / CI secrets**: flag it; see [`SECURITY.md`](./SECURITY.md). Security fixes are *not* filed as ordinary public PRs/issues.
- **Commit message hygiene** — do **not** include AI co-author trailers in commits or PR bodies. Lines like `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`, `Co-authored-by: Claude Code <noreply@anthropic.com>`, or `🤖 Generated with Claude Code` are **rejected** at PR review (see `pr-review` Step 1). AI assistance for drafting / refactoring / debugging is fine — we just don't tag it in the commit history (the repo's authorship semantics stay human-attributed, `git log` / `git blame` doesn't carry an AI noreply email). If your local tooling auto-appends trailers, strip them via `git commit --amend` before pushing, or add a `prepare-commit-msg` git hook that filters them out.

## Testing a skill locally

```bash
git clone https://github.com/PeterGuy326/git-skill
cd git-skill
./install.sh <skill>            # -> ~/.claude/skills/<skill>/SKILL.md
# or  ./install.sh <skill> --project   # -> ./.claude/skills/<skill>/SKILL.md
# or  ./install.sh --all
./install.sh --list             # see what's available
```

Restart Claude Code (or open a new session) so it picks up the `name:` frontmatter. For non-Claude agents, paste the SKILL.md body per the table in the README.

## Releases and hotfixes

You don't cut releases in a PR — **tag is the only release trigger**. The release procedure is the `release-sop` skill (CHANGELOG rollover PR → tag on `main` HEAD → GitHub Release → post-release verify → DOD). A critical fix in a released version that can't wait goes through `hotfix-flow` (cherry-pick only the fix off the release tag → patch tag → forward-merge back to `main`).

## License

By contributing you agree your contributions are licensed under the [MIT License](./LICENSE).
