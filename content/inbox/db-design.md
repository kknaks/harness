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
