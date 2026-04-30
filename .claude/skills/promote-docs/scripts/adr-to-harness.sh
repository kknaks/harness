#!/usr/bin/env bash
# Usage: adr-to-harness.sh <content/adr/adr-NNNN-<slug>.md> <role>
#
# ADR-0014 단일 plugin scaffolder 모델 — content ADR 이 어느 *role* 의 SKILL
# 자산으로 입주했는지 박제 (Notes lineage). 본 스크립트는 *기록만* —
# 실제 SKILL 디렉토리·자산 박기는 `add-role-skill.sh` (또는 `create-skill.sh`)
# 가 담당.
#
# 7-plugin → 1-plugin pivot (ADR-0014 / 2026-04-30) 후 인자 의미:
#   - 옛날: <plugin-name> = base / planner / pm / frontend / backend / qa / infra
#   - 지금: <role> = base / planner / pm / frontend / backend / qa / infra / fullstack
#           → content/harness/plugins/base/role-templates/<role>/ 가 cascade target
#
# 동작:
#   1. ADR 파일 + role-templates/<role>/ 디렉토리 존재 검증
#   2. ADR `## Notes` 에 lineage 한 줄 append (idempotent)
#   3. 다음 단계 안내 (release flow — adr-0005)
#
# Plugin packaging (manifest version, marketplace registration) 은 spec-09
# release pipeline 영역, 본 스크립트 X.

set -euo pipefail

ADR="${1:-}"
ROLE="${2:-}"
if [[ -z "$ADR" || ! -f "$ADR" ]]; then
  echo "usage: $0 <content/adr/adr-NNNN-<slug>.md> <role>" >&2
  exit 1
fi
if [[ -z "$ROLE" ]]; then
  echo "role required (e.g. base, planner, pm, frontend, backend, qa, infra, fullstack)" >&2
  exit 1
fi
if [[ ! "$ROLE" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "role must be kebab-case: '$ROLE'" >&2
  exit 4
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
ROLE_DIR="$REPO_ROOT/content/harness/plugins/base/role-templates/$ROLE"
if [[ ! -d "$ROLE_DIR" ]]; then
  echo "role-templates/<role>/ 디렉토리 없음: $ROLE_DIR" >&2
  echo "(ADR-0014 단일 plugin 모델 — base plugin 의 role-templates/<role>/ 가 입주 target)" >&2
  echo "먼저 mkdir 으로 박은 뒤 sync-role-manifest.sh 로 manifest 박기:" >&2
  echo "  mkdir -p $ROLE_DIR/skills" >&2
  echo "  $(dirname "$0")/sync-role-manifest.sh $ROLE" >&2
  exit 3
fi

ADR_BASE="$(basename "$ADR" .md)"
TODAY=$(date +%Y-%m-%d)

# Notes line — single plugin + role 박제
NOTE="- $TODAY: applied to plugin \`base\` role \`$ROLE\` (content/harness/plugins/base/role-templates/$ROLE/)"

# idempotent — 이미 박혀 있으면 skip
if ! grep -qF "applied to plugin \`base\` role \`$ROLE\`" "$ADR"; then
  if grep -q "^## Notes" "$ADR"; then
    printf "%s\n" "$NOTE" >> "$ADR"
  else
    printf "\n## Notes\n\n%s\n" "$NOTE" >> "$ADR"
  fi
fi

cat <<EOF
ADR applied: $ADR_BASE -> base/role-templates/$ROLE

Notes appended (lineage trace).

Next steps (NOT handled by this script — see adr-0005 version-rollout):
  1. SKILL 자산 박기 (없으면): add-role-skill.sh $ROLE <skill-name> "<desc>"
  2. SKILL 본문 채움 (ADR-0007 §1 표준): SKILL.md / rules.md / checklist.md / examples/
  3. base plugin manifest version bump: content/harness/plugins/base/plugin.json
  4. dogfood install: /plugin marketplace add ... + /plugin install harness + /reload-plugins
  5. 사용처에서 검증: /harness:init $ROLE → .claude/skills/<n>/ 박힘 확인
EOF
