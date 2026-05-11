# git-skill

> A collection of **AI Agent skills for Git-based workflows** — works with any Git host (GitHub, GitLab, Gitea, self-hosted) and any AI agent (Claude Code, Qoder, Cursor, ChatGPT Custom GPT, generic LLMs). Each skill is a single self-contained `SKILL.md` that encodes one repeatable engineering procedure with hard gates and no skip paths.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](./LICENSE)

## Why agent-agnostic?

A skill here is just a markdown behavior contract. It **doesn't depend on any single agent's runtime** — Claude Code reads it directly via its `~/.claude/skills/` convention; Qoder / Cursor / Custom GPT users paste the body into their system prompt or rules file. Same contract, different load mechanism. That's the whole point: **process is the asset, not the loader**.

## Skills

| Skill | Status | What it does |
|---|---|---|
| [`release-sop`](./skills/release-sop) | ✅ shipped | Drives any project through an 11-stage release SOP (project ID → identity → **SemVer version recommend** → PR DoR replay → Pre-flight → **Cut PR** rename `[Unreleased]` → `[X.Y.Z]` reviewed by a teammate → tag → CI watch → smoke → **group-channel announcement** → DOD). Auto-detects latest tag + reads `[Unreleased]` to recommend patch/minor/major then asks the Captain to confirm; CHANGELOG ships as a separate Cut PR (no self-approve; sole-maintainer exception requires PR-body declaration + 24h cool-off); post-release announcement ships a structured markdown card to DingTalk / Lark / Slack / Teams / Discord webhooks so users outside the GitHub-watcher set actually hear. Includes an **optional `release-please` automation track** that bots Step 1.5 + Cut PR body + tag push while preserving the human review gate. Auto-detects Go / Node / Python / Rust / Docker. |
| [`pr-review`](./skills/pr-review) | ✅ shipped | Structured 8-stage PR review SOP — context load → DoR meta check → change classification & interface-impact → line-level code review → test coverage → CHANGELOG entry → security-review trigger → `APPROVE` / `REQUEST_CHANGES` / `BLOCK` verdict. Hard gates, no skip path, no "fix it in a follow-up". GitHub / GitLab / Gitea. |
| [`changelog-bot`](./skills/changelog-bot) | ✅ shipped | Turns a PR / commit-range / diff into a precise Keep-a-Changelog entry — walks the diff, classifies into the right section (Breaking / Added / Changed / Fixed / Security…), drafts "phenomenon + root cause + fix + impact" bullets with PR refs, places them at the top of `[Unreleased]`. Proposes only — never commits. GitHub / GitLab / Gitea. |
| [`issue-triage`](./skills/issue-triage) | ✅ shipped | 7-stage issue triage SOP — context load → type classification → actionability gate (accepted / needs-repro / needs-info / duplicate / out-of-scope / …) → area labels → severity rubric (bugs, S1–S4) → written verdict with a one-line rationale on the issue → handoff / batch mode. Security reports routed to `SECURITY.md`, never triaged in the open. GitHub / GitLab / Gitea. |
| [`hotfix-flow`](./skills/hotfix-flow) | ✅ shipped | 8-stage hotfix SOP for a released version that can't wait for the next release — should-we-hotfix gate → fix lands on `main` first → branch off the release tag (or `release/*`) → cherry-pick **only** the fix → CHANGELOG → simplified review → patch tag handed to `release-sop` → **forward-merge back to `main`** (and every intermediate release branch) → DOD. The forward-merge is a hard red line: no merge-back = not done. GitHub / GitLab / Gitea. |

> All five skills are shipped — the Git-host-workflow family (`issue-triage` → `pr-review` → `changelog-bot` → `release-sop`, with `hotfix-flow` as the emergency entry) is complete. Have another procedure you'd like encoded? Open an issue.

> Worked transcripts: [`examples/pr-review-demo.md`](./examples/pr-review-demo.md) (`pr-review`, 8 steps → `REQUEST_CHANGES` → `APPROVE`), [`examples/changelog-bot-demo.md`](./examples/changelog-bot-demo.md) (`changelog-bot`, a vague `fix a bug` PR → a granular `Fixed` + `Security` entry), [`examples/issue-triage-demo.md`](./examples/issue-triage-demo.md) (`issue-triage`, a no-repro bug report → `needs-repro` → `accepted` + `S2`, plus a batch pass), [`examples/hotfix-flow-demo.md`](./examples/hotfix-flow-demo.md) (`hotfix-flow`, an S1 regression in a released version → `v0.4.1` patch → forward-merged back to `main`).

## Why a collection?

Single-skill repos rot fast — each skill is one file, install is trivial, but you end up with 5+ repos to maintain when only one of them is actually special. This repo treats Git-host workflows as a **family** of related procedures sharing the same hard-gate philosophy:

