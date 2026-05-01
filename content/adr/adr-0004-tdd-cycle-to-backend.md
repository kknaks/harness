---
id: adr-0004
title: TDD Cycle To Backend
type: adr
status: proposed
date: 2026-05-01
sources:
  - "[[wiki-04-tdd-cycle-pattern]]"
tags: [adr]
categories: [tdd]
role: backend
related_to:
  - "[[adr-0002-test-design-to-backend]]"
  - "[[adr-0003-api-design-to-backend]]"
  - "[[adr-0005-refactor-layered-to-backend]]"
aliases: []
---

# TDD Cycle To Backend

## Context

승격 원본: `content/wiki/wiki-04-tdd-cycle-pattern.md` (sources-03 의 `tdd-cycle.md` 부분 — NEXUS `/tdd-cycle` SKILL 박제). wiki 두 층 — 공용 골격 (Red→Green→Refactor 3 단계 / 강제 순서 / 각 단계 본질·산출) + NEXUS 슬롯 (`docker compose exec server uv run pytest` 명령 / `tests/api,repository,services/` 위치 / Mother 컨벤션 / `plan/design-standards/testing-strategy.md`).

자매 SKILL 인 `test-design` (사전 시나리오) 와 `api-design` (엔드포인트 결정) 의 *후속*, `refactor-layered` (4 계층 정렬) 의 *직전*.

## Decision

backend role plugin 의 신규 SKILL `tdd-cycle` 본문에 **공용 골격만** — 3 단계 루프 / 강제 순서 / 각 단계 본질. NEXUS 의 명령·위치·Mother·테스트 전략 reference 는 SKILL trigger 시 *reference 로드* (`plan/design-standards/testing-strategy.md`, `tests/mothers/`, `CLAUDE.md`), 부재 시 *role-generic fallback* (pytest 추정 / `tests/` 자동 탐색 / 사용자 fixture 명 주입 요청).

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| `test-design` (adr-0002) 와 합치기 | test-design = *사전 설계* (시나리오 / docstring / Mother 정의). tdd-cycle = *Red→Green→Refactor 실행 루프*. 결정 단위 다름 (설계 vs 실행) — 별 ADR / 별 SKILL |
| 단일 `backend-rules` SKILL 로 묶기 | ADR-0014 Notes V — 메타-내러티브 묶음 금지 |
| Red→Green 만 SKILL, Refactor 는 `refactor-layered` (adr-0005) 로 분리 | 현재 wiki-04 가 3 단계 모두 cover. Refactor 단계의 4 계층 정렬 도구는 wiki-05 가 보유 — 본 SKILL 의 Refactor 단계가 wiki-05 *참조* 로 충분 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| backend plugin `tdd-cycle` SKILL 본문 (공용 3 단계) | 메인테이너 | v0.1+ | wiki-04 → SKILL.md / rules.md |
| reference 로드 (`plan/design-standards/testing-strategy.md` / `CLAUDE.md` 슬롯) | 메인테이너 | v0.1+ | rules.md |
| role-generic fallback (pytest 가정 / fixture 명 사용자 주입) | 메인테이너 | v0.1+ | rules.md §fallback |
| examples 두 개 | 메인테이너 | v0.1+ | examples/ |
| `add-role-skill.sh backend tdd-cycle "..."` | 메인테이너 | v0.1+ | role.json |
| `adr-to-harness.sh ... backend` Notes | 메인테이너 | v0.1+ | 본 ADR Notes |

## Consequences

**Pros**
- 자매 SKILL (`test-design` / `api-design` / `refactor-layered`) 와 단계 인계 자연 — 작업 라이프사이클 cover.
- 강제 순서 (Red→Green→Refactor) 가 *재현 가능한 테스트 주도* 보장.

**Cons**
- 사용처가 *기존 워크플로우* (코드 먼저 후 테스트) 면 충돌 가능 — fallback 안내 박을 것.
- Refactor 단계가 wiki-05 (refactor-layered) 도구 의존 — 두 SKILL 의 호출 순서 사용자에게 명시 필요.

**Follow-ups**
- [ ] frontend (Jest / Vitest) / qa (E2E TDD) 에서도 채택 사례 발생 시 ADR-0011 §3 hoisting
- [ ] `test-design` / `tdd-cycle` 두 SKILL 의 fixture / Mother reference 공통 추출

## Notes

_(시간순 append)_

- 2026-05-01 — proposed. wiki-04 → backend role 매핑. 자매 ADR: 0002 / 0003 / 0005.
- 2026-05-01: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
