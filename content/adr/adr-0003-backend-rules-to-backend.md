---
id: adr-0003
title: Backend Rules To Backend
type: adr
status: proposed
date: 2026-04-30
sources:
  - "[[wiki-03-backend-rules-pattern]]"
tags: [adr]
categories: [backend-rules, lifecycle]
role: backend
related_to:
  - "[[adr-0001-code-review-to-backend]]"
  - "[[adr-0002-test-design-to-backend]]"
aliases: []
---

# Backend Rules To Backend

## Context

승격 원본: `content/wiki/wiki-03-backend-rules-pattern.md` (sources: `sources-03-backend-rules`, NEXUS 백엔드 SKILL 4종 박제 — `api-design` / `tdd-cycle` / `refactor-layered` / `backend.md` 컨벤션 reference).

wiki-03 은 두 층으로 합성됨:
- **공용 골격 (project-agnostic)** — *백엔드 작업 라이프사이클 4단계* (설계 → Red → Green → Refactor) + *4계층 아키텍처* (Router / Service / Repository / Schema 책임·금지 표) + *grep 기반 위반 검출* + *TDD 사이클* + *reference 로드 모델*.
- **프로젝트 의존 슬롯 (NEXUS 백엔드 사례)** — 환경 (uv / docker compose / alembic) / API 도메인 위치 (`plan/api/<domain>.md`) / 4계층 위치 (`server/app/{routers,services,repositories,schemas}/`) / 도메인 어휘 (멀티테넌시·UUID·소프트 딜리트·ISO 8601) / 리팩토링 트래커 (`plan/refactor/re6-*.md`).

본 ADR 의 결정 단위 = *이 자산이 backend role plugin 에 어떻게 입주하는가*. 자매 ADR `adr-0001-code-review-to-backend` (사후 검토) / `adr-0002-test-design-to-backend` (사전 설계) 와 동일한 *wiki 두 층 → plugin 단계 분리 처리* 패턴 적용 — 본 ADR 은 *작업 라이프사이클* 영역 매핑.

## Decision

backend role plugin 의 신규 SKILL `backend-rules` 본문에 **공용 골격만 박는다** — 라이프사이클 4단계 / 4계층 책임표 / grep 위반 검출 / TDD 사이클 / reference 로드 모델. NEXUS 의 환경·위치·도메인 어휘 슬롯은 SKILL trigger 시 *reference 로 로드* — `plan/api/`, `plan/design-standards/`, `plan/erd/`, `plan/refactor/`, `CLAUDE.md` 가 사용처에 있으면 우선 로드, 부재 시 *role-generic fallback* (REST 일반 원칙 / SOLID / 일반 디렉토리 추정) 으로 동작.

특정 컨벤션 채택 사례 누적 시 본 ADR 과 병렬로 *분기 ADR* (`adr-NNNN-{convention}-backend-rules-to-backend`) 추가. 라이프사이클 4단계 중 일부 (예: `api-design` 만) 가 다른 role 에서도 채택되면 ADR-0011 §3 hoisting 트리거 후보.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + NEXUS 슬롯 *합쳐서* backend plugin 본문에 박기 | wiki 두 층 분리 무효화. backend role plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지). NEXUS 외 프로젝트 이식 0 |
| 4 SKILL 로 분리 박기 (`api-design` / `tdd-cycle` / `refactor-layered` / `backend-conventions`) | 1차 demo 시점엔 단일 `backend-rules` SKILL 로 묶음 — 운영 사용 사례 누적 후 분기 결정 (use-case 별로 *하나만 호출* 되는 사례가 충분할 때). 현재는 4단계 라이프사이클이 *함께 호출* 되는 시나리오가 더 자연 |
| `tdd-cycle` 을 `test-design` (adr-0002) 와 합치기 | test-design = *사전 설계* (시나리오·docstring·Mother). tdd-cycle = *Red→Green→Refactor 루프*. 같은 도메인이지만 *결정 단위* 가 다름 (설계 vs 실행). 별 ADR 유지 |
| `backend.md` 컨벤션 reference 를 wiki / SKILL 본문에 박기 | wiki 두 층 분리 §금지 (NEXUS 어휘는 plugin 본문 X). reference 로드 모델로 사용처에서 끌어옴 |
| 처음부터 분기 ADR (`nexus-backend-rules-to-backend`) 만 박고 본 ADR 생략 | 채택 사례 1건만 있는 시점 분기는 과조숙. role-generic 부재 시 NEXUS 외 들어올 때 referent 0 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| backend plugin `backend-rules` SKILL 본문 작성 — 공용 골격 5요소 (4단계 / 4계층 / grep 검출 / TDD / reference 로드) | 메인테이너 | v0.1+ (현 데모 사이클) | wiki-03 §공용 골격 → SKILL.md / rules.md |
| reference 로드 메커니즘 박기 — 5 슬롯 (`plan/api/` / `plan/design-standards/` / `plan/erd/` / `plan/refactor/` / `CLAUDE.md`). adr-0001·adr-0002 의 reference hook 와 공통화 검토 | 메인테이너 | v0.1+ | rules.md `## reference 로드 모델` |
| role-generic fallback 작성 (사용처 디렉토리 자동 탐색 + 사용자에게 도메인 어휘 주입 요청) | 메인테이너 | v0.1+ | rules.md §fallback |
| examples 두 개 박기 (sample-no-reference: REST 일반 / sample-with-reference: NEXUS) | 메인테이너 | v0.1+ | examples/ |
| `add-role-skill.sh backend backend-rules "..."` 호출 → role-templates/backend/skills/backend-rules/ 박힘 + role.json 자동 갱신 | 메인테이너 | v0.1+ | manifest skills[] += backend-rules |
| `adr-to-harness.sh content/adr/adr-0003-backend-rules-to-backend.md backend` cascade — Notes lineage | 메인테이너 | v0.1+ | 본 ADR Notes 에 `applied to plugin backend` 라인 |
| 운영 사용 누적 후 `tdd-cycle` 또는 `api-design` 의 *별 SKILL 분리* 검토 — 사용 사례가 *독립 호출* 패턴일 때 분기 ADR | 메인테이너 | v0.2+ | follow-up 트래커 |

