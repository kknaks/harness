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
