#!/usr/bin/env bash
# Usage: create-skill.sh [--reference] <skill-name> <location> [description]
#
# 4 필수 자산 (SKILL.md + rules.md + examples/sample-no-reference.md + checklist.md) 자동 박는
# scaffold. ADR-0007 §1 표준 강제 (S5/S6/S7) — 누락 X.
#
# `--reference` 플래그 (ADR-0015):
#   - SKILL.md frontmatter `asset_type: reference` 박기 (디폴트: 생략 = skill)
#   - `allowed_tools: [Read]` (코드 변경 X)
#   - examples/ + checklist.md 생성 SKIP (OQ-A: 완전 면제)
#   - rules.md 는 여전히 생성 (개념·룰 박는 곳)
#
# Arguments:
#   <skill-name>   kebab-case (예: code-review, db-transaction)
#   <location>     SKILL 디렉토리 부모.
#                  - 메인테이너: .claude/skills
#                  - 사용자 배포본: content/harness/plugins/<role>/skills
#   [description]  SKILL.md frontmatter description (선택)
#
# Output: 생성된 SKILL 디렉토리 경로.
# Exit codes:
#   0 = 성공
#   1 = 인자 부족
#   2 = 디렉토리 이미 존재
#   4 = name 이 kebab-case 아님

set -euo pipefail

ASSET_TYPE="skill"
ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reference) ASSET_TYPE="reference"; shift ;;
    *) ARGS+=("$1"); shift ;;
  esac
done

NAME="${ARGS[0]:-}"
LOCATION="${ARGS[1]:-}"
DESC="${ARGS[2]:-}"

if [[ -z "$NAME" || -z "$LOCATION" ]]; then
  echo "usage: $0 [--reference] <skill-name> <location> [description]" >&2
  echo "  e.g. $0 code-review content/harness/plugins/backend/skills" >&2
  echo "  e.g. $0 --reference db-transaction content/harness/plugins/base/role-templates/backend/skills" >&2
  exit 1
fi

