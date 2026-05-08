# claude-skill-release-sop

> A [Claude Code](https://docs.claude.com/claude-code) skill that turns Claude into your **Release Captain co-pilot** — driving any GitHub project through a 7-stage release SOP with hard gates, never skipping a check.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

## What it does

When you say `/release-sop` or `帮我发版 v1.2.3`, the skill walks Claude through:

```
Step 0  项目识别 (Go / Node / Python / Rust / Docker auto-detect)
Step 1  身份对齐 (version, captain, value, breaking?)
Step 2  PR 准入回放 (CI green, CHANGELOG, tests, docs)
Step 3  Pre-flight (lint + test + dry-run package)
Step 4  CHANGELOG 终稿 (Keep a Changelog format)
Step 5  打 Tag (the only release trigger)
Step 6  盯盘 release.yml
Step 7  发布后验证 (smoke test in clean env)
Step 8  DOD 闭环 (one-by-one checklist + report)
```

**Hard rules**: any gate failure stops execution at that step. No skipping. No `unpublish`. No same-version reissues.

Backed by a runbook for build failures, credential expiry, version conflicts, missing assets, and downstream notification breakage.

## Install

### One-liner (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/PeterGuy326/claude-skill-release-sop/main/SKILL.md \
  -o ~/.claude/skills/release-sop/SKILL.md --create-dirs
```

### Git clone

```bash
git clone https://github.com/PeterGuy326/claude-skill-release-sop ~/.claude/skills/release-sop-src
ln -sf ~/.claude/skills/release-sop-src/SKILL.md ~/.claude/skills/release-sop/SKILL.md
```

### Project-local

```bash
mkdir -p .claude/skills/release-sop
curl -fsSL https://raw.githubusercontent.com/PeterGuy326/claude-skill-release-sop/main/SKILL.md \
  -o .claude/skills/release-sop/SKILL.md
```

After installing, restart Claude Code (or open a new session). The skill is auto-loaded via the `name: release-sop` frontmatter.

## Usage

| Trigger | Effect |
|---|---|
| `/release-sop` | Explicit invocation |
| `帮我发版 v1.2.3` | Implicit: starts the flow with that version |
| `cut a release` / `tag and release` | English natural language |
| `走发版流程` | Chinese natural language |

## Why this exists

Most release failures are not tooling problems — they're **process leaks**: someone publishing locally, someone tagging on a red CI, someone shipping without a CHANGELOG entry. This skill makes the SOP non-negotiable by encoding it into the AI co-pilot's behavior.

> **底层逻辑**：发布的本质不是"把代码推出去"，是"把承诺交付给用户"。承诺要可重复、可追溯、可回滚。
>
> Release isn't "pushing code out" — it's "delivering on a promise to your users". Promises need to be repeatable, auditable, reversible.

## Background

Companion blog post (with full SOP framework + dws case study):
- [`source/_posts/github-release-sop.md` on PeterGuy326.github.io](https://github.com/PeterGuy326/PeterGuy326.github.io/blob/master/source/_posts/github-release-sop.md)

Originally distilled while writing release procedures for the [DingTalk Workspace CLI](https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli) (Go + GoReleaser, ~23 releases in one month). Generalized so it works for any GitHub-hosted project.

## Customize

The skill is one file: [`SKILL.md`](./SKILL.md). Fork and edit freely. Common customizations:

- Add ecosystem-specific Pre-flight commands under Step 3
- Tighten the PR DoR list under Step 2 to match your CI workflow names
- Adjust the rollback policy under §回滚 if your registry has different yank semantics

## Contributing

PRs welcome. Keep changes ecosystem-agnostic in the core flow — put project-specific recipes under examples or as forks.

## License

[MIT](./LICENSE)
