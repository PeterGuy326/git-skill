#!/usr/bin/env bash
# Install release-sop skill into the current user's Claude Code skills dir.
# Usage:
#   ./install.sh                # install to ~/.claude/skills/release-sop/
#   ./install.sh --project      # install to ./.claude/skills/release-sop/

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/SKILL.md"

if [ ! -f "$SOURCE" ]; then
  echo "error: SKILL.md not found in $SCRIPT_DIR" >&2
  exit 1
fi

if [ "${1-}" = "--project" ]; then
  TARGET_DIR="./.claude/skills/release-sop"
else
  TARGET_DIR="$HOME/.claude/skills/release-sop"
fi

mkdir -p "$TARGET_DIR"
cp "$SOURCE" "$TARGET_DIR/SKILL.md"

echo "✓ Installed: $TARGET_DIR/SKILL.md"
echo ""
echo "Next: restart Claude Code (or open a new session)."
echo "Trigger: /release-sop  or  帮我发版 vX.Y.Z"
