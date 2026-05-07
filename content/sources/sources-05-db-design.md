---
id: sources-05
title: DB 설계 (FastAPI + Alembic + Pydantic + SQLAlchemy)
type: sources
status: promoted
sources:
  - "[[db-design.md]]"
  - "[[sources-03-backend-rules]]"
tags: [sources, db, sqlalchemy, alembic, pydantic, transaction, fastapi]
aliases: [db-design, entity-lifecycle, db-transaction]
---

# DB 설계 (FastAPI + Alembic + Pydantic + SQLAlchemy)

> 1차 가공 = 원본 박제. 이후 불변. 원본의 정체(이름·목적)를 명확히 한 채 보존한다.

## 정체 (Identification)

**원본**: `content/inbox/db-design.md` (시드 outline. backend-rules 4 SKILL 이 다루지 않는 DB 쪽 박제 의도)

**무엇인가 (한 줄)**:

NEXUS 백엔드 (FastAPI + Alembic + Pydantic v2 + SQLAlchemy 2.0 async + PostgreSQL) 의 **DB 작업 라이프사이클** SKILL 시드 — `backend-rules` (4계층 컨벤션) 와 `refactor-layered` (라우터 정렬) 가 *전제* 만 깔고 절차로는 다루지 않는 4개 절차 묶음: (1) 새 엔티티 추가 (Model → Alembic revision → Pydantic Schema → Repository → 테스트), (2) Alembic 마이그레이션 운영 (autogenerate / downgrade 금지 / conflict 해소), (3) Pydantic 스키마 설계 (입출력 분리, `ConfigDict(from_attributes=True)`, `model_validate(orm)`), (4) **트랜잭션** (ACID + 격리 수준 + `commit/flush/rollback` 책임 분리 + `refresh=False` 함정 + async session 라이프사이클).

**왜 보존하는가**:

기존 `sources-03-backend-rules` 가 *컨벤션 reference* (테이블 3분류 / 네이밍 / PK·FK 규칙 / JSONB·TIMESTAMP 룰 / 디렉토리) 와 *라우터 정렬 절차* 까지는 박제했지만, **새 도메인이 들어왔을 때의 DB 작업 절차** 와 **트랜잭션 경계 의사결정** 은 빠져 있다 — 4계층 책임표(`refactor-layered.md`)는 *flush 는 Service / commit 은 미들웨어* 라고 *결과* 만 박았고, *왜 그런 분리인지·언제 savepoint 가 필요한지·격리 수준 선택 기준* 은 다루지 않는다.

이 sources 는 다음 단계 (wiki 합성 → ADR → harness/skill 산출) 에서 다음에 기여한다:

- (a) **`entity-add` SKILL 후보** — 새 엔티티/도메인 추가 시 5단 절차(Model → Alembic → Schema → Repo → 테스트). `api-design` (= 엔드포인트 단위) 의 짝.
- (b) **`alembic-migration` SKILL 후보** — autogenerate 사용 절차 + downgrade 금지 정책 (backend.md §배포 와 정합) + conflict 해소 + prod 마이그레이션 룰. backend-rules 의 `plan/erd/migrations.md` 참조 1줄을 *실행 가능 절차* 로 풀어냄.
- (c) **`db-transaction` reference (또는 SKILL)** — ACID / 격리 수준 / `commit/flush/rollback` 책임. `refactor-layered.md` 가 grep 룰 (`db.commit() 금지` 등) 만 박은 부분의 *근거* 를 reference 로 박제. SKILL 인지 wiki reference 인지는 wiki 단계에서 판정.
- (d) **Pydantic 스키마 설계** — 단독 SKILL 보다는 (a) entity-add 안에 흡수가 자연스러움. 분량 보고 wiki 합성 시 결정.

## 본문 (raw 인용)


~~~markdown
# DB 설계

> 백엔드 SKILL 후보. backend-rules (4계층 / api-design / tdd-cycle / refactor-layered) 가 다루지 않는 **DB 쪽** 만 박제.

## 다룰 것

- 새 엔티티 추가 절차 — Model → Alembic revision → Pydantic Schema (Request/Response) → Repository
- Alembic 마이그레이션 — autogenerate 사용 / downgrade 금지 / conflict 해소
- Pydantic 스키마 설계 — 입출력 분리, `ConfigDict(from_attributes=True)`, `model_validate(orm)`
- **트랜잭션 개념** — ACID / 격리 수준 / commit·flush·rollback 책임 (Service = flush, 미들웨어 = commit) / `refresh=False` 함정 / async session 라이프사이클

