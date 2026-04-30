# Harness Rules

> 스킬이 강제하는 룰셋. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 시나리오 실행 시 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## 6 시나리오 분기 ([[adr-0006-onboarding-skill]] §3)

| # | 시나리오 | 트리거 | 동작 |
|---|----------|--------|------|
| 1 | **상태 확인** | "내 설치 상태 보여줘" / 명시 분기 모호 시 default | `claude plugin list` + `~/.claude/settings.json` 요약 + medi_docs 존재 여부 |
| 2 | **처음 셋업** | "mediness 처음" / role 미설치 | role 합의 → install → `scaffold-medi-docs.sh` (cwd 에 9 카테고리) |
| 3 | **역할 변경** | "백엔드에서 인프라로" 등 단일 role 교체 | 기존 uninstall + 신규 install (dry-run 동의 후) |
| 4 | **다중 역할** | "풀스택이라 둘 다" | 추가 role install (기존 보존) |
| 5 | **환경 동기화** | "회사 CLAUDE.md 갱신" / "공통 settings 변경" | base/plugin 갱신 — v0.2 |
| 6 | **정리·재설치** | "다 지우고 다시" / 부분 실패 복구 | 모든 mediness plugin uninstall → 재셋업 — v0.2 |

v0.1 = 시나리오 1 우선, 2-4 보강. 5-6 v0.2.

## 강제 룰

### dry-run 필수

위험 명령 (`claude plugin install/uninstall`, `git config`) 호출 전:
1. **실행 계획 보고** — "다음 명령을 실행할 예정입니다: ..."
2. **사용자 동의 대기** — Yes/No 입력. 명시 동의 없으면 abort.
3. **실행 후 결과 보고** — exit code + 변경된 파일/설정 요약.

LLM 이 자동으로 install/uninstall 결정 X — 항상 사용자 손에 쥐어주기.

### idempotent

부분 설치 상태 (예: install 중 인터럽트) 에서 재호출해도 안전:
- 이미 설치된 plugin 재install 시 → no-op 보고
- `medi_docs/current/` 이미 존재 시 → scaffold no-op
- `~/.claude/settings.json` 키 존재 시 → 덮어쓰지 않고 사용자 확인

### 상태 확인 fallback

LLM 분기 실패 (의도 모호) 시 자동 시나리오 1 (상태 확인) — 잘못된 install/uninstall 위험 0.

## 보안 룰

- **위험 명령** (allowed_commands 박혀있음): `claude plugin install`/`uninstall`/`list`, `git config`. 모두 dry-run 동의 후 실행.
- **`~/.claude/settings.json` 수정 시 백업**: 변경 직전 `~/.claude/settings.json.bak.{YYYYMMDD-HHMMSS}` 복사. 사용자에게 백업 경로 보고.
- **시크릿 (예: `HARNESS_GITHUB_TOKEN`)**: 셸 rc / OS keychain 보관 권장. harness skill 자체는 token 저장·관리 X — 사용자가 직접 박음 ([[adr-0010-harness-mcp]] §3).
- **사용자 환경 손상 방지**: `rm -rf` / `chmod` / `chown` 호출 금지 (allow_commands 에 없음). 디렉토리 정리는 사용자가 직접 또는 `claude plugin uninstall` 경유.

## scaffold 룰 (medi_docs)

`scripts/scaffold-medi-docs.sh` 가 사용자 cwd 에 9 카테고리 박음 ([[adr-0008-medi-docs-scaffold]] §4):

```
medi_docs/current/
├── adr/
├── plan/
├── planning/
├── policy/
├── release-notes/
├── retrospective/
├── runbook/
├── spec/
└── test/
```

- 각 카테고리 = `template.md` + `README.md` 박힘 (base/medi-docs-templates/ 에서 복사).
- 이미 존재 시 → no-op (덮어쓰기 X).
- 사용자에게 "9 카테고리가 cwd 에 박혔습니다 — `medi_docs/current/`" 보고.

## Don't

- 명시 동의 없이 `claude plugin install/uninstall` 실행 금지.
- `~/.claude/settings.json` 백업 없이 수정 금지.
- 시크릿 (token 등) 을 harness skill 본문 / scripts / settings 에 hardcode 금지.
- 의도 모호 시 *추측해서* 시나리오 분기 X — 시나리오 1 (상태 확인) 으로 fallback.
