---
id: adr-0003
title: API Design To Backend
type: adr
status: proposed
date: 2026-05-01
sources:
  - "[[wiki-03-api-design-pattern]]"
tags: [adr]
categories: [api-design]
role: backend
related_to:
  - "[[adr-0001-code-review-to-backend]]"
  - "[[adr-0002-test-design-to-backend]]"
  - "[[adr-0004-tdd-cycle-to-backend]]"
aliases: []
---

# API Design To Backend

## Context

승격 원본: `content/wiki/wiki-03-api-design-pattern.md` (sources-03 의 `api-design.md` 부분 — NEXUS `/api-design` SKILL 박제). wiki 는 두 층 합성 — 공용 골격 (5 단계 절차 / REST URL·Method·응답 코드 컨벤션 / Request·Response 스키마 / 에러 케이스 / 도메인 문서 갱신) + NEXUS 슬롯 (`plan/api/<domain>.md` 위치 / `plan/erd/*.md` reference / `plan/agent/task-flow.md` 등). 결정 단위 = *backend role plugin 입주 방식*. 자매 ADR (0001 code-review / 0002 test-design / 0004 tdd-cycle / 0005 refactor-layered) 와 함께 backend role 의 5 SKILL 라인업 구성.

## Decision

backend role plugin 의 신규 SKILL `api-design` 본문에 **공용 골격만 박는다** — 5 단계 절차 / REST 컨벤션 / 산출 포맷. NEXUS 의 API 도메인 위치 / DB 룰 reference / 에이전트 영역은 SKILL trigger 시 *reference 로 로드* (`plan/api/`, `plan/erd/`, `CLAUDE.md`), 부재 시 *role-generic fallback* (REST 표준 / 자동 디렉토리 추정 / 사용자 도메인 어휘 주입 요청).

특정 컨벤션 누적 시 분기 ADR (`adr-NNNN-{convention}-api-design-to-backend`).

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 공용 골격 + NEXUS 슬롯 합쳐서 plugin 본문에 박기 | wiki 두 층 분리 무효화 (promote-docs §자산 분리 룰 §금지). NEXUS 외 이식 0 |
| `api-design` + `tdd-cycle` + `refactor-layered` 단일 SKILL `backend-rules` | ADR-0014 Notes V 학습 — 메타-내러티브 ("라이프사이클") 묶음 금지. 각자 독립 트리거이므로 별 SKILL |
| 처음부터 분기 ADR (`nexus-api-design-to-backend`) 만 | 채택 사례 1건만 있는 시점 분기는 과조숙 |
| `qa` role 매핑 | API 설계는 *백엔드 코드 작성 흐름의 일부*. QA 분리 조직이면 후보지만 현 운영은 backend 일체 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| backend plugin `api-design` SKILL 본문 작성 (공용 골격 5 요소) | 메인테이너 | v0.1+ | wiki-03 §공용 골격 → SKILL.md / rules.md |
| reference 로드 메커니즘 박기 (`plan/api/` / `plan/erd/` / `CLAUDE.md` 슬롯) | 메인테이너 | v0.1+ | rules.md `## reference 로드 모델` |
| role-generic fallback (REST 표준 / 디렉토리 자동 추정 / 도메인 어휘 사용자 주입) | 메인테이너 | v0.1+ | rules.md §fallback |
| examples 두 개 (sample-no-reference: REST 일반 / sample-with-reference: NEXUS) | 메인테이너 | v0.1+ | examples/ |
| `add-role-skill.sh backend api-design "..."` 호출 | 메인테이너 | v0.1+ | role.json skills[] += api-design |
| `adr-to-harness.sh ... backend` Notes lineage | 메인테이너 | v0.1+ | 본 ADR Notes |

## Consequences

**Pros**
- backend plugin 의 5 SKILL (code-review / test-design / api-design / tdd-cycle / refactor-layered) 라인업 완성 — 작업 라이프사이클 cover.
- wiki-03 의 공용 골격이 *project-agnostic* 으로 이식 가능.
- 자매 ADR (0001/2/4/5) 와 동일한 분리 패턴 — backend role 의 일관된 SKILL 모델.

**Cons**
- 첫 사용처가 NEXUS 외 프로젝트면 fallback 정확도 ↓ (특히 도메인 어휘).
- 분기 ADR 누적 시 backend plugin 의 reference 로드 매트릭스 복잡도 ↑.

**Follow-ups**
- [ ] `code-review` / `test-design` / `api-design` / `tdd-cycle` / `refactor-layered` 5 SKILL 의 reference 로드 hook 공통 추출 — backend plugin 공통 hook
- [ ] `api-design` 단계가 frontend (UI 스펙·컴포넌트 API) 에서도 채택 사례 발생 시 ADR-0011 §3 hoisting 후보
- [ ] OpenAPI / Swagger 등 다른 API 스펙 도구 reference 슬롯 추가 (NEXUS 외 사용처)

## Notes

_(시간순 append)_

- 2026-05-01 — proposed. wiki-03 → backend role 매핑. 자매 ADR: 0001 (사후 검토) / 0002 (사전 시나리오) / 0004 (Red→Green) / 0005 (4계층 정렬).
- 2026-05-01: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