## 스택

FastAPI + Alembic + Pydantic v2 + SQLAlchemy 2.0 async + PostgreSQL

## 메모

(추가 메모 박을 자리 — 사용자 dump)

~~~

## 보강 (sources 단계 polish)

원본은 *outline* 수준이라 sources 단계에서 4 토픽의 *실체* 를 박제. wiki 단계는 이 실체를 SKILL 의 절차·체크리스트·grep 룰로 가공.

### 1. 새 엔티티 추가 5단 절차

```
1. Model      → app/models/{domain}.py     (BaseEntity 상속, ENUM 금지 = VARCHAR + Python Enum)
2. Alembic    → python -m alembic revision --autogenerate -m "add {entity}"
              → 생성된 revision 수동 검토 (autogenerate 한계 §2 참조)
3. Schema     → app/schemas/{domain}.py    (*Request / *Response 분리, ConfigDict(from_attributes=True))
4. Repository → app/repositories/{domain}_repo.py  (class XRepository(BaseRepository[X]) 상속만으로 CRUD)
5. Test       → tests/api/test_{domain}_api.py  (TDD = wiki-04 사이클 적용)
```

**동기화 룰**: Model 변경과 Alembic revision 은 *동일 PR* 안에서 같이. Model 수정 후 revision 누락 시 `alembic upgrade head` 실패 → CI 차단. revision 만 있고 Model 안 바뀐 경우도 동일.

### 2. Alembic 운영

**명령어**:
```bash
docker compose exec server uv run python -m alembic revision --autogenerate -m "<msg>"
docker compose exec server uv run python -m alembic upgrade head
docker compose exec server uv run python -m alembic history
```

**autogenerate 가 못 잡는 것** (수동 보완 필수):
- 인덱스 변경 (`ix_*`, UNIQUE)
- FK ON DELETE / ON UPDATE 액션 변경
- `server_default` 변경 / 추가
- 컬럼 reorder (Postgres 는 reorder 불가 — drop + add 로 풀어 작성)
- VARCHAR 길이 변경
- CHECK constraint

**downgrade 금지 정책**:
- `revision()` 의 `def downgrade()` 작성은 하되 *prod 에서 호출 X*. backend.md §배포 = forward-only 마이그레이션. 잘못된 revision 발견 시 = 새 revision 으로 보정.
- 이유: prod 무중단 배포 (구 코드 + 신 스키마 = OK / 신 코드 + 구 스키마 = 깨짐). downgrade 는 항상 후자.

**conflict 해소** (동시 PR 두 개 모두 revision 추가했을 때):
1. 늦게 머지하는 쪽 pull 후 alembic head 가 둘이 됨 → `alembic heads` 로 확인
2. `alembic merge -m "merge" <head1> <head2>` → merge revision 생성
3. merge revision 만 추가 commit, push

### 3. Pydantic 스키마 설계

```python
class IssueCreateRequest(BaseModel):
    title: str
    description: str | None = None

class IssueResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)  # ORM → DTO 변환 허용
    id: UUID
    title: str
    created_at: datetime

# Service 안에서:
issue: Issue = await self.repo.create(...)        # ORM 인스턴스
return IssueResponse.model_validate(issue)        # ORM → Pydantic

# 부분 업데이트:
patch_data = body.model_dump(exclude_unset=True, exclude_none=True)
await self.repo.update(issue, **patch_data, refresh=False)  # §4 함정 참조
```

**룰**: Request 와 Response 클래스 공유 X (입출력 필드 분리). SQLAlchemy 모델 import 금지 (타입 힌트용도 X). 검증은 `Annotated[str, Field(min_length=1)]` 같은 Pydantic 어노테이션으로.

### 4. 트랜잭션 (reference)

#### ACID

| 속성 | 의미 | Postgres 디폴트 |
|------|------|----------------|
| Atomicity | 전부 성공 or 전부 롤백 | 트랜잭션 단위 보장 |
| Consistency | 제약 위반 시 롤백 | FK / CHECK / UNIQUE |
| Isolation | 동시 트랜잭션 격리 | READ COMMITTED |
| Durability | commit 후 영속 | WAL fsync |

#### 격리 수준

