---
id: wiki-09
title: DB Transaction Reference
type: wiki
status: promoted
sources:
  - "[[sources-05-db-design]]"
related_to:
  - "[[wiki-05-refactor-layered-pattern]]"
  - "[[wiki-07-entity-add-pattern]]"
  - "[[wiki-08-alembic-migration-pattern]]"
tags: [wiki]
categories: [db-design, transaction]
aliases: [transaction-reference]
asset_type: reference
---

# DB Transaction Reference

> 합성·정리. sources-05 의 트랜잭션 부분에서 합성. **인간 검토 필요**.

## Summary

DB 트랜잭션 *reference* (절차 SKILL 아님) — ACID + 격리 수준 + `commit/flush/rollback` 책임 분리 + savepoint + async session 라이프사이클 + `refresh=False` 함정. `wiki-05 (refactor-layered)` 가 grep 룰만 박은 부분의 *근거* 를 풀어 박아 entity-add / alembic SKILL 본문에서 1줄 참조 가능.

## Synthesis

### 공용 골격 (project-agnostic)

**1) ACID**

| 속성 | 의미 | Postgres 디폴트 |
|------|------|----------------|
| Atomicity | 전부 성공 or 전부 롤백 | 트랜잭션 단위 |
| Consistency | 제약 위반 시 롤백 | FK / CHECK / UNIQUE |
| Isolation | 동시 트랜잭션 격리 | READ COMMITTED |
| Durability | commit 후 영속 | WAL fsync |

**2) 격리 수준**

| 수준 | phantom | non-repeatable | dirty | 사용처 |
|------|:---:|:---:|:---:|------|
| READ COMMITTED (디폴트) | ✓ | ✓ | ✗ | 거의 모든 API |
| REPEATABLE READ | ✓ | ✗ | ✗ | 같은 트랜잭션 다회 read 일관성 (집계 / 잔액) |
| SERIALIZABLE | ✗ | ✗ | ✗ | 회피 — 직렬화 실패 시 retry 부담 |

**기본 가정**: 모든 API = READ COMMITTED. 격리 강화는 *해당 Service 메서드 안에서만* `SET TRANSACTION ISOLATION LEVEL ...` 일시 변경.

**3) commit / flush / rollback 책임 분리**

| 호출 | 누가 | 언제 | 효과 |
|------|------|------|------|
| `flush()` | Service | INSERT/UPDATE 후 ID/FK 필요 시 | SQL 실행, 트랜잭션 *유지* |
| `commit()` | 미들웨어 | 요청 정상 종료 직전 | WAL fsync, 트랜잭션 *닫음* |
| `rollback()` | 미들웨어 | 예외 핸들러 | 변경 버림, 트랜잭션 닫음 |

**Service 가 commit 하면 안 되는 이유** — 한 요청 = 한 트랜잭션. Service A 가 commit 했는데 같은 요청의 Service B 에서 예외 → A 변경은 *이미 영속*, 부분 실패. 미들웨어가 닫아야 요청 단위 원자성 보장.

**4) savepoint (부분 롤백)**

```python
async with db.begin_nested():    # SAVEPOINT
    try:
        await risky_op()         # 실패해도 바깥 트랜잭션은 살아있음
    except SpecificError:
        pass                     # 자동 ROLLBACK TO SAVEPOINT
# 바깥 트랜잭션 계속
```

사용처 — 일괄 처리에서 *일부 실패는 무시* 하고 나머지 commit (배치 import row-level 실패).

**5) async session 라이프사이클**

```
request 진입
  └─ Depends(get_db) → AsyncSession 생성 (begin)
      └─ Router → Service (.flush 만)
          └─ Service → Repository (SQL)
  └─ response 반환 직전
      └─ middleware → commit (정상) / rollback (예외)
      └─ session close
```

`begin()` 은 *암묵적* — 첫 SQL 실행 시 트랜잭션 자동 시작. 명시적 `async with db.begin():` 일반적으로 불필요 (미들웨어가 다룸).

**6) `refresh=False` 함정 (왜 그런가)**

`session.refresh(obj)` 디폴트 호출 → DB 최신값으로 ORM 동기화. 부작용: **eager-load 된 관계 (`selectinload` / `joinedload`) 가 expire**.

이후 `model_validate(obj)` 가 그 관계 필드 읽으려 하면 → SQLAlchemy lazy load 시도 → async session 의 greenlet 컨텍스트 밖이면 `MissingGreenlet` 예외.

**룰**:
- eager-load 자식 가진 객체 update = `refresh=False` 필수
- `func.now()` 대신 `datetime.now(UTC)` 사용 (refresh 안 하면 `func.now()` 객체 그대로 남아 직렬화 실패)

**7) DDL 트랜잭션 (Alembic)**

Alembic revision 1 개 = 1 트랜잭션 (Postgres 는 DDL 트랜잭션 지원). `op.*` 호출 안에서 commit X — Alembic runner 가 revision 끝에 commit / 실패 시 rollback. wiki-08 의 forward-only 정책과 정합.

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

- **미들웨어 commit/rollback**: `server/app/main.py` 또는 `core/middleware.py` — request scope 트랜잭션 핸들러
- **session Depends**: `server/app/core/deps.py` `get_db()` — `AsyncSession` yield
- **BaseRepository**: `server/app/repositories/base.py` — `update(obj, refresh=True)` 디폴트
- **grep 룰** (`wiki-05` 와 정합):
  ```bash
  grep -nE "db\.commit\(\)" server/app/services/   # 0 이어야 함
  grep -nE "db\.commit\(\)" server/app/repositories/ # 0 이어야 함
  ```
- **`refresh=False` 적용 대상**: eager-loaded 관계 가진 객체 update (`assignments`, `leaders`, `members`, `job_roles` 등 관계 필드 보유)

다른 ORM 매핑 — Django (`atomic` 데코레이터 / `transaction.on_commit`), TypeORM (`@Transaction` / `EntityManager.transaction`), JPA (`@Transactional` / `Propagation`). 책임 분리 원칙 (Service flush / 외곽 commit) 은 ORM 무관.

## References

- `sources-05-db-design` (트랜잭션 부분)
- 자매 wiki: `wiki-05-refactor-layered-pattern` (grep 룰 짝 — 본 wiki 가 *근거* 제공)
- 자매 wiki: `wiki-07-entity-add-pattern` (Service flush 호출처)
- 자매 wiki: `wiki-08-alembic-migration-pattern` (DDL 트랜잭션)
- ADR 계보: `[[adr-XXXX-db-transaction-reference]]` (예정)
