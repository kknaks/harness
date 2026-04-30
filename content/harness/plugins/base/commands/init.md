---
description: 현재 프로젝트의 .claude/ 에 mediness role-templates 의 SKILL 들을 scaffold (예 — /harness:init backend)
argument-hint: <role> [role...] [--force]
allowed-tools: [Bash]
---

User invoked `/harness:init` with arguments: `$ARGUMENTS`

본 slash command 는 mediness `harness` plugin 의 scaffolder. plugin 내부의 `role-templates/<role>/skills/*` 를 *현재 프로젝트의* `.claude/skills/` 로 복사.

## Action

다음 bash 블록 실행:

```bash
# plugin 내부의 init.sh 위치 (Claude Code plugin cache 경로는 install 시점마다 다름)
INIT_SH=$(find ~/.claude/plugins -type f -name "init.sh" -path "*/skills/harness/scripts/*" 2>/dev/null | head -1)

if [[ -z "$INIT_SH" ]]; then
  echo "harness plugin 의 init.sh 를 찾지 못했습니다." >&2
  echo "다음으로 재설치 후 재시도하세요:" >&2
  echo "  /plugin install harness" >&2
  echo "  /reload-plugins" >&2
  exit 1
fi

# 인자 그대로 init.sh 에 전달 (예: "backend" 또는 "backend qa --force")
bash "$INIT_SH" $ARGUMENTS
```

## 결과 보고

스크립트 출력을 사용자에게 그대로 전달.

- 인자 없이 호출됐다면 (`$ARGUMENTS` 비어있음): init.sh 가 사용 가능한 role 목록 + usage 를 stderr 로 출력하고 exit 1. 이를 사용자에게 보여주고 다음 호출 예시 제안 (예: `/harness:init backend`).
- `skipped > 0` 가 출력에 보이면: 사용자 커스텀 보존 룰이 작동한 것. 갱신 의도였는지 확인 후 `--force` 재호출 제안.
- 성공 (`copied > 0`) 시: `.claude/skills/` 에 박힌 SKILL 들 + `medi_docs/current/` 9 카테고리 박힘 안내. SKILL 활성을 위해 세션 재시작 또는 `/reload-plugins` 가 필요할 수도 있음 (Claude Code 가 `.claude/skills/` 를 세션 시작 시 스캔).

## 보안

- `$ARGUMENTS` 는 init.sh 내부에서 role 디렉토리 화이트리스트 (존재 검증) 로 검증. slash command 단계 raw passthrough 안전.
- 스크립트는 *복사* 만 — `--force` 외에 destructive 동작 없음. uninstall 은 별 명령 또는 사용자 손.

## 관련

- plugin 의 `skills/harness/SKILL.md` — description-매칭 활성 시 같은 동작 (자연어 호출 경로)
- plugin 의 `role-templates/README.md` — 사용 가능한 role 목록
- ADR: [[adr-0014-single-plugin-scaffolder]] — 본 모델 결정
