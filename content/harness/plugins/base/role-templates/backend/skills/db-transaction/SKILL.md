---
name: db-transaction
description: 트랜잭션 reference (ACID / 격리 수준 / commit·flush·rollback 책임 / refresh=False 함정) — 절차 SKILL 아님, 자매 SKILL 본문에서 lookup
allowed_tools: [Read]
asset_type: reference
---

# DB Transaction

> **reference 자산** (개념·룰 묶음). 절차 SKILL 아님 — 트리거는 *능동적 작업* 아닌 *다른 SKILL 호출 시 lookup*. `asset_type: reference` 마커 (ADR-0015) 로 식별.

DB 트랜잭션 *reference* — ACID + 격리 수준 + `commit/flush/rollback` 책임 분리 + savepoint + async session 라이프사이클 + `refresh=False` 함정. `refactor-layered` SKILL 의 grep 룰 *근거*, `entity-add` / `alembic-migration` SKILL 본문에서 1줄 참조로 인용.

## When to use

- `entity-add` SKILL 의 Service 단계에서 `flush()` 책임 lookup
- `alembic-migration` SKILL 의 DDL 트랜잭션 근거 lookup
- `refactor-layered` SKILL 의 grep 룰 (`db.commit()` 금지) 근거 lookup
- `MissingGreenlet` / `refresh=False` 함정 디버깅
- 격리 수준 결정 (READ COMMITTED 디폴트 외 필요 시)

## How to invoke

```
/db-transaction acid              # ACID + 격리 수준 표
/db-transaction lifecycle         # commit·flush·rollback 책임 분리
/db-transaction refresh           # refresh=False 함정 (왜 MissingGreenlet 나는지)
/db-transaction savepoint         # 부분 롤백 패턴
```

후속:
1. **lookup 후 자매 SKILL 로 복귀** — 이 reference 는 *정보 제공* 만, 코드 변경 X.
2. **NEXUS 슬롯 reference 로드** — `<middleware-file>` (commit/rollback 호출처), `BaseRepository.update(refresh=True)` 디폴트.
3. **fallback 매핑** — Django `atomic` / JPA `@Transactional` / TypeORM `@Transaction` (async/sync ORM 차이는 사용처별 확인).

자세한 ACID·격리·책임·savepoint·async session·refresh 함정·DDL 은 [`rules.md`](rules.md).

## 보안 고려사항

- `allow_commands` X — read-only reference. 코드 수정 안 함.
- 시크릿 차단 + 출력 마스킹 — 아래 패턴은 read 대상에서 제외하고, 출력에 잡히면 `***` 으로 마스킹.

| 카테고리 | 경로/이름 패턴 | 정규식 (예) |
|----------|----------------|-------------|
| dotenv | `.env`, `.env.*` (`.local`, `.production` 등) | `(^|/)\.env(\..+)?$` |
| 시크릿 디렉토리 | `secrets/`, `secret/`, `credentials/` | `(^|/)(secrets?|credentials)/` |
| 토큰 파일 | `*token*`, `*apikey*`, `*api_key*` | `(token|api[_-]?key)` (대소문자 무시) |
| 키 자료 | `*.pem`, `*.key`, `*.p12`, `*.pfx`, `id_rsa*` | `\.(pem|key|p12|pfx)$\|^id_rsa` |
| 인증 헤더값 | `Authorization: Bearer ...`, `x-api-key: ...` | `(Bearer\s+\S+|x-api-key:\s*\S+)` |

- 위 패턴 매치 시: 입력 거부 (read 단계) + 출력 발견 시 `***` 치환.