- **Tag is the only release trigger; CI is the only executor; CHANGELOG is the only source of truth.**
- Every step has a written gate; failure stops execution at that step.
- No `unpublish`, no skipping, no "I'll fix it later".

If you adopt one skill, the others compose with it — `release-sop` reads CHANGELOG entries written by `changelog-bot`; `hotfix-flow` ends by handing off to `release-sop`; `pr-review` blocks the very gates `release-sop` later replays.

## Install — pick your agent

Each skill is one self-contained `skills/<skill>/SKILL.md`. The install path differs per agent; the contract inside doesn't.

| Agent | Install path | Trigger | Notes |
|---|---|---|---|
| **Claude Code** | `~/.claude/skills/<skill>/SKILL.md` (user) <br> `<project>/.claude/skills/<skill>/SKILL.md` (project) | `/release-sop`, natural language | Auto-loaded via `name:` frontmatter; restart session after install |
| **Qoder** | Paste SKILL.md body (without frontmatter) into a Custom Mode's system prompt | Natural language inside that mode | Strip the `---...---` block — Qoder doesn't parse it |
| **Cursor** | Append SKILL.md body to `<project>/.cursorrules`, OR drop a `.cursor/rules/<skill>.mdc` | Composer / Agent mode | `.mdc` keeps frontmatter; classic `.cursorrules` doesn't |
| **ChatGPT Custom GPT** | Paste full SKILL.md into the GPT's "Instructions" | Use the GPT directly | Add triggers to GPT description so users know how to invoke |
| **Generic LLM** (Gemini / DeepSeek / Kimi / 通义) | Paste SKILL.md as system prompt or first message of the conversation | "现在按上面的 SOP 走，帮我发版 vX.Y.Z" | Long SOPs eat tokens; trim or attach as external reference if needed |

> **Cross-agent invariant**: the behavior contract (steps, gates, red lines, rollback) is one document. **Variables**: trigger protocol, frontmatter shape, load mechanism — those are each agent's concern, not the skill's.

### Quickstart commands (Claude Code path)

**One-liner per skill**:

```bash
# release-sop
mkdir -p ~/.claude/skills/release-sop && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/release-sop/SKILL.md \
  -o ~/.claude/skills/release-sop/SKILL.md

# pr-review
mkdir -p ~/.claude/skills/pr-review && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/pr-review/SKILL.md \
  -o ~/.claude/skills/pr-review/SKILL.md

# changelog-bot
mkdir -p ~/.claude/skills/changelog-bot && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/changelog-bot/SKILL.md \
  -o ~/.claude/skills/changelog-bot/SKILL.md

# issue-triage
mkdir -p ~/.claude/skills/issue-triage && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/issue-triage/SKILL.md \
  -o ~/.claude/skills/issue-triage/SKILL.md

# hotfix-flow
mkdir -p ~/.claude/skills/hotfix-flow && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/hotfix-flow/SKILL.md \
  -o ~/.claude/skills/hotfix-flow/SKILL.md
```

**Multi-skill install via `install.sh`**:

```bash
git clone https://github.com/PeterGuy326/git-skill ~/.claude/git-skill-src
cd ~/.claude/git-skill-src
./install.sh release-sop                # install one skill, user scope
./install.sh release-sop --project      # install one skill, project scope
./install.sh --all                      # install every skill in this repo
./install.sh --list                     # see what's available
```

> `install.sh` currently targets the Claude Code skills directory layout. A `--target qoder|cursor|...` flag for other agents is on the roadmap — open an issue if you want a specific one prioritized.

### Project-local (Claude Code)

```bash
mkdir -p .claude/skills/release-sop
curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/release-sop/SKILL.md \
  -o .claude/skills/release-sop/SKILL.md
```

After install, restart your agent (or open a new session). Claude Code auto-loads via the `name:` frontmatter; for other agents, follow that agent's reload procedure for system prompts / rules.

## Usage

Each skill defines its own triggers in its `SKILL.md` frontmatter. For example, `release-sop` triggers on:

| Trigger | Effect |
|---|---|
| `/release-sop` | Explicit invocation (Claude Code) |
| `帮我发版 v1.2.3` | Implicit: starts the flow with that version |
| `cut a release` / `tag and release` | English natural language |
| `走发版流程` | Chinese natural language |

And `pr-review` triggers on:

| Trigger | Effect |
|---|---|
| `/pr-review` | Explicit invocation (Claude Code) |
| `review #123` | Implicit: reviews that PR / MR by number |
| `review this PR` / `can this MR merge?` | English natural language |
| `帮我看下这个 PR` / `过一下这个 PR` | Chinese natural language |

And `changelog-bot` triggers on:

