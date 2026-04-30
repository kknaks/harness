#!/usr/bin/env bash
# sync-role-manifest.sh <role>|--all
#
# `role-templates/<role>/role.json` 을 디렉토리 (skills/, commands/, hooks/) 에
# 맞춰 동기화. 자세한 동작은 sync-role-manifest.py 참고.
#
# 일괄 갱신 시 (예: 300 SKILL 박는 야간 작업):
#   1. role-templates/<role>/skills/ 에 자유롭게 mv/rm/cp
#   2. bash sync-role-manifest.sh --all
#   3. validate.sh   # R12 가 drift 검증
#   4. git commit

set -euo pipefail
exec python3 "$(dirname "$0")/sync-role-manifest.py" "$@"
