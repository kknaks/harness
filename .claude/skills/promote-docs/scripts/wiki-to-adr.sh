#!/usr/bin/env bash
# Usage: wiki-to-adr.sh <content/wiki/wiki-NN-<slug>.md> [slug] [role]
# Creates content/adr/adr-NNNN-<slug>.md scaffold (4-digit, ADR standard body).
# Distinct from spec-to-adr.sh which targets docs/adr/ (meta layer).
# Content ADR counter is independent from meta ADR counter.
#
# Optional <slug>:
#   - kebab-case override for output filename.
#   - If omitted, slug is derived from the wiki filename.
#
# Optional <role>:
#   - plugin role this asset maps to. enum: base|planner|pm|frontend|backend|qa|infra
#     ([[adr-0011-base-hoisting]] §1).
#   - If provided, written to frontmatter as `role: <value>`. Same skill (e.g.
#     code-review) can land in different roles via separate ADRs — role is the
#     plugin facet (categories is the topic facet, propagated from wiki).
#   - If omitted, `role:` line is omitted (operator fills in by hand).

set -euo pipefail

WIKI="${1:-}"
SLUG_OVERRIDE="${2:-}"
ROLE="${3:-}"
if [[ -z "$WIKI" || ! -f "$WIKI" ]]; then
  echo "usage: $0 <content/wiki/wiki-NN-<slug>.md> [slug] [role]" >&2
  exit 1
fi

if [[ -n "$ROLE" ]]; then
  case "$ROLE" in
    base|planner|pm|frontend|backend|qa|infra) ;;
    *)
      echo "role must be one of: base|planner|pm|frontend|backend|qa|infra (got: '$ROLE')" >&2
      exit 5
      ;;
  esac
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

# Propagate categories from source wiki frontmatter (single-line form `categories: [...]`).
WIKI_CATS="$(grep -E '^categories:[[:space:]]*\[' "$WIKI" | head -n1 | sed -E 's/^categories:[[:space:]]*//' || true)"

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

CATEGORIES_LINE=""
[[ -n "$WIKI_CATS" ]] && CATEGORIES_LINE="categories: $WIKI_CATS"$'\n'
ROLE_LINE=""
[[ -n "$ROLE" ]] && ROLE_LINE="role: $ROLE"$'\n'

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
${CATEGORIES_LINE}${ROLE_LINE}aliases: []
---

# $TITLE

## Context

(승격 원본: \`$WIKI\` — 합성된 지식에서 추출한 결정 배경. wiki 의 *공용 골격 + 프로젝트 의존 슬롯* 구조 + plugin 매핑 가설 후보)

## Decision

(atomic 결정: *공용 골격은 plugin 본문 / 프로젝트 의존 슬롯은 reference 로드·분기 ADR·별도 plugin 중 택1*. wiki 의 두 층 분리를 plugin 단계에서 합치지 말 것 (promote-docs SKILL §자산 분리 룰). 1~2문장 + §부속결정)

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + 프로젝트 슬롯 *합쳐서* role plugin 본문에 박기 | wiki 두 층 분리 무효화. role plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지) |
| | |

(wiki 의 *Plugin 매핑 가설* 들 + 검토한 다른 후보 — 채택 안 한 이유 명시)

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| | | | |

(액션 아이템 표 — 어느 plugin 의 어디에 / 무엇을 / 누가 / 언제 / 의존. ADR-0004 본문 표준)

## Consequences

**Pros**
-

**Cons**
-

**Follow-ups**
- [ ]

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_
EOF

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
python3 "$SCRIPT_DIR/lib/update-status.py" "$WIKI" promoted 2>/dev/null || true

echo "$OUT"
