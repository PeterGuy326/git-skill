# Worked example — `pr-review` walking a real-ish PR

> A demo transcript of the [`pr-review`](../skills/pr-review/SKILL.md) skill running its 8 steps on a hypothetical PR **#128 — "feat(http): add `--retry N` flag to `dws fetch`"** (a `dingtalk-workspace-cli`-style Go repo). It shows the gates that *don't* pass, the line-level comments, and the final verdict — then a second pass after the author pushes fixes. Substitute `gh` with `glab` / `tea` for GitLab / Gitea; the contract is the same.
>
> **Bottom line of this run:** `🔁 REQUEST_CHANGES` — the feature is the right shape and CI is green, but it ships with two correctness blockers, a missing regression test, a missing CHANGELOG entry, and stale `--help` docs. After the author's follow-up commit (end of file) it flips to `✅ APPROVE`.

---

## Step 0 — PR context load

```
$ gh pr view 128 --json title,body,baseRefName,headRefName,additions,deletions,changedFiles,labels,state
$ gh pr diff 128
$ gh pr checks 128
```

| | |
|---|---|
| PR | #128 — `feat(http): add --retry N flag to dws fetch` |
| Author | @alice |
| Branch | `feat/fetch-retry` → `main` |
| Diff | +84 / −6, 3 files (`cmd/fetch.go`, `internal/httpx/client.go`, `internal/httpx/client_test.go`) |
| CI | ✅ green (lint, unit, race, build) |
| Linked issue | `closes #119` ("`dws fetch` should retry on transient 5xx") |
| Labels | `enhancement` |

→ confirmed with requester: this is the PR to review.

## Step 1 — DoR meta check

- [x] Title follows `type(scope): summary`
- [x] Description has What/Why ("adds `--retry N`, default `0` = current behavior; retries on 5xx / conn-reset with backoff")
- [x] Linked issue `closes #119`
- [x] Target branch `main` — correct
- [x] Size +84 / −6, 3 files — reviewable
- [x] Commit history: 2 commits, clean; author says will squash

→ **DoR: PASS.**

## Step 2 — change classification + interface/behavior impact

| Change | Class |
|---|---|
| New `--retry N` flag on `dws fetch` | **interface change** (new CLI flag) |
| Retry loop in `httpx.Client.Do` behind a count param | behavior change (only when `--retry > 0`) |
| Default `--retry 0` | — preserves current behavior |

- [x] Breaking? **No** — additive; default preserves old behavior → no `Breaking` CHANGELOG section needed.
- [ ] **Docs synced? ❌** — `dws fetch --help` / man not updated to mention `--retry`; README command table not updated. → **unmet**
- [x] Backward-compat path: yes, opt-in flag.

→ **Step 2: 1 unmet item (docs).**

## Step 3 — line-level code review

| `file:line` | severity | issue | suggestion |
|---|---|---|---|
| `internal/httpx/client.go:71` | `[blocking]` | retry loop doesn't reset `req.Body` between attempts — a retried POST sends an **empty body** on attempt 2+ | re-create the body reader each iteration (or require `GetBody`); add a test for a retried POST |
| `internal/httpx/client.go:78` | `[blocking]` | backoff is `time.Sleep(time.Second * attempt)` — no cap, no jitter, ignores `ctx` → long stalls and synchronized retries across callers; can't be cancelled | cap (~30s), add ±20% jitter, select on `ctx.Done()` during the sleep |
| `internal/httpx/client.go:64` | `[nit]` | `for i := 0; i <= retry; i++` — the `<=` is correct (1 initial + N retries) but trips up the next reader | add `// 1 initial attempt + retry retries` |
| `cmd/fetch.go:33` | `[nit]` | `--retry` has no upper bound; `--retry 1000000` is accepted | clamp (e.g. 10) or document a sane max |

→ **Step 3: 2 `[blocking]` + 2 `[nit]`.**

## Step 4 — test-coverage gate

- [x] New test added same-PR: "retries twice, then succeeds on 200"
- [ ] **Regression test for the failure mode ❌** — nothing covers "retries exhausted → returns last error, no panic, no hang"; nothing covers the retried-POST-body case (ties to the `[blocking]` above) → **unmet**
- [x] Existing tests still run; none skipped / `xfail`'d
- [x] CI green (`gh pr checks 128` → all ✅)
- [x] Coverage +1.2% (no drop)

→ **Step 4: CI green; 1 unmet item (missing regression test).** Not a `⛔ BLOCK` — there *is* a test and CI is green; this contributes to `REQUEST_CHANGES`.

## Step 5 — CHANGELOG-entry gate

- [ ] **`CHANGELOG.md` not touched in this diff ❌.** This is a behavior + interface change → it needs an entry. Not exempt (not pure-refactor / pure-CI / pure-docs / pure-test). → **unmet**

