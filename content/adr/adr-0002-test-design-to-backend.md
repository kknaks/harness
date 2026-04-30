---
id: adr-0002
title: Test Design To Backend
type: adr
status: proposed
date: 2026-04-30
sources:
  - "[[wiki-02-test-design-pattern]]"
related_to:
  - "[[adr-0001-code-review-to-backend]]"
tags: [adr]
categories: [test-design]
role: backend
aliases: []
---

# Test Design To Backend

## Context

`wiki-02-test-design-pattern` 은 두 층으로 합성된 지식 노드:
- **공용 골격 (project-agnostic)** — "테스트 = 실행 가능한 문서" 원칙, 3계층 docstring (클래스=기획서 / 메서드=상황·동작·결과 + G-W-T / 코드=주석), Test Data Builder(Mother) 패턴, 시나리오 4유형(Happy / Edge·Error / 비즈니스 규칙 / 상태 전이), 설계 리포트 포맷
- **프로젝트 의존 슬롯** — NEXUS 백엔드 인프라 (`packages/admin-api/tests/mothers/`, `AdminApiClient`, 도메인 어휘 branch/manager/customer/..., `BRANCH_NAME_DUPLICATE` 같은 에러 코드 컨벤션, HQ vs 지점 권한 분기)

원본 SKILL 의 사용 환경 = NEXUS 백엔드 admin-api 테스트. 슬롯이 백엔드 테스트 인프라(Mother·fixture·API client)를 가정.

[[adr-0011-base-hoisting]] §사전 분할 X 정렬 + 자매 ADR `adr-0001-code-review-to-backend` 와 동일 결정 모델 (1 wiki → 1 plugin atomic).

## Decision

`wiki-02-test-design-pattern` 자산을 **`content/harness/plugins/backend/skills/test-design/`** 에 입주시킨다.

- **SKILL 본문 = wiki 의 *공용 골격* 만** (project-agnostic): "테스트 = 실행 가능한 문서" 원칙, 3계층 docstring (클래스/메서드/코드), 시나리오 4유형 (Happy/Edge·Error/비즈니스 규칙/상태 전이), Test Data Builder *패턴* (이름·역할·G-W-T 골격), 설계 리포트 포맷.
- **NEXUS 백엔드 인프라 슬롯은 plugin 본문에 박지 않는다.** (promote-docs SKILL §자산 분리 룰) 처리 모델:
  - (a) **reference 로드** — 사용처 프로젝트의 테스트 인프라 문서 (`tests/README.md`, mothers/fixtures 위치, API client 가이드 등) 를 SKILL trigger 시 로드.
  - (b) **role-generic fallback** — reference 부재 시 SKILL 본문에 *generic 백엔드 테스트 원칙* (Test Data Builder 패턴 일반론·픽스처 격리·빌더 명명 가이드 수준). NEXUS-specific Mother 위치 (`packages/admin-api/tests/mothers/`) / `AdminApiClient` / 도메인 어휘 (branch/manager/...) / `BRANCH_NAME_DUPLICATE` 같은 에러 코드는 박지 않음.
- 슬래시 명령 `/test-design` 본문 보존 (트리거 + 인프라 reference 로드 지시).
- NEXUS 인프라 슬롯이 필요한 사용처는 별도 분기 ADR (`adr-NNNN-nexus-backend-test-design`) 또는 별도 plugin (`nexus-backend/`) 로 분리.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| (a) **base/skills/test-design/ 직접 입주** (사전 hoisting) | [[adr-0011-base-hoisting]] §사전 분할 X 위반. 다른 분야 테스트 SKILL 추가 전 실제 중복 X |
| (b) **공용 골격 + NEXUS 슬롯 *합쳐서* role plugin 본문 박기** | wiki 두 층 분리 무효화. backend role plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지). 다른 백엔드 프로젝트 도입 시 NEXUS 인프라 박혀 있어 이식 비용 ↑ |
| (c) **공용 골격만 role plugin 입주 + NEXUS 인프라 슬롯 reference / 분기 ADR 분리 (현재 ✓)** | wiki 두 층 분리 보존. backend plugin 은 role-generic 유지. NEXUS 외 백엔드 인프라 (다른 ORM/프레임워크/Mother 컨벤션) 도입 시 분기 ADR 또는 별도 plugin 으로 자연 확장. 자매 ADR adr-0001 과 동일 패턴 |
| (d) **NEXUS 특화 plugin 신설** (예: `nexus-backend/`) — 단독 채택 | 공용 골격까지 NEXUS plugin 에 박히면 다른 백엔드 프로젝트가 골격 못 받음. (c) 와 결합해 *공용 골격 = backend / NEXUS 인프라 = nexus-backend* 분리는 운영 사례 누적 시 자연스러운 다음 단계 |
| (e) **테스트 설계 + 코드 리뷰 묶어 1 ADR** | atomic 단위 위반 — 자산 매핑은 자산별 별 결정. 운영 후 둘 다 같은 정책 굳을 때 별 정책 ADR (예: `adr-NNNN-backend-skill-extraction-policy`) 신설 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `content/harness/plugins/backend/skills/test-design/SKILL.md` 작성 — **공용 골격만** (3계층 docstring·시나리오 4분류·리포트 포맷·Test Data Builder 패턴 일반론). NEXUS Mother 위치 / `AdminApiClient` / 도메인 어휘 / 에러 코드 박지 않음 | 메인테이너 | v0.1 release 전 | [[wiki-02-test-design-pattern]] §공용 골격 |
| SKILL trigger 가이드 — 사용처 프로젝트의 테스트 인프라 문서 (`tests/README.md`, mothers/fixtures 위치) 를 reference 로 로드. 부재 시 *role-generic fallback* (Builder 패턴 일반론·빌더 명명 가이드) 작동 | 메인테이너 | v0.1 release 전 | — |
| harness skill 안내에 *프로젝트 테스트 인프라 reference 채우기* 가이드 추가 | 메인테이너 | v0.2 release 전 | [[adr-0006-onboarding-skill]] |
| NEXUS 인프라 슬롯이 명시적으로 필요한 사용처 발견 시 분기 ADR `adr-NNNN-nexus-backend-test-design` 또는 별도 plugin `nexus-backend/` 신설 | 메인테이너 | 사례 발생 시 | promote-docs SKILL §자산 분리 룰 (b)/(c) |
| frontend/qa plugin 에 테스트 설계 SKILL 추가 시 — 공용 골격 hoist 검토 | 운영 후 | v0.2+ | [[adr-0011-base-hoisting]] §3 |

