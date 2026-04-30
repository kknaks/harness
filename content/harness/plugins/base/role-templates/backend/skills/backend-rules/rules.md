# Backend Rules Rules

> 스킬이 강제하는 룰셋·정책·금지 사항. SKILL.md (사용자 시점 진입점) 가 trigger 시 로드 → 본 rules.md 는 실제 룰 적용 시점에 지연 로드 ([[adr-0007-skill-authoring-rules]] §1).
>
> **rules.md 의 책임 (본질·SSOT)**: *무엇을 강제하는가 / 왜 / 위반 시 어떻게 되는가*. 도메인 룰 본문·정책·금지·예외 처리. 운영 단계 (Pre-flight / Action / Post-flight 표) 는 `checklist.md` 가 SSOT — rules 에는 박지 않음 ([[adr-0007-skill-authoring-rules]] §1 SKILL.md vs rules.md vs checklist.md 분리). 같은 정보가 양쪽에 박히면 표류 — 한쪽만 SSOT.

## 라이프사이클 4단계

| 단계 | 시간 (가이드) | 본질 (강제) | 산출 |
|------|---------------|-------------|------|
| 1. 설계 (`api-design`) | 10–30분 | 엔드포인트 / 입출력 / 에러 케이스 / 기존 API 충돌 점검 / DB 룰 정합 | `<api-docs-dir>/<domain>.md` 갱신 |
| 2. 구현 Red (`tdd-cycle`) | 20–60분 | 스펙 기반 테스트 작성 → **실패 확인** | `tests/api/test_<domain>.py` (실패) |
| 3. 구현 Green (`tdd-cycle`) | 30–120분 | 통과하는 *최소* 코드. Schema → Router → Service → Repository 순 | 4계층 파일 + 테스트 통과 |
| 4. 정렬 (`refactor-layered`) | 20–60분 | 4계층 위반 0 + 회귀 테스트 통과 | grep 위반 0 + 테스트 100% |

**컬럼 구분** — *시간 (가이드)* 컬럼은 가이드라인 (강제 X — 도메인 복잡도에 따라 가변). *본질 (강제)* 컬럼은 강제 (skip 시 차단 사유). 단계 순서도 강제 — Red 없이 Green 들어가면 TDD 무효, Green 없이 Refactor 들어가면 회귀 검증 불가.

## 4계층 아키텍처

```
Router(HTTP)  →  Service(비즈니스)  →  Repository(DB 접근)  →  Model(ORM)
    ↕ Request/Response DTO        ↕ Internal DTO / ORM 인스턴스
```

| 계층 | 책임 (강제) | 금지 (강제) |
|------|-------------|-------------|
| Router | 경로·메서드·상태코드 / 인증·권한 Depends / Request DTO 파싱 / Service 호출 / Response DTO 반환 / `response_model=` 강제 | DB 직접 호출 (`select / db.execute / db.add / db.flush`) / Repository import / Model 직접 응답 / 라우터 내 쿼리 헬퍼 함수 정의 |
| Schema | `*Request` / `*Response` / `*DTO` (Pydantic v2) / `model_validate` 변환 | SQLAlchemy 모델 import (타입 힌트도 X) / Request·Response 클래스 공유 |
| Service | 비즈니스 로직 / 트랜잭션 조율 / Repository 조합 / Request → Response 변환 / `flush` 까지 | DB 직접 호출 / `data: dict` 파라미터 / Model 직접 반환 / `commit()` |
| Repository | `BaseRepository[Model]` 상속 / 도메인 쿼리 확장 / Model 인스턴스 반환 | 비즈니스 규칙 (상태 전이·권한 체크) / `commit()` |

## grep 기반 위반 검출

각 단계 끝에서 검증. 위반 0 = 4계층 정렬 통과.

```bash
# Router 의 DB 직접 호출
grep -n "select\|db\.execute\|db\.add\|db\.flush" {router-dir}/*.py
# Service 의 SQLAlchemy 직접 사용
grep -n "^from sqlalchemy import.*select\|await db\.execute\|db\.add(\|db\.flush(" {service-dir}/*.py
# Response DTO 누락
grep -L "response_model=" {router-dir}/*.py
```

자동화 가능한 checklist 가 *재현 가능한 정렬* 의 핵심. CI 후크 또는 PreToolUse hook 으로 강제할 수 있음 (follow-up).

## TDD 사이클 — Red → Green → Refactor

