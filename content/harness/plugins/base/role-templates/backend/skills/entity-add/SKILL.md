---
name: entity-add
description: 새 엔티티 추가 5단 절차 (Model → Alembic → Schema → Repository → Test)
allowed_tools: [Read, Edit, Bash]
---

# Entity Add

새 엔티티/도메인이 들어왔을 때 5단 절차 (Model → Alembic → Schema → Repository → Test). 데이터 단위 작업의 *짝* — `api-design` (엔드포인트 단위) 와 페어. 4계층 책임표 (`refactor-layered`) 를 *생성 시점* 에 적용. 트랜잭션 함정은 `db-transaction` reference 로 lookup.

## When to use

- 새 도메인/엔티티 추가 — `User`, `Issue` 같은 신규 테이블 생성
- 기존 엔티티에 *관계 컬럼* 추가 시 (Model + Migration + Schema 동기화 필요)
- `api-design` 호출 *직전* — 엔드포인트보다 데이터 단위 먼저

## How to invoke

```
/entity-add <entity-name>          # 5단 절차 가이드
/entity-add <entity-name> scan     # 사전 스캔 (모델·스키마·repo 누락 검출)
```

후속:
1. **reference 로드** — `backend.md` (네이밍 / PK·FK 규칙 / 4계층), `plan/erd/table-design.md` (BaseEntity Mixin), 사용처 `<models-dir>` / `<schemas-dir>` / `<repositories-dir>`.
2. **5단 절차** — Model → Alembic revision → Schema (Request/Response) → Repository → Test.
3. **동기화 룰** — Model 변경 + Alembic revision *같은 commit*. 누락 시 `alembic upgrade head` 실패.
4. **흔한 실수 grep** — Model 비즈니스 로직 / Schema ORM import / Repository commit 등 5종.
5. **Migration 본체** — 2단계는 `alembic-migration` SKILL 호출 (별 SKILL).
6. **트랜잭션 함정** — Service 단계 `refresh=False` 룰은 `db-transaction` reference 참조.

자세한 5단 절차표·산출물·검증 명령은 [`rules.md`](rules.md). 운영 체크리스트는 [`checklist.md`](checklist.md). sample [`examples/`](examples/).

## 보안 고려사항

- `allow_commands` — alembic 명령 (`python -m alembic revision/upgrade/history`) + grep (read-only) + 테스트 실행. 모두 사용처 컨테이너 내부.
- 동적 입력 (entity-name / 디렉토리 path) 처리: `printf %q` 또는 quoted expansion. entity-name 은 kebab-case / snake_case 검증 후 사용.
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\.env(\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\.(pem|key|p12|pfx)$\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\s+\S+|x-api-key:\s*\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환.
