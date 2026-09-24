#!/usr/bin/env bash
# Vendor selected skills from cockroachlabs/cockroachdb-skills into ./skills/.
# Kiro installs powers straight from the repo (no submodule fetch), so skills
# must be committed as real files. Re-run this to pull upstream updates.
#
# Usage:
#   scripts/sync-skills.sh                      # sync from main
#   UPSTREAM_REF=<tag-or-branch> scripts/sync-skills.sh
set -euo pipefail

UPSTREAM_REPO="${UPSTREAM_REPO:-https://github.com/cockroachlabs/cockroachdb-skills.git}"
UPSTREAM_REF="${UPSTREAM_REF:-main}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$ROOT/skills.manifest"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Cloning $UPSTREAM_REPO@$UPSTREAM_REF ..."
git clone --quiet --depth 1 --branch "$UPSTREAM_REF" "$UPSTREAM_REPO" "$TMP/upstream"
SHA="$(git -C "$TMP/upstream" rev-parse HEAD)"

mkdir -p "$ROOT/skills"
count=0
while IFS= read -r line || [ -n "$line" ]; do
  line="${line%%#*}"
  line="$(printf '%s' "$line" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"
  [ -z "$line" ] && continue

  src="$TMP/upstream/skills/$line"
  name="$(basename "$line")"

  if [ ! -f "$src/SKILL.md" ]; then
    echo "ERROR: $line has no SKILL.md upstream" >&2
    exit 1
  fi

  rm -rf "$ROOT/skills/$name"
  cp -R "$src" "$ROOT/skills/$name"
  echo "  synced $name"
  count=$((count + 1))
done < "$MANIFEST"

printf '%s\n' "$SHA" > "$ROOT/skills/.upstream-sha"
echo "Done: $count skills synced from $SHA"
echo "Review with 'git status' / 'git diff', then commit."