## Consequences

**Pros**
- 백엔드 기여자가 `backend` plugin 1개 설치로 `/test-design` 사용 — 기획서 → 의도 담긴 테스트 스켈레톤 산출
- **role plugin = role-generic** 의미 보존 — NEXUS 외 백엔드 프로젝트도 같은 plugin 그대로 도입 가능
- 시나리오 4분류·3계층 docstring·Builder 패턴 일반론 골격은 다른 백엔드 프로젝트도 그대로 재사용
- adr-0001 과 짝을 이뤄 백엔드 plugin 의 *리뷰(사후) + 설계(사전)* 두 phase SKILL 셋 완성
- wiki 의 두 층 분리가 plugin 단계까지 보존 (promote-docs SKILL §자산 분리 룰 정렬)

**Cons**
- reference 부재 + role-generic fallback 만으로는 NEXUS Mother 명명 / 도메인 어휘 / 에러 코드 같은 *세부 컨벤션 강제* 가 빈약 — NEXUS 사용처는 분기 ADR 또는 별도 plugin 으로 보강 필요
- Builder 패턴은 *백엔드 테스트* 의 가정 (DB·API·도메인 엔티티). 프론트엔드 (컴포넌트 fixture·MSW handler) 또는 데이터 파이프라인 (sample 입력 빌더) 에는 그대로 안 맞음 → 분야별 SKILL 추가 시 별도 결정
- 만약 frontend plugin 에 테스트 설계 SKILL 추가 → 공용 골격 (3계층 docstring·시나리오 4분류·리포트) 이 중복 → [[adr-0011-base-hoisting]] §3 hoisting 트리거 충족 가능

**Follow-ups**
- [ ] frontend/qa 등에 테스트 설계 SKILL 추가 시 공용 골격 hoisting 결정
- [ ] NEXUS 인프라 슬롯이 필요한 사용처 발견 시 분기 ADR `adr-NNNN-nexus-backend-test-design` 또는 별도 plugin 신설
- [ ] adr-0001 과 둘 다 같은 정책 (공용 골격만 plugin / project 슬롯 분리) 굳으면 *backend SKILL 추출 정책* ADR 신설 검토
- [ ] role-generic fallback 본문 분량이 SKILL 500자 초과 시 reference/ 분리

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_

- 2026-04-30: scaffold 생성. status=proposed. e2e 사이클 콘텐츠 ADR 두 번째 사례 — adr-0001 과 같은 결정 모델 일반화 신호.
- 2026-04-30: Decision 본문 patch — 초안은 "공용 골격 + NEXUS 인프라 슬롯 *합쳐서* backend plugin 본문 박음" 으로 role plugin 의 role-generic 의미와 자기모순. promote-docs SKILL §자산 분리 룰 신규 박은 후 본 ADR Decision 을 *공용 골격만 plugin / NEXUS 인프라는 reference·분기 ADR·별도 plugin* 모델로 재정의 (자매 ADR adr-0001 과 동일 패치).
- **hoisting 가설** — 다른 분야 plugin (frontend/QA 등) 에 동일 *공용 골격* (3계층 docstring · 시나리오 4분류 · Builder 패턴) 이 추가되어 ADR-0011 §3 트리거 충족 시: 공용 골격을 `base/skills/test-design-pattern/` 으로 hoist + 분야별 fallback 만 분야 plugin 에 잔류.
- **슬롯 분기 가설** — NEXUS 외 백엔드 (다른 ORM/프레임워크/Mother 컨벤션) 도입 시 별도 ADR `adr-NNNN-{infra}-test-design-to-backend` 또는 별도 plugin 으로 분기 (병렬 채택).
- 자매 ADR: [[adr-0001-code-review-to-backend]] — 같은 모델 (atomic 1 wiki → 1 plugin, 공용 골격만 plugin 본문, project 슬롯 분리).
