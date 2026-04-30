# Backend Rules

> 팀 원칙은 `plan/design-standards/` 참고 (coding-convention, project-structure, error-handling, security, testing-strategy)
> 상세 DB 규칙은 `plan/erd/database-rules.md`, 모델 패턴은 `plan/erd/table-design.md` 참고
> 마이그레이션: `plan/erd/migrations.md`, 시드: `plan/erd/seed.md`

## 패키지 매니저
- **uv** (Rust 기반, pip 대비 10~100배 빠름)
- `uv sync` — 의존성 설치 (lock 파일 기반)
- `uv add {패키지}` — 의존성 추가
- `uv run {명령}` — 가상환경 내 실행
- 설정: `server/pyproject.toml` + `uv.lock`

## 개발 환경 (Docker)
- `docker compose up -d` — postgres(5433) + redis(6379) + server(8000) 바인드마운트
- `docker compose exec server uv run python -m alembic upgrade head` — 마이그레이션
- `docker compose exec server uv run python -m app.seeds.run --minimal` — 시드 (admin 1명)
- `docker compose exec server uv run python -m app.seeds.run --dev` — 시드 (풀 데이터, 기본)
- `docker compose exec server uv run python -m app.seeds.run --e2e` — 시드 (E2E 테스트용)
- `docker compose exec server uv run pytest` — 테스트
- `docker compose down -v` — DB 초기화 (볼륨 삭제)
- 호스트 Claude CLI 공유: `~/.claude:/root/.claude:ro` 볼륨

> ⚠️ alembic은 `python -m alembic`으로 실행 (`uv run alembic`은 sys.path 문제로 ModuleNotFoundError 발생)

### 환경 변수 (.env)
- `server/.env` — 로컬 개발용 (`.gitignore`에 포함, 커밋 안 함)
- `server/.env.example` — 템플릿 (커밋 대상)
- Docker compose 내에서는 `environment:` 블록으로 직접 주입 (`.env` 불필요)
- `pydantic-settings`가 `.env` 파일 자동 로드 (`app/config.py`)

## 배포 (GHCR)
- GitHub Actions: test → build → push `ghcr.io/{repo}/server:latest` → 서버 pull + migrate + restart
- Prod 마이그레이션: downgrade 금지, 새 마이그레이션으로 수정
- 상세: `plan/erd/migrations.md` 8절

## 포맷터 / 린터
- **black**: line-length=120, target-version=py312
- **ruff**: select=["E","F","I","W","UP"], isort 호환
- **mypy**: strict=false (점진적 도입), warn_return_any=true
- 설정은 `pyproject.toml`에 통합 (`plan/design-standards/coding-convention.md` 2.2절)

## 4계층 아키텍처 (필수 — RE6)

> **모든 도메인은 반드시 4계층으로 작성한다.**
> 새 라우터/기능 추가 시, 기존 라우터 수정 시 이 규칙을 위반하면 안 된다.
> 라우터 단위 리팩토링 절차는 `.claude/skills/refactor-layered.md` (체크리스트 필수).
> 전체 리팩토링 플랜: `plan/refactor/re6-layered-architecture.md`.

### 계층 구조
```
Router(HTTP)  →  Service(비즈니스)  →  Repository(DB 접근)  →  Model(ORM)
    ↕ Request/Response DTO        ↕ Internal DTO / ORM 인스턴스
    (Pydantic v2)                 (Pydantic v2)
```

### 계층별 책임과 금지사항

**Router (`routers/*.py`) — "HTTP 어댑터"**
- ✅ 경로/메서드/상태코드 정의, 인증·권한 Depends, Request DTO 파싱, Service 호출, Response DTO 반환
- ✅ 모든 엔드포인트에 `response_model=` 지정
- ❌ **`select() / db.execute() / db.add() / db.flush()` 직접 호출 금지**
- ❌ 라우터 파일 내부에 쿼리 헬퍼 함수 정의 금지 (예: `_resolve_*_slugs()` → Service로)
- ❌ SQLAlchemy 모델을 응답으로 return 금지 (반드시 Response DTO 경유)
- ❌ Repository 를 Router 가 직접 import 금지 (Service 경유)
- ⚠️ Model import 는 **`Depends(...)` 반환 타입 힌트용만 허용** (예: `user: User = Depends(get_current_active_user)`). 라우터 본문에서 Model 필드에 접근하거나 쿼리에 쓰면 위반

