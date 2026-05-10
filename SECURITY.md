# Security Policy

## Supported versions

This repo ships fast-moving single-file skills; only the **latest release** is supported. If you're on an older tag, upgrade (the install one-liners in the README track `main`) before reporting — the issue may already be fixed.

| Version | Supported |
|---|---|
| Latest release | ✅ |
| Older releases | ❌ (upgrade first) |

## What counts as a security issue here

This is a docs/skill repo — there's no service and no compiled binary. The security-relevant surface is:

- A **SKILL.md** whose instructions could be steered to do something harmful, leak data, or bypass a safety gate when an agent follows them (e.g. a gate that's trivially skippable, a runbook step that exfiltrates a secret, an instruction that disables a protection).
- **`install.sh`** or any tooling that touches the user's filesystem in an unexpected place.
- A **supply-chain** concern with how the skills are distributed (the `raw.githubusercontent.com` one-liners, the install path).

Plain bugs ("a gate's wording is confusing", "a step is wrong") are *not* security issues — open a normal issue (it'll be triaged per the `issue-triage` flow).

## Reporting a vulnerability — do not open a public issue

Use **GitHub's private vulnerability reporting**: the repo's **Security** tab → **Report a vulnerability** (this opens a private advisory only the maintainer sees). If that's unavailable to you, contact the maintainer privately via their GitHub profile.

Please include: the affected SKILL.md / file + line, what an agent could be made to do, a minimal reproduction (the prompt / sequence), and the impact. **Don't** post details, PoCs, or "I think X is exploitable" in a public issue, PR, or discussion — that's the one thing this policy exists to prevent.

## What to expect

- **Acknowledgement** within a few days.
- A **fix or a written decision** (with rationale) once the report is understood; a security fix that can't wait for the normal release train goes through the `hotfix-flow` procedure (cherry-pick off the release tag → patch release → forward-merge back to `main`).
- **Coordinated disclosure**: details stay private until a fixed release is out; the release notes then carry an advisory naming the affected versions (and a CVE/GHSA reference if one was assigned).
- **Credit** in the advisory, if you want it.

## How this ties into the skills

`issue-triage` routes anything that looks like a vulnerability here instead of triaging it in the open; `pr-review` Step 6 flags PRs that touch the security-relevant surface above and requires this flow rather than a reviewer self-clearing; `hotfix-flow` runs security fixes through this policy end to end (private until release, advisory in the notes, Step 6 judgement not skipped).
