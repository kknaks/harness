---
name: refactor-layered
description: 라우터 1개를 4계층(Schema/Router/Service/Repository)으로 정렬하는 리팩토링 절차 + 체크리스트 + 결과 보고
---

# 라우터 1개 4계층 정렬 리팩토링

## 실행 조건
- `plan/refactor/re6-layered-architecture.md` 대상 라우터 작업 시
- 새 라우터/도메인을 처음부터 추가할 때 (신규도 이 절차를 따른다)
- 기존 라우터를 수정/확장하는 PR 에서 해당 라우터가 아직 4계층 정렬 전이면 "작업 전 정렬" 원칙으로 먼저 이 절차를 실행

## 참고 문서 (필수)
- `.claude/rules/backend.md` → `## 4계층 아키텍처 (필수 — RE6)` 섹션 (계층 책임/금지/허용)
- `plan/refactor/re6-layered-architecture.md` (전체 플랜 + 도메인별 현황표)
- `server/app/repositories/base.py` (BaseRepository API)
- `server/app/schemas/common.py` (DataResponse, PaginatedResponse, ErrorResponse)
- `plan/api/overview.md` (응답/에러 포맷, 페이지네이션)
- `plan/api/{도메인}.md` (대상 라우터의 엔드포인트 스펙)

---

## 절차 (라우터 1개 단위)

### 0. 사전 스캔 — "현재 어긋난 지점" 숫자로 확정
대상 라우터 파일 이름을 `R` (예: `harness`), 연결 서비스를 `S` (예: `harness_service`) 라고 하면:

```bash
# Router: DB 직접 호출
grep -nE "select\(|db\.execute|db\.add\(|db\.flush\(|db\.commit\(" server/app/routers/${R}.py

# Router: response_model 누락
grep -nE "@router\.(get|post|put|patch|delete)" server/app/routers/${R}.py
grep -c "response_model=" server/app/routers/${R}.py

# Router: Model/Repository 직접 import
grep -nE "^from app\.(models|repositories)" server/app/routers/${R}.py

# Service: DB 직접 호출
grep -nE "select\(|db\.execute|db\.add\(|db\.flush\(|db\.commit\(" server/app/services/${S}.py

# Service: dict 파라미터
grep -nE "data: dict|: Dict\b|: dict\b" server/app/services/${S}.py

# Service: SQLAlchemy 모델 반환 타입
grep -nE "^async def.*-> (list\[)?[A-Z][a-zA-Z]*\b" server/app/services/${S}.py
```

위 수치를 **결과 보고 "Before" 칼럼**에 기록한다.

### 1. Schema 계층 — Request/Response DTO 확보
`server/app/schemas/{도메인}.py` 를 열고 엔드포인트별로:

- **입력**: `{Action}{Resource}Request` — Path/Query/Body 를 Pydantic 으로. 라우터 시그니처에서 받음
- **출력**: `{Resource}Response` (단건), `{Resource}ListResponse` (목록 — data: list[..] + pagination). 전부 `DataResponse[...]` 또는 `PaginatedResponse[...]` 로 감싸 반환
- **내부 DTO**: 서비스끼리 또는 서비스↔레포 사이에 ORM 객체 대신 전달할 필요가 있으면 `{Resource}DTO` 작성 (필요 시에만, 남용 금지)
- `ConfigDict(from_attributes=True)` 설정 — ORM → DTO 변환용
- Request/Response 필드를 공유 base 로 묶지 않는다 (입출력 분리 원칙)

### 2. Repository 계층 — 쿼리 이관
`server/app/repositories/{도메인}_repo.py`:

- 단순 CRUD: `class XRepository(BaseRepository[X]): pass` 유지 (확장 불필요)
- 복잡 쿼리(JOIN/집계/eager load/재귀): Service 에 있던 `select()` 를 **통째로 Repository 메서드로 이관**
- 반환은 ORM 인스턴스(또는 `list[ORM]`, `tuple[list[ORM], int]`). DTO 변환은 Service 책임
- 트랜잭션: `flush` 까지만, `commit` 금지
- 도메인 Repository 파일이 없으면 `plan/erd/table-design.md` 의 모델 파일 구분에 맞춰 신설