**Schema (`schemas/*.py`) — "데이터 계약"**
- ✅ `*Request` — 입력 DTO (라우터 → 서비스)
- ✅ `*Response` — 출력 DTO (서비스 → 라우터 → 클라이언트)
- ✅ `*DTO` (필요 시) — 서비스 내부 전달용 Pydantic 모델
- ✅ ORM 객체 → Response DTO 변환: `Response.model_validate(obj)` (Pydantic v2 `from_attributes=True`)
- ❌ SQLAlchemy 모델 import 금지 (타입 힌트용도 X)
- ❌ Request/Response 를 하나의 클래스로 공유 금지 (입출력 필드 분리)

**Service (`services/*.py`) — "비즈니스 로직"**
- ✅ 클래스 기반: `class XService:` + `__init__(self, db: AsyncSession)`
- ✅ **입력**: Request DTO (또는 스칼라 인자), **출력**: Response DTO / Internal DTO
- ✅ 비즈니스 규칙, 트랜잭션 조율, 여러 Repository 조합
- ✅ 모든 DB 접근은 Repository 경유 (`self.repo.xxx()`)
- ❌ **`select() / db.execute() / db.add() / db.flush()` 직접 호출 금지**
- ❌ `data: dict` 파라미터 금지 (Request DTO 로 받음)
- ❌ SQLAlchemy 모델을 라우터로 그대로 반환 금지 (Response DTO 로 변환)
- ⚠️ `commit()` 은 미들웨어/엔드포인트 레벨 트랜잭션에서 (Service 는 `flush` 까지)

**Repository (`repositories/*.py`) — "DB 접근"**
- ✅ `BaseRepository[Model]` 상속, 단순 CRUD 는 상속만으로 OK
- ✅ 도메인 전용 쿼리(JOIN/집계/재귀) 는 확장 메서드로 추가
- ✅ 반환: SQLAlchemy 모델 인스턴스 (서비스가 DTO 로 변환)
- ❌ 비즈니스 규칙 금지 (상태 전이, 권한 체크 등은 Service)
- ❌ `commit()` 금지 (`flush` 까지)

### 금지 패턴 (grep 으로 검출)
```
# Router 에 있으면 위반
grep -n "select\|db\.execute\|db\.add\|db\.flush" server/app/routers/*.py
# Service 에 있으면 위반
grep -n "^from sqlalchemy import.*select\|await db\.execute\|db\.add(\|db\.flush(" server/app/services/*.py
# Response DTO 누락 검출 (엔드포인트 있는데 response_model 없음)
grep -L "response_model=" server/app/routers/*.py
```

### 허용 예외
- `seeds/` — 시드 스크립트는 직접 DB 조작 허용
- `alembic/` — 마이그레이션은 ORM 우회 가능
- `ws_agent.py`, `ws_web.py` — WebSocket 핸들러는 Service 로 위임하되 메시지 파싱/전송 책임만
- `core/` — 인증·미들웨어·Redis 는 계층 무관

---

## FastAPI
- 라우터는 도메인별 분리 (`routers/issues.py`, `routers/projects.py`)
- Pydantic v2로 request/response 스키마 정의
- 의존성 주입 (Depends)으로 DB 세션, 인증 처리
- async 함수 기본 (순수 연산은 sync 허용)
- **모든 엔드포인트 `response_model=` 지정 필수** (4계층 규칙 참고)

## SQLAlchemy
- SQLAlchemy 2.0 async 스타일
- 모델은 `models/` 디렉토리 (도메인별 파일 분리)
- **ENUM 사용 안 함** → VARCHAR + Python Enum 검증 (Alembic 마이그레이션 에러 방지)
- **소프트 딜리트** → `deleted_at` 컬럼, 쿼리 시 `where(deleted_at.is_(None))`
- 공통 Base 모델에 `id(UUID)`, `created_at`, `updated_at`, `deleted_at` 포함
- **테이블 3분류**:
  - 엔티티 (BaseEntity 상속): id + timestamps + soft delete
  - 로그 (TimestampMixin만): created_at만, 수정/삭제 안 함
  - 매핑 (복합 PK): 공통 컬럼 없음, FK 두 개 = PK

