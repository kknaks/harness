#!/usr/bin/env bash
# Usage: idea-to-spec.sh <docs/idea/idea-NN-title.md> [slug]
# Creates docs/spec/spec-MM-<slug>.md scaffold with Obsidian frontmatter
# and the 6-section spec body (+ 2 optional sections).
# `sources` is initialized as a list with the given idea; merge additional
# ideas later with merge.sh.
#
# Optional <slug>:
#   - kebab-case override for output filename + `owns` field.
#   - Use when one idea splits into multiple specs (1 idea -> N specs)
#     to avoid filename collisions.
#   - If omitted, slug is derived from the idea filename.

set -euo pipefail

IDEA="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$IDEA" || ! -f "$IDEA" ]]; then
  echo "usage: $0 <docs/idea/idea-NN-title.md> [slug]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SPEC_DIR="$REPO_ROOT/docs/spec"
mkdir -p "$SPEC_DIR"

BASE="$(basename "$IDEA" .md)"
if [[ -n "$SLUG_OVERRIDE" ]]; then
  # validate kebab-case
  if [[ ! "$SLUG_OVERRIDE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "slug must be kebab-case (lowercase a-z, 0-9, '-'): '$SLUG_OVERRIDE'" >&2
    exit 4
  fi
  TITLE_SLUG="$SLUG_OVERRIDE"
else
  TITLE_SLUG="$(echo "$BASE" | sed -E 's/^idea-[0-9]+-//')"
fi

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

## Scope

(이 spec 이 다루는 범위 1~2문장. 머지 판단 기준 — _map.md 에 노출됨)

## Summary

(1~2문장 TL;DR)

## Background

(원본: \`$IDEA\` — 핵심 발췌 / 동기)

## Goals

-

## Non-goals

-

## Design

## Open Questions

- [ ]

<!-- 아래는 선택 섹션. 해당 시 주석 해제하고 작성, 아니면 삭제. -->

<!--
## Interface

(CLI / API / 파일 포맷 등 사용자가 마주하는 표면)
-->

<!--
## Alternatives Considered

- 대안 A — 채택 안 한 이유
- 대안 B — 채택 안 한 이유
-->
EOF

echo "$OUT"
