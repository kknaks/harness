#!/usr/bin/env bash
# Usage: add-role-skill.sh [--reference] <role> <skill-name> [description]
#
# 한 번에 SKILL scaffold + role manifest 갱신. 한 SKILL 단위로 박을 때 마찰
# 최소화 (메인테이너가 JSON 안 만짐).
#
# `--reference` 플래그 (ADR-0015):
#   - reference 자산 (절차 SKILL 아님 — 개념·룰·근거)
#   - SKILL.md frontmatter `asset_type: reference` 박힘
#   - examples/ + checklist.md 생성 SKIP (OQ-A: 면제)
#   - role.json 의 skills[] 에서 object 형태 (`{"name": "...", "type": "reference"}`)
#
# 동작:
#   1. content/harness/plugins/base/role-templates/<role>/skills/<skill-name>/
#      디렉토리 생성 (이미 있으면 exit 2)
#   2. create-skill.sh 호출 — ADR-0007 §1 자산 (reference 면 examples/checklist 생략)
#   3. sync-role-manifest.sh <role> 호출 — role.json 의 skills[] 자동 갱신
#
# Arguments:
#   <role>           backend / frontend / planner / pm / qa / infra
#   <skill-name>     kebab-case
#   [description]    SKILL.md frontmatter description (선택)
#
# Exit codes:
#   0 = 성공
#   1 = 인자 부족
#   2 = SKILL 또는 role 디렉토리 충돌
#   3 = role 디렉토리 부재 (먼저 만들어야 함)
#   4 = SKILL 이름 kebab-case 위반

set -euo pipefail

REF_FLAG=""
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reference) REF_FLAG="--reference"; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

ROLE="${ARGS[0]:-}"
NAME="${ARGS[1]:-}"
DESC="${ARGS[2]:-}"

if [[ -z "$ROLE" || -z "$NAME" ]]; then
  echo "usage: $0 [--reference] <role> <skill-name> [description]" >&2
  echo "  e.g. $0 backend api-design \"신규 API 설계 합의\"" >&2
  echo "  e.g. $0 --reference backend db-transaction \"트랜잭션 reference\"" >&2
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
ROLE_DIR="$REPO_ROOT/content/harness/plugins/base/role-templates/$ROLE"
if [[ ! -d "$ROLE_DIR" ]]; then
  echo "role 디렉토리 부재: $ROLE_DIR" >&2
  echo "먼저 mkdir 으로 박은 뒤 sync-role-manifest.sh 로 manifest 생성:" >&2
  echo "  mkdir -p $ROLE_DIR/skills" >&2
  echo "  $(dirname "$0")/sync-role-manifest.sh $ROLE" >&2
  exit 3
fi

# 1) create-skill.sh 호출
LOCATION="content/harness/plugins/base/role-templates/$ROLE/skills"
if [[ -n "$REF_FLAG" ]]; then
  "$(dirname "$0")/create-skill.sh" "$REF_FLAG" "$NAME" "$LOCATION" "$DESC" >/dev/null
else
  "$(dirname "$0")/create-skill.sh" "$NAME" "$LOCATION" "$DESC" >/dev/null
fi

# 2) sync-role-manifest.sh — skills[] 갱신
"$(dirname "$0")/sync-role-manifest.sh" "$ROLE"

echo ""
ASSET_LABEL="SKILL"
[[ -n "$REF_FLAG" ]] && ASSET_LABEL="reference"
echo "✓ $ROLE/$NAME ($ASSET_LABEL) 박힘. 다음:"
echo "  1. $LOCATION/$NAME/SKILL.md 본문 채우기 (ADR-0007 §1 표준)"
if [[ -z "$REF_FLAG" ]]; then
  echo "  2. (조건부) reference 로드·phase 표·산출 포맷 — promote-docs/rules.md §체크리스트 통과"
else
  echo "  2. rules.md 본문 채우기 (개념·룰 SSOT)"
fi
echo "  3. validate.sh 로 정합성 확인 (R11 스킬 자산 + R12 manifest drift)"
