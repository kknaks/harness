# Example: Backend Rules — NEXUS Backend (reference 로드)

> 사용처 프로젝트가 `plan/api/`, `plan/erd/`, `plan/design-standards/`, `plan/refactor/`, `CLAUDE.md` 보유 → 5 슬롯 모두 로드한 case sample. `sample-no-reference.md` 와 짝.

## 트리거

```
/backend-rules tdd-cycle issue
```

## reference 로드 결과

```
plan/api/issues.md                    : 로드 (~15 endpoint, request/response 형식)
plan/erd/database-rules.md            : 로드 (UUID PK, soft delete, multi-tenancy)
plan/erd/table-design.md              : 로드 (BaseEntity + Mixin 패턴)
plan/design-standards/coding-convention.md : 로드 (black 120, ruff, mypy)
plan/design-standards/testing-strategy.md  : 로드 (pytest, fixture, mock 룰)
plan/refactor/re6-layered-architecture.md  : 로드 (issues 도메인 = 4계층 정렬 완료 상태)
CLAUDE.md                             : 로드 (Repository 룰, import 컨벤션)
→ 7/7 reference 로드. 충돌 없음.
```

## 출력 (tdd-cycle 단계)

````markdown
## Backend Rules 작업 보고

### 대상
- 단계: 2-3. tdd-cycle (Red → Green)
- 도메인: `issue`
- reference: `plan/api/issues.md`, `plan/erd/database-rules.md`, `plan/erd/table-design.md`, `plan/design-standards/{coding-convention,testing-strategy}.md`, `CLAUDE.md` (7/7. 충돌 없음.)

### Red — 테스트 작성

`tests/api/test_issue.py`:
- `TestCreateIssue` 클래스 + 6 메서드 (test-design SKILL 의 시나리오 표 기반)
- request/response 는 `plan/api/issues.md §POST /issues` 의 형식 그대로
- fixture: `issue_mother`, `admin_api_client.issues` (CLAUDE.md §Repository 룰 적용)

```bash
docker compose exec server uv run pytest tests/api/test_issue.py
# → 6 tests failed (구현 0)  ✓ Red 통과
```

### Green — 4계층 구현

생성 파일:
- `server/app/schemas/issue.py` — `IssueCreateRequest`, `IssueResponse`, `IssueListResponse` (Pydantic v2, `model_validate` 변환)
- `server/app/repositories/issue.py` — `IssueRepository(BaseRepository[Issue])` + 도메인 쿼리 (`list_by_project_with_assignee_join`)
- `server/app/services/issue.py` — `class IssueService` + `create()` / `list()` / `accept()` (Repository 조합, Request → Response 변환)
- `server/app/routers/issue.py` — `@router.post("/issues", response_model=IssueResponse)` + 인증 Depends

수정 파일:
- `server/app/models/issue.py` — `BaseEntity` 상속, `MultiTenantMixin` 으로 `company_id` 자동 (DB 룰 §multi-tenancy)
- `server/app/main.py` — router 등록

```bash
docker compose exec server uv run pytest tests/api/test_issue.py
# → 6 passed in 0.34s  ✓ Green 통과
```

### 검증

```bash
# Router DB 직접 호출
grep -n "select\|db\.execute\|db\.add\|db\.flush" server/app/routers/issue.py
# → 0 hits  ✓

# Service SQLAlchemy 직접
grep -n "^from sqlalchemy import.*select" server/app/services/issue.py
# → 0 hits  ✓

# Response DTO 누락
grep -L "response_model=" server/app/routers/issue.py
# → 0 hits  ✓ (모든 endpoint 가 response_model 보유)
```

reference 출처 박힘:
- 멀티테넌시: `plan/erd/database-rules.md §multi-tenancy` (company_id 자동 필터)
- BaseEntity: `plan/erd/table-design.md §BaseEntity` (id / created_at / updated_at / deleted_at)
- Repository 룰: `CLAUDE.md §Repository 룰` (`get_by_xxx` 추가 금지 — `BaseRepository.get_all(filter=...)` 재사용)
- 4계층: `plan/refactor/re6-layered-architecture.md` (issues 정렬 패턴 따름)

### 다음 단계
1. ✓ Refactor 단계 — 이미 4계층 정렬 상태이므로 추가 작업 없음
2. `/code-review server/app/routers/issue.py server/app/services/issue.py` (자매 SKILL) — 사후 검토
````

## reference 로드의 가치

`sample-no-reference.md` (fallback) 와 비교하면:
- **reference 로드 정확도** — fallback 의 "위치 추정" 대신 *명시 출처* (`plan/api/issues.md`, `plan/erd/database-rules.md` 등)
- **검증 자동화** — grep 명령에 *실제 디렉토리 경로* 박힘 (`server/app/routers/issue.py`)
- **컨벤션 준수** — Repository 룰 (CLAUDE.md), BaseEntity (table-design.md), multi-tenancy (database-rules.md) 모두 *reference 의 §* 인용
- **회귀 안정성** — `plan/refactor/re6-layered-architecture.md` 의 진행 상태 추적 → 이미 정렬된 도메인 vs 정렬 필요 도메인 자동 구분

reference 충돌 시 [`rules.md` §reference 로드 모델 §충돌 룰](../rules.md) 참조 — 우선순위 낮은 번호 (1 = `plan/api/`) 우선 + 충돌 자체를 §대상 §reference 에 박는다.
