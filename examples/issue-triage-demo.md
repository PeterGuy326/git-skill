# Worked example — `issue-triage` on an incoming bug report

> A demo transcript of the [`issue-triage`](../skills/issue-triage/SKILL.md) skill running its 7 steps on a hypothetical issue **#155 — "dws fetch hangs forever"** (a `dingtalk-workspace-cli`-style repo), then a second pass after the reporter supplies a repro. Substitute `gh` with `glab` / `tea` for GitLab / Gitea.
>
> **Bottom line:** first pass → `needs-repro` + a templated comment (no severity yet). Reporter responds with steps → second pass → `accepted`, `area/http`, `S2`, milestone `v0.6.0`, owner from CODEOWNERS, one-line rationale posted. Plus a short batch-mode table for three more issues.

---

## Step 0 — issue & repo context load

```
$ gh issue view 155 --json title,body,labels,author,comments,createdAt,milestone
$ gh label list ; gh api repos/{owner}/{repo}/milestones --jq '.[].title'
```

| | |
|---|---|
| Issue | #155 — `dws fetch hangs forever` |
| Author | @bob (first-time reporter) |
| Body | "I ran `dws fetch` and it just hangs. Please fix." (no version, no OS, no URL, no steps) |
| Labels | *(none)* |
| Milestone | *(none)* |
| Created | 3 days ago |

Repo triage taxonomy (from `gh label list` + templates): `type/bug`, `type/feature`, `type/docs`, `type/question`, `area/cli`, `area/http`, `area/auth`, `area/keyring`, `S1`–`S4`, `needs-repro`, `needs-info`, `needs-discussion`, `duplicate`, `wontfix`, `upstream`. Milestones: `v0.6.0` (open), `Backlog`. `CODEOWNERS` maps `internal/httpx/` → @carol. `SECURITY.md` present (private advisory flow).

## Step 1 — Type classification

