# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.0] - 2026-05-10

`issue-triage` skill shipped — the front of the workflow chain: it decides which issues are `accepted` (and thus `fixes #N`-eligible for `changelog-bot`, a DoR plus for `pr-review`, milestone fodder for `release-sop` DOD). Same hard-gate philosophy: a written rationale on every disposition, an explicit `S1`–`S4` severity rubric instead of title-driven guessing, and security reports routed to `SECURITY.md` rather than triaged in the open. Agent-agnostic markdown contract; Git-host-agnostic (GitHub / GitLab / Gitea). After this, only `hotfix-flow` remains 🚧 in the roadmap.

### Added

- **`skills/issue-triage/SKILL.md` — generic issue-triage SOP** — takes an incoming issue (or a batch) and produces a written triage verdict. Seven steps: Step 0 issue + repo context load (`gh issue view` / `glab` / `tea`; label taxonomy, `.github/ISSUE_TEMPLATE/`, `CONTRIBUTING`/`SUPPORT`, `SECURITY.md`, milestones, `CODEOWNERS`), Step 1 type classification into exactly one of `bug` / `feature` / `question`-`support` / `docs` / `task`-`chore` / `security` / `meta`-`discussion` — `security` stops here and routes to `SECURITY.md` (no detail-chasing in the open), Step 2 actionability gate with a written rationale per disposition (`accepted` / `needs-repro` / `needs-info` / `needs-discussion` / `duplicate` / `out-of-scope`-`wontfix` / `stale` / `upstream`), Step 3 area/component labeling against the repo's `area/*` taxonomy (no unilateral new labels), Step 4 severity for accepted bugs against an explicit `S1`–`S4` rubric (severity ≠ priority; `S1` security-adjacent → back to the Step 1 security path), Step 5 the triage output block (type · disposition · area · severity · suggested labels/milestone/owner · one-line rationale posted on the issue · templated `needs-repro`/`needs-info` comment or `duplicate`/`out-of-scope` close comment · what-happens-next) — applied via `gh issue edit/comment/close` only with write access + user confirm; never closes on a guess, Step 6 handoff / batch mode (per-issue table, never blanket-label). Includes an edge-case runbook (no label taxonomy, security report in a public issue, no reporter response, multi-issue bundle, bug-that's-actually-a-question, emotion-titled report, duplicate-with-better-info, cross-repo/upstream, in-scope-but-undecided) and six red lines (no rationale-free triage, no public-issue security handling, no title-driven severity, no unilateral label/milestone changes, no guess-based closes, no batch blanket-labeling). Explicit composition: `changelog-bot` writes `fixes #N` only against `accepted` issues; `pr-review` Step 1 counts a linked-triaged-issue as a DoR plus; `release-sop` Step 8 DOD closes the milestoned issues; `S1`+security feeds `hotfix-flow`. Agent-agnostic; Git-host-agnostic.
- **`README.md` — `issue-triage` promoted from 🚧 planned to ✅ shipped** — Skills table row rewritten with the 7-stage summary; quickstart gains an `issue-triage` curl one-liner; Usage section gains an `issue-triage` trigger table; repo-layout tree updated for `skills/issue-triage/SKILL.md` and `examples/issue-triage-demo.md`. `install.sh` unchanged — it auto-discovers any `skills/<name>/SKILL.md`.
- **`examples/issue-triage-demo.md` — worked `issue-triage` transcript** — the 7 steps run end-to-end on a hypothetical no-repro bug report (`dws fetch hangs forever`): first pass → `needs-repro` (area + severity deferred on no evidence) with the filled-in template comment; second pass after the reporter supplies a repro → `accepted`, `area/http`, `S2` (rationale records why it's not `S1`), milestone `v0.6.0`, owner from `CODEOWNERS`, posted rationale, `gh` commands; plus a batch-mode table triaging three more issues (`duplicate` close, `question` route + close, `out-of-scope` close) and a closing contrast on the public-issue-security and emotion-titled-report cases.

## [0.5.0] - 2026-05-10

`changelog-bot` skill shipped — generates the CHANGELOG entries that `pr-review` Step 5 later checks and `release-sop` Step 4 later folds into a dated release. Same hard-gate philosophy: a granularity gate that bounces low-quality bullets, a Breaking special case with a mandatory migration line, and a hard red line against committing the CHANGELOG itself (it proposes; the author merges via a normal PR). Agent-agnostic markdown contract; Git-host-agnostic (GitHub / GitLab / Gitea).

### Added

- **`skills/changelog-bot/SKILL.md` — generic CHANGELOG-entry drafter** — takes a PR / commit-range / branch / pasted diff and produces a ready-to-paste Keep-a-Changelog entry. Six steps: Step 0 input identification + CHANGELOG house-style scan (file location, sections used, bullet conventions, `[Unreleased]` vs dated sections), Step 1 diff walk + classification into `Breaking` / `Added` / `Changed` / `Deprecated` / `Removed` / `Fixed` / `Security` with non-user-facing noise (refactors, test-only, CI, formatting, behavior-neutral dep bumps) discarded — whole-PR-is-noise ⇒ a valid "no entry needed, because …" output, Step 2 per-entry drafting behind a granularity gate (every bullet must carry **bolded phenomenon + root cause/trigger + fix/implementation + impact** plus PR ref / `fixes #N`; rejects "fix a bug" / "improve performance" / "update deps"; won't fabricate root cause), Step 3 Breaking-change special case (own `Breaking` section + mandatory migration line + major-bump cross-check), Step 4 placement & output (top of `[Unreleased]` under the right section in Keep-a-Changelog order; never a tag commit / dated section; never auto-commits), Step 5 self-check against the exact gates `pr-review` Step 5 applies + handoff line. Includes an edge-case runbook (no CHANGELOG file, repo doesn't use one, multi-change PR, oversized diff, unknown root cause, dependency bump, pure-docs/CI/test PR, pre-existing non-compliant entry) and six red lines (never commits the CHANGELOG, never fabricates root cause/impact, no low-granularity bullets, no hiding Breaking in a normal section, never writes into a tag commit / dated section, never changes the repo's CHANGELOG format unilaterally). Explicit composition: `pr-review` Step 5 *checks* presence/format/granularity — `changelog-bot` *generates* the content; `release-sop` Step 4 folds `[Unreleased]` entries into the dated release. Agent-agnostic; Git-host-agnostic.
- **`README.md` — `changelog-bot` promoted from 🚧 planned to ✅ shipped** — Skills table row rewritten; quickstart gains a `changelog-bot` curl one-liner; Usage section gains a `changelog-bot` trigger table; repo-layout tree updated for `skills/changelog-bot/SKILL.md` and `examples/changelog-bot-demo.md`. `install.sh` unchanged — it auto-discovers any `skills/<name>/SKILL.md`.
- **`examples/changelog-bot-demo.md` — worked `changelog-bot` transcript** — the 6 steps run end-to-end on a hypothetical PR (`fix(auth): refresh token rotation drops the new token on a slow write`): Step 0 input + house-style scan, Step 1 classification into one `Fixed` + one `Security` change (test file noted as coverage, not its own entry), Step 2 turning a would-be "fix a bug" bullet into two four-element granular entries (with a counter-example of the bounced version), Step 3 not-Breaking determination, Step 4 the ready-to-paste `[Unreleased]` block placed under `### Fixed` / `### Security`, Step 5 the self-check + handoff to `pr-review` Step 5 / `release-sop` Step 4. Closes with the "pure-refactor ⇒ no entry needed" and "renamed flag ⇒ Breaking + migration line" contrasts.

## [0.4.0] - 2026-05-10

`pr-review` skill shipped — a generic 8-stage PR review SOP that guards exactly the gates `release-sop` Step 2 later replays. Same hard-gate philosophy as `release-sop`: every step has a written gate, failure stops execution at that step, no skip path, no "fix it in a follow-up". Agent-agnostic markdown contract; Git-host-agnostic (GitHub / GitLab / Gitea).

### Added

- **`skills/pr-review/SKILL.md` — generic 8-stage PR review SOP** (#1) — encodes Step 0 PR context load (GitHub `gh` / GitLab `glab` / Gitea `tea` / manual), Step 1 DoR meta check (title convention, What/Why, linked issue, target branch, PR size, clean history), Step 2 change classification + interface/behavior/data impact (breaking → must be flagged + CHANGELOG `Breaking` + migration note), Step 3 line-level code review (correctness, edge/failure, error handling, resource & concurrency, consistency, unintended side effects) producing `[blocking]` / `[nit]` comments, Step 4 test-coverage gate (tests same-PR, regression test for fixes, no skipped tests, CI green — zero-test feature PR or red CI ⇒ hard `BLOCK`), Step 5 CHANGELOG-entry gate (presence + Keep-a-Changelog format + granularity; content generation deferred to `changelog-bot`), Step 6 security-review trigger checklist (auth / crypto / parsers & deserialization / permission model / dependency bumps / CI secrets & `pull_request_target` / new endpoints — must write an explicit hit-or-no-hit line), Step 7 verdict report (`✅ APPROVE` / `🔁 REQUEST_CHANGES` / `⛔ BLOCK` with per-gate results, unmet-item list with "how to fix", security verdict, line-level comments, one-line conclusion). Includes edge-case runbook (CI in-flight, sole-maintainer author, hotfix PR, oversized diff, bot/dependency PR, vendored/generated code, reviewer out of depth), seven red lines (no approve on red CI, no zero-test feature PR, no unflagged breaking change, security trigger ⇒ must route, no "fix in a follow-up", no self-approve, don't promote nits to blockers or demote blockers to nits), and explicit composition with `release-sop` (this skill guards exactly the gates `release-sop` Step 2 later replays), `changelog-bot`, `hotfix-flow`, `issue-triage`. Agent-agnostic: same contract loads into Claude Code / Qoder / Cursor / Custom GPT / generic LLM.
- **`README.md` — `pr-review` promoted from 🚧 planned to ✅ shipped** — Skills table row rewritten with the 8-stage summary; quickstart now has a `pr-review` curl one-liner alongside `release-sop`; Usage section gains a `pr-review` trigger table; repo-layout tree updated to show `skills/pr-review/SKILL.md` and the new `examples/` directory. `install.sh` needs no change — it already auto-discovers any `skills/<name>/SKILL.md`.
- **`examples/pr-review-demo.md` — worked `pr-review` transcript** — the 8 steps run end-to-end against a hypothetical PR (`feat(http): add --retry N flag`): Step 0 context load, DoR pass, change classification flagging stale docs, a line-level review surfacing two `[blocking]` (unreset POST body on retry, unbounded un-jittered backoff) plus two `[nit]`, a test-coverage gate noting a missing regression test, a missing-CHANGELOG-entry gate, an explicit no-hit security-trigger judgement, a `🔁 REQUEST_CHANGES` verdict report with a numbered how-to-fix list, then a second pass after the author's follow-up commit flipping it to `✅ APPROVE`. Closes with notes on when the verdict would instead be `⛔ BLOCK` / `🔒 SECURITY REVIEW REQUIRED`, and on why this repo's own PR #1 is a near-trivial `APPROVE` (docs-only).

## [0.3.0] - 2026-05-10

Repo and `release-sop` skill repositioned from "Claude Code-only" into **agent-agnostic**: the SKILL is a markdown behavior contract that loads into Claude Code, Qoder, Cursor, ChatGPT Custom GPT, or any LLM. Same contract, different load mechanism.

### Changed

- **`skills/release-sop/SKILL.md` frontmatter & H1 generalized** — description now reads "通用 Git 项目发布 SOP 引导 skill（适用于 GitHub / GitLab / Gitea 等 Git 主机；可装入 Claude Code / Qoder / Cursor / 通用 LLM 等任意 AI Agent）"; H1 changed from "通用 GitHub 发布流程" to "通用 Git 项目发布流程（多 Agent 兼容）". Body of the SOP unchanged — the steps, gates, red lines, runbook stay identical.
- **`README.md` rewritten** — opening positions repo as agent-agnostic skill collection; new "Why agent-agnostic?" section; install section now leads with a 5-row Agent × install-path × trigger × notes table (Claude Code / Qoder / Cursor / Custom GPT / generic LLM); Claude Code commands kept as the quickstart subsection; companion blog post link updated to `/git-release-sop/`.
- **Companion blog post URL changed** — companion post slug renamed from `/github-release-sop/` to `/git-release-sop/` to match the broadened positioning. Old URL retains a meta-refresh redirect on the blog side.

### Notes

- This is **non-breaking for existing installs**: anyone who installed v0.2.0's `~/.claude/skills/release-sop/SKILL.md` keeps working — the skill body and its `name:` frontmatter are unchanged. Only the description text and H1 in the file's metadata-zone were touched.
- `install.sh` continues to target the Claude Code skills directory layout. Per-target install (Qoder / Cursor / etc.) is on the roadmap but not in this version.

## [0.2.0] - 2026-05-10

Repo repositioned from a single-skill project (`claude-skill-release-sop`) into a **multi-skill collection** (`git-skill`) for Git-host workflows (GitHub / GitLab / Gitea). `release-sop` is the first skill; `pr-review`, `issue-triage`, `changelog-bot`, `hotfix-flow` are planned.

### Breaking

- **Repo renamed** `PeterGuy326/claude-skill-release-sop` → `PeterGuy326/git-skill` — old URLs auto-redirect via GitHub but new clones / installs should use the new URL. Update any pinned `raw.githubusercontent.com` install commands accordingly.
- **`SKILL.md` moved** from repo root to `skills/release-sop/SKILL.md` — the one-liner curl install command path changed from `/main/SKILL.md` to `/main/skills/release-sop/SKILL.md`.
- **`install.sh` signature changed** from "no-arg installs the only skill" to "takes a skill name or `--all`" — old `./install.sh` invocation now errors and prints usage; use `./install.sh release-sop` to keep prior behavior.

### Changed

- **`README.md` rewritten** to introduce the repo as a skill collection — includes a roadmap table for planned skills, a layout section, and updated install paths.
- **`install.sh` rewritten** to support multi-skill installs (`--all`, `--list`, `<skill-name>`) and both user / project scopes — fails fast with usage hint and skill list when called with no args.
- **GitHub repo description** updated to reflect collection positioning.

### Migration

If you installed v0.1.0:

```bash
# Update local clone (only needed if you keep a local working copy):
cd <your-local-clone>
git remote set-url origin https://github.com/PeterGuy326/git-skill.git
git pull --ff-only

# Update one-liner install (the SKILL itself is unchanged behaviorally):
mkdir -p ~/.claude/skills/release-sop && \
  curl -fsSL https://raw.githubusercontent.com/PeterGuy326/git-skill/main/skills/release-sop/SKILL.md \
  -o ~/.claude/skills/release-sop/SKILL.md
```

The installed `~/.claude/skills/release-sop/SKILL.md` file is **identical** to v0.1.0 — no behavior change inside the skill, only repo-level reorganization.

## [0.1.0] - 2026-05-09

Initial public release of `release-sop`, a Claude Code skill that drives any GitHub-hosted project through a 7-stage release SOP with hard gates.

### Added

- **`SKILL.md` — generic 7-stage release SOP** (#init) — encodes Step 0 project detection (Go/Node/Python/Rust/Docker probes), Step 1 identity alignment (version + captain + value + breaking), Step 2 PR DoR replay, Step 3 Pre-flight, Step 4 Keep-a-Changelog drafting, Step 5 tag-only release trigger, Step 6 CI watch, Step 7 post-release verify, Step 8 DOD closeout. Hard gates with no skip path; failure runbook for build / 401-403 / version-conflict / asset-miss / webhook-silent. Five red lines including "no unpublishing same version".
- **`README.md`** — install instructions for one-liner curl, git clone + symlink, and project-local install; usage triggers (English + Chinese natural language); customization guidance; companion blog post backlink.
- **`install.sh`** — convenience installer that copies `SKILL.md` into `~/.claude/skills/release-sop/` (default) or `./.claude/skills/release-sop/` (with `--project`); fails fast if `SKILL.md` is missing.
- **`LICENSE`** — MIT License (Copyright 2026 PeterGuy326).
- **`.gitignore`** — minimal: editor / OS junk only.

### Notes

- This release was itself produced by walking the very SOP the skill encodes — dogfooding closed-loop. Pre-flight, CHANGELOG, tag, GitHub Release, and post-release verification all followed Steps 0-8 of the skill body.
- No CI workflow ships with v0.1.0 by design: a docs-only single-file skill repo has no build / test / package step. A release workflow may be added in a future minor version if asset-shaping becomes necessary.
