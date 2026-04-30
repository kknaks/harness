#!/usr/bin/env bash
# Usage: inbox-to-idea.sh <content/inbox/file> [slug]
# Creates docs/idea/idea-NN-<slug>.md scaffold from a content/inbox/ raw asset
# that the maintainer triaged as a META POLICY (스킬 작성법, 훅 정책, MCP 추가 룰 등) —
# NOT a plugin asset. (For plugin assets use inbox-to-sources.sh.)
#
# inbox raw 는 그대로 둠 (R2 대상 X, raw 단계). 메인테이너가 검토 후 수동 정리.
# 새 idea 는 raw 의 내용을 참조해 *재작성* — 자동 복사 X (메타 idea 는
# *생각의 정리* 라 재구성 필요).
#
# ADR-0002 §inbox PR 워크플로우 §4 triage 분기 자동화.
#
# Optional <slug>: kebab-case 강제. 미지정 시 inbox 파일명에서 추출 시도.

set -euo pipefail

INBOX="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$INBOX" || ! -f "$INBOX" ]]; then
  echo "usage: $0 <content/inbox/file> [slug]" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
IDEA_DIR="$REPO_ROOT/docs/idea"
mkdir -p "$IDEA_DIR"

BASE="$(basename "$INBOX")"
BASE_NOEXT="${BASE%.md}"
if [[ -n "$SLUG_OVERRIDE" ]]; then
  if [[ ! "$SLUG_OVERRIDE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "slug must be kebab-case (lowercase a-z, 0-9, '-'): '$SLUG_OVERRIDE'" >&2
    exit 4
  fi
  TITLE_SLUG="$SLUG_OVERRIDE"
else
  TITLE_SLUG=$(echo "$BASE_NOEXT" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | sed 's/[^a-z0-9-]//g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
  if [[ -z "$TITLE_SLUG" || ! "$TITLE_SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
    echo "could not derive kebab-case slug from '$BASE'. provide [slug] arg." >&2
    exit 5
  fi
fi

LAST=0
shopt -s nullglob
for f in "$IDEA_DIR"/idea-*.md; do
  n=$(basename "$f" | sed -E 's/^idea-([0-9]+)-.*/\1/')
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%02d" $((LAST + 1)))

OUT="$IDEA_DIR/idea-$NN-$TITLE_SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 2; }

TITLE=$(echo "$TITLE_SLUG" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

# repo-relative path (fallback to original)
INBOX_REL=$(python3 -c "import os,sys; p=sys.argv[1]; r=sys.argv[2]; print(os.path.relpath(p, r))" "$INBOX" "$REPO_ROOT" 2>/dev/null || echo "$INBOX")

cat > "$OUT" <<EOF
---
id: idea-$NN
title: $TITLE
type: idea
status: open
tags: [idea]
aliases: []
---

# $TITLE

> 원본: \`$INBOX_REL\` (메타 정책으로 triage 된 inbox raw — [[adr-0002-permissions-flow]] §inbox PR 워크플로우 §4)

## Background

(inbox raw 의 핵심 발췌 / 동기 — 메인테이너 재작성)

## Open Questions

- [ ]
EOF

echo "$OUT"
