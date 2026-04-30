---
description: mediness harness scaffolder — /harness init <role> 으로 프로젝트 .claude/ 에 SKILL 박기 (또는 인자 없이 상태 확인)
argument-hint: init <role> [--force] | (no args for status)
allowed-tools: [Bash]
---

User invoked `/harness` with arguments: `$ARGUMENTS`

mediness harness 단일 plugin 의 사용자 진입점. 본 slash command 는 본 plugin 의 `skills/harness/scripts/init.sh` 를 호출하여 *현재 프로젝트의* `.claude/` 에 role-templates 의 SKILL 자산을 복사하는 scaffolder.

## 실행 흐름

### 1. plugin root 위치 찾기

가장 신뢰성 있게 — find 으로 본 plugin 의 init.sh 검색:

```bash
INIT_SH=$(find ~/.claude/plugins -type f -name "init.sh" -path "*/harness/scripts/*" 2>/dev/null | head -1)
```

`$INIT_SH` 가 비어있으면 plugin install 이 깨졌다는 뜻 — 사용자에게 `/plugin install harness` 재실행 안내.

### 2. 인자 분기

**(a) `$ARGUMENTS` 가 비었으면** — 상태 확인:

```bash
echo "=== plugin 설치 상태 ==="
[[ -n "$INIT_SH" ]] && echo "OK: harness plugin 설치됨 ($(dirname $INIT_SH | xargs dirname | xargs dirname))"

echo ""
echo "=== 사용 가능한 role ==="
ROLE_TEMPLATES="$(dirname $INIT_SH | xargs dirname | xargs dirname)/role-templates"
for d in "$ROLE_TEMPLATES"/*/; do
  [[ -d "$d" ]] && echo "  - $(basename $d)"
done

echo ""
echo "=== 현재 프로젝트 .claude/skills/ ==="
ls .claude/skills/ 2>/dev/null || echo "  (없음 — /harness init <role> 로 셋업)"
```

**(b) `$ARGUMENTS` 가 `init` 으로 시작하면** — scaffolder 실행:

```bash
# "init backend" → "backend"
INIT_ARGS="${ARGUMENTS#init }"
bash "$INIT_SH" $INIT_ARGS
```

**(c) `$ARGUMENTS` 가 `update` 로 시작하면** — `init --force` alias (v0.1):

```bash
UPDATE_ARGS="${ARGUMENTS#update }"
bash "$INIT_SH" $UPDATE_ARGS --force
```

**(d) `$ARGUMENTS` 가 `uninstall`** — 안내만 (자동 rm X, 사용자 확인 필수):

```
아래 명령으로 프로젝트의 harness 자산을 제거할 수 있습니다 (medi_docs/ 는 사용자 자산이라 보존):
  rm -rf .claude/skills/code-review .claude/skills/test-design

plugin 자체 제거:
  /plugin uninstall harness
```

### 3. 결과 보고

스크립트 출력을 그대로 사용자에게 전달. 추가 필요한 후속 단계 (예: 세션 재시작 권고) 는 plugin 의 `skills/harness/SKILL.md` 본문 정책 참조.

## 보안

- 동적 입력 (`$ARGUMENTS`) 는 init.sh 내부에서 role 화이트리스트 (디렉토리 존재 검증) 으로 검증됨 — slash command 단계에선 raw passthrough 안전.
- `--force` 플래그 외에 *덮어쓰기 / 삭제* 동작 없음. uninstall 은 안내만, rm 은 사용자가 직접.
- `.env` / `secrets/` / token 파일은 init 대상 디렉토리 (`.claude/`) 와 무관하므로 마스킹 불필요. 단, 출력에 시크릿 포함될 가능성 보이면 plugin 의 `skills/harness/SKILL.md` §보안 의 마스킹 패턴 적용.

## 관련 자료

- `skills/harness/SKILL.md` — 진입점 SKILL (description-매칭 invocation 시 활성)
- `skills/harness/scripts/init.sh` — 실제 scaffolder 로직
- `role-templates/README.md` — 사용 가능한 role 목록 + 각 role 의 SKILL
- ADR: `[[adr-0014-single-plugin-scaffolder]]` — 본 모델 결정
