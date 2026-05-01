---
id: sources-03
title: Backend Rules
type: sources
status: pending
sources:
  - "[[backend-rules]]"
tags: [sources]
aliases: []
---

# Backend Rules

> 1차 가공 = 원본 박제. 이후 불변. 원본의 정체(이름·목적)를 명확히 한 채 보존한다.

## 정체 (Identification)

**원본**: `content/inbox/backend-rules`

**무엇인가 (한 줄)**:

NEXUS 백엔드 (FastAPI / Python / PostgreSQL / 4계층 아키텍처) 의 *작업 절차* SKILL 4종 박제 — `api-design` (새 API 엔드포인트 설계 + plan/api/ 문서화), `tdd-cycle` (Red→Green→Refactor 루프), `refactor-layered` (라우터 1개 4계층 정렬 리팩토링), `backend.md` (전반 컨벤션·환경 reference).

**왜 보존하는가**:

이 4 파일은 *백엔드 작업의 라이프사이클 4단계* 를 cover — 설계 (api-design) → 구현 + 검증 (tdd-cycle) → 정리 (refactor-layered), 그리고 그 위의 *공용 컨벤션 reference* (backend.md). 기존 wiki-01 (code-review, *사후 검토*) / wiki-02 (test-design, *사전 설계*) 와 동일한 두 층 분리 패턴 (공용 골격 + 프로젝트 의존 슬롯) 을 적용하여 wiki-03+ 으로 합성 가능 — 단일 wiki "backend-rules-pattern" 으로 묶음 (주제 = "백엔드 작업 라이프사이클 절차"). 후속 사용 사례 누적되면 4 wiki 로 분리 가능 (api-design / tdd / refactor 각각).

## 본문 (raw 인용)


### api-design.md

~~~markdown
---
name: api-design
description: API 엔드포인트를 설계하고 plan/api/에 문서화한다
---

# API 설계

## 실행 조건
새 API 엔드포인트 설계 또는 기존 API 추가/수정 시 실행한다.

## 기존 API 문서 (10개 파일, ~210 엔드포인트)
- `plan/api/overview.md` — 공통 규칙 (응답 형식, 페이지네이션, Rate Limiting)
- `plan/api/auth.md` — 인증/사용자/직군/권한 (~20)
- `plan/api/issues.md` — 이슈 (~15)
- `plan/api/projects.md` — 프로젝트/스프린트/티켓/에픽/릴리즈 (~35)
- `plan/api/services.md` — 서비스/의존성 (~12)
- `plan/api/organization.md` — 조직/리더/멤버 (~12)
- `plan/api/docs.md` — 문서/폴더/버전 (~12)
- `plan/api/communication.md` — 채팅/미팅/알림 (~30)
- `plan/api/ai-routing.md` — 하네스/Control Center (~20)
- `plan/api/agent.md` — 에이전트 (~10)
- `plan/api/websocket.md` — WebSocket 이벤트 (~15)

## 절차

1. 해당 스펙 문서 확인 (`docs/specs/`)
2. **기존 API 문서 확인** (`plan/api/{도메인}.md`) — 중복/충돌 방지
3. ERD 확인 (`plan/erd/full-erd.md`) — 엔티티 관계, 필드 타입
4. DB 규칙 확인 (`plan/erd/database-rules.md`) — 네이밍, FK 정책
5. 에이전트 API는 `plan/agent/task-flow.md` 참고
6. 엔드포인트 정의 (method, path, 설명)
7. Request 스키마 (Pydantic)
8. Response 스키마 (Pydantic)
9. 에러 케이스
10. `plan/api/{도메인}.md`에 추가/수정

## 엔드포인트 설계 규칙

### URL 규칙
- 복수형 명사: `/issues`, `/projects`, `/services`
- 계층: `/projects/{id}/tickets`, `/projects/{id}/sprints`
- 행위: `/issues/{id}/accept`, `/issues/{id}/forward`

### Method
- GET: 조회 (소프트 딜리트 자동 필터: `deleted_at IS NULL`)
- POST: 생성 (PK는 UUID 자동 생성)
- PATCH: 부분 수정
- DELETE: 소프트 딜리트 (`deleted_at = now()`, 물리 삭제 안 함)

### 데이터 타입 규칙 (`plan/erd/database-rules.md` 참고)
- PK/FK: UUID 문자열
- 상태값: VARCHAR 문자열 (ENUM 아님). 예: `"assigned"`, `"in_progress"`
- 시간: ISO 8601 UTC (`2026-04-07T14:30:00Z`)
- 멀티테넌시: JWT에서 company_id 추출, 모든 목록 API에 자동 필터
- 페이지네이션 응답에 소프트 딜리트된 데이터 미포함

### 응답 코드
- 200: 성공 (조회/수정)
- 201: 생성 성공
- 204: 삭제 성공
- 400: 잘못된 요청
- 401: 인증 필요
- 403: 권한 없음
- 404: 리소스 없음
- 422: 밸리데이션 실패

### 문서 형식

```markdown
### POST /issues
이슈 등록

**Request:**
| 필드 | 타입 | 필수 | 설명 |
|------|------|:---:|------|

**Response (201):**
| 필드 | 타입 | 설명 |
|------|------|------|

**Error:**
| 코드 | 상황 |
|------|------|
```

~~~

### backend.md

~~~markdown
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

~~~

### refactor-layered.md

~~~markdown
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

~~~

### tdd-cycle.md

~~~markdown
---
name: tdd-cycle
description: TDD 사이클 (Red→Green→Refactor) 절차를 실행한다
---

# TDD 사이클

## 실행 조건
새 기능 개발 또는 API 구현 시 실행한다.

## 참고 문서
- `plan/design-standards/testing-strategy.md` — 테스트 피라미드, 케이스 생성 절차, 도메인별 핵심 맵
- `plan/api/` — API 상세 설계 10개 파일, ~210 엔드포인트 (테스트 대상)
- `plan/erd/table-design.md` — BaseEntity, Mixin 패턴 (fixture/팩토리 기반)
- `plan/erd/database-rules.md` — 소프트 딜리트, company_id 스코핑, FK 정책 (테스트 시나리오)

## 절차

### 1. Red (테스트 먼저)
- Test 에이전트가 API 스펙 기반으로 테스트 코드 작성
- `plan/api/` 문서를 참고하여 request/response 테스트
- 실행 → **실패 확인** (구현 코드 없으니까)

### 2. Green (최소 구현)
- Backend 에이전트가 테스트 통과하는 최소한의 코드 작성
- 모델(`plan/erd/table-design.md` BaseEntity 패턴), 스키마, 라우터, 서비스 순서로 구현
- 실행 → **통과 확인**

### 3. Refactor (정리)
- 코드 정리 (중복 제거, 네이밍 개선)
- 테스트는 계속 통과 상태 유지
- 커밋

### 4. 반복
- 다음 기능으로 1~3 반복

## 예시 플로우

```
1. Test: test_create_issue_returns_201() 작성 → 실패
2. Backend: POST /issues 라우터 + 서비스 구현 → 통과
3. Refactor: 스키마 정리, 에러 핸들링 추가 → 통과 유지
4. Test: test_create_issue_without_title_returns_422() 작성 → 실패
5. Backend: 밸리데이션 추가 → 통과
6. 커밋
```

~~~
