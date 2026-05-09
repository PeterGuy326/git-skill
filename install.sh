#!/usr/bin/env bash
# Install one or more skills from this repo into Claude Code's skills directory.
#
# Usage:
#   ./install.sh <skill>              install one skill, user scope (~/.claude/skills/<skill>/)
#   ./install.sh <skill> --project    install one skill, project scope (./.claude/skills/<skill>/)
#   ./install.sh --all                install every skill, user scope
#   ./install.sh --all --project      install every skill, project scope
#   ./install.sh --list               list available skills and exit
#
# Each skill lives at skills/<skill>/SKILL.md. The installer copies that single
# file into <target>/<skill>/SKILL.md.

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"

list_skills() {
  if [ ! -d "$SKILLS_DIR" ]; then
    echo "error: skills/ directory not found in $SCRIPT_DIR" >&2
    exit 1
  fi
  find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -name SKILL.md \
    | sed -E "s|^$SKILLS_DIR/||; s|/SKILL.md$||" \
    | sort
}

install_one() {
  local skill="$1"
  local scope="$2" # user | project
  local source="$SKILLS_DIR/$skill/SKILL.md"

  if [ ! -f "$source" ]; then
    echo "error: skill '$skill' not found (expected $source)" >&2
    echo "available skills:" >&2
    list_skills | sed 's/^/  /' >&2
    return 1
  fi

  local target_dir
  case "$scope" in
    user)    target_dir="$HOME/.claude/skills/$skill" ;;
    project) target_dir="./.claude/skills/$skill" ;;
    *) echo "error: unknown scope: $scope" >&2; return 1 ;;
  esac

  mkdir -p "$target_dir"
  cp "$source" "$target_dir/SKILL.md"
  echo "✓ Installed: $target_dir/SKILL.md"
}

# --- arg parsing ---
ALL=0
PROJECT=0
SKILL=""

while [ $# -gt 0 ]; do
  case "$1" in
    --all)     ALL=1 ;;
    --project) PROJECT=1 ;;
    --list)    list_skills; exit 0 ;;
    -h|--help) sed -n '2,15p' "$0" | sed 's/^# \?//'; exit 0 ;;
    --*)       echo "error: unknown flag: $1" >&2; exit 1 ;;
    *)         if [ -n "$SKILL" ]; then
                 echo "error: too many positional args (got '$SKILL' and '$1')" >&2; exit 1
               fi
               SKILL="$1" ;;
  esac
  shift
done

SCOPE=user
[ "$PROJECT" -eq 1 ] && SCOPE=project

if [ "$ALL" -eq 1 ]; then
  if [ -n "$SKILL" ]; then
    echo "error: --all is mutually exclusive with a skill name" >&2; exit 1
  fi
  count=0
  while IFS= read -r s; do
    install_one "$s" "$SCOPE"
    count=$((count + 1))
  done < <(list_skills)
  echo ""
  echo "✓ Installed $count skill(s) into $SCOPE scope."
elif [ -n "$SKILL" ]; then
  install_one "$SKILL" "$SCOPE"
else
  echo "usage: $0 <skill> | --all | --list  [--project]" >&2
  echo "" >&2
  echo "available skills:" >&2
  list_skills | sed 's/^/  /' >&2
  exit 1
fi

echo ""
echo "Next: restart Claude Code (or open a new session)."
