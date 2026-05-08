# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