| Trigger | Effect |
|---|---|
| `/changelog-bot` | Explicit invocation (Claude Code) |
| `changelog for #123` | Implicit: drafts the entry for that PR / MR |
| `propose a changelog entry` / `write a changelog entry` | English natural language |
| `写个 changelog 词条` / `这个 PR 的 changelog 怎么写` | Chinese natural language |

And `issue-triage` triggers on:

| Trigger | Effect |
|---|---|
| `/issue-triage` | Explicit invocation (Claude Code) |
| `triage #123` / `triage the backlog` | Implicit: triages that issue, or batch-triages untriaged ones |
| `triage this issue` / `is this actionable?` | English natural language |
| `分诊 issue` / `帮我 triage 这个 issue` / `过一下 issue 列表` | Chinese natural language |

And `hotfix-flow` triggers on:

| Trigger | Effect |
|---|---|
| `/hotfix-flow` | Explicit invocation (Claude Code) |
| `hotfix` / `cut a hotfix` / `patch release for #123` | Implicit: starts the hotfix flow for that issue / released version |
| `走 hotfix 流程` / `出个 hotfix` / `紧急修复发版` | Chinese natural language |

See each skill's own `SKILL.md` for full trigger lists and behavior contracts. Non-Claude agents trigger via natural language in their own way; the contract handles the rest.

## Repo layout

```
git-skill/
├── README.md                       this file
├── CONTRIBUTING.md                 PR conventions, local testing, release/hotfix procedure
├── SECURITY.md                     supported versions + how to report a vulnerability (privately)
├── CHANGELOG.md                    repo-level release notes (one entry per skill ship/bump)
├── install.sh                      multi-skill installer
├── LICENSE                         MIT
├── skills/
│   ├── release-sop/                one directory per skill
│   │   └── SKILL.md                self-contained: frontmatter + behavior contract
│   ├── pr-review/
│   │   └── SKILL.md
│   ├── changelog-bot/
│   │   └── SKILL.md
│   ├── issue-triage/
│   │   └── SKILL.md
│   └── hotfix-flow/
│       └── SKILL.md
└── examples/                       worked transcripts / project-specific recipes (not loaded by agents)
    ├── pr-review-demo.md           pr-review walking a PR end-to-end, REQUEST_CHANGES → APPROVE
    ├── changelog-bot-demo.md       changelog-bot turning a vague "fix a bug" PR into a granular entry
    ├── issue-triage-demo.md        issue-triage taking a no-repro bug report → needs-repro → accepted
    └── hotfix-flow-demo.md         hotfix-flow patching a released version, cherry-pick + forward-merge
```

Each skill directory is self-contained — copy `SKILL.md` into your agent's appropriate path (see the install table above) and you're done. The repo just bundles them.

## Why this exists

Most engineering process failures aren't tooling problems — they're **process leaks**: someone tagging on a red CI, someone shipping without a CHANGELOG entry, someone "just this once" cherry-picking outside the hotfix flow. These skills make the procedures non-negotiable by encoding them into the AI co-pilot's behavior.

> **底层逻辑**：工程承诺（发布、合并、上线）要可重复、可追溯、可回滚。skill 的价值是把"应该这么做"变成"非这么做不可"。
>
> Engineering promises (release, merge, deploy) need to be repeatable, auditable, reversible. The value of a skill is turning *"this is how we should do it"* into *"this is the only way we can do it"*.

## Background

Companion blog post (full SOP framework + dws case study):
- Live: [Git Release SOP — 通用 AI Agent 发版副驾手册](https://peterguy326.github.io/git-release-sop/)
- Source: [`source/_posts/git-release-sop.md`](https://github.com/PeterGuy326/PeterGuy326.github.io/blob/master/source/_posts/git-release-sop.md)

The `release-sop` skill was originally distilled while writing release procedures for the [DingTalk Workspace CLI](https://github.com/DingTalk-Real-AI/dingtalk-workspace-cli) (Go + GoReleaser, ~23 releases in one month). The other four skills emerged from the same project's issue / PR / changelog / hotfix workflows, generalized so they work on any Git-hosted repo regardless of host or stack.

## Contributing

PRs welcome. Two hard rules:

1. **One skill per directory.** A skill is one self-contained `SKILL.md` plus optional fixtures. Don't cross-import between skills — they should compose at the AI's runtime, not at file load time.
2. **Keep the core ecosystem-agnostic.** Project-specific recipes go under `examples/` or as forks. The core flow shouldn't assume a particular package manager, CI platform, or repo host.

Open an issue first if you're proposing a new skill so we can discuss scope and trigger naming. `main` is a protected branch — all changes land via PR (squash merge, linear history). Full PR conventions, local-testing steps, and the release / hotfix procedure are in [`CONTRIBUTING.md`](./CONTRIBUTING.md); vulnerability reporting (don't open a public issue) is in [`SECURITY.md`](./SECURITY.md).

## License

[MIT](./LICENSE)