## 네이밍 규칙
- 테이블명: snake_case, 단수형 (`user`, `org_node`, `issue_assignment`)
- 매핑 테이블: `{테이블A}_{테이블B}` (`user_job_role`, `channel_member`)
- FK: `{참조테이블}_id` (`company_id`, `parent_id`)
- Boolean: `is_` 접두사 (`is_active`, `is_read`)
- 시간: `_at` 접미사 (`created_at`, `deleted_at`)
- 날짜: `_date` 접미사 (`start_date`, `due_date`)
- 인덱스: `ix_{테이블}_{컬럼}`, UNIQUE: `uq_{테이블}_{컬럼}`

## PK / FK 규칙
- PK: UUID v4 (`gen_random_uuid()`)
- 매핑 테이블: 복합 PK (FK 두 개 조합)
- FK ON DELETE: CASCADE / SET NULL / RESTRICT 명시 (`plan/erd/database-rules.md` 8번 섹션)
- 멀티테넌시: 13개 최상위 테이블에 `company_id` FK 필수

## MD 콘텐츠 저장 규칙
- **AI용 긴 MD → S3 파일** (DB에 file_path 저장)
  - TaskFile: `/tasks/{issue_id}/{user_id}-지시.md`, `/results/{issue_id}/{user_id}-결과.md`
  - HarnessProfile: `/harness/{company_id}/company-v{ver}.md`, `.../{project_id}/project-v{ver}.md`, `.../{job_role_id}/jobrole-v{ver}.md`
  - Service 정책 MD (하네스 아님, AI 컨텍스트): `/service-policy/{service_id}/v{ver}.md`
- **UI용 짧은 텍스트 → DB TEXT 컬럼**
  - Document.body, Issue.description, Ticket.description, ChatMessage.body 등

## JSONB 사용 규칙
- 유동적 설정만: `ExternalIntegration.config`, `IssueEvent.detail`, `ExecutionRun.result_json`
- **HarnessRule.action은 JSONB 아님** → `HarnessRuleAction` 테이블로 정규화됨
- 조회 빈도 높은 필드는 정규 컬럼으로
- 암호화 필요한 JSONB는 애플리케이션 레벨 암호화

## TIMESTAMP 규칙
- 모든 시간: TIMESTAMPTZ (WITH TIME ZONE)
- 서버/DB: UTC 기준
- `created_at`, `updated_at`: DB `DEFAULT now()`
- `updated_at`: SQLAlchemy `onupdate=func.now()`

## API 규칙 (`plan/api/overview.md` 참고)
- RESTful 설계, ~240 엔드포인트 (plan/api/ 11개 파일)
- 응답: `{ "data": ..., "message": "..." }`
- 에러: `{ "error": { "code": "UPPER_SNAKE", "message": "한국어", "detail": "개발용" } }`
- **422 에러**: FastAPI 기본 422를 커스텀 변환 → `{ "error": { "code": "VALIDATION_ERROR", "fields": [{ "field": "title", "message": "필수" }] } }`
- 페이지네이션: `?page=1&size=20` (page<1, size>100 → 400, 소프트 딜리트 자동 제외)
- 정렬: `?sort=created_at&order=desc` (허용 컬럼만, 임의 컬럼 → 400)
- 다중 값 필터: 쉼표 구분 (`?status=assigned,in_progress`), 잘못된 값은 무시
- HTTP 코드: 200/201/204/400/401/403/404/408/409/422/429/500

## 인증 (2가지)
- **JWT** (웹 API): `Authorization: Bearer {access_token}` — access 30분, refresh 7일 httpOnly, **rotation 적용**
- **에이전트 토큰** (agent API + WebSocket): `Authorization: Bearer {agent_token}` — 무기한, `mslv_{role}_{random}`
- JWT claims: `sub`(user_id), `cid`(company_id), `roles`, `exp`
- permissions는 JWT에 없음 → DB 조회 (roles → JobRolePermission)

