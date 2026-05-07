# Entity Add Rules

> 스킬이 강제하는 룰셋·정책·금지 사항. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 룰 적용 시점에 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).

## 5단 절차

| 단계 | 산출물 | 본질 | 검증 |
|------|--------|------|------|
| 1. Model | ORM 클래스 | 엔티티 정체 박기 — PK / 컬럼 / 제약 / 관계 | 모델 import 가능 + Mixin 일관성 |
| 2. Migration | DDL revision | Model 변경의 *영속화 단위* — autogenerate + 수동 보완 | `upgrade head` 통과 + autogenerate 한계 항목 검토 |
| 3. Schema | Request / Response DTO | 입출력 *계약* — ORM 노출 차단 | Request·Response 클래스 분리 / `from_attributes=True` |
| 4. Repository | DB 접근 클래스 | 쿼리 *위치* 박기 — Service 가 DB 직접 안 만짐 | BaseRepository 상속 + 비즈니스 룰 0 |
| 5. Test | API 통합 테스트 | 계약 검증 + TDD Red → Green | `tdd-cycle` SKILL 사이클 적용 |

## 동기화 룰

```
Model 변경  ─┬─ Alembic revision  (한 PR / 한 commit)
            └─ Schema → Repository → Test  (다음 commit 가능, 단 같은 PR)
```

- **Model + Alembic 은 같은 commit** — Model 만 push 하면 `alembic upgrade head` 실패, revision 만 push 하면 ORM 동기화 깨짐.
- **Schema → Repository → Test 는 분할 가능** — 하지만 같은 PR 안에서. 미완 상태로 머지 금지.

## Pydantic 패턴 (3단계 핵심)

```python
class IssueCreateRequest(BaseModel):
    title: str
    description: str | None = None

class IssueResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)   # ORM → DTO 변환 허용
    id: UUID
    title: str

# Service:
issue = await self.repo.create(...)               # ORM 인스턴스
return IssueResponse.model_validate(issue)        # ORM → Pydantic

# 부분 업데이트:
patch = body.model_dump(exclude_unset=True, exclude_none=True)
await self.repo.update(issue, **patch, refresh=False)   # ← db-transaction reference
```

`refresh=False` 의 *왜* 는 `db-transaction` reference 의 §refresh 함정 참조.

## NEXUS 슬롯 (사용처 reference 로드)

| 단계 | 위치 | 패턴 |
|------|------|------|
| Model | `server/app/models/{domain}.py` | `BaseEntity` 상속 (id UUID + created_at + updated_at + deleted_at) / **ENUM 금지** = VARCHAR + Python Enum |
| Migration | `server/alembic/versions/` | `docker compose exec server uv run python -m alembic revision --autogenerate -m "..."` |
| Schema | `server/app/schemas/{domain}.py` | `*Request` / `*Response` 분리 |
| Repository | `server/app/repositories/{domain}_repo.py` | `class XRepository(BaseRepository[X]): pass` |
| Test | `server/tests/api/test_{domain}_api.py` | conftest fixture 활용 |

reference 부재 시 fallback: ORM 디렉토리 자동 추정 (Spring `@Entity`, Django `models.py`, TypeORM `@Entity`) + 사용자 확인.

## Don't

- **Model 안에 비즈니스 로직** (`def [a-z_]+` 메서드) — Service 로 이관
- **Schema 가 ORM import** (`from app.models import` 가 schemas/ 에 있음) — DTO 패턴 위반
- **Repository 가 비즈니스 룰** (상태 전이 / 권한 체크) — Service 로 이관
- **Repository 가 commit** (`db.commit()`) — 미들웨어로 (`db-transaction` reference 참조)
- **Migration 누락 push** — Model 만 push 시 `alembic upgrade head` 실패. 같은 commit 강제
- **Pydantic Request 와 Response 클래스 공유** — 입출력 필드 분리 원칙
- **Repository 에서 도메인 룰 grep**:
  ```bash
  grep -nE "if .*\.(status|state) ==" server/app/repositories/*.py   # 0 이어야 함
  ```
