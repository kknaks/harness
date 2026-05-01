#!/usr/bin/env bash
# Usage: inbox-to-sources.sh <content/inbox/<asset>> [slug]
#
# Promotes an inbox asset (1 unit = inbox 직접 자식) to sources.
# 출력은 항상 단일 .md 1 file (ADR-0003 §자산 단위 — 평탄화).
#   - 파일 입력 (e.g., content/inbox/note.md):
#       → content/sources/sources-NN-<slug>.md (frontmatter scaffold, raw 본문은 Claude 합성)
#   - 디렉토리 입력 (e.g., content/inbox/code-review/):
#       → content/sources/sources-NN-<slug>.md (frontmatter scaffold + 디렉토리 walk → 각 파일별 코드 블록 자동 인용)
#
# Inbox raw 는 그대로 둠 ([[adr-0002-permissions-flow]] §inbox 워크플로우 §4). sources 박제 후 메인테이너 수동 정리.
# 정체 한 줄 / 보존 이유 등 메타는 Claude (메인테이너) 본문 합성 — ADR-0012 §1.
#
# Optional <slug>: kebab-case override. 미지정 시 입력 basename 에서 추출.

set -euo pipefail

INBOX="${1:-}"
SLUG_OVERRIDE="${2:-}"
if [[ -z "$INBOX" || ! -e "$INBOX" ]]; then
  echo "usage: $0 <content/inbox/<asset>> [slug]" >&2
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
  bn=$(basename "$f")
  n=$(echo "$bn" | sed -E 's/^sources-([0-9]+)-.*/\1/')
  [[ "$n" =~ ^[0-9]+$ ]] || continue
  (( 10#$n > LAST )) && LAST=10#$n
done
shopt -u nullglob
NN=$(printf "%02d" $((LAST + 1)))

OUT="$SOURCES_DIR/sources-$NN-$TITLE_SLUG.md"
[[ -e "$OUT" ]] && { echo "already exists: $OUT" >&2; exit 2; }

INBOX_REL="${INBOX#$REPO_ROOT/}"
INBOX_REF="$(basename "$INBOX")"

TITLE=$(echo "$TITLE_SLUG" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

# frontmatter + 정체화 scaffold
cat > "$OUT" <<EOF
---
id: sources-$NN
title: $TITLE
type: sources
status: pending
sources:
  - "[[$INBOX_REF]]"
tags: [sources]
aliases: []
---

# $TITLE

> 1차 가공 = 원본 박제. 이후 불변. 원본의 정체(이름·목적)를 명확히 한 채 보존한다.

## 정체 (Identification)

**원본**: \`$INBOX_REL\`

**무엇인가 (한 줄)**:

(Claude 합성 — ADR-0012 §1)

**왜 보존하는가**:

(이 자산이 wiki 합성에 어떻게 기여할지 — Claude 합성)

## 본문 (raw 인용)

EOF

# 진단: 디렉토리 입력 시 child 파일의 frontmatter `name:` 카운트 — N>1 이면
# *각자 자체 SKILL* 신호. 합성자 (Claude / 메인테이너) 가 sources→wiki 단계에서
# 단일 wiki 로 묶지 않도록 stderr 경고. 본 sh 자체는 mechanical 1:1 유지
# (자산 단위 = 디렉토리, ADR-0003 §자산 단위) — block X.
if [[ -d "$INBOX" ]]; then
  N_NAMED=$(grep -l "^name:" "$INBOX"/*.md 2>/dev/null | wc -l | tr -d ' ')
  if (( N_NAMED > 1 )); then
    {
      echo ""
      echo "⚠ 합성자 진단: $INBOX 의 .md 파일 중 $N_NAMED 개가 frontmatter \`name:\` 보유"
      echo "  → 각자 *자체 SKILL 정체* (Claude Code SKILL 모델 / ADR-0007 §S1)"
      echo "  → sources→wiki 단계에서 *N wiki* 박을 것 (메타-내러티브 묶음 금지 — promote-docs/rules.md §sources→wiki)"
      echo "  발견된 SKILL:"
      grep -l "^name:" "$INBOX"/*.md 2>/dev/null | while read f; do
        nm=$(grep "^name:" "$f" | head -1 | sed 's/name: *//' | tr -d ' ')
        echo "    - $(basename "$f"): name=$nm"
      done
      echo ""
    } >&2
  fi
fi

# raw 본문 인용 — 디렉토리/파일 분기 자동
if [[ -d "$INBOX" ]]; then
  # 디렉토리: 각 파일별 코드 블록 자동 인용 (자식 트리 walk)
  while IFS= read -r f; do
    rel="${f#$INBOX/}"
    ext="${f##*.}"
    # markdown 은 인용 깨짐 회피 위해 코드 fence 길이 조정
    if [[ "$ext" == "md" ]]; then
      fence='~~~'
      lang='markdown'
    elif [[ "$ext" == "py" ]]; then
      fence='```'
      lang='python'
    elif [[ "$ext" == "sh" ]]; then
      fence='```'
      lang='bash'
    elif [[ "$ext" == "json" ]]; then
      fence='```'
      lang='json'
    else
      fence='```'
      lang=''
    fi
    {
      printf '\n### %s\n\n%s%s\n' "$rel" "$fence" "$lang"
      cat "$f"
      printf '\n%s\n' "$fence"
    } >> "$OUT"
  done < <(find "$INBOX" -type f | sort)
elif [[ -f "$INBOX" ]]; then
  # 파일: 단일 코드 블록 인용
  ext="${INBOX##*.}"
  if [[ "$ext" == "md" ]]; then
    fence='~~~'
    lang='markdown'
  else
    fence='```'
    lang=''
  fi
  {
    printf '\n%s%s\n' "$fence" "$lang"
    cat "$INBOX"
    printf '\n%s\n' "$fence"
  } >> "$OUT"
else
  echo "not a regular file or directory: $INBOX" >&2
  exit 3
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# inbox raw 가 .md (frontmatter 가질 수 있음) 면 status: promoted 갱신.
# 디렉토리 자산은 단위 자체 — 메인 .md 가 식별 가능하면 갱신 시도.
if [[ -f "$INBOX" && "$INBOX" == *.md ]]; then
  python3 "$SCRIPT_DIR/lib/update-status.py" "$INBOX" promoted 2>/dev/null || true
elif [[ -d "$INBOX" ]]; then
  for cand in "$INBOX/SKILL.md" "$INBOX/README.md"; do
    if [[ -f "$cand" ]]; then
      python3 "$SCRIPT_DIR/lib/update-status.py" "$cand" promoted 2>/dev/null || true
      break
    fi
  done
fi

echo "$OUT"
