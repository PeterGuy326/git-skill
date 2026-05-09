# git-skill

> A collection of [Claude Code](https://docs.claude.com/claude-code) skills for **Git-based workflows** — works with GitHub, GitLab, Gitea, or any Git host. Each skill encodes one repeatable engineering procedure into Claude's behavior, with hard gates and no skip paths.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

## Skills

| Skill | Status | What it does |
|---|---|---|
| [`release-sop`](./skills/release-sop) | ✅ shipped | Drives any project through a 7-stage release SOP (PR DoR replay → Pre-flight → CHANGELOG → tag → CI watch → smoke → DOD). Auto-detects Go / Node / Python / Rust / Docker. |
| `pr-review` | 🚧 planned | Structured PR review against a checklist (interface change, test coverage, CHANGELOG, security review trigger). |
| `issue-triage` | 🚧 planned | Triage incoming issues into severity / area / actionable-or-not, with a one-line written rationale. |
| `changelog-bot` | 🚧 planned | Walk a PR's diff and propose a Keep-a-Changelog entry under the right section. |
| `hotfix-flow` | 🚧 planned | Cherry-pick-only hotfix branch flow with forward-merge enforcement back to main. |

> Want one of the planned skills sooner, or have a procedure you'd like encoded? Open an issue.

## Why a collection?

Single-skill repos rot fast — each skill is one file, install is trivial, but you end up with 5+ repos to maintain when only one of them is actually special. This repo treats Git-host workflows as a **family** of related procedures sharing the same hard-gate philosophy:

- **Tag is the only release trigger; CI is the only executor; CHANGELOG is the only source of truth.**
- Every step has a written gate; failure stops execution at that step.
- No `unpublish`, no skipping, no "I'll fix it later".

If you adopt one skill, the others compose with it — `release-sop` reads CHANGELOG entries written by `changelog-bot`; `hotfix-flow` ends by handing off to `release-sop`; `pr-review` blocks the very gates `release-sop` later replays.

## Install

Each skill installs into its own directory under `~/.claude/skills/<skill-name>/SKILL.md`. Pick a method:

### One-liner (per skill)

```bash
# release-sop
mkdir -p ~/.claude/skills/release-sop && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/release-sop/SKILL.md \
  -o ~/.claude/skills/release-sop/SKILL.md
```

### install.sh (multi-skill aware)

```bash
git clone https://github.com/PeterGuy326/git-skill ~/.claude/git-skill-src
cd ~/.claude/git-skill-src
./install.sh release-sop                # install one skill, user scope
./install.sh release-sop --project      # install one skill, project scope
./install.sh --all                      # install every skill in this repo
```

### Project-local

```bash
mkdir -p .claude/skills/release-sop
curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/release-sop/SKILL.md \
  -o .claude/skills/release-sop/SKILL.md
```

After install, restart Claude Code (or open a new session). Each skill is auto-loaded by its `name:` frontmatter.

## Usage

Each skill defines its own triggers in its `SKILL.md` frontmatter. For example, `release-sop` triggers on:

| Trigger | Effect |
|---|---|
| `/release-sop` | Explicit invocation |
| `帮我发版 v1.2.3` | Implicit: starts the flow with that version |
| `cut a release` / `tag and release` | English natural language |
| `走发版流程` | Chinese natural language |

See each skill's own `SKILL.md` for full trigger lists and behavior contracts.

## Repo layout

```
git-skill/
├── README.md                       this file
├── CHANGELOG.md                    repo-level release notes (one entry per skill ship/bump)
├── install.sh                      multi-skill installer
├── LICENSE                         MIT
└── skills/
    └── release-sop/                one directory per skill
        └── SKILL.md                self-contained: frontmatter + behavior contract
```

Each skill directory is self-contained — copy it directly into `~/.claude/skills/<name>/` and you're done. The repo just bundles them.

## Why this exists

Most engineering process failures aren't tooling problems — they're **process leaks**: someone tagging on a red CI, someone shipping without a CHANGELOG entry, someone "just this once" cherry-picking outside the hotfix flow. These skills make the procedures non-negotiable by encoding them into the AI co-pilot's behavior.

> **底层逻辑**：工程承诺（发布、合并、上线）要可重复、可追溯、可回滚。skill 的价值是把"应该这么做"变成"非这么做不可"。
>
> Engineering promises (release, merge, deploy) need to be repeatable, auditable, reversible. The value of a skill is turning *"this is how we should do it"* into *"this is the only way we can do it"*.

## Background

Companion blog post (full SOP framework + dws case study):
- [`source/_posts/github-release-sop.md` on PeterGuy326.github.io](https://github.com/PeterGuy326/PeterGuy326.github.io/blob/master/source/_posts/github-release-sop.md)

The `release-sop` skill was originally distilled while writing release procedures for the [DingTalk Workspace CLI](https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli) (Go + GoReleaser, ~23 releases in one month). The other planned skills emerged from the same project's issue / PR / hotfix workflows, generalized so they work on any Git-hosted repo regardless of host or stack.

## Contributing

PRs welcome. Two rules:

1. **One skill per directory.** A skill is one self-contained `SKILL.md` plus optional fixtures. Don't cross-import between skills — they should compose at the AI's runtime, not at file load time.
2. **Keep the core ecosystem-agnostic.** Project-specific recipes go under `examples/` or as forks. The core flow shouldn't assume a particular package manager, CI platform, or repo host.

Open an issue first if you're proposing a new skill so we can discuss scope and trigger naming.

## License

[MIT](./LICENSE)
