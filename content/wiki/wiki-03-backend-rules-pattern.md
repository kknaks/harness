---
id: wiki-03
title: Backend Rules Pattern
type: wiki
status: promoted
sources:
  - "[[sources-03-backend-rules]]"
related_to:
  - "[[wiki-01-code-review-pattern]]"
  - "[[wiki-02-test-design-pattern]]"
tags: [wiki]
categories: [backend-rules, lifecycle]
aliases: []
---

# Backend Rules Pattern

> 합성·정리. 비슷한·연관된 sources 를 묶어 다듬은 지식 노드. LLM 이 합성, **인간이 검토**.

## Summary

백엔드 작업의 **라이프사이클 4단계 패턴** — (1) 설계 (API 엔드포인트 + 문서화) → (2) 구현 (TDD Red→Green) → (3) 검증·정리 (Refactor) → (4) 계층 정렬 (4계층 아키텍처 준수). 각 단계는 *공용 reference 문서* (컨벤션·DB 룰·디자인 표준) 를 trigger 시 로드하고, 부재 시 role-generic fallback (REST 일반 원칙·SOLID) 으로 동작. wiki-01 (사후 코드 리뷰) / wiki-02 (사전 테스트 설계) 와 *같은 두 층 분리 패턴* (project-agnostic 골격 + 프로젝트 의존 슬롯) 을 적용.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 라이프사이클 4단계** — 백엔드 도메인 작업의 표준 진행

| 단계 | 본질 | 산출 | 트리거 SKILL |
|------|------|------|--------------|
| 1. 설계 | 엔드포인트 / 입출력 / 에러 케이스 합의 + 기존 API 와 충돌 점검 | `<API 도메인 문서> §POST /resource` | `api-design` |
| 2. 구현 (Red) | 테스트 먼저 — 스펙 기반 request/response 테스트 | `tests/api/test_<domain>.py` (실패 확인) | `tdd-cycle` step 1 |
| 3. 구현 (Green) | 테스트 통과하는 최소 코드 — Schema → Router → Service → Repository | `app/{schemas,routers,services,repositories}/<domain>.py` | `tdd-cycle` step 2 |
| 4. 정렬 (Refactor) | 4계층 위반 검출 + 정렬 + 회귀 테스트 통과 | 위반 0 + 테스트 100% pass | `refactor-layered` |

**2) 4계층 아키텍처** (RE6 패턴 — 모든 도메인 강제)

```
Router(HTTP)  →  Service(비즈니스)  →  Repository(DB 접근)  →  Model(ORM)
    ↕ Request/Response DTO        ↕ Internal DTO / ORM 인스턴스
```

| 계층 | 책임 | 금지 |
|------|------|------|
| Router | 경로 / 인증·권한 Depends / DTO 파싱 / Service 호출 / Response 반환 | DB 직접 호출 (`select / db.execute / db.add / db.flush`), Repository import, Model 응답 반환 |
| Schema | Request / Response / Internal DTO (Pydantic v2) | SQLAlchemy 모델 import, Request·Response 공유 |
| Service | 비즈니스 로직 / 트랜잭션 조율 / Repository 조합 / Request → Response 변환 | DB 직접 호출, `data: dict` 파라미터, Model 직접 반환 |
| Repository | `BaseRepository[Model]` 상속 + 도메인 쿼리 확장 | 비즈니스 규칙 (상태 전이·권한 체크 등) |

**3) 검증 자동화 — grep 기반 위반 검출**

```bash
# Router 에 DB 직접 호출이 있으면 위반
grep -n "select\|db\.execute\|db\.add\|db\.flush" {router-dir}/*.py
# Service 에 select / SQLAlchemy 직접 사용이 있으면 위반
grep -n "^from sqlalchemy import.*select\|await db\.execute\|db\.add(\|db\.flush(" {service-dir}/*.py
# Response DTO 누락 검출
grep -L "response_model=" {router-dir}/*.py
```

각 단계에 grep 한 줄로 *위반 0* 보장. 자동화 가능한 checklist 가 *재현 가능한 정렬* 의 핵심.

**4) TDD 사이클 — Red → Green → Refactor**