**시나리오 예 (사용자가 새 도메인 박을 때)** — 라이프사이클 4단계 적용

1. `/backend-rules api-design` (또는 자연어 호출) → 1단계: API 엔드포인트 합의 + `plan/api/<domain>.md` 갱신
2. `/test-design <domain>` (자매 SKILL) → 시나리오 합의
3. `/backend-rules tdd-cycle` Red → 테스트 작성 + 실패 확인
4. `/backend-rules tdd-cycle` Green → 4계층 (Schema → Router → Service → Repository) 최소 구현
5. `/backend-rules refactor-layered` → grep 위반 0 + 회귀 테스트 통과
6. `/code-review` (자매 SKILL) → 사후 검토

→ 6 SKILL 이 *라이프사이클 1 cycle* 을 cover (3 SKILL 은 backend-rules 의 sub-procedure, 2 는 자매 SKILL).

## Consequences

**Pros**
- backend plugin 이 *project-agnostic* 으로 이식 가능 — 환경 / 디렉토리 / 도메인 어휘만 사용처 reference 로 끌어옴.
- 라이프사이클 4단계가 SKILL 단위로 트리거 가능 — 각 단계 독립 호출 또는 연쇄 호출.
- `code-review` / `test-design` / `backend-rules` 3 SKILL 이 backend role 의 *완결된 작업 사이클* 을 cover.
- grep 기반 위반 검출이 자동화 (CI 후크에도 박을 수 있음 — follow-up).

**Cons**
- 단일 `backend-rules` SKILL 안에 4 sub-procedure (api-design / tdd-cycle / refactor-layered / 공용 reference) 가 묶여 있어 SKILL.md 본문 비대 위험. 운영 사용 사례 누적 후 분기 결정.
- reference 부재 시 fallback 의 정확도 ↓ (특히 4계층 위치 추정 — Spring vs Express 등 프레임워크 별로 다름).
- TDD 사이클의 *Red→Green→Refactor* 강제는 사용처의 기존 워크플로우 (예: 코드 먼저 후 테스트) 와 충돌 가능 — fallback 안내 박을 것.

**Follow-ups**
- [ ] 4 sub-procedure 를 별 SKILL 로 분기 (`api-design` / `tdd-cycle` / `refactor-layered` / `backend-conventions-reference`) — 사용 사례 누적 후 결정 (3 role+ 분포 도달 시 ADR-0011 §3 hoisting 후보)
- [ ] `code-review` / `test-design` / `backend-rules` 3 SKILL 의 reference 로드 hook 공통 추출 — backend plugin 공통 hook (adr-0002 follow-up 와 통합)
- [ ] grep 위반 검출 자동화 — CI 후크 또는 PreToolUse hook 으로 박기
- [ ] `tdd-cycle` 단계가 frontend/qa role 에서도 채택 사례 발생 시 base 로 hoisting (ADR-0011 §3)
- [ ] NEXUS 외 프로젝트 fallback 검증 — 첫 외부 사용처에서 어휘 / 디렉토리 추정 정확도 측정

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_

- 2026-04-30 — proposed. wiki-03 → backend role 매핑 결정. 자매 ADR: `adr-0001-code-review-to-backend` (사후 검토) / `adr-0002-test-design-to-backend` (사전 설계). 본 ADR 은 *작업 라이프사이클* 영역 — 3 ADR 이 backend role 의 완결된 작업 사이클을 cover.
- 2026-04-30: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
