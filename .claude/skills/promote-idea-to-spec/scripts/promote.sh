#!/usr/bin/env bash
# Usage: promote.sh <docs/idea/idea-NN-title.md>
# Creates docs/spec/spec-MM-<title>.md scaffold with Obsidian frontmatter.
# `sources` is initialized as a list with the given idea; merge additional
# ideas later with merge.sh.

set -euo pipefail

IDEA="${1:-}"
if [[ -z "$IDEA" || ! -f "$IDEA" ]]; then
  echo "usage: $0 <docs/idea/idea-NN-title.md>" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/docs/spec"
mkdir -p "$SPEC_DIR"

BASE="$(basename "$IDEA" .md)"
TITLE_SLUG="$(echo "$BASE" | sed -E 's/^idea-[0-9]+-//')"

LAST=0
shopt -s nullglob
for f in "$SPEC_DIR"/spec-*.md; do
  n=$(basename "$f" | sed -E 's/^spec-([0-9]+)-.*/\1/')
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%02d" $((LAST + 1)))

OUT="$SPEC_DIR/spec-$NN-$TITLE_SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 2; }

TODAY=$(date +%Y-%m-%d)
TITLE=$(echo "$TITLE_SLUG" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

cat > "$OUT" <<EOF
---
id: spec-$NN
title: $TITLE
type: spec
status: draft
created: $TODAY
updated: $TODAY
sources:
  - "[[$BASE]]"
owns: $TITLE_SLUG
tags: [spec]
aliases: []
---

# $TITLE

## Goal

(원본: \`$IDEA\`)

## Non-goals

-

## Design

## Open Questions

- [ ]
EOF

echo "$OUT"