"X is broken vs. expected behavior" → **`type/bug`**. Not a question (it's not "how do I…"), not a feature, not docs. Single issue, not several rolled into one. Not security (no secret/auth/crypto angle in the report). → one bucket: `bug`.

## Step 2 — actionability gate

The report has **no reproduction**: no `dws` version, no OS, no target URL, no steps, no logs. Can't reproduce, can't classify severity, can't even confirm it's a bug vs. a slow endpoint. → disposition **`needs-repro`**.

> Not `out-of-scope` (fetch hanging would be a real bug), not `duplicate` (searched open + closed issues for "hang" / "fetch timeout" — nothing matching), not `needs-discussion` (no design question).

**Rationale (to post):** *"Can't reproduce or size this without a repro — need `dws --version`, OS, the URL/endpoint, exact command, and ideally `--verbose` output. Labeled `needs-repro`; will pick it up once that lands."*

## Step 3 — area / component labeling

Deferred — until there's a repro, "fetch hangs" *could* be `area/http` (the request itself), `area/auth` (token refresh stalling), or `area/keyring` (a blocking keyring read on rotation). Don't guess a single area on no evidence. No area label yet.

## Step 4 — severity (bugs only) + priority hint

Deferred — severity needs the repro (is it every fetch, or one flaky endpoint? is there a workaround?). No `S*` label yet. (If the eventual repro shows "every `dws fetch` hangs on a clean install with no workaround", that's `S1`; if it's "one slow corporate proxy", `S3`.)

## Step 5 — triage output (first pass)

**#155** · Type `type/bug` · disposition **`needs-repro`** · area *(deferred)* · severity *(deferred)* · labels to add: `type/bug`, `needs-repro` · milestone: none yet · owner: none yet

**Templated comment to post** (the repo's `needs-repro` template, filled in):

```markdown
Thanks for the report! To dig into this I need a reproduction:

- [ ] `dws --version`
- [ ] OS + version
- [ ] The exact command you ran (and the target URL/endpoint, redacted if sensitive)
- [ ] What you expected vs. what happened (it hangs — for how long? does Ctrl-C work?)
- [ ] Output of the command with `--verbose`

Marked `needs-repro` for now — drop the above in a comment and I'll pick it back up. If we don't hear back in ~2 weeks (per our stale policy) this'll be closed, but it's easy to reopen.
```

**Apply** (write access + user confirmed):
```bash
gh issue edit 155 --add-label "type/bug,needs-repro"
gh issue comment 155 --body-file needs-repro-155.md
```
(No `gh issue close` — `needs-repro` stays open.)

**Next:** waiting on @bob; on response, re-triage for area + severity + milestone.

## Step 6 — handoff

Not `accepted` yet → not `fixes #N`-eligible for `changelog-bot`, not a DoR plus for `pr-review` yet. Re-enters this skill when the reporter responds.

---

## Second pass — @bob replies with a repro

> "`dws 0.4.0` on macOS 14. `dws fetch https://internal.example.com/big.json` — hangs ~indefinitely, Ctrl-C works. `--verbose` shows it gets a `503`, then sleeps and retries… forever. No `--retry` flag passed. Happens every time on that endpoint; a plain `curl` of the same URL returns the 503 immediately."

Re-run, deltas only:

- **Step 1** — still `type/bug`.
- **Step 2** — now reproducible and in scope → **`accepted`**. (Root cause is now visible from the report: the retry-on-5xx path has no cap when `--retry` is unset — it shouldn't retry *at all* with `--retry 0`. Note: this overlaps the `--retry` work in the `changelog-bot` demo's PR #142 — link them.)
- **Step 3** — area is now clear: **`area/http`** (the retry loop in `internal/httpx/`). CODEOWNERS → owner **@carol**.
- **Step 4** — severity: a core command hangs with no workaround other than "don't fetch that URL", but it's scoped to endpoints returning 5xx (not *every* fetch). Not data loss, not security, not crash-on-startup. → **`S2`** (not `S1`: there *is* a narrow workaround and it doesn't affect most users; rationale records why it's not `S1`). Milestone: `v0.6.0` (S2 + an owner + related work already in flight).
- **Step 1 security re-check** — still no security angle. (If the verbose output had shown a token in the logs, that's the Step 1 → `SECURITY.md` path — but it didn't.)

**#155** · `type/bug` · **`accepted`** · `area/http` · **`S2`** · labels: `type/bug`, `area/http`, `S2` (remove `needs-repro`) · milestone `v0.6.0` · owner @carol

**Rationale (to post):** *"Reproduced on `dws 0.4.0` / macOS: `dws fetch` against a 5xx endpoint loops the retry path forever even with `--retry` unset — it should be a single attempt at `--retry 0`. Accepted, `area/http`, `S2` (narrow workaround = avoid that endpoint; not `S1`). Milestone `v0.6.0`, owner @carol. Likely the same area as #142's `--retry` work — cross-linking."*

```bash
gh issue edit 155 --add-label "area/http,S2" --remove-label "needs-repro" --milestone "v0.6.0"
gh issue comment 155 --body "Reproduced … (rationale above) … cross-linking #142."
# @carol assigned via CODEOWNERS suggestion; maintainer confirms the assignment.
```

**Handoff:** #155 is now `accepted` → a PR may carry `fixes #155`; `changelog-bot` will then produce a `### Fixed` entry referencing it; `pr-review` Step 1 will count the linked-triaged-issue as a DoR plus; at release, #155's closure + the `v0.6.0` milestone feed `release-sop` Step 8 DOD.

---

## Batch mode — triaging three more `untriaged` issues

`gh issue list --search "no:label" --json number,title,author` → #156, #157, #158. One pass each, table out:

| # | title | type | disposition | area | sev | action |
|---|---|---|---|---|---|---|
| #156 | "Add a `--retry` flag to `dws fetch`" | `feature` | `duplicate` | `area/http` | — | `Duplicate of #119`; close with `gh issue close 156 --reason "not planned" --comment "Duplicate of #119 — that's the tracking issue for retry support; subscribe there."` |
| #157 | "Can `dws` read config from env vars?" | `question` | (route) | — | — | not a bug → `gh issue edit 157 --add-label type/question`; comment pointing to the Discussions tab + the config docs; close per the repo's "questions go to Discussions" policy |
| #158 | "Support pushing to Bitbucket" | `feature` | `out-of-scope` | — | — | repo's README says GitHub/GitLab/Gitea only → `gh issue close 158 --reason "not planned" --comment "Out of scope — git-skill targets GitHub/GitLab/Gitea (see README 'Why this exists'); Bitbucket support would be a fork's call. Thanks though!"` |

**Batch summary:** 1 dup closed, 1 question routed + closed, 1 out-of-scope closed; no `accepted` ones in this batch (so nothing new for `changelog-bot`/`pr-review` from #156–158). #155 from the earlier pass remains the one `accepted` item, on `v0.6.0`.

---

> **What this demo is *not*:** a substitute for the contract in [`skills/issue-triage/SKILL.md`](../skills/issue-triage/SKILL.md) — it's one trace through it. A **security report filed as a public issue** would stop at Step 1: no detail-chasing in the public thread, redirect to `SECURITY.md`'s private advisory flow, leave only a "moved to private handling" note (and edit out anything sensitive) — `issue-triage` never sizes or labels an exploit in the open. And a report titled `🔥🔥 P0 CRITICAL 🔥🔥` that turns out to be a cosmetic glitch gets `S4` with the rationale explaining *why it isn't `S1`* — the rubric decides, not the title.
