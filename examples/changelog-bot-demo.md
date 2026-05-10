# Worked example — `changelog-bot` drafting an entry from a PR

> A demo transcript of the [`changelog-bot`](../skills/changelog-bot/SKILL.md) skill running its 6 steps on a hypothetical PR **#142 — "fix(auth): refresh token rotation drops the new token on a slow write"** (a `dingtalk-workspace-cli`-style repo). It shows how a vague `fix a bug` gets turned into a four-element granular entry, where it lands, and the handoff to `pr-review` Step 5 / `release-sop` Step 4. Substitute `gh` with `glab` / `tea` for GitLab / Gitea.
>
> **Bottom line:** one `### Fixed` bullet + one `### Security` bullet, dropped at the top of `[Unreleased]`, no commit made — the author edits wording and merges it via a normal PR.

---

## Step 0 — input & CHANGELOG state

```
$ gh pr diff 142
$ gh pr view 142 --json title,body
```

**Input:** PR #142 — `fix(auth): refresh token rotation drops the new token on a slow write`. Diff: 2 files (`internal/auth/refresh.go`, `internal/auth/refresh_test.go`), +37 / −9. PR body: "rotation writes the new token to the keyring async; if the write hasn't landed when the next request fires we re-use the *old* token, server rejects it, user gets logged out. Also we logged the full token on the failure path." Linked: `closes #138`.

**CHANGELOG:** `CHANGELOG.md` at repo root. Keep a Changelog. House style observed in the last ~8 entries:
- Bullet leads with a **bolded user-observable phenomenon**.
- PR number as `(#N)`; issue close as `closes #N` / `fixes #N`.
- Sections used: `Breaking` (top-level), `Added`, `Changed`, `Fixed`, `Security`.
- An `[Unreleased]` section sits at the top; dated `## [X.Y.Z] - YYYY-MM-DD` sections are cut at release time (not by this skill).
- Granularity: entries read "phenomenon — root cause + fix + impact", not "fixed a bug".

→ confirmed with author: right file, right format. Proceeding.

## Step 1 — diff walk & classification

| Change in the diff | Bucket |
|---|---|
| Rotation now awaits the keyring write before returning the new token (was fire-and-forget) | `Fixed` — bug: stale token re-use → spurious logout |
| Failure-path logging changed from `log.Printf("refresh failed: %s", token)` to logging only the token's last 4 chars | `Security` — secret was being written to logs |
| `refresh_test.go`: new `TestRotate_SlowKeyringWrite` + `TestRotate_NoTokenInLogs` | (test — not a changelog entry on its own; it's the regression coverage for the two above) |

Nothing here is `Added` / `Changed` / `Breaking` / `Removed` / `Deprecated`. No noise to discard — both code changes are user-observable. → two entries.

## Step 2 — draft each entry (granularity gate)

**Entry A — `### Fixed`:**

```markdown
- **`dws` no longer logs you out right after a token refresh** (#142, closes #138) — token rotation wrote the new token to the OS keyring asynchronously; if the next request fired before that write landed, `dws` re-used the *old* token, the server rejected it, and the session was dropped. Rotation now awaits the keyring write before returning the refreshed token. Affects anyone on a slow or contended keyring backend; no action needed — the fix is automatic on upgrade.
```

Four elements: *phenomenon* = "no longer logs you out right after a token refresh"; *root cause / trigger* = "async keyring write + next request fires before it lands → stale token re-used → server reject"; *fix* = "rotation awaits the keyring write"; *impact* = "slow/contended keyring users; automatic on upgrade, no action".

**Entry B — `### Security`:**

```markdown
- **Refresh-token value no longer written to logs on the failure path** (#142) — the error branch of token rotation logged the full refresh token (`refresh failed: <token>`); it now logs only the last 4 characters. Rotate any refresh token that may have been captured in logs from an affected build (any release up to and including the previous one); the token itself is unchanged in this build, only what gets logged.
```

Four elements: *phenomenon* = "refresh-token value no longer written to logs"; *root cause / trigger* = "error branch logged the full token"; *fix* = "logs only last 4 chars"; *impact* = "rotate tokens that may have leaked into logs from affected builds".

> Counter-example the skill rejects: the PR title is `fix(auth): refresh token rotation drops the new token on a slow write` — fine as a commit subject, but `- fix token rotation bug (#142)` would be **bounced**: no bolded phenomenon, no root cause, no impact, hides the separate security issue entirely.

## Step 3 — Breaking-change check

Neither change breaks existing users: no flag/format/default/exit-code change, no platform drop, no min-runtime bump. The token *value* and the keyring layout are unchanged. → **not Breaking; no major version bump implied.** (The `Security` entry does carry an *operator action* — rotate possibly-leaked tokens — but that's an advisory in the entry, not a breaking API change.)

## Step 4 — placement & output

Both go at the **top of `[Unreleased]`**, under their sections, in Keep-a-Changelog order (`Fixed` before `Security`). `Fixed` / `Security` sub-headings created if absent. Ready-to-paste block:

```markdown
## [Unreleased]

### Fixed

- **`dws` no longer logs you out right after a token refresh** (#142, closes #138) — token rotation wrote the new token to the OS keyring asynchronously; if the next request fired before that write landed, `dws` re-used the *old* token, the server rejected it, and the session was dropped. Rotation now awaits the keyring write before returning the refreshed token. Affects anyone on a slow or contended keyring backend; no action needed — the fix is automatic on upgrade.

### Security

- **Refresh-token value no longer written to logs on the failure path** (#142) — the error branch of token rotation logged the full refresh token (`refresh failed: <token>`); it now logs only the last 4 characters. Rotate any refresh token that may have been captured in logs from an affected build (any release up to and including the previous one); the token itself is unchanged in this build, only what gets logged.
```

**File:** `CHANGELOG.md` · **Where:** under the existing `## [Unreleased]` heading, creating `### Fixed` and `### Security` if they aren't there yet · **Not** in a tag commit, **not** in a dated section. (Want it as a diff hunk instead? say so.)

**`changelog-bot` does not commit this.** The author reviews the wording (especially the "affected build" range in the Security entry), tweaks, and merges it via a normal PR.

## Step 5 — self-check & handoff

- [x] Each bullet leads with a **bolded phenomenon**
- [x] PR number `(#142)`; issue `closes #138` on the Fixed entry
- [x] No "fixed a bug" / "improved security" — both bullets carry root cause + fix + impact
- [x] Correct sections; `Fixed` before `Security` (Keep-a-Changelog order)
- [x] No Breaking entry needed; checked
- [x] Lands in `[Unreleased]`, not a tag commit / dated section

**Handoff:** *Paste into `CHANGELOG.md` under `[Unreleased] > ### Fixed` / `### Security`. Will pass `pr-review` Step 5 (presence + format + granularity). At the next release, `release-sop` Step 4 will fold these into the dated `## [X.Y.Z]` section — and the `Security` entry should also be surfaced in the GitHub Release notes and, given it's an operator-action advisory, considered for the `release-sop` rollback/security playbook.*

---

> **What this demo is *not*:** a substitute for the contract in [`skills/changelog-bot/SKILL.md`](../skills/changelog-bot/SKILL.md) — it's one trace through it. If the PR had been pure refactor / test-only / CI, the result would be a one-line *"no CHANGELOG entry needed, because …"* — also a valid output. If a change had broken users (e.g. renamed `--token-file` to `--credential-file`), `changelog-bot` would put it under `Breaking` with a `**Migration:** if you passed --token-file, pass --credential-file` line and flag the major-version-bump question — it never hides a breaking change in `Changed`.