| 수준 | phantom | non-repeatable read | dirty read | 사용처 |
|------|:------:|:------:|:------:|------|
| READ COMMITTED (디폴트) | ✓ | ✓ | ✗ | 거의 모든 API |
| REPEATABLE READ | ✓ | ✗ | ✗ | 같은 트랜잭션에서 여러 번 읽고 *같은 결과 보장* 필요 (집계 / 잔액 계산) |
| SERIALIZABLE | ✗ | ✗ | ✗ | 회피 — Postgres 는 직렬화 실패 시 retry 필요 (예외 처리 부담) |

**기본 가정**: 모든 API = READ COMMITTED. 격리 강화가 필요하면 *해당 Service 메서드 안에서만* `await db.execute(text("SET TRANSACTION ISOLATION LEVEL ..."))` 로 일시 변경.

#### commit / flush / rollback 책임 분리

| 호출 | 누가 | 언제 | 효과 |
|------|------|------|------|
| `db.flush()` | Service | INSERT/UPDATE 후 ID/FK 가 필요할 때 | SQL 실행 (ID 발급), 트랜잭션 *유지* |
| `db.commit()` | 미들웨어 (request scope) | 요청 정상 종료 직전 | WAL fsync, 트랜잭션 *닫음* |
| `db.rollback()` | 미들웨어 (예외 핸들러) | 예외 발생 | 변경 버림, 트랜잭션 닫음 |

**Service 가 commit 하면 안 되는 이유**: 한 요청 = 한 트랜잭션. Service A 가 commit 했는데 같은 요청의 Service B 에서 예외 → A 의 변경은 *이미 영속*, 부분 실패 상태. 미들웨어가 닫아야 요청 단위 원자성 보장.

#### savepoint (부분 롤백)

```python
async with db.begin_nested():    # SAVEPOINT
    try:
        await risky_op()         # 실패해도 바깥 트랜잭션은 살아있음
    except SpecificError:
        # 자동 ROLLBACK TO SAVEPOINT
        pass
# 바깥 트랜잭션 계속
```

**사용처**: 일괄 처리 중 *일부 실패는 무시* 하고 나머지를 commit 해야 할 때 (예: 배치 import 의 row-level 실패).

#### async session 라이프사이클

```
request 진입
  └─ Depends(get_db) → AsyncSession 생성 (begin)
      └─ Router → Service (.flush 만)
          └─ Service → Repository (SQL)
  └─ response 반환 직전
      └─ middleware → commit (정상) / rollback (예외)
      └─ session close
```

`begin()` 은 *암묵적* — 첫 SQL 실행 시 트랜잭션 자동 시작. 명시적 `async with db.begin():` 은 일반적으로 불필요 (미들웨어가 다룸).

#### `refresh=False` 함정 (왜 그런가)

`BaseRepository.update()` 디폴트는 `session.refresh(obj)` 호출 — DB 의 최신 값으로 ORM 인스턴스 동기화. 부작용: **eager-load 된 관계 (`selectinload`, `joinedload`) 가 expire** 됨.

이후 Pydantic `model_validate(obj)` 가 그 관계 필드를 읽으려 하면 → SQLAlchemy 가 lazy load 시도 → async session 의 greenlet 컨텍스트 밖이면 `MissingGreenlet` 예외.

**룰**: eager-load 한 자식을 가진 객체를 update 할 때 = `refresh=False` 필수. 그리고 `func.now()` 대신 `datetime.now(UTC)` 사용 (refresh 안 하면 `func.now()` 객체가 그대로 남아 직렬화 실패).

---

이 4 토픽이 wiki 분할 기준:

- **(1) entity-add** — 1 SKILL (절차 + 체크리스트 + grep)
- **(2) alembic** — 1 SKILL (명령어 + autogenerate 한계 + conflict 해소). entity-add 의 한 단계지만 *마이그레이션 단독 작업* (스키마 변경) 이 빈번하면 분리.
- **(3) pydantic** — 단독 SKILL 보다는 entity-add 안 통합 권장 (분량 작음).
- **(4) 트랜잭션** — *reference wiki* (절차가 아니라 개념 + 룰). entity-add / alembic 두 SKILL 이 본문에서 1 줄로 참조.

→ 권장: **2 SKILL (entity-add + alembic) + 1 reference wiki (transaction)**. wiki 합성 단계에서 분량 보고 최종 결정.