| 단계 | 본질 | 강제 |
|------|------|------|
| Red | 스펙 기반 테스트 작성 → **실패 확인** | 구현 0 으로 시작. 통과하면 테스트가 의미 없음 |
| Green | 통과하는 *최소* 구현. Schema → Router → Service → Repository 순 | 과도 설계 금지 — 통과만 시키고 다음 단계로 |
| Refactor | 통과 유지하면서 정리 (네이밍·중복·계층 위반 정렬) | 테스트 fail 시 즉시 revert |

**5) 작업 시작 전 reference 로드** — 모든 4 단계 SKILL 의 공통 전제

다음 reference 문서가 있으면 우선 로드, 부재 시 role-generic fallback:
- API 도메인 문서 (`<api-docs-dir>/<domain>.md`) — 기존 엔드포인트 / 응답 형식 / 페이지네이션 컨벤션
- 디자인 표준 (`<design-standards-dir>/`) — 코딩 컨벤션 / 에러 핸들링 / 보안 / 테스트 전략
- DB 룰 (`<erd-dir>/database-rules.md`) — 네이밍 / FK 정책 / 소프트 딜리트
- 모델 패턴 (`<erd-dir>/table-design.md`) — BaseEntity / Mixin / 시드

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

같은 골격 위에 *프로젝트별 컨벤션* 만 슬롯에 끼운다 — `sources-03-backend-rules` 의 NEXUS 사례:

**환경 슬롯**
- 패키지: `uv` (Rust 기반, pip 대비 10~100배). `server/pyproject.toml` + `uv.lock`
- 컨테이너: `docker compose up -d` — postgres(5433) / redis(6379) / server(8000) 바인드마운트
- 마이그레이션: `python -m alembic upgrade head` (alembic 직접 실행 시 sys.path 문제로 ModuleNotFoundError)
- 테스트: `docker compose exec server uv run pytest`

**API 도메인 슬롯**
- 위치: `plan/api/<domain>.md` (10 파일, ~210 엔드포인트)
- 도메인: auth / issues / projects / services / organization / docs / communication / ai-routing / agent / websocket
- 응답 형식: 공통 `{success, data, meta}` 컨벤션 (`plan/api/overview.md`)

**4계층 위치 슬롯**
- Router: `server/app/routers/<domain>.py`
- Service: `server/app/services/<domain>.py`
- Repository: `server/app/repositories/<domain>.py`
- Schema: `server/app/schemas/<domain>.py` + `schemas/common.py` (DataResponse / PaginatedResponse / ErrorResponse)
- BaseRepository: `server/app/repositories/base.py`

**도메인 어휘 슬롯**
- 멀티테넌시: JWT 의 `company_id` 추출 → 모든 목록 API 자동 필터
- PK/FK: UUID 문자열, ENUM 대신 VARCHAR 상태값 (`"assigned" / "in_progress"`)
- 소프트 딜리트: `deleted_at IS NULL` 자동 필터 (페이지네이션 포함)
- 시간: ISO 8601 UTC

**리팩토링 진행 트래커**
- `plan/refactor/re6-layered-architecture.md` — 도메인별 4계층 정렬 진행 현황표

### 다른 프로젝트는 위 슬롯만 자기 환경으로 교체

- 환경 — 패키지 매니저 (poetry / pip / npm / mvn) / 컨테이너 (k8s / nomad) / 마이그레이션 도구 (flyway / liquibase / prisma)
- API 도메인 — OpenAPI yaml / swagger / 별 도구 위치
- 4계층 위치 — Spring Boot (`controller/service/repository/entity`) / Express (`routes/services/dao/models`) / NestJS 등 프레임워크 컨벤션 따름
- 도메인 어휘 — 도메인별 멀티테넌시 키 / ID 정책 / 시간 표현 / soft-delete 컨벤션

## References

- `sources-03-backend-rules` (NEXUS 백엔드 4 SKILL 박제 — 이 wiki 의 첫 sources)
- 관련: `wiki-01-code-review-pattern` — 사후 검토 (이 wiki 의 4단계 *후* 적용 — 5번째 단계 후보)
- 관련: `wiki-02-test-design-pattern` — 사전 *설계* (이 wiki 의 step 2 Red 단계의 *앞* 자리)
- ADR 계보: `[[adr-0001-code-review-to-backend]]`, `[[adr-0002-test-design-to-backend]]` 와 동등한 *backend role 매핑* — `[[adr-0003-backend-rules-to-backend]]` 로 진행 예정
