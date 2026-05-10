# Worked example — `hotfix-flow` patching a released version

> A demo transcript of the [`hotfix-flow`](../skills/hotfix-flow/SKILL.md) skill running its 8 steps on a hypothetical S1 regression in **`dws 0.4.0`** (a `dingtalk-workspace-cli`-style repo that tags releases off `main`, no long-lived `release/*` branches). It shows the cherry-pick-only discipline and the non-negotiable forward-merge back to `main`. Substitute `gh` with `glab` / `tea` for GitLab / Gitea.
>
> **Bottom line:** issue #170 (`dws fetch` panics on a 30x redirect — regression in 0.4.0) → fix lands on `main` first via PR #171 → `hotfix/v0.4.1` branched off tag `v0.4.0` → only the fix commit cherry-picked → `[0.4.1]` CHANGELOG entry → simplified review → `v0.4.1` tagged + released (handed to `release-sop`) → **forward-merged back to `main`** → DOD closed.

---

## Step 0 — should we hotfix?

- Regression in a *released* version? **Yes** — `dws 0.4.0` shipped a redirect-following change; `dws fetch <url-that-30x-redirects>` now panics (`nil deref` in the redirect handler). `issue-triage` already filed #170 as `type/bug` · `accepted` · `area/http` · **`S1`** (core command crashes, no workaround other than "don't fetch redirecting URLs", affects anyone hitting a redirect).
- Release train too slow? `v0.5.0` is a week+ out. `S1` crash → can't wait.
- Does the fix exist? Not yet — needs writing.
- Repo conventions: `main` is protected (require PR, linear history, no force-push); tags off `main`, no `release/*` branches; `SECURITY.md` present (not a security issue here — no secret/auth angle, just a crash); no CI workflow ships, so "CI green" = the test suite passes locally / in the PR's checks if any exist.

→ **Confirmed: hotfix.** Affected released version `v0.4.0`; base = tag `v0.4.0`; fix = to be written; linked issue #170.

## Step 1 — the fix lands on `main` first

Write the fix on `main` via a normal PR (`#171 — fix(http): guard nil response in redirect handler`), through `pr-review`, with a regression test (`TestFetch_RedirectNoPanic`) and a `changelog-bot`-drafted entry in `main`'s `[Unreleased] > ### Fixed`. Merged. Fix commit on `main`: `a1b2c3d`.

> `main` is now the source of truth and won't regress. (If `main` had already moved past the bug — e.g. the redirect handler had been rewritten — Step 1 would be skipped and we'd carry a tailored equivalent commit on the hotfix branch instead.)

## Step 2 — branch the hotfix off the release point

```bash
git fetch --tags
git switch -c hotfix/v0.4.1 v0.4.0          # off the TAG, not main
```

`hotfix/v0.4.1` now == exactly the code that shipped as `v0.4.0`. Version: `S1` bug → patch bump → `v0.4.1`.

## Step 3 — cherry-pick *only* the fix

```bash
git cherry-pick a1b2c3d                      # the single commit from PR #171
# (also cherry-pick a1b2c3d's test commit if it landed separately — exactly that)
```

No conflicts (the redirect handler is unchanged since `v0.4.0`). **Nothing else is cherry-picked** — not the `--retry` work that also landed on `main` after 0.4.0, not a doc fix, not a dep bump. `git log v0.4.0..hotfix/v0.4.1` at this point: just the fix (+ its test).

> If the cherry-pick had hit a non-trivial conflict, the skill would stop here: that's not a clean hotfix — either narrow the scope or hand-write a minimal equivalent fix commit *on `hotfix/v0.4.1`* and note the divergence from `main` in the PR.

## Step 4 — CHANGELOG entry on the hotfix branch

On `hotfix/v0.4.1`, add a new dated section (the one case where an entry goes into a dated section on a non-`main` branch — because this branch *is* the `v0.4.1` release line). Drafted with `changelog-bot`:

```markdown
## [0.4.1] - 2026-05-12

### Fixed

- **`dws fetch` no longer panics on a redirecting URL** (#171, fixes #170) — the HTTP redirect handler dereferenced the response without a nil check; a `30x` to a location that failed to resolve produced a `nil` response and a panic. The handler now guards the nil case and surfaces the underlying error. Regression introduced in `v0.4.0`; affects any `dws fetch` of a URL that issues a redirect. Upgrade to `v0.4.1` or pin `v0.3.0` as a stopgap.
```

> `main`'s CHANGELOG already has this fix under `[Unreleased]` (from PR #171) — leave it; it'll land in `main`'s next dated release. Don't double-add to `main` now.

## Step 5 — review with the simplified hotfix gates

Open the hotfix PR — `hotfix/v0.4.1` → ... there's no `release/0.4` branch, so the "PR" here is a pre-tag review of `hotfix/v0.4.1` itself (a self-PR against `main` would show the wrong base diff). Run `pr-review`'s **hotfix gates only**, not the full 8 steps:

- [x] CI green (test suite passes; `TestFetch_RedirectNoPanic` is green)
- [x] Regression test present — `TestFetch_RedirectNoPanic` reproduces the panic on the pre-fix code, passes after
- [x] CHANGELOG entry present — the `[0.4.1]` section above
- [x] Target / base correct — branched off `v0.4.0`, contains only the fix
- [x] **`pr-review` Step 6 security-trigger judgement — run, not skipped:** no auth/crypto/parser/deps/CI-secrets change; the redirect handler does follow user-influenced `Location` headers, but this PR *adds* a guard, doesn't widen the surface → **no security trigger** (recorded). (A redirect-to-internal SSRF concern in `dws fetch` exists independently of this PR — track separately.)

No "fix it in a follow-up." → hotfix PR approved.

## Step 6 — tag the patch release, hand to `release-sop`

Hand to `release-sop` entering at its **Step 5** (project-detect / identity / DoR-replay / pre-flight / CHANGELOG were done by Steps 0–5 above):

```bash
git tag -a v0.4.1 -m "Hotfix v0.4.1 — fix panic on redirecting URL (#170)"
git push origin v0.4.1
gh release create v0.4.1 \
  --title "v0.4.1 — hotfix: fix panic on redirecting URL" \
  --notes-file v0.4.1-notes.md          # the [0.4.1] CHANGELOG section
```

Then `release-sop` Step 7 (post-release verify) — re-run the original repro against the `v0.4.1` build: `dws fetch <redirecting-url>` returns the underlying error instead of panicking ✓ — and Step 8 DOD. Release notes state: *fixes a panic introduced in v0.4.0; everyone on v0.4.0 should upgrade.*

## Step 7 — forward-merge `hotfix/v0.4.1` back to `main` (non-negotiable)

`hotfix/v0.4.1` has a commit `main` doesn't: the `[0.4.1]` dated CHANGELOG section. Merge it back so `main` reflects reality. `main` is protected → open a PR:

```bash
# PR: "Merge hotfix v0.4.1 back to main"  (base: main, head: hotfix/v0.4.1)
# Conflict resolution: keep main's [Unreleased] structure; ADD the
# ## [0.4.1] - 2026-05-12 section into main's CHANGELOG history (above [0.4.0]),
# since v0.4.1 is a real release between 0.4.0 and the next minor.
# The fix code itself: already on main (a1b2c3d) — git sees it as already-applied.
```

PR merged. **Until this lands, the hotfix is NOT done** — otherwise `v0.5.0` could silently re-introduce the panic (it wouldn't here, since `a1b2c3d` is already on `main`, but the principle stands, and the `[0.4.1]` changelog history would be missing).

Verify:
```bash
git branch --contains a1b2c3d            # → includes 'main' and 'hotfix/v0.4.1'  ✓
git show main:CHANGELOG.md | grep '\[0.4.1\]'   # → present  ✓
```

## Step 8 — DOD closeout

- [x] hotfix branch created off `v0.4.0` (not `main`)
- [x] only the fix (+ its test) cherry-picked — `git log v0.4.0..hotfix/v0.4.1` = fix commit + CHANGELOG commit, nothing else
- [x] regression test `TestFetch_RedirectNoPanic` present and green
- [x] `v0.4.1` tagged, pushed, GitHub Release published; notes name the affected version (`v0.4.0`) and the recommendation (upgrade)
- [x] post-release smoke passed — original repro now returns an error instead of panicking on the `v0.4.1` build
- [x] **hotfix forward-merged to `main`** — `git branch --contains a1b2c3d` shows `main`; `main`'s CHANGELOG has `[0.4.1]`
- [x] (n/a) no intermediate `release/*` branches in this repo
- [x] #170 closed (referencing `v0.4.1`); milestone updated
- [x] handed back to `release-sop` for the standard release closeout report

**Verdict: hotfix `v0.4.1` complete** — released and forward-merged.

---

> **What this demo is *not*:** a substitute for the contract in [`skills/hotfix-flow/SKILL.md`](../skills/hotfix-flow/SKILL.md) — it's one trace through it. If this had been a **security** issue (say, the redirect handler leaked the `Authorization` header to the redirect target), the whole flow would run through `SECURITY.md`: the fix and discussion stay private until `v0.4.1` ships, the release notes carry a red-letter advisory + CVE/GHSA link + a "rotate anything exposed" line, and `pr-review` Step 6's security judgement is emphatically not skipped. If someone had tried to also slip the `--retry` feature into `hotfix/v0.4.1` "while we're cutting a release anyway", the skill bounces it — cherry-pick only; the feature goes through a normal PR to `main`. And if the forward-merge in Step 7 were skipped, Step 8's `git branch --contains` check fails and the hotfix is *not* done — that omission is the single most common hotfix process leak this skill exists to close.
