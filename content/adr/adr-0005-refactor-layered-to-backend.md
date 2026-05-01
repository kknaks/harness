---
id: adr-0005
title: Refactor Layered To Backend
type: adr
status: proposed
date: 2026-05-01
sources:
  - "[[wiki-05-refactor-layered-pattern]]"
tags: [adr]
categories: [refactoring, layered-architecture]
role: backend
related_to:
  - "[[adr-0001-code-review-to-backend]]"
  - "[[adr-0004-tdd-cycle-to-backend]]"
aliases: []
---

# Refactor Layered To Backend

## Context

승격 원본: `content/wiki/wiki-05-refactor-layered-pattern.md` (sources-03 의 `refactor-layered.md` 부분 — NEXUS `/refactor-layered` SKILL 박제). wiki 두 층 — 공용 골격 (4 계층 책임표 + 정렬 절차 + grep 위반 검출) + NEXUS 슬롯 (`server/app/{routers,services,repositories,schemas}/` 위치 / `plan/refactor/re6-*.md` 트래커 / 허용 예외 영역).

자매 SKILL: `tdd-cycle` (Refactor 단계의 도구로 본 SKILL 활용) + `code-review` (사후 검토 시 grep 도구 공유).

## Decision

backend role plugin 의 신규 SKILL `refactor-layered` 본문에 **공용 골격만** — 4 계층 책임표 / 정렬 절차 / grep 위반 검출 명령. NEXUS 의 디렉토리 위치 / 트래커 / 예외 영역은 *reference 로드* (`plan/refactor/re*-*.md`, `CLAUDE.md`, 사용처 `<router-dir>` 등), 부재 시 *role-generic fallback* (Spring Boot / Express / NestJS 등 프레임워크 디렉토리 자동 추정 + 사용자 확인).

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| `tdd-cycle` (adr-0004) 의 Refactor 단계에 흡수 | wiki-05 자체가 *독립 트리거* (라우터 1 개 단위 정렬은 TDD 사이클 외에도 단독 호출). 별 SKILL 유지 |
| `code-review` (adr-0001) 와 합치기 | code-review = *사후 검토 + 리포트*. refactor-layered = *능동적 정렬 작업*. 결정 단위 다름 |
| grep 위반 검출만 SKILL, 정렬 절차는 가이드만 | 정렬 절차는 *재현 가능한 단계* 가 핵심 — SKILL 본문에 박는 게 정합 |
| 4 계층 패턴이 *기본 가정* 이라 SKILL 불필요 | 4 계층은 *모든 백엔드* 가 따르는 패턴 아님 (예: hexagonal / clean architecture 변형). SKILL 로 명시 박는 게 사용처 fallback 에 도움 |

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `refactor-layered` SKILL 본문 (4 계층 책임표 + 정렬 절차 + grep) | 메인테이너 | v0.1+ | wiki-05 → SKILL.md / rules.md |
| reference 로드 (`plan/refactor/re*-*.md` / `CLAUDE.md` / 사용처 디렉토리 슬롯) | 메인테이너 | v0.1+ | rules.md |
| role-generic fallback (프레임워크 자동 추정 — Spring / Express / NestJS / FastAPI / Django REST) | 메인테이너 | v0.1+ | rules.md §fallback |
| examples 두 개 | 메인테이너 | v0.1+ | examples/ |
| `add-role-skill.sh backend refactor-layered "..."` | 메인테이너 | v0.1+ | role.json |
| `adr-to-harness.sh ... backend` Notes | 메인테이너 | v0.1+ | 본 ADR Notes |
| (옵션) grep 위반 검출 자동화 — CI 후크 또는 PreToolUse hook | 메인테이너 | v0.2 | follow-up |

## Consequences

**Pros**
- 라우터 1 개 단위 정렬이 *재현 가능한 절차* — 메인테이너 손에 일관성.
- grep 검출이 자동화 가능 — CI 후크로 박으면 위반 0 강제.
- `code-review` (사후) / `tdd-cycle` (Refactor 도구) 와 자연 인계.

**Cons**
- 4 계층 패턴 가정이 *모든 백엔드* 에 적용 안 됨 — hexagonal / clean architecture / functional 패턴 등은 별 ADR 분기 필요할 가능성.
- grep 검출이 *실제 동작* 검증 안 함 — 정적 분석 한계 (런타임 동작은 테스트가 cover).

**Follow-ups**
- [ ] grep 위반 검출 자동화 — CI 후크 / PreToolUse hook
- [ ] hexagonal / clean architecture 변형 ADR 분기 (사용 사례 누적 시)
- [ ] frontend 의 *컴포넌트 4 계층* (presentation / container / hooks / api) 와 hoisting 검토

## Notes

_(시간순 append)_

- 2026-05-01 — proposed. wiki-05 → backend role 매핑. 자매 ADR: 0001 / 0004.
- 2026-05-01: applied to plugin `base` role `backend` (content/harness/plugins/base/role-templates/backend/)
