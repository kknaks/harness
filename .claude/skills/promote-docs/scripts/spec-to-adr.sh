#!/usr/bin/env bash
# Usage: spec-to-adr.sh <docs/spec/spec-NN-title.md> [slug]
# Creates docs/adr/adr-NNNN-<slug>.md scaffold with ADR frontmatter.
# `sources` is initialized as a list with the given spec; merge additional
# specs later if needed (extend merge.sh or hand-edit).
#
# Optional <slug>:
#   - kebab-case override for output filename.
#   - Use when one spec produces multiple ADRs (1 spec -> N adrs)
#     to avoid filename collisions.
#   - If omitted, slug is derived from the spec filename.

set -euo pipefail

SPEC="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$SPEC" || ! -f "$SPEC" ]]; then
  echo "usage: $0 <docs/spec/spec-NN-title.md> [slug]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
ADR_DIR="$REPO_ROOT/docs/adr"
mkdir -p "$ADR_DIR"

BASE="$(basename "$SPEC" .md)"
if [[ -n "$SLUG_OVERRIDE" ]]; then
  if [[ ! "$SLUG_OVERRIDE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "slug must be kebab-case (lowercase a-z, 0-9, '-'): '$SLUG_OVERRIDE'" >&2
    exit 4
  fi
  TITLE_SLUG="$SLUG_OVERRIDE"
else
  TITLE_SLUG="$(echo "$BASE" | sed -E 's/^spec-[0-9]+-//')"
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

(승격 원본: \`$SPEC\` — 결정 배경·동기·제약)

## Decision

(atomic 결정 1~2문장 + 구체 §부속 결정)

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| | |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| | | | |

## Consequences

**Pros**
-

**Cons**
-

**Follow-ups**
- [ ]

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 spec 추가 등)_
EOF

echo "$OUT"