### 3. Service 계층 — 클래스화 + DTO 입출력
`server/app/services/{도메인}_service.py`:

- 함수형 → 클래스 (`class XService`). 생성자: `def __init__(self, db: AsyncSession)` + 필요한 Repository 인스턴스 생성
- 기존 모듈 함수 호출부(다른 서비스/라우터)가 있으면 `get_x_service(db)` 팩토리 함수로 호환 레이어 제공하거나, Router 에서 `XService(db)` 로 직접 인스턴스화
- 메서드 시그니처: **Request DTO 또는 스칼라(id/uuid) 입력 → Response DTO/Internal DTO 출력**
  - `data: dict` 파라미터 제거. 라우터에서 이미 Pydantic 검증된 DTO 를 그대로 받음
  - ORM 객체를 그대로 반환하지 않음 — `Response.model_validate(orm)` 으로 변환
- DB 접근은 반드시 `self.repo.*()` 경유. 서비스 안에 `select()` 금지
- 비즈니스 규칙(상태 전이/권한/검증)과 트랜잭션 조율만 남긴다

### 4. Router 계층 — 얇게
`server/app/routers/{도메인}.py`:

- 모든 엔드포인트에 `response_model=DataResponse[XResponse]` 또는 `PaginatedResponse[XResponse]` 지정
- 시그니처: `body: XRequest`, `path_param: UUID`, `query: Annotated[XQuery, Depends()]`, `db: AsyncSession = Depends(get_db)`, `user = Depends(get_current_active_user)`
- 본문: `svc = XService(db); result = await svc.xxx(body); return DataResponse(data=result)`
- Router 파일에서 **`select() / db.execute() / db.add()` 등 모든 직접 DB 호출 삭제**
- Router 내부 헬퍼 함수(쿼리성) 전부 Service/Repository 로 이관
- `from app.models...` import 제거 (SQLAlchemy 모델을 Router 가 알 필요 없음)

### 5. 테스트 확인
```bash
# 해당 도메인 테스트만 먼저
docker compose exec server uv run pytest tests/api/test_{도메인}_api.py -v

# 통합: 전체 테스트 Green
docker compose exec server uv run pytest
```
- 테스트가 기존 응답 포맷(dict vs DataResponse)과 어긋나면 **테스트를 새 포맷에 맞춰 갱신**한다 — API 계약이 변경된 것은 아니므로 `data.*` 접근 경로만 바꿔주면 됨. 단, 기존 클라이언트 호환이 필요하면 라우터 응답 포맷을 유지하는 쪽으로 Response DTO 를 설계한다 (기본: 유지).

### 6. 린트/포맷
```bash
docker compose exec server uv run ruff check server/app/routers/${R}.py server/app/services/${S}.py server/app/repositories/${도메인}_repo.py server/app/schemas/${도메인}.py
docker compose exec server uv run black --check ...
```

### 7. 금지 패턴 재확인 (0 이어야 함)
```bash
grep -nE "select\(|db\.execute|db\.add\(|db\.flush\(" server/app/routers/${R}.py
grep -nE "select\(|db\.execute|db\.add\(|db\.flush\(" server/app/services/${S}.py
grep -c "response_model=" server/app/routers/${R}.py  # 엔드포인트 수와 일치해야 함
grep -nE "data: dict|: dict\b" server/app/services/${S}.py
```

### 8. 체크리스트 채우기 → 결과 보고

---

## 체크리스트 (라우터 1개 — 모든 항목 체크 필수)

### Schema
- [ ] 엔드포인트별 `*Request` DTO 존재
- [ ] 엔드포인트별 `*Response` DTO 존재 (단건/목록 구분)
- [ ] `ConfigDict(from_attributes=True)` 설정 (ORM → DTO 변환 대상)
- [ ] Request/Response 가 같은 클래스를 공유하지 않음
- [ ] SQLAlchemy 모델 import 없음

