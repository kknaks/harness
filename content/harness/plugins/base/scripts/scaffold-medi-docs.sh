#!/usr/bin/env bash
# Usage: scaffold-medi-docs.sh [project-dir]
#
# 사용자 cwd (또는 인자 project-dir) 의 `medi_docs/current/` 9 카테고리
# scaffold (ADR-0008 §1, §4). idempotent — 이미 존재하는 카테고리·README·
# template.md 는 건드리지 않음 (사용자 자산 보호).
#
# 9 카테고리: adr / plan / planning / policy / release-notes / retrospective
#             / runbook / spec / test
#
# 각 카테고리에 plugin 의 `medi-docs-templates/<cat>/{README.md, template.md}`
# 가 복사됨. README.md = 카테고리 의도 안내. template.md = 사용자가 새 문서
# 박을 때의 시작점.

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
PLUGIN_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATES_DIR="$PLUGIN_ROOT/medi-docs-templates"
TARGET="$PROJECT_DIR/medi_docs/current"

if [[ ! -d "$TEMPLATES_DIR" ]]; then
  echo "templates not found: $TEMPLATES_DIR" >&2
  exit 1
fi

mkdir -p "$TARGET"

declare -i created=0 existed=0

for cat_dir in "$TEMPLATES_DIR"/*/; do
  [[ -d "$cat_dir" ]] || continue
  cat=$(basename "$cat_dir")
  out_dir="$TARGET/$cat"
  if [[ -d "$out_dir" ]]; then
    existed=$((existed + 1))
    continue
  fi
  mkdir -p "$out_dir"
  for f in README.md template.md; do
    if [[ -f "$cat_dir/$f" ]]; then
      cp "$cat_dir/$f" "$out_dir/$f"
    fi
  done
  echo "  → medi_docs/current/$cat/"
  created=$((created + 1))
done

if (( created == 0 )); then
  echo "  (medi_docs/current/ 이미 셋업됨 — $existed 카테고리 보존)"
else
  echo "  ($created 카테고리 신규 생성, $existed 보존)"
fi
