# Example: Entity Add — NEXUS Backend (reference 로드)

> NEXUS reference 모두 로드한 case. `sample-no-reference.md` 와 짝.

## 트리거

```
/entity-add issue_assignment
```

## reference 로드 결과

```
backend.md                       : 로드 (네이밍 / FK / 4계층 / ENUM 금지)
plan/erd/table-design.md        : 로드 (BaseEntity / TimestampMixin / 매핑 테이블 패턴)
plan/erd/database-rules.md      : 로드 (FK ON DELETE 정책 / 멀티테넌시)
사용처 디렉토리                   : 명시 — server/app/{models,schemas,repositories,services}/
                                  + server/alembic/versions/ + server/tests/api/
허용 예외                        : seeds/, alembic/
→ 5/5 로드. 충돌 없음.
```

## 출력

````markdown
## Entity Add 작업 보고

### 대상
- 엔티티: `issue_assignment` (Issue ↔ User 매핑 테이블)
- reference: `backend.md`, `plan/erd/table-design.md`, `plan/erd/database-rules.md`, 사용처 디렉토리 (5/5. 충돌 없음.)

### 1. Model — `server/app/models/issue.py` (기존 파일 확장)
- `class IssueAssignment(Base)` — 매핑 테이블 패턴
- 출처: `table-design.md §매핑 테이블` — 복합 PK = FK 두 개
- `issue_id` (UUID, FK Issue.id, ON DELETE CASCADE) + `user_id` (UUID, FK User.id, ON DELETE CASCADE)
- BaseEntity 미상속 (매핑 테이블) — TimestampMixin 만 (`created_at`)
- `assigned_at = created_at` (별 컬럼 X — TimestampMixin 활용)
- ENUM 미사용 — `role` (VARCHAR, Python Enum `AssignmentRole`)

### 2. Migration — `server/alembic/versions/`
- `docker compose exec server uv run python -m alembic revision --autogenerate -m "add issue_assignment"`
- autogenerate 한계 검토:
  - 인덱스: `ix_issue_assignment_user_id` (user 별 lookup) — **수동 추가**
  - FK ON DELETE: autogenerate 가 잡음 ✓
  - 복합 PK: autogenerate 가 잡음 ✓
- `docker compose exec server uv run python -m alembic upgrade head` 통과
- Model + revision 같은 commit

### 3. Schema — `server/app/schemas/issue.py` (기존 파일 확장)
- `IssueAssignmentCreateRequest` — issue_id, user_id, role
- `IssueAssignmentResponse` — `ConfigDict(from_attributes=True)`, 위 필드 + assigned_at
- 라우터에서 `model_validate(assignment)` 변환

### 4. Repository — `server/app/repositories/issue_repo.py` (기존 파일 확장)
- `class IssueAssignmentRepository(BaseRepository[IssueAssignment])` — `repositories/base.py` 의 BaseRepository 상속
- 도메인 쿼리: `list_by_user(user_id, company_id)` — 멀티테넌시 적용
- 비즈니스 룰 0 / `commit()` 0

### 5. Test — `tdd-cycle` 호출
- `/tdd-cycle issue_assignment` 인계 → Red → Green → Refactor
- 산출: `server/tests/api/test_issue_assignment_api.py` (8 tests)
- 회귀: 202/202 pass (baseline 194 + 신규 8)

### 사후 검증
- Model 비즈니스 로직 grep: 0 ✓
- Schema ORM import grep: 0 ✓
- Repository 비즈니스 룰 grep: 0 ✓
- Repository commit grep: 0 ✓
- alembic upgrade head: 통과 ✓
- 테스트 202/202 pass ✓
- 멀티테넌시 검증: `list_by_user` 가 `company_id` 필터 ✓

### 다음 단계
1. `/api-design issue` — Issue 라우터에 assignment 엔드포인트 추가 (`POST /issues/{id}/assignments`)
2. plan/api/issues.md 갱신 (사용자 손)
3. plan/erd/full-erd.md 의 매핑 테이블 섹션에 추가 (사용자 손)
````

## reference 로드 효과

NEXUS reference 가 있어서:
- 매핑 테이블 패턴 자동 적용 (`table-design.md`)
- FK ON DELETE CASCADE 자동 결정 (`database-rules.md §FK 정책`)
- 멀티테넌시 `company_id` 필터 자동 적용
- 디렉토리 위치 사용자 확인 단계 skip
- 기존 파일 확장 (별 파일 X) — `models/issue.py`, `schemas/issue.py`, `repositories/issue_repo.py`