### Router
- [ ] 모든 엔드포인트 `response_model=` 지정
- [ ] `select() / db.execute() / db.add() / db.flush() / db.commit()` 직접 호출 0건
- [ ] `from app.models` / `from app.repositories` import 없음
- [ ] 라우터 파일 내부 쿼리 헬퍼 함수 없음 (`_resolve_*` 등 Service/Repo 로 이관)
- [ ] Request DTO 로 입력 받음 (dict/개별 Body 필드 나열 X)
- [ ] Service 인스턴스화 후 호출 (`XService(db).xxx(...)`)
- [ ] ORM 모델을 직접 return 하지 않음

### Service
- [ ] 클래스 기반 (`class XService`) + 생성자에서 Repository 인스턴스화
- [ ] 메서드 입력: Request DTO 또는 스칼라 (dict 파라미터 0건)
- [ ] 메서드 출력: Response DTO 또는 Internal DTO (ORM 직접 반환 0건)
- [ ] `select() / db.execute() / db.add() / db.flush()` 직접 호출 0건
- [ ] 모든 DB 접근 `self.repo.*` 경유
- [ ] 트랜잭션 `commit()` 호출 없음 (flush 까지만)

### Repository
- [ ] 도메인 Repository 파일 존재 (`{도메인}_repo.py`)
- [ ] `BaseRepository[Model]` 상속
- [ ] 복잡 쿼리가 있으면 도메인 메서드로 분리 (Service 에 select 잔존 X)
- [ ] 비즈니스 규칙(상태전이/권한/검증) 없음
- [ ] `commit()` 없음

### 테스트 / 린트
- [ ] 해당 도메인 API 테스트 전부 Green
- [ ] 전체 테스트 Green (회귀 없음)
- [ ] ruff check 통과
- [ ] 금지 패턴 grep 재확인 0건

### 문서
- [ ] `plan/refactor/re6-layered-architecture.md` 진행표의 해당 라우터 행을 "완료 (날짜 / PR / 테스트 수)" 로 갱신
- [ ] 변경된 API 응답 포맷이 있으면 `plan/api/{도메인}.md` 반영
- [ ] (선택) 신규 규칙 위반 패턴 발견 시 `.claude/rules/backend.md` 보강

---

## 결과 보고 양식

라우터 1개 리팩토링을 완료하면 아래 양식으로 사용자에게 보고한다.

```markdown
## RE6 리팩토링 보고 — `{도메인}` 라우터

### 변경 파일
- `server/app/schemas/{도메인}.py` (+N / -M)
- `server/app/repositories/{도메인}_repo.py` (+N / -M)
- `server/app/services/{도메인}_service.py` (+N / -M)
- `server/app/routers/{도메인}.py` (+N / -M)
- (테스트/문서 갱신 시 추가)

### 계층 정렬 지표 (Before → After)

| 항목 | Before | After |
|------|------:|------:|
| Router `select()` 직접 호출 | X | **0** |
| Router `response_model` 지정 | X / N 개 | **N / N** |
| Router 내부 쿼리 헬퍼 | X | **0** |
| Service `select()` 직접 호출 | X | **0** |
| Service `dict` 파라미터 | X | **0** |
| Service → Repository 호출 | X | **Y** |
| 라우터 줄 수 | X | Y |
| 서비스 줄 수 | X | Y |

### 체크리스트
- Schema ✅ (5/5)
- Router ✅ (7/7)
- Service ✅ (6/6)
- Repository ✅ (5/5)
- 테스트/린트 ✅ (4/4)
- 문서 ✅ (3/3)

### 테스트
- 해당 도메인: N/N Green
- 전체: N/N Green
- 새로 추가한 테스트: 없음 / N개

### 남은 이슈 / 후속
- (없음 / 있으면 나열)

### 다음 대상
- 플랜에 따라 다음 라우터: `{도메인}` (Phase {N})
```

