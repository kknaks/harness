---
id: adr-0001
title: Code Review To Backend
type: adr
status: proposed
date: 2026-04-30
sources:
  - "[[wiki-01-code-review-pattern]]"
related_to:
  - "[[adr-0002-test-design-to-backend]]"
tags: [adr]
categories: [code-review]
role: backend
aliases: []
---

# Code Review To Backend

## Context

`wiki-01-code-review-pattern` 은 두 층으로 합성된 지식 노드:
- **공용 골격 (project-agnostic)** — 4단계 리뷰 프로세스, 변경 규모 임계값(400줄), 심각도 5분류표, 마크다운 리포트 포맷, 줄 단위 일반 점검 항목
- **프로젝트 의존 슬롯** — NEXUS 백엔드 컨벤션 (Layer Objects, L1/L2/L3 검증, Router/Service/Repository 룰)

원본 SKILL 의 사용 환경 = NEXUS 백엔드 (`packages/admin-api`). 슬롯이 백엔드 컨벤션 문서(`docs/common/layer-objects.md` 등)를 trigger 시 reference 로 로드함.

[[adr-0011-base-hoisting]] §사전 분할 X — 첫 입주는 분야 plugin, 운영 중 중복 발생 시 base 로 hoisting. 본 결정은 그 패턴의 *콘텐츠 레이어 첫 적용 사례*.

## Decision

`wiki-01-code-review-pattern` 자산을 **`content/harness/plugins/backend/skills/code-review/`** 에 입주시킨다.

- **SKILL 본문 = wiki 의 *공용 골격* 만** (project-agnostic): 4단계 리뷰 프로세스, 심각도 5분류, 400줄 임계, 언어 무관/특화 분리, 마크다운 리포트 포맷.
- **NEXUS 백엔드 슬롯은 plugin 본문에 박지 않는다.** (promote-docs SKILL §자산 분리 룰) 처리 모델:
  - (a) **reference 로드** — 사용처 프로젝트의 `docs/common/*.md`, `CLAUDE.md` 를 SKILL trigger 시 로드.
  - (b) **role-generic fallback** — reference 부재 시 SKILL 본문에 *generic 백엔드 원칙* (계층 분리·의존 방향·검증 책임 분리 일반론 수준). NEXUS-specific Layer Objects 4객체 / L1-L3 / Router 4파라미터 룰 등은 박지 않음.
- 슬래시 명령 `/review` 본문 보존 (트리거 + 컨벤션 reference 로드 지시).
- NEXUS 컨벤션 슬롯이 필요한 사용처는 별도 분기 ADR (`adr-NNNN-nexus-backend-review`) 또는 별도 plugin (`nexus-backend/`) 로 분리.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| (a) **base/skills/code-review/ 직접 입주** (사전 hoisting) | 추측 분할 — [[adr-0011-base-hoisting]] §사전 분할 X 위반. 다른 분야 SKILL 추가 전 실제 중복 발생 X. 가설 단계 |
| (b) **공용 골격 + NEXUS 슬롯 *합쳐서* role plugin 본문 박기** | wiki 두 층 분리 무효화. backend role plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지). 다른 백엔드 프로젝트 도입 시 NEXUS 슬롯 박혀 있어 이식 비용 ↑ |
| (c) **공용 골격만 role plugin 입주 + NEXUS 슬롯 reference / 분기 ADR 분리 (현재 ✓)** | wiki 두 층 분리 보존. backend plugin 은 role-generic 유지. NEXUS 외 백엔드 컨벤션 도입 시 분기 ADR 또는 별도 plugin 으로 자연 확장 |
| (d) **NEXUS 특화 plugin 신설** (예: `nexus-backend/`) — 단독 채택 | 공용 골격까지 NEXUS plugin 에 박히면 다른 백엔드 프로젝트가 골격 못 받음. (c) 와 결합해 *공용 골격 = backend / NEXUS 슬롯 = nexus-backend* 분리는 운영 사례 누적 시 자연스러운 다음 단계 |
| (e) **wiki-01 + wiki-02 묶어 1 ADR** (정책 ADR) | atomic 단위 위반 — 자산 매핑은 자산별 분리 ([[adr-0003-content-pipeline]] §wiki vs adr 단계). 정책 추출은 N개 매핑 굳을 때 별 정책 ADR |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `content/harness/plugins/backend/skills/code-review/SKILL.md` 작성 — **공용 골격만** (4단계·심각도 5종·400줄 임계·언어 무관/특화 분리·리포트 포맷). NEXUS Layer Objects/L1-L3/Router 룰 박지 않음 | 메인테이너 | v0.1 release 전 | [[wiki-01-code-review-pattern]] §공용 골격 |
| SKILL trigger 가이드 — 사용처 프로젝트의 `docs/common/*.md`, `CLAUDE.md` 를 reference 로 로드. 부재 시 *role-generic fallback* (계층 분리·의존 방향 일반론) 작동 | 메인테이너 | v0.1 release 전 | — |
| harness skill 안내에 *사용자 프로젝트 컨벤션 reference 채우기* 가이드 추가 | 메인테이너 | v0.2 release 전 | [[adr-0006-onboarding-skill]] |
| NEXUS 컨벤션 슬롯이 명시적으로 필요한 사용처 발견 시 분기 ADR `adr-NNNN-nexus-backend-review` 또는 별도 plugin `nexus-backend/` 신설 | 메인테이너 | 사례 발생 시 | promote-docs SKILL §자산 분리 룰 (b)/(c) |
| 다른 분야 plugin (frontend/QA 등) 에 동일 *공용 골격* SKILL 추가 시 — base 로 hoist 검토 | 운영 후 | v0.2+ | [[adr-0011-base-hoisting]] §3 트리거 |