## 에러 처리
- 커스텀 예외는 `AppError` 상속 (`plan/design-standards/error-handling.md` 3절)
- Router에서 직접 처리 안 함 → 글로벌 핸들러가 AppError catch → JSON 변환
- `RequestValidationError` → 422 커스텀 핸들러 (fields 배열 변환)
- Service에서 비즈니스 에러 raise (NotFoundError, ValidationError 등)
- `detail` 필드: 개발=항상, 프로덕션=5xx만 제외 (스택트레이스 숨김)

## 보안
- 비밀번호: bcrypt 해시 (단방향)
- 외부 토큰: AES-256 암호화 (복호화 필요)
- Refresh Token Rotation: 갱신 시 기존 토큰 폐기 + 새 토큰 발급
- access_token 블랙리스트: 로그아웃/비밀번호 변경 시 Redis TTL
- CORS: 프로덕션 + localhost:3000만 허용
- 보안 헤더: `X-Content-Type-Options`, `X-Frame-Options`, `Strict-Transport-Security`, `CSP`
- Rate limiting: 로그인 5회/분, API 100회/분, Claude 10회/시간
- 멀티테넌시: 타사 데이터 접근 → 404 (403 아님, 존재 숨김)
- 민감 필드 API 응답 제외: password_hash, access_token 등

