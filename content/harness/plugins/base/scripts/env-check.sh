#!/usr/bin/env bash
# H5 — 환경 의존성 안내 hook (SessionStart).
# ADR-0009 §1: Docker / Node 부재 시 안내. block X — exit 0 + 메시지만.
# Follow-up (ADR-0009): role plugin 별 환경 검증 분리 운영 후 검토.
set -euo pipefail

MISSING=()
command -v docker >/dev/null 2>&1 || MISSING+=("Docker (필요: GitHub MCP — ADR-0010)")
command -v node   >/dev/null 2>&1 || MISSING+=("Node")

if [[ ${#MISSING[@]} -gt 0 ]]; then
  echo "[harness H5] 환경 의존성 안내:"
  for m in "${MISSING[@]}"; do
    echo "  - $m 부재"
  done
  echo "  설치 후 Claude Code 재시작 권장. (차단 없음)"
fi

exit 0