## Consequences

**Pros**
- 백엔드 기여자가 `backend` plugin 1개 설치로 `/review` 사용 가능 — 분야별 plugin 분리 모델 ([[adr-0011-base-hoisting]]) 에 충실
- **role plugin = role-generic** 의미 보존 — NEXUS 외 백엔드 프로젝트 (Spring/DDD/Rails 등) 도 같은 plugin 그대로 도입 가능
- 공용 골격이 분야 plugin 에 박혀 있어 다른 분야 plugin 에 hoisting 자연 — base 이동 시 골격 그대로
- wiki 의 두 층 분리가 plugin 단계까지 보존됨 (promote-docs SKILL §자산 분리 룰 정렬)

**Cons**
- reference 부재 + role-generic fallback 만으로는 NEXUS Layer Objects 같은 *세부 컨벤션 강제* 가 빈약 — NEXUS 사용처는 분기 ADR 또는 별도 plugin 으로 보강 필요
- 공용 골격이 backend plugin 안에 박혀 있는 동안 frontend·QA 등이 동일 골격을 별도로 만들면 중복 발생 → [[adr-0011-base-hoisting]] §3 hoisting 트리거 (2+ role plugin 에 복사) 충족 시 base 로 이동

**Follow-ups**
- [ ] 다른 분야 plugin (frontend/qa) 코드 리뷰 SKILL 추가 시 공용 골격 hoisting 결정 (base 로 이동)
- [ ] NEXUS 컨벤션 슬롯이 필요한 사용처 발견 시 분기 ADR `adr-NNNN-nexus-backend-review` 또는 별도 plugin 신설
- [ ] role-generic fallback 본문 분량이 SKILL 500자 초과 시 reference/ 분리 ([[adr-0007-skill-authoring-rules]] §1)

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_

- 2026-04-30: scaffold 생성. status=proposed. e2e 사이클 콘텐츠 ADR 첫 사례.
- 2026-04-30: Decision 본문 patch — 초안은 "공용 골격 + NEXUS 슬롯 *합쳐서* backend plugin 본문 박음" 으로 role plugin 의 role-generic 의미와 자기모순. promote-docs SKILL §자산 분리 룰 신규 박은 후 본 ADR Decision 을 *공용 골격만 plugin / NEXUS 슬롯은 reference·분기 ADR·별도 plugin* 모델로 재정의.
- **hoisting 가설** — 다른 분야 plugin (frontend/QA 등) 에 동일 *공용 골격* SKILL 이 추가되어 ADR-0011 §3 트리거 충족 시: 공용 골격을 `base/skills/code-review-pattern/` 으로 hoist + 분야별 fallback 만 분야 plugin 에 잔류.
- **슬롯 분기 가설** — NEXUS 등 특정 컨벤션 채택 사례 누적 시 별도 ADR `adr-NNNN-{convention}-{role}` 또는 별도 plugin (`nexus-backend/`) 으로 분기. supersede 가 아니라 *병렬 채택* (사용 프로젝트별 선택).
- 자매 ADR: [[adr-0002-test-design-to-backend]] — 동일 결정 모델 (1 wiki → 1 plugin atomic, 공용 골격만 plugin 본문, project 슬롯 분리) 적용.