if [[ ! "$NAME" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "skill-name must be kebab-case (lowercase a-z, 0-9, '-'): '$NAME'" >&2
  exit 4
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
TARGET="$REPO_ROOT/$LOCATION/$NAME"

if [[ -e "$TARGET" ]]; then
  echo "already exists: $TARGET" >&2
  echo "" >&2
  echo "기존 SKILL 에 scaffold heredoc 갱신을 동기화하려면:" >&2
  echo "  bash $(dirname "$0")/sync-skill.sh \"$TARGET\" --apply" >&2
  exit 2
fi

# reference 자산은 examples/ + scripts/ 안 만듦 (OQ-A: 면제)
if [[ "$ASSET_TYPE" == "reference" ]]; then
  mkdir -p "$TARGET"
else
  mkdir -p "$TARGET/examples" "$TARGET/scripts"
fi

# Title from name (kebab → Title Case)
TITLE=$(echo "$NAME" | tr '-' ' ' \
  | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')

# Frontmatter — asset_type / allowed_tools 분기
if [[ "$ASSET_TYPE" == "reference" ]]; then
  ALLOWED_TOOLS="[Read]"
  ASSET_TYPE_LINE="asset_type: reference"$'\n'
else
  ALLOWED_TOOLS="[Read, Edit, Bash]"
  ASSET_TYPE_LINE=""
fi

# SKILL.md
cat > "$TARGET/SKILL.md" <<EOF
---
name: $NAME
description: $DESC
allowed_tools: $ALLOWED_TOOLS
${ASSET_TYPE_LINE}---

# $TITLE

(스킬이 하는 일 1~2문장. 사용자 시점 진입점 — 무엇 / 언제 / 어떻게 호출. 룰셋·정책은 \`rules.md\` 로 분리.)

## When to use

- (호출 트리거 1)
- (호출 트리거 2)

## How to invoke

(주된 sh 또는 명령. 인자 시그니처 + 의미.)

후속:
1. (단계 1)
2. (단계 2)

자세한 룰셋·정책·금지 사항은 [\`rules.md\`](rules.md). 운영 체크리스트는 [\`checklist.md\`](checklist.md).

## 보안 고려사항

- \`allow_commands\` 선언 이유: (위험 명령 호출 시 — 없으면 "X — read/write only")
- 동적 입력 (\$VAR / CLI 인자 / 파일 경로) 처리: \`source ../scripts/sanitize.sh\` 또는 인용 규칙 (\`"\$VAR"\`/\`printf %q\`).
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 \`***\` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | \`.env\`, \`.env.*\` (\`.local\`, \`.production\` 등) | \`(^|/)\\.env(\\..+)?$\` |
| 시크릿 디렉토리 | \`secrets/\`, \`secret/\`, \`credentials/\` | \`(^|/)(secrets?|credentials)/\` |
| 토큰 파일 | \`*token*\`, \`*apikey*\`, \`*api_key*\` | \`(token|api[_-]?key)\` (대소문자 무시) |
| 키 자료 | \`*.pem\`, \`*.key\`, \`*.p12\`, \`*.pfx\`, \`id_rsa*\` | \`\\.(pem|key|p12|pfx)$\|^id_rsa\` |
| 인증 헤더값 | \`Authorization: Bearer ...\`, \`x-api-key: ...\` | \`(Bearer\\s+\\S+|x-api-key:\\s*\\S+)\` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 \`***\` 치환. 사용처 환경별 추가 패턴은 본 § 에 보강.
EOF

# rules.md (reference 자산도 생성 — 룰·개념 박는 곳)
cat > "$TARGET/rules.md" <<EOF
# $TITLE Rules

> 스킬이 강제하는 룰셋·정책·금지 사항. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 룰 적용 시점에 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).
>
> **rules.md 의 책임 (본질·SSOT)**: *무엇을 강제하는가 / 왜 / 위반 시 어떻게 되는가*. 도메인 룰 본문·정책·금지·예외 처리. 운영 단계 (Pre-flight / Action / Post-flight 표) 는 \`checklist.md\` 가 SSOT — rules 에는 박지 않음 ([[adr-0007-skill-authoring-rules]] §1 SKILL.md vs rules.md vs checklist.md 분리). 같은 정보가 양쪽에 박히면 표류 — 한쪽만 SSOT.

## (룰 카테고리 1)

(룰 본문 — 강제 사항·정책·예외 처리)

## (룰 카테고리 2)

## Don't

- (금지 사항 1)
- (금지 사항 2)
EOF

# reference 자산은 checklist.md / examples/ 안 만듦 (ADR-0015 OQ-A: 면제)
if [[ "$ASSET_TYPE" != "reference" ]]; then
  # checklist.md
  cat > "$TARGET/checklist.md" <<EOF
# $TITLE Checklist

> 운영 체크리스트 — *어떤 순서로 무엇을 점검·실행·검증하는가* (SSOT).
> 룰의 본질 (왜 강제되는가) 은 \`rules.md\` 가 SSOT. 본 checklist 는 *실행 절차* 만 — 룰 본문 중복 박지 않음.
> 운영 점검 항목이 늘어나면 본 파일을, 룰 자체가 늘어나면 \`rules.md\` 를 갱신.

## (시나리오 1) — Pre-flight

- [ ] (점검 항목)

### Action

- [ ] (실행 단계)

### Post-flight

- [ ] (검증 단계)
EOF

  # examples/sample-no-reference.md (fallback / role-generic 케이스)
  cat > "$TARGET/examples/sample-no-reference.md" <<EOF
# Example: $TITLE — fallback (no reference)

> 사용 예 — 실제 결과물 sample.

## 트리거

(어떤 사용자 입력으로 호출되는가)

## 동작

(스킬이 수행하는 핵심 단계)

## 출력 포맷

\`\`\`
(예시 출력)
\`\`\`
EOF
fi

echo "$TARGET"