| 단계 | 본질 | 강제 |
|------|------|------|
| Red | 스펙 기반 테스트 → **실패 확인** | 구현 0 으로 시작. 통과하면 테스트가 의미 없음 (의도 미반영) |
| Green | 통과하는 *최소* 구현 | 과도 설계 금지. 통과만 시키고 다음 단계로 |
| Refactor | 통과 유지하면서 정리 (네이밍·중복·계층 위반) | 테스트 fail 시 즉시 revert |

`test-design` SKILL (자매) 가 Red 단계의 *시나리오 합의* 영역 — 본 SKILL 의 step 2 직전.

## reference 로드 모델

SKILL trigger 시 사용처 프로젝트의 컨벤션·인프라 문서를 우선 로드 — 5 슬롯:

| 우선순위 | 경로 | 슬롯 | 책임 |
|---------|------|------|------|
| 1 | `plan/api/<domain>.md`, `plan/api/overview.md` | A. API 도메인 / 응답 컨벤션 | 기존 엔드포인트 · 응답 형식 · 페이지네이션 · Rate Limiting |
| 2 | `plan/erd/database-rules.md`, `plan/erd/table-design.md` | B. DB 룰 / 모델 패턴 | 네이밍 · FK 정책 · 소프트 딜리트 · BaseEntity / Mixin |
| 3 | `plan/design-standards/*.md` | C. 디자인 표준 | 코딩 컨벤션 · 에러 핸들링 · 보안 · 테스트 전략 |
| 4 | `plan/refactor/re*-*.md` | D. 리팩토링 트래커 | 도메인별 4계층 정렬 진행 현황 |
| 5 | `CLAUDE.md` | E. 프로젝트 가이드라인 | Repository 룰 · import 컨벤션 · 도메인 어휘 |
| 6 (fallback) | role-generic | A~E 모두 | REST 일반 원칙 / SOLID / 일반 4계층 디렉토리 추정 (`{server,backend,api}/{routers,services,repositories,schemas}/`) / 사용자에게 도메인 어휘 주입 요청 |

**fallback (role-generic)** 의 점검 항목:
- API 설계: REST 표준 (복수형 명사·계층 URL·HTTP 메서드 의미·상태코드)
- DB: 자동 생성 PK · 명시적 FK · 소프트 딜리트 권장 · 멀티테넌시 식별자 (사용자 주입 필요)
- 4계층: HTTP 어댑터 / 비즈니스 / DB 접근 / 모델 — 디렉토리 자동 탐색
- TDD: pytest / unittest 기본 가정. 프로젝트별 위치는 사용자 주입

**충돌 룰** — 두 reference 가 같은 항목을 다르게 정의하면:
1. **우선순위 낮은 번호 (1번 `plan/api/`) 가 우선**. API 도메인 결정은 plan/api 의 SSOT.
2. 충돌 자체를 *작업 보고* 에 명시 — "X 항목: plan/api/foo.md (룰 A) vs CLAUDE.md (룰 B), 본 작업은 1번 적용".
3. 명백한 오타·구버전 잔재로 보이면 1번 적용 후 사용자에게 정합성 점검 권고.

**리포트 출처 강제** — 각 단계의 결정 / 위반 / 정렬 항목은 *어느 reference 의 어느 §* 인지 명시:
- `plan/erd/database-rules.md §FK 정책` 처럼 *파일 + § (섹션)* 까지.
- fallback 만으로 결정한 항목은 `role-generic — {항목}` (예: `role-generic — REST 표준 URL 컨벤션`).
- 출처 미박힘 = 다음 작업 시 재현 불가.

NEXUS 등 특정 컨벤션은 본 SKILL 본문에 박지 않음 — [[adr-0003-backend-rules-to-backend]] §자산 분리 룰. 사용 사례 누적 시 분기 ADR + 별도 reference 자산.

## Don't

- 단계 순서 위반 — Red 없이 Green / Green 없이 Refactor 금지.
- 4계층 위반 — Router 의 DB 직접 호출 / Repository 의 비즈니스 규칙 / Schema 의 SQLAlchemy import 등 모두 grep 으로 검출되는 즉시 차단.
- `commit()` 을 Service / Repository 에서 호출 — 미들웨어 · 엔드포인트 레벨에서만.
- `data: dict` 파라미터 — 모든 Service 입력은 `*Request` DTO.
- Response DTO 없이 Model 직접 응답 — `response_model=` 누락 = 차단.
- 테스트 fail 상태로 Refactor 단계 진입.
- 본 SKILL 본문에 NEXUS / Spring 등 특정 컨벤션 박기 ([[adr-0003-backend-rules-to-backend]] §자산 분리 룰 §금지).
- 사용자 코드 (구현 본문) 직접 작성 — 본 SKILL 은 *절차 안내 + 위반 검출* 만. Green 단계의 실제 구현은 사용자 손.
