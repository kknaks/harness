---
id: adr-0001
title: Code Review To Backend
type: adr
status: proposed
date: 2026-04-30
sources:
  - "[[wiki-01-code-review-pattern]]"
tags: [adr]
categories: [code-review]
role: backend
related_to:
  - "[[adr-0002-test-design-to-backend]]"
aliases: []
---

# Code Review To Backend

## Context

승격 원본: `content/wiki/wiki-01-code-review-pattern.md` (sources: `sources-01-code-review`, NEXUS 백엔드 `/review` SKILL 박제).

wiki-01 은 두 층으로 합성됨:
- **공용 골격 (project-agnostic)** — 4단계 리뷰 프로세스 / 400줄 임계값 / 심각도 5분류 (🔴🟡🟢💡🎉) / 줄단위 점검 (언어 무관·언어 특화 분리) / 마크다운 리포트 포맷 (이슈 ID + Convention 출처 + Before/After).
- **프로젝트 의존 슬롯 (NEXUS 백엔드 사례)** — Layer Objects 4객체 / Validator 3계층 / Router-Service-Repository 룰. `docs/common/layer-objects.md`, `docs/common/layer-design.md`, `CLAUDE.md` 를 reference 로 의존.

본 ADR 의 결정 단위 = *이 자산이 backend role plugin 에 어떻게 입주하는가*. ADR-0011 §1 base/role hoisting 모델 위에서 backend role facet 매핑.

## Decision

backend role plugin 의 `code-review` SKILL 본문에는 **공용 골격만 박는다**. NEXUS 등 프로젝트 의존 슬롯은 SKILL trigger 시 사용처 프로젝트의 `docs/common/*.md` + `CLAUDE.md` 를 **reference 로 로드**하고, 해당 reference 부재 시 *role-generic fallback* (MVC/계층화 일반 원칙·역방향 의존 금지·BaseRepository 류 일반 패턴) 으로 동작한다. 특정 컨벤션 채택 사례가 누적되면 본 ADR 과 병렬로 분기 ADR (`adr-NNNN-{convention}-code-review-to-backend`) 을 추가하지 supersede 하지 않는다.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + NEXUS 슬롯 *합쳐서* backend plugin 본문에 박기 | wiki 두 층 분리 무효화. backend role plugin 의 *role-generic* 의미 자기모순 (promote-docs SKILL §자산 분리 룰 §금지). 다른 프로젝트 이식 0 |
| 처음부터 분기 ADR (`nexus-code-review-to-backend`) 만 박고 본 ADR 생략 | NEXUS 채택 사례 1건만 있는 현 시점에 분기는 과조숙. role-generic 본 ADR 부재 시 다른 프로젝트가 들어올 때 referent 가 없음 |
| 별도 convention plugin (`nexus-backend/`) | role plugin 모델과 분리되는 결정 — ADR-0011 §3 hoisting 영역, 본 ADR scope 외 |
| base role 로 hoisting | code-review topic 이 frontend / qa 등 다른 role 에서도 채택된 사례 0. ADR-0011 §3 hoisting 트리거 (3 role+ 분포) 미달 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| backend plugin `code-review` SKILL 본문 작성 — 공용 골격 5요소 (4단계 / 임계값 / 심각도 / 줄단위 분리 / 리포트 포맷) | 메인테이너 | v0.1 | wiki-01 §공용 골격 → SKILL.md |
| SKILL trigger 시 reference 로드 메커니즘 박기 — `docs/common/*.md` + `CLAUDE.md` 우선, 부재 시 fallback | 메인테이너 | v0.1 | adr-0007 skill-authoring rules §lazy-load |
| role-generic fallback 작성 (MVC·계층화 일반 원칙) | 메인테이너 | v0.1 | SKILL.md 내 fallback 섹션 |
| 두 번째 채택 사례 발생 시 분기 ADR 트리거 검토 | 메인테이너 | 운영 누적 후 | 본 ADR Notes append |
| `adr-to-harness.sh` 로 backend plugin 자산 입주 + Notes lineage | 메인테이너 | v0.1 패키징 | spec-09 release flow |

## Consequences

**Pros**
- backend plugin 이 *project-agnostic* 으로 이식 가능 — NEXUS 외 프로젝트는 자기 `docs/common/*` 만 박으면 채택
- wiki 두 층 분리가 plugin 단계까지 보존 → ADR-0011 hoisting 모델 정합
- 분기 ADR 패턴이 열려있어 컨벤션-specific 풍부도를 잃지 않음 (병렬 채택)

**Cons**
- 첫 사용처가 NEXUS 외 프로젝트인 경우 fallback 으로 동작 → 풍부도 떨어짐
- SKILL 본문 (공용 골격) vs reference (프로젝트 의존) 경계 운영 부담 — 새 점검 항목 추가 시 어느 층인지 매번 판단 필요

**Follow-ups**
- [ ] NEXUS 외 백엔드 프로젝트 채택 사례 1건 발생 시 분기 ADR 필요성 재평가
- [ ] frontend / qa role 에 같은 `code-review` topic ADR 가 생기면 ADR-0011 §3 hoisting 후보 (base 로)
- [ ] reference 로드 메커니즘이 `test-design-to-backend` (adr-0002) 와 중복되면 backend plugin 공통 hook 으로 추출

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 wiki 추가 등)_

- 2026-04-30 — proposed. wiki-01 → backend role 매핑 결정. 자매 ADR: `adr-0002-test-design-to-backend` (같은 패턴, test-design topic).
- 2026-04-30: applied to plugin `backend` (content/harness/plugins/backend/)
