---
id: wiki-04
title: TDD Cycle Pattern
type: wiki
status: promoted
sources:
  - "[[sources-03-backend-rules]]"
related_to:
  - "[[wiki-02-test-design-pattern]]"
  - "[[wiki-03-api-design-pattern]]"
  - "[[wiki-05-refactor-layered-pattern]]"
tags: [wiki]
categories: [tdd]
aliases: []
---

# TDD Cycle Pattern

> 합성·정리. sources-03 의 `tdd-cycle.md` 부분에서 합성. **인간 검토 필요**.

## Summary

테스트 주도 개발의 *Red → Green → Refactor 루프* 패턴. wiki-02 (test-design, 시나리오 사전 합의) + wiki-03 (api-design, 엔드포인트 결정) 의 *후속*. wiki-05 (refactor-layered, 4계층 정렬) 의 *직전*. 각 단계는 강제 순서 — Red 없이 Green / Green 없이 Refactor 금지.

## Synthesis

### 공용 골격 (project-agnostic)

**1) 3 단계 루프**

| 단계 | 본질 (강제) | 산출 |
|------|-------------|------|
| Red | 스펙 기반 테스트 작성 → **실패 확인** | 테스트 파일 + fail 출력 |
| Green | 통과하는 *최소* 구현 (과도 설계 금지) | 구현 파일 + pass 출력 |
| Refactor | 통과 유지하면서 정리 (네이밍·중복·책임 분리) | 정리 후 pass 유지 |

순서 강제 — Red 없이 Green 들어가면 *의도 미반영* / Green 없이 Refactor 들어가면 *회귀 검증 불가*.

**2) Red 단계 — 테스트 작성**

- 입력: API 스펙 (wiki-03 의 산출 — endpoint / Request / Response / 에러 케이스)
- 입력: 시나리오 표 (wiki-02 의 산출 — 4 분류 cover)
- 작성: request/response 형식 일치 + 시나리오 1:1 매핑 + Mother / Fixture 활용
- **실패 확인 필수** — 통과하면 테스트가 의도 미반영 (구현 0 인 상태에서 통과 = 잘못 작성)

**3) Green 단계 — 최소 구현**

- 4계층 패턴 (wiki-05 참조): Schema → Router → Service → Repository 순
- 각 계층의 *최소 책임* 만 구현 — 비즈니스 룰·검증·에러 케이스 다 포함하되 *과도 설계 금지*
- 통과 확인 → 다음 단계 (Refactor)

**4) Refactor 단계 — 정리**

- 네이밍 (도메인 어휘 일관) / 중복 제거 / 책임 분리 (4계층 위반 정렬)
- 매 변경 후 *재실행* — 한 번이라도 fail 시 즉시 revert
- 4계층 위반 검출은 wiki-05 의 grep 명령 활용

### 프로젝트 의존 슬롯 (예시: NEXUS 백엔드)

- **테스트 명령**: `docker compose exec server uv run pytest`
- **테스트 위치**: `tests/api/test_<domain>.py` (API 테스트), `tests/repository/` (Repository 테스트), `tests/services/` (Service 테스트)
- **Fixture / Mother**: `packages/admin-api/tests/mothers/` (NEXUS 컨벤션 — `<Entity>Mother` 클래스)
- **API 클라이언트**: `admin_api_client.<sub>` (예: `admin_api_client.issues`)
- **테스트 전략 reference**: `plan/design-standards/testing-strategy.md` (피라미드·케이스 생성·도메인별 핵심 맵)

다른 프로젝트는 슬롯만 자기 환경으로 교체 — pytest / unittest / Jest / Vitest / Spring Test 등.

## References

- `sources-03-backend-rules` (tdd-cycle.md 부분 — NEXUS `/tdd-cycle` SKILL 박제)
- 자매 wiki: `wiki-02-test-design-pattern` (Red 입력 — 시나리오 표)
- 자매 wiki: `wiki-03-api-design-pattern` (Red 입력 — endpoint 스펙)
- 자매 wiki: `wiki-05-refactor-layered-pattern` (Refactor 단계의 *grep 위반 검출* 도구)
- ADR 계보: `[[adr-0004-tdd-cycle-to-backend]]` (예정)
