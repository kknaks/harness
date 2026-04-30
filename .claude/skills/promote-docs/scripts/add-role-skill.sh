#!/usr/bin/env bash
# Usage: add-role-skill.sh <role> <skill-name> [description]
#
# 한 번에 SKILL scaffold + role manifest 갱신. 한 SKILL 단위로 박을 때 마찰
# 최소화 (메인테이너가 JSON 안 만짐).
#
# 동작:
#   1. content/harness/plugins/base/role-templates/<role>/skills/<skill-name>/
#      디렉토리 생성 (이미 있으면 exit 2)
#   2. create-skill.sh 호출 — ADR-0007 §1 4 필수 자산 (SKILL.md / rules.md /
#      checklist.md / examples/sample-no-reference.md) 박힘
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
#
# 일괄 박을 때:
#   for skill in foo bar baz; do
#     add-role-skill.sh backend "$skill" "..."
#   done

set -euo pipefail

ROLE="${1:-}"
NAME="${2:-}"
DESC="${3:-}"

if [[ -z "$ROLE" || -z "$NAME" ]]; then
  echo "usage: $0 <role> <skill-name> [description]" >&2
  echo "  e.g. $0 backend api-design \"신규 API 설계 합의\"" >&2
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

# 1) create-skill.sh 호출 — kebab-case 검증 + 디렉토리 충돌 검증 그대로 위임
LOCATION="content/harness/plugins/base/role-templates/$ROLE/skills"
"$(dirname "$0")/create-skill.sh" "$NAME" "$LOCATION" "$DESC" >/dev/null

# 2) sync-role-manifest.sh — skills[] 갱신
"$(dirname "$0")/sync-role-manifest.sh" "$ROLE"

echo ""
echo "✓ $ROLE/$NAME 박힘. 다음:"
echo "  1. $LOCATION/$NAME/SKILL.md 본문 채우기 (ADR-0007 §1 표준)"
echo "  2. (조건부) reference 로드·phase 표·산출 포맷 — promote-docs/rules.md §체크리스트 통과"
echo "  3. validate.sh 로 정합성 확인 (R11 스킬 자산 + R12 manifest drift)"
