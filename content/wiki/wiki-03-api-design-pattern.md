---
id: wiki-03
title: API Design Pattern
type: wiki
status: promoted
sources:
  - "[[sources-03-backend-rules]]"
related_to:
  - "[[wiki-02-test-design-pattern]]"
  - "[[wiki-04-tdd-cycle-pattern]]"
tags: [wiki]
categories: [api-design]
aliases: []
---

# API Design Pattern

> 합성·정리. sources-03 의 `api-design.md` 부분에서 합성. **인간 검토 필요**.

## Summary

신규·수정 API 엔드포인트의 *구현 전* 설계 합의 패턴 — (1) 기존 API 문서 충돌 점검, (2) ERD / DB 룰 정합 검증, (3) Request / Response 스키마 결정, (4) 에러 케이스 명세, (5) API 도메인 문서 갱신. wiki-02 (test-design, 시나리오 합의) 의 *직전 단계* + wiki-04 (tdd-cycle, Red→Green) 의 *입력*.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 절차 5 단계** — 모든 API 설계 작업의 표준

| 단계 | 본질 | 산출 |
|------|------|------|
| 1. 충돌 점검 | 기존 API 문서·엔드포인트와의 중복·일관성 검증 | "충돌 0" 확인 |
| 2. ERD / DB 룰 정합 | 엔티티·관계·필드 타입·FK 정책·소프트 딜리트 부합 | DB 컨벤션 위반 0 |
| 3. Request 스키마 | 입력 DTO + 필드 / 타입 / 필수·선택 / 검증 | `*Request` 클래스 또는 schema 문서 |
| 4. Response 스키마 + 에러 | 출력 DTO + 상태 코드별 응답 + 에러 케이스 enum | `*Response` 클래스 + 에러 코드 표 |
| 5. 도메인 문서 갱신 | 결정 사항을 *프로젝트의 API 문서* 에 박는다 | `<api-docs>/<domain>.md` 갱신 |

**2) 엔드포인트 설계 규칙** (REST 표준 골격)

- URL: 복수형 명사 (`/issues`, `/projects`) / 계층 (`/projects/{id}/tickets`) / 행위 (`/issues/{id}/accept`)
- Method 의미 강제: GET (조회·소프트 딜리트 자동 필터) / POST (생성·자동 PK) / PATCH (부분 수정) / DELETE (소프트 딜리트)
- 응답 코드: 200 (조회·수정) / 201 (생성) / 204 (삭제) / 400 / 401 / 403 / 404 / 422

**3) 데이터 타입 컨벤션** (project-dependent — fallback 으로 기본값)

- PK / FK: UUID 권장 (또는 사용처 컨벤션)
- 상태값: VARCHAR + 명시 enum (ENUM 타입 X — 추가·이력 관리 곤란)
- 시간: ISO 8601 UTC
- 멀티테넌시: JWT / 세션에서 식별자 추출 → 모든 목록 API 자동 필터

**4) 산출 포맷** (도메인 문서 작성)

```markdown
### POST /resource
설명

**Request:**
| 필드 | 타입 | 필수 | 설명 |

**Response (201):**
| 필드 | 타입 | 설명 |

**Error:**
| 코드 | 상황 |
```

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

같은 골격 위에 *프로젝트별 인프라 가정*만 슬롯에 끼움 — sources-03 의 NEXUS 사례:

- **API 도메인 위치**: `plan/api/<domain>.md` (10 파일, ~210 endpoint — auth / issues / projects / services / organization / docs / communication / ai-routing / agent / websocket)
- **공통 응답 형식**: `plan/api/overview.md` (페이지네이션·Rate Limiting·에러 응답 표준)
- **DB 룰 reference**: `plan/erd/database-rules.md` (UUID / soft delete / multi-tenancy)
- **모델 reference**: `plan/erd/table-design.md` (BaseEntity + Mixin)
- **에이전트 영역**: `plan/agent/task-flow.md` (별도 흐름)

다른 프로젝트는 위 슬롯만 자기 인프라로 교체 — OpenAPI yaml / Swagger / 별 도구 위치.

## References

- `sources-03-backend-rules` (api-design.md 부분 — NEXUS `/api-design` SKILL 박제)
- 자매 wiki: `wiki-02-test-design-pattern` (시나리오 합의 — 본 wiki 직후 진행)
- 자매 wiki: `wiki-04-tdd-cycle-pattern` (Red→Green→Refactor — 본 wiki 의 산출이 입력)
- ADR 계보: `[[adr-0003-api-design-to-backend]]` (예정)
