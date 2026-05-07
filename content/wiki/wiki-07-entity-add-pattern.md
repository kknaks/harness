---
id: wiki-07
title: Entity Add Pattern
type: wiki
status: promoted
sources:
  - "[[sources-05-db-design]]"
related_to:
  - "[[wiki-03-api-design-pattern]]"
  - "[[wiki-04-tdd-cycle-pattern]]"
  - "[[wiki-05-refactor-layered-pattern]]"
  - "[[wiki-08-alembic-migration-pattern]]"
  - "[[wiki-09-db-transaction-reference]]"
tags: [wiki]
categories: [db-design, entity-lifecycle]
aliases: []
---

# Entity Add Pattern

> 합성·정리. sources-05 의 entity-add + Pydantic 스키마 부분에서 합성. **인간 검토 필요**.

## Summary

새 엔티티/도메인이 들어왔을 때의 5단 절차 — Model → Alembic revision → Schema (Request/Response) → Repository → Test. `wiki-03 (api-design)` = 엔드포인트 단위 짝, 본 wiki = *데이터* 단위. `wiki-04 (tdd-cycle)` 와 `wiki-05 (refactor-layered)` 의 4계층 책임을 *생성 시점* 에 적용.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 5단 절차 + 산출물 + 검증**

| 단계 | 산출물 | 본질 | 검증 |
|------|--------|------|------|
| 1. Model | ORM 클래스 (테이블 정의) | 엔티티 정체 박기 — PK / 컬럼 / 제약 / 관계 | 모델 import 가능 + Mixin 일관성 |
| 2. Migration | DDL revision | Model 변경의 *영속화 단위* — autogenerate + 수동 보완 | `upgrade head` 통과 + autogenerate 한계 항목 검토 |
| 3. Schema | Request / Response DTO | 입출력 *계약* — ORM 노출 차단 | Request·Response 클래스 분리 / `from_attributes=True` 설정 |
| 4. Repository | DB 접근 클래스 | 쿼리 *위치* 박기 — Service 가 DB 직접 안 만짐 | BaseRepository 상속 + 비즈니스 룰 0 |
| 5. Test | API 통합 테스트 | 계약 검증 + TDD Red → Green | wiki-04 의 사이클 적용 |

**2) 동기화 룰 (4계층 ↔ 5단 절차)**

```
Model 변경  ─┬─ Alembic revision  (한 PR / 한 commit)
            └─ Schema → Repository → Test  (다음 commit 가능, 단 같은 PR)
```

- **Model + Alembic 은 같은 commit** — Model 만 push 하면 `alembic upgrade head` 실패, revision 만 push 하면 ORM 동기화 깨짐.
- **Schema → Repository → Test 는 분할 가능** — 하지만 같은 PR 안에서. 미완 상태로 머지 금지.

**3) 흔한 실수 (grep 검출 가능)**

| 실수 | grep 패턴 | 교정 |
|------|----------|------|
| Model 안에 비즈니스 로직 | `def [a-z_]+\(self.*\):` 가 Model 클래스 안에 있음 | Service 로 이관 |
| Schema 가 ORM import | `from app.models import` 가 schemas/ 에 있음 | DTO 패턴 위반 — 재설계 |
| Repository 가 비즈니스 룰 | 상태 enum 비교 / 권한 체크 코드 | Service 로 이관 |
| Migration 누락 | `alembic upgrade head` 실패 | revision 추가 |
| Repository 가 commit | `db.commit()` 호출 | 미들웨어로 (`wiki-09` 참조) |

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

| 단계 | 위치 | 패턴 |
|------|------|------|
| Model | `server/app/models/{domain}.py` | `BaseEntity` 상속 (id UUID + created_at + updated_at + deleted_at) / **ENUM 금지** = VARCHAR + Python Enum |
| Migration | `server/alembic/versions/` | `docker compose exec server uv run python -m alembic revision --autogenerate -m "..."` |
| Schema | `server/app/schemas/{domain}.py` | `*Request` / `*Response` 분리 / `model_config = ConfigDict(from_attributes=True)` |
| Repository | `server/app/repositories/{domain}_repo.py` | `class XRepository(BaseRepository[X]): pass` (상속만으로 CRUD) |
| Test | `server/tests/api/test_{domain}_api.py` | conftest 의 `client` + `db_session` fixture 활용 |

**Pydantic 패턴** (스키마 단계 핵심):

```python
class IssueCreateRequest(BaseModel):
    title: str
    description: str | None = None

class IssueResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: UUID
    title: str

# Service:
issue = await self.repo.create(...)              # ORM
return IssueResponse.model_validate(issue)       # ORM → DTO

# 부분 업데이트:
patch = body.model_dump(exclude_unset=True, exclude_none=True)
await self.repo.update(issue, **patch, refresh=False)   # wiki-09 참조
```

다른 프레임워크 슬롯 — Spring Boot (`@Entity / Migration / DTO / Repository / @Test`), Django (`models.Model / makemigrations / serializer / Manager / TestCase`).

## References

- `sources-05-db-design` (entity-add 5단 + Pydantic 부분)
- 자매 wiki: `wiki-03-api-design-pattern` (엔드포인트 단위 짝)
- 자매 wiki: `wiki-04-tdd-cycle-pattern` (5단계 Test)
- 자매 wiki: `wiki-05-refactor-layered-pattern` (4계층 책임 — Schema/Service/Repo)
- 자매 wiki: `wiki-08-alembic-migration-pattern` (2단계 Migration 상세)
- 자매 wiki: `wiki-09-db-transaction-reference` (`refresh=False` 근거 / commit 책임)
- ADR 계보: `[[adr-XXXX-entity-add-skill]]` (예정)
