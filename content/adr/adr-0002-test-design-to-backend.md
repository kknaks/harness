---
id: adr-0002
title: Test Design To Backend
type: adr
status: proposed
date: 2026-04-30
sources:
  - "[[wiki-02-test-design-pattern]]"
tags: [adr]
categories: [test-design]
role: backend
related_to:
  - "[[adr-0001-code-review-to-backend]]"
aliases: []
---

# Test Design To Backend

## Context

승격 원본: `content/wiki/wiki-02-test-design-pattern.md` (sources: `sources-02-test-designer`, NEXUS 백엔드 `/test-design` SKILL 박제).

wiki-02 는 두 층으로 합성됨:
- **공용 골격 (project-agnostic)** — *테스트 = 실행 가능한 문서* 원칙 / 3계층 docstring 구조 (클래스·메서드·코드 주석) / Test Data Builder (Mother) 패턴 / 시나리오 4분류 (Happy / Edge / 비즈니스 규칙 / 상태 전이) / 설계 리포트 포맷 (구현 전 합의 산출물).
- **프로젝트 의존 슬롯 (NEXUS 백엔드 사례)** — Mother 위치 (`packages/admin-api/tests/mothers/`) / API 클라이언트 (`AdminApiClient` + sub-client) / 도메인 어휘 (branch / manager / customer ... + HQ vs 지점 권한 / 에러 코드 컨벤션).

본 ADR 의 결정 단위 = *이 자산이 backend role plugin 에 어떻게 입주하는가*. 자매 ADR `adr-0001-code-review-to-backend` 와 동일한 *wiki 두 층 → plugin 단계 분리 처리* 패턴 적용.

## Decision

backend role plugin 의 `test-design` SKILL 본문에는 **공용 골격만 박는다** (의도 표현 원칙 / 3계층 docstring / Mother 패턴 / 시나리오 4분류 / 설계 리포트 포맷). NEXUS 등 프로젝트 의존 슬롯 (Mother 위치 / API 클라이언트 / 도메인 어휘) 은 SKILL trigger 시 사용처 프로젝트의 컨벤션 문서 (`docs/common/test-data-builders.md`, `docs/common/api-clients.md`, `CLAUDE.md` 등) 를 **reference 로 로드**하고, 부재 시 *role-generic fallback* ("Mother 위치는 사용처 테스트 디렉토리에서 자동 탐색" / "도메인 어휘는 사용처에서 주입") 으로 동작한다. 특정 컨벤션 채택 사례 누적 시 본 ADR 과 병렬로 분기 ADR (`adr-NNNN-{convention}-test-design-to-backend`) 을 추가한다.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + NEXUS 슬롯 *합쳐서* backend plugin 본문에 박기 | wiki 두 층 분리 무효화. backend role plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지). NEXUS 외 프로젝트 이식 0 |
| 처음부터 분기 ADR (`nexus-test-design-to-backend`) 만 박고 본 ADR 생략 | 채택 사례 1건만 있는 시점 분기는 과조숙. role-generic 부재 시 NEXUS 외 들어올 때 referent 0 |
| `qa` role 에 매핑 | sources-02 가 백엔드 `admin-api` 테스트 설계 — 백엔드 코드 작성 흐름의 일부. QA 분리 조직이면 `qa` 후보지만 현 운영은 backend 일체. QA role 분기 발생 시 별 ADR 분기 가능 |
| Mother 패턴만 base 로 hoist | Mother 패턴이 frontend 에서도 채택된 사례 0. ADR-0011 §3 hoisting 트리거 (3 role+ 분포) 미달 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| backend plugin `test-design` SKILL 본문 작성 — 공용 골격 5요소 (의도 표현 / 3계층 docstring / Mother / 시나리오 4분류 / 리포트 포맷) | 메인테이너 | v0.1 | wiki-02 §공용 골격 → SKILL.md |
| SKILL trigger 시 reference 로드 메커니즘 박기 — Mother 위치·API 클라이언트·도메인 어휘 3 슬롯 | 메인테이너 | v0.1 | adr-0001 의 reference 로드 hook 와 공통화 검토 |
| role-generic fallback 작성 (Mother 자동 탐색·도메인 어휘 주입) | 메인테이너 | v0.1 | SKILL.md 내 fallback 섹션 |
| `code-review`·`test-design` 두 SKILL 의 reference 로드 hook 공통 추출 검토 | 메인테이너 | v0.2 | backend plugin 공통 hook |
| `adr-to-harness.sh` 로 backend plugin 자산 입주 + Notes lineage | 메인테이너 | v0.1 패키징 | spec-09 release flow |

## Consequences

**Pros**
- backend plugin 이 *project-agnostic* 으로 이식 가능 — Mother 위치·API 클라이언트만 사용처에서 박으면 채택
- 시나리오 4분류·3계층 docstring 같은 *문서로서의 테스트* 원칙은 컨벤션과 무관하게 보편 적용
- `code-review` 와 같은 분리 패턴 → backend plugin 의 일관된 SKILL 모델

**Cons**
- 첫 사용처가 NEXUS 외 프로젝트면 Mother 위치 fallback 이 약함 (테스트 디렉토리 컨벤션 다양)
- 도메인 어휘 슬롯이 비면 시나리오 명명 (예: `test_creates_branch_with_auto_generated_slug`) 의 풍부도 ↓
- 분기 ADR 누적 시 backend plugin 의 reference 로드 매트릭스 관리 복잡도 ↑

**Follow-ups**
- [ ] Mother 패턴이 frontend test 에서도 채택되면 ADR-0011 §3 hoisting 후보 (base 로)
- [ ] QA 분리 조직 채택 사례 발생 시 `qa` role 분기 ADR 검토
- [ ] `adr-0001` 의 reference 로드 hook 와 공통화 — backend plugin 의 공통 hook 추출

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_

- 2026-04-30 — proposed. wiki-02 → backend role 매핑 결정. 자매 ADR: `adr-0001-code-review-to-backend` (같은 패턴, code-review topic).
