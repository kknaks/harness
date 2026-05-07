---
name: alembic-migration
description: Alembic 마이그레이션 운영 (autogenerate / forward-only / conflict 해소)
allowed_tools: [Read, Edit, Bash]
---

# Alembic Migration

스키마 변경 1 단위 = Alembic revision 1 개. autogenerate 사용 + 한계 6종 수동 보완 + downgrade 금지 (forward-only) + 동시 PR conflict 해소. `entity-add` SKILL 의 2단계 *본체* + 단독 스키마 변경 (FK / 인덱스 / server_default 등) 호출.

## When to use

- `entity-add` SKILL 의 2단계에서 호출됨
- 단독 스키마 변경 — FK 액션 변경 / 인덱스 추가 / 컬럼 reorder / 데이터 마이그레이션
- conflict 해소 — 동시 PR 두 개 모두 revision 추가 시
- prod 배포 전 revision 검토

## How to invoke

```
/alembic-migration new "<msg>"     # autogenerate revision 생성 + 한계 6종 검토
/alembic-migration apply           # upgrade head
/alembic-migration history         # revision 체인 확인
/alembic-migration merge           # conflict 해소 (head 두 개 merge)
```

후속:
1. **reference 로드** — `backend.md §배포` (forward-only 정책), 사용처 `<alembic-dir>` (`alembic.ini` + `env.py` 위치).
2. **autogenerate 한계 6종 검토** — 인덱스 / FK action / server_default / 컬럼 reorder / VARCHAR 길이 / CHECK constraint. 자동 생성 결과는 *초안* — 반드시 파일 열어 검토.
3. **forward-only 강제** — 잘못된 revision 발견 시 새 revision 으로 보정. prod 에서 downgrade 호출 X.
4. **conflict 해소** — `alembic heads` → `alembic merge` → merge revision commit.
5. **DDL 트랜잭션** — `db-transaction` reference 의 §DDL 참조 (revision 1 개 = 1 트랜잭션).

자세한 명령어·한계 6종·forward-only 호환성 매트릭스·conflict 해소는 [`rules.md`](rules.md). 운영 체크리스트는 [`checklist.md`](checklist.md). sample [`examples/`](examples/).

## 보안 고려사항

- `allow_commands` — `python -m alembic ...` (revision / upgrade / history / merge). prod 환경에서는 GHCR Action 자동 호출만, 메인테이너 수동 호출은 staging 까지.
- 동적 입력 (revision message) 처리: `printf %q` 또는 quoted expansion.
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\.env(\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\.(pem|key|p12|pfx)$\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\s+\S+|x-api-key:\s*\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환.