Expected entry (format only — drafting the wording is [`changelog-bot`](../README.md#skills)'s job, not the reviewer's):

```markdown
### Added
- **`dws fetch` now supports `--retry N`** (#128, closes #119) — opt-in retry on transient 5xx / connection-reset with capped jittered backoff; default `--retry 0` keeps current single-attempt behavior.
```

→ **Step 5: 1 unmet item (no CHANGELOG entry).**

## Step 6 — security-review trigger judgement

Checked against the trigger list, item by item:

- auth / session / token / password hash / OAuth — **no**
- crypto / signature verify / RNG / cert verify — **no**
- parser / deserialization / template / SQL / shell / path / URL build — **no** (adds a loop count + a sleep)
- permission model / ACL / multi-tenant / CORS / CSP / SSRF — **borderline**: retry-on-5xx mildly amplifies an SSRF-to-internal-endpoint *if* the URL is attacker-influenced — but `dws fetch` already takes a user-supplied URL with no SSRF guard either way; this PR doesn't change the threat surface
- dependency add / bump (incl. transitive) — **no** (lockfile unchanged)
- CI/CD secrets / `pull_request_target` / `workflow_run` / unpinned action / self-hosted runner — **no**
- new network endpoint / upload / external callback / reflected user data — **no**

→ **No security-review trigger.** (Recorded: retry amplifies any *pre-existing* SSRF in `dws fetch` — out of scope for this PR; file a separate hardening issue if `dws fetch` ever needs SSRF protection.)

## Step 7 — verdict report

**PR #128 — `feat(http): add --retry N flag to dws fetch`** · `feat/fetch-retry` → `main` · +84 / −6, 3 files

Change classification: 1 interface change (new flag), 1 behavior change (retry loop, opt-in), no breaking.

| Gate | Result |
|---|---|
| Step 1 — DoR meta | ✅ pass |
| Step 2 — interface impact | ⚠️ docs not updated |
| Step 3 — code review | ❌ 2 `[blocking]` |
| Step 4 — test coverage | ⚠️ CI green, but missing regression test |
| Step 5 — CHANGELOG entry | ❌ missing |
| Step 6 — security trigger | ✅ no hit (SSRF note recorded) |

**Unmet items — how to fix:**
1. `[blocking]` reset `req.Body` between retry attempts; add a test for a retried POST. — `internal/httpx/client.go:71`
2. `[blocking]` cap backoff (~30s) + add jitter + honor `ctx` during the sleep. — `internal/httpx/client.go:78`
3. Add regression test: retries exhausted → returns last error, no panic, no hang.
4. Add the CHANGELOG `### Added` entry (format shown in Step 5).
5. Update `dws fetch --help` text and the README command table to mention `--retry`.
6. `[nit]` add the `// 1 initial + retry` comment; `[nit]` clamp / document `--retry` max.

Security: no review trigger; recorded that retry amplifies any pre-existing SSRF in `dws fetch` — track separately, not a blocker here.

**结论：🔁 REQUEST_CHANGES** — right shape, CI green, but two correctness blockers (POST body, unbounded backoff), a missing regression test, a missing CHANGELOG entry, and stale `--help` docs must land before merge.

---

## Second pass — after @alice pushes the follow-up commit

@alice pushes one commit: bodies re-created per attempt + `TestRetry_POSTBodyResent`; backoff capped at 30s with ±20% jitter and a `ctx`-aware sleep + `TestRetry_Exhausted_ReturnsLastError`; CHANGELOG `### Added` entry; `--help` + README updated; `--retry` clamped to 10 with a doc note.

Re-run — deltas only:

- **Step 2** docs → ✅ now updated (`--help` + README table)
- **Step 3** → both `[blocking]` resolved; both `[nit]`s addressed
- **Step 4** → `TestRetry_POSTBodyResent` + `TestRetry_Exhausted_ReturnsLastError` present; CI still ✅ green; coverage +1.9%
- **Step 5** → CHANGELOG entry present, Keep-a-Changelog format OK, has `#128` + `closes #119`
- **Steps 1 & 6** → unchanged (still pass; still no security trigger)

**结论：✅ APPROVE** — all gates pass, no `[blocking]` left, CI green, no security trigger. Squash-merge.

---

> **What this demo is *not*:** a substitute for the contract in [`skills/pr-review/SKILL.md`](../skills/pr-review/SKILL.md) — it's one trace through it. A PR whose code actually hits a Step 6 trigger (e.g. touching token handling) stops at `🔒 SECURITY REVIEW REQUIRED` and never reaches `APPROVE`, however clean the rest is. A red-CI or zero-test feature PR is a `⛔ BLOCK` at Step 4, not a `REQUEST_CHANGES`.
>
> For contrast: running `pr-review` on **this repo's own PR #1** (the one that *adds* `pr-review`) is a near-trivial `✅ APPROVE` — docs-only single-file skill, so Step 3 has nothing executable to break, Step 4's "no tests" is fine (no code; CI is docs-only), Step 5's CHANGELOG entry is present, Step 6 has no trigger. The interesting gates only bite on code PRs. Dogfooding closed-loop, same as `release-sop`.