하나라도 체크 실패 시 **"완료" 보고 금지**. 문제 항목을 사용자에게 질문하거나 후속 태스크로 등록한다.

---

## 주의
- **여러 라우터를 한 번에 묶어서 리팩토링하지 않는다.** 라우터 1개 = 1 PR(또는 1 커밋) 원칙. 롤백 용이성 + 회귀 격리.
- 라우터 리팩토링 중 **비즈니스 로직 변경을 같이 하지 않는다.** 순수 계층 정렬만. 버그 발견 시 별도 태스크로 분리.
- 대형 라우터(`projects.py` 1,573줄, `qa.py` 820줄, `chat.py` 543줄, `ai_broker.py` 583줄, `meetings.py` 489줄)는 라우터 내부에서 **sub-도메인별로 나눠서 여러 Phase 에 걸쳐** 진행할 수 있음 (플랜 참조).

## 파일럿 교훈 (P0 permissions 기준 — 반드시 사전 확인)

### Repository 파일 배치
- 기존 `repositories/*_repo.py` 안에 **여러 도메인 Repository 가 통합돼 있을 수 있음** (예: `user_repo.py` = Company + User + JobRole + Permission + PersonalSkill)
- 새 `xxx_repo.py` 를 만들기 전에 `grep -rn "class XRepository" server/app/repositories/` 로 기존 위치 먼저 확인
- 이미 빈 껍데기 Repository 가 있으면 **그 안의 클래스를 확장**. 새 파일 만들지 말 것 (`__init__.py` 에 이미 export 돼 있음)

### Repository 메서드 선택
- **중복 체크** (하나라도 있으면 True): `exists()` 사용. `get_one_or_none` 은 `scalar_one_or_none` 기반이라 여러 행이면 `MultipleResultsFound` 터짐
- **단건 조회 (없으면 None)**: `get_one_or_none`
- **단건 조회 (없으면 NotFoundError)**: `get_by_id(id, company_id)` / `get_one(*filters)`
- **시스템+회사 OR 필터** 같은 도메인 특수 조건: Repository 메서드로 추가 (`list_by_company` 등)

### Router 예외
- **DELETE 204 엔드포인트는 `response_model` 불필요** (응답 body 없음). 체크리스트에서 `response_model=` 개수 세면 `엔드포인트 수 - 204 개수` 와 일치하면 통과
- **Depends 반환 타입 힌트용 Model import 허용**: `user: User = Depends(...)` 목적만. 라우터 본문에서 Model 필드에 직접 접근하거나 쿼리에 쓰면 위반

### Service 변환
- 메서드 출력을 Response DTO 로 바꿀 때 `Response.model_validate(orm)` 이 표준 (Pydantic v2, `from_attributes=True` 필수)
- 부분 업데이트: `body.model_dump(exclude_unset=True, exclude_none=True)` → Repository `update(obj, **dict)` 로 전달
- 서비스가 반환 없이 사이드 이펙트만 (delete 등) → `None` 반환, Router 는 데이터 없이 204 또는 200
- **eager load 된 관계가 있는 객체를 update 할 때는 `refresh=False` 필수** — `BaseRepository.update()` 기본값(`refresh=True`)은 관계를 expire 시켜 이후 Pydantic 직렬화 시 `MissingGreenlet` 발생. eager load 한 자식 컬렉션(`assignments`, `leaders`, `members`, `job_roles` …)이 있으면 전부 `refresh=False`
- **`func.now()` 대신 `datetime.now(UTC)`** — `refresh=False` 상태에서는 ORM 속성에 `func.now()` 객체가 그대로 남아 Pydantic 이 직렬화 실패. 타임스탬프 업데이트는 `datetime.now(UTC)` 써서 즉시 값이 되도록

### 호환성
- 응답 Schema 에 필드를 **추가**하는 것은 기존 테스트/클라이언트 호환 가능 (테스트가 특정 필드만 검증하면 OK)
- 응답 필드를 **삭제/이름 변경** 하면 계약 변경이므로 금지 (RE6 는 계층 정렬만)
