#!/usr/bin/env bash
# Usage: sources-to-wiki.sh <content/sources/sources-NN-<slug>.md> [slug]
# Creates content/wiki/wiki-MM-<slug>.md scaffold. `sources` frontmatter
# starts with the given source; add more later (multiple sources can be
# merged into one wiki node — extend by hand or via a future merge script).
#
# Wiki = LLM 합성 + 인간 검토. 이 스크립트는 scaffold 만 — 실제 합성은
# Claude 가 sources 본문을 읽고 본문에 채운다.
#
# Optional <slug>:
#   - kebab-case override for output filename.
#   - If omitted, slug is derived from the sources filename.

set -euo pipefail

SOURCE="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$SOURCE" || ! -f "$SOURCE" ]]; then
  echo "usage: $0 <content/sources/sources-NN-<slug>.md> [slug]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
WIKI_DIR="$REPO_ROOT/content/wiki"
mkdir -p "$WIKI_DIR"

BASE="$(basename "$SOURCE" .md)"
if [[ -n "$SLUG_OVERRIDE" ]]; then
  if [[ ! "$SLUG_OVERRIDE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "slug must be kebab-case (lowercase a-z, 0-9, '-'): '$SLUG_OVERRIDE'" >&2
    exit 4
  fi
  TITLE_SLUG="$SLUG_OVERRIDE"
else
  TITLE_SLUG="$(echo "$BASE" | sed -E 's/^sources-[0-9]+-//')"
fi

LAST=0
shopt -s nullglob
for f in "$WIKI_DIR"/wiki-*.md; do
  n=$(basename "$f" | sed -E 's/^wiki-([0-9]+)-.*/\1/')
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%02d" $((LAST + 1)))

OUT="$WIKI_DIR/wiki-$NN-$TITLE_SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 2; }

TITLE=$(echo "$TITLE_SLUG" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

cat > "$OUT" <<EOF
---
id: wiki-$NN
title: $TITLE
type: wiki
sources:
  - "[[$BASE]]"
tags: [wiki]
aliases: []
---

# $TITLE

> 합성·정리. 비슷한·연관된 sources 를 묶어 다듬은 지식 노드. LLM 이 합성, **인간이 검토**.

## Summary

(이 wiki 노드가 정리한 주제 1~2문장)

## Synthesis

(여러 sources 의 핵심을 하나의 일관된 서사로 묶기)

## References

- \`$BASE\`
EOF

echo "$OUT"
