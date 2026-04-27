#!/usr/bin/env bash
# Usage: new-idea.sh "<human readable title>"
# Creates docs/idea/idea-NN-<slug>.md with required frontmatter (id, type).
# Adds template fields (created, tags) and empty sections for relationships.

set -euo pipefail

TITLE="${1:-}"
[[ -n "$TITLE" ]] || { echo "usage: $0 \"<title>\"" >&2; exit 1; }

REPO_ROOT="$(git rev-parse --show-toplevel)"
DIR="$REPO_ROOT/docs/idea"
mkdir -p "$DIR"

SLUG=$(echo "$TITLE" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/[^a-z0-9 -]+//g; s/[ ]+/-/g; s/-+/-/g; s/^-|-$//g')
[[ -n "$SLUG" ]] || { echo "title produced empty slug" >&2; exit 2; }

LAST=0
shopt -s nullglob
for f in "$DIR"/idea-*.md; do
  n=$(basename "$f" | sed -E 's/^idea-([0-9]+)-.*/\1/')
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%02d" $((LAST + 1)))

OUT="$DIR/idea-$NN-$SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 3; }

TODAY=$(date +%Y-%m-%d)

cat > "$OUT" <<EOF
---
id: idea-$NN
type: idea
created: $TODAY
tags: [idea]
---

# $TITLE

EOF

echo "$OUT"
