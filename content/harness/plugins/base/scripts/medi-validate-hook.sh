#!/usr/bin/env bash
# H1 plugin-level wrapper. ADR-0009 §1.
#
# Responsibilities (plugin manifest 미지원 → script 내부 처리):
#   1. env 게이트 (HARNESS_HOOK_H1_ENABLED)
#   2. path 필터 (medi_docs/current/** 만 발동)
#   3. 사용자 프로젝트의 docs-validate skill (init.sh 가 박는 것) 으로 dispatch
#      — skill 미설치 (init 미실행) 면 silent exit
#
# Trigger: PostToolUse Write|Edit. stdin = Claude Code hook JSON.
set -euo pipefail

[[ "${HARNESS_HOOK_H1_ENABLED:-true}" == "true" ]] || exit 0

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" \
  | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" \
  2>/dev/null || echo "")

case "$FILE_PATH" in
  */medi_docs/current/*) ;;
  *) exit 0 ;;
esac

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
SKILL="$PROJECT_DIR/.claude/skills/docs-validate/scripts/medi-validate.sh"

[[ -x "$SKILL" ]] || exit 0  # init 미실행 — silent

exec "$SKILL"
