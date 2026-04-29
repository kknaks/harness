#!/usr/bin/env bash
# Usage: wiki-to-adr.sh <content/wiki/wiki-NN-<slug>.md> [slug]
# Creates content/adr/adr-NNNN-<slug>.md scaffold (4-digit, ADR standard body).
# Distinct from spec-to-adr.sh which targets docs/adr/ (meta layer).
# Content ADR counter is independent from meta ADR counter.
#
# Optional <slug>:
#   - kebab-case override for output filename.
#   - If omitted, slug is derived from the wiki filename.

set -euo pipefail

WIKI="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$WIKI" || ! -f "$WIKI" ]]; then
  echo "usage: $0 <content/wiki/wiki-NN-<slug>.md> [slug]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
ADR_DIR="$REPO_ROOT/content/adr"
mkdir -p "$ADR_DIR"

BASE="$(basename "$WIKI" .md)"
if [[ -n "$SLUG_OVERRIDE" ]]; then
  if [[ ! "$SLUG_OVERRIDE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "slug must be kebab-case (lowercase a-z, 0-9, '-'): '$SLUG_OVERRIDE'" >&2
    exit 4
  fi
  TITLE_SLUG="$SLUG_OVERRIDE"
else
  TITLE_SLUG="$(echo "$BASE" | sed -E 's/^wiki-[0-9]+-//')"
fi

LAST=0
shopt -s nullglob
for f in "$ADR_DIR"/adr-*.md; do
  n=$(basename "$f" | sed -E 's/^adr-([0-9]+)-.*/\1/')
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%04d" $((LAST + 1)))

OUT="$ADR_DIR/adr-$NN-$TITLE_SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 2; }

TODAY=$(date +%Y-%m-%d)
TITLE=$(echo "$TITLE_SLUG" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

cat > "$OUT" <<EOF
---
id: adr-$NN
title: $TITLE
type: adr
status: proposed
date: $TODAY
sources:
  - "[[$BASE]]"
tags: [adr]
aliases: []
---

# $TITLE

## Context

(승격 원본: \`$WIKI\` — 합성된 지식에서 추출한 결정 배경)

## Decision

## Consequences

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_
EOF

echo "$OUT"
