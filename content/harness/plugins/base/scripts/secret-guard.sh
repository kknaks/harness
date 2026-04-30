#!/usr/bin/env bash
# H4 — 시크릿 차단 hook (PreToolUse Write|Edit).
# ADR-0009 §1: 시크릿 패턴 매칭 시 permissionDecision: "deny".
# 동적 입력 (file_path) 은 case 패턴 매칭에만 사용 — 셸 삽입 회피 (ADR-0007 §5).
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))")

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

MATCH=""
case "$FILE_PATH" in
  *.env|*.env.*|*/.env|*/.env.*) MATCH=".env" ;;
  *.pem|*/*.pem)                  MATCH="*.pem" ;;
  *.key|*/*.key)                  MATCH="*.key" ;;
  */secrets/*|secrets/*)          MATCH="secrets/" ;;
esac

if [[ -n "$MATCH" ]]; then
  cat <<EOF
{
  "permissionDecision": "deny",
  "reason": "[harness H4] 시크릿 패턴 ($MATCH) 차단. 변경 거부됨: $FILE_PATH"
}
EOF
fi

exit 0