## 디렉토리 구조
```
server/
├── app/
│   ├── main.py
│   ├── config.py
│   ├── models/              ← SQLAlchemy 모델 (도메인별 분리)
│   │   ├── __init__.py      ← Base, 모든 모델 import
│   │   ├── base.py          ← Base, TimestampMixin, SoftDeleteMixin, BaseEntity
│   │   ├── enums.py         ← Python Enum (IssueType, IssueStatus, TicketStatus, HarnessRuleCategory, EscalationTime 등)
│   │   ├── user.py          ← User, JobRole, Permission, PersonalSkill
│   │   ├── organization.py  ← OrgNode, OrgNodeLeader, MemberAssignment
│   │   ├── service.py       ← Service, ServiceDependency, GitRepoMapping, BusinessGoal, Milestone (+ MilestoneProject 매핑은 mappings.py)
│   │   ├── project.py       ← Project, Sprint, Epic, Ticket, SubTask, Release
│   │   ├── issue.py         ← Issue, IssueAssignment, TaskFile
│   │   ├── routing.py       ← IssueEvent, ExecutionRun, AgentTaskSession
│   │   ├── harness.py       ← Harness, HarnessSkill, HarnessTool, HarnessRule, HarnessRuleAction, HarnessProfile
│   │   ├── document.py      ← DocFolder, Document, DocumentRevision (+ DocumentRelation 매핑은 mappings.py)
│   │   ├── communication.py ← Channel, ChatMessage, ChatReaction, MeetingRoom, MeetingRecord, MeetingSegment, MeetingRollingSummary, MeetingTodo
│   │   ├── notification.py  ← Notification
│   │   ├── external.py      ← ExternalIntegration, ExternalAuth
│   │   ├── agent.py         ← AgentSession
│   │   └── mappings.py      ← 매핑 테이블 8개 (Table 객체)
│   ├── schemas/             ← Pydantic 스키마
│   │   ├── common.py        ← DataResponse, PaginatedResponse, ErrorResponse
│   │   ├── auth.py          ← LoginRequest, UserMeResponse 등
│   │   ├── user.py          ← InviteRequest, UserUpdateRequest 등
│   │   ├── jobrole.py       ← JobRoleCreateRequest, AssignJobRolesRequest 등
│   │   ├── harness.py       ← HarnessSkill/Tool/Rule/Profile CRUD 스키마
│   │   ├── issue.py         ← Issue CRUD + 상태변경 + 피드백/리뷰 + 타임라인 스키마
│   │   └── project.py       ← Project/Sprint/Ticket/SubTask/Epic/Release 스키마
│   ├── routers/             ← API 라우터
│   │   ├── auth.py          ← /api/auth (login, refresh, logout, me, invite/accept)
│   │   ├── users.py         ← /api/users (CRUD, invite, skills, agent-token, password)
│   │   ├── jobroles.py      ← /api/job-roles (CRUD)
│   │   ├── permissions.py   ← /api/permissions (CRUD)
│   │   ├── company.py       ← /api/company (get, patch)
│   │   ├── harness.py       ← /api/harness (3레벨 × Skills/Tools/Rules CRUD + enums + md-content + profile, 44개)
│   │   ├── issues.py        ← /api/issues (CRUD, 상태변경, 피드백/리뷰, 타임라인, 20개)
│   │   ├── projects.py      ← /api/projects (CRUD, phase, 스프린트, 티켓, 에픽, 릴리즈, milestone_ids, 36개+)
│   │   ├── services.py      ← /api/services (S7-1: CRUD + 의존성 메타 + BusinessGoal/Milestone/Roadmap + 레포, 20+)
│   │   └── docs.py          ← /api/docs (폴더/문서/Revision + DocumentRelation S7-1)
│   ├── services/            ← 비즈니스 로직
│   │   ├── auth_service.py  ← login, refresh, logout, get_me, change_password
│   │   ├── user_service.py  ← invite, accept, list, get, update, delete
│   │   ├── jobrole_service.py ← list, create, update, delete, assign
│   │   ├── permission_service.py ← list, create, update, delete
│   │   ├── skill_service.py ← list, add, delete
│   │   ├── company_service.py ← get, update
│   │   ├── harness_service.py ← 하네스 CRUD, get_or_create
│   │   ├── issue_service.py ← 이슈 CRUD, 상태전이, 피드백/리뷰, 이벤트 기록
│   │   ├── project_service.py ← 프로젝트 CRUD, phase 전이, 스프린트, 티켓, 에픽, 릴리즈, milestone_ids
│   │   ├── service_service.py ← 서비스 CRUD, 의존성(메타), Git 레포 (S7-1)
│   │   ├── business_goal_service.py ← BusinessGoal CRUD + 마일스톤 로드 (S7-1)
│   │   ├── milestone_service.py ← Milestone CRUD + Project N:M 매핑 (S7-1)
│   │   └── doc_relation_service.py ← DocumentRelation 양방향 매핑 (S7-1)
│   ├── repositories/        ← DB 접근 계층 (BaseRepository 패턴)
│   ├── core/                ← 인프라 (인증, 에러, Redis, 미들웨어)
│   │   ├── auth.py          ← JWT 생성/검증
│   │   ├── deps.py          ← Depends 팩토리 (DB 세션, 인증, RBAC)
│   │   ├── errors.py        ← 커스텀 예외 계층 (AppError)
│   │   └── redis.py         ← Redis 연결, 블랙리스트, refresh 저장
│   ├── utils/               ← 공통 유틸리티 (도메인 무관)
│   │   ├── security.py      ← 비밀번호 해시, 에이전트/초대 토큰 생성
│   │   └── pagination.py    ← 페이지네이션 헬퍼
│   └── seeds/               ← 시드 데이터
│       ├── __init__.py
│       ├── run.py            ← 시드 실행 진입점
│       ├── system_permissions.py ← 시스템 권한 25개
│       ├── company_jobroles.py   ← 기본 직군 10개 + 매핑
│       ├── dev_data.py           ← 개발용 더미 데이터
│       └── harness_data.py      ← 하네스 시드 (회사/프로젝트/직군 + Skills/Tools/Rules + Profile MD)
├── tests/
│   ├── conftest.py           ← 공통 fixture (NullPool, FakeRedis, 테스트 회사/유저)
│   └── api/                  ← API 엔드포인트 테스트 (194개)
│       ├── test_auth_api.py
│       ├── test_users_api.py
│       ├── test_jobroles_api.py
│       ├── test_permissions_api.py
│       ├── test_skills_api.py
│       ├── test_company_api.py
│       ├── test_harness_api.py   ← 하네스 CRUD (25개)
│       ├── test_issues_api.py    ← 이슈 CRUD + 상태전이 + 피드백/리뷰 + 타임라인 (35개)
│       └── test_projects_api.py  ← 프로젝트 CRUD + phase + 스프린트 + 티켓 + 에픽 + 릴리즈 (37개)
├── alembic/
│   ├── env.py                ← async 엔진, Base.metadata
│   ├── script.py.mako
│   └── versions/             ← S1~S4 마이그레이션
├── pyproject.toml            ← uv 의존성 + black/ruff/mypy/pytest 설정
├── uv.lock
├── Dockerfile
├── .env.example
└── alembic.ini
```
