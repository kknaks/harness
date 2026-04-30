#!/usr/bin/env bash
# sync-skill.sh <skill-dir> [--apply]
#
# `create-skill.sh` scaffold heredoc 갱신을 기존 SKILL 디렉토리에 idempotent
# additive 적용 — 보편 슬롯 (SKILL.md 보안 §, rules/checklist SSOT docstring) 만.
# 자세한 동작은 sync-skill.py docstring 참고.
#
# Exit codes:
#   0 = no-op (이미 sync) / --apply 성공
#   1 = 변경 필요 (dry-run, --apply 없음)
#   2 = 인자/경로 오류

set -euo pipefail
exec python3 "$(dirname "$0")/sync-skill.py" "$@"
