#!/usr/bin/env bash
# scaffold-medi-docs.sh — 사용자 medi_docs/current/ 9 카테고리 scaffold (ADR-0008 §4).
# Usage: scaffold-medi-docs.sh [target-dir]
#   기본 target = $PWD/medi_docs/current
#
# 동작:
#   - target 이미 존재 → no-op (사용자 자산 보호, ADR-0008 §4)
#   - 부재 → 9 카테고리 디렉토리 + README + template 복사 + _map.md placeholder
#
# template 위치 resolve 우선순위:
#   1. $CLAUDE_PLUGIN_ROOT/medi-docs-templates  (plugin install 환경)
#   2. <script>/../../../medi-docs-templates    (개발/dogfood 환경)

set -euo pipefail

TARGET="${1:-$PWD/medi_docs/current}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" && -d "$CLAUDE_PLUGIN_ROOT/medi-docs-templates" ]]; then
  TEMPLATE_ROOT="$CLAUDE_PLUGIN_ROOT/medi-docs-templates"
else
  TEMPLATE_ROOT="$SCRIPT_DIR/../../../medi-docs-templates"
fi

[[ -d "$TEMPLATE_ROOT" ]] || { echo "[scaffold-medi-docs] template root 부재: $TEMPLATE_ROOT" >&2; exit 1; }

if [[ -d "$TARGET" ]]; then
  echo "[scaffold-medi-docs] 이미 존재: $TARGET (no-op, 사용자 자산 보호)" >&2
  exit 0
fi

CATEGORIES=(planning plan spec policy adr runbook test release-notes retrospective)
mkdir -p "$TARGET"

for cat in "${CATEGORIES[@]}"; do
  mkdir -p "$TARGET/$cat"
  for f in README.md template.md; do
    if [[ -f "$TEMPLATE_ROOT/$cat/$f" ]]; then
      cp "$TEMPLATE_ROOT/$cat/$f" "$TARGET/$cat/$f"
    fi
  done
done

cat > "$TARGET/_map.md" <<'EOF'
# medi_docs Map

> 자동 생성 placeholder. docs-validate 사용자 배포본 (plan D2) 가동 후 자동 갱신.

_9 카테고리 scaffold 완료. 자산 0._
EOF

echo "[scaffold-medi-docs] scaffold 완료: $TARGET"
echo "  9 카테고리: ${CATEGORIES[*]}"
