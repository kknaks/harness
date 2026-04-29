#!/usr/bin/env bash
# Usage: inbox-to-sources.sh <content/inbox/<file>> [slug]
# Creates content/sources/sources-NN-<slug>.md by *identifying* a raw inbox
# asset (giving it a name + purpose) and freezing it as immutable source.
# `sources` frontmatter field points back to the inbox file (lineage).
#
# Inbox files may be raw (no frontmatter). This script does NOT copy body —
# it creates a fresh scaffold; the maintainer hand-fills the identification.
#
# Optional <slug>:
#   - kebab-case override for output filename.
#   - If omitted, slug is derived from the inbox filename (extension stripped,
#     non-alnum -> '-').

set -euo pipefail

INBOX="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$INBOX" || ! -f "$INBOX" ]]; then
  echo "usage: $0 <content/inbox/<file>> [slug]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SOURCES_DIR="$REPO_ROOT/content/sources"
mkdir -p "$SOURCES_DIR"

BASE="$(basename "$INBOX")"
BASE_NOEXT="${BASE%.*}"
if [[ -n "$SLUG_OVERRIDE" ]]; then
  if [[ ! "$SLUG_OVERRIDE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "slug must be kebab-case (lowercase a-z, 0-9, '-'): '$SLUG_OVERRIDE'" >&2
    exit 4
  fi
  TITLE_SLUG="$SLUG_OVERRIDE"
else
  TITLE_SLUG="$(echo "$BASE_NOEXT" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  [[ -z "$TITLE_SLUG" ]] && { echo "could not derive slug from '$BASE'; pass [slug]" >&2; exit 4; }
fi

LAST=0
shopt -s nullglob
for f in "$SOURCES_DIR"/sources-*.md; do
  n=$(basename "$f" | sed -E 's/^sources-([0-9]+)-.*/\1/')
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%02d" $((LAST + 1)))

OUT="$SOURCES_DIR/sources-$NN-$TITLE_SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 2; }

# inbox lineage: relative path from repo root
INBOX_REL="${INBOX#$REPO_ROOT/}"
INBOX_REF="$(basename "$INBOX")"

TITLE=$(echo "$TITLE_SLUG" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

cat > "$OUT" <<EOF
---
id: sources-$NN
title: $TITLE
type: sources
sources:
  - "[[$INBOX_REF]]"
tags: [sources]
aliases: []
---

# $TITLE

> 1차 가공 = 원본 박제. 이후 불변. 원본의 정체(이름·목적)를 명확히 한 채 보존한다.

## 정체 (Identification)

**원본 파일**: \`$INBOX_REL\`

**무엇인가 (한 줄)**:

(예: "v1 시기에 작성된 unscoped SKILL.md — 명령 실행 권한 검증을 시도했던 스킬.")

**왜 보존하는가**:

(이 자산이 wiki 합성에 어떻게 기여할지)

## 본문 (raw 보존 또는 정리)

(원본을 그대로 인용하거나, 정체화에 필요한 만큼만 정리. 결정·합성·재해석은 wiki 단계에서)
EOF

echo "$OUT"
