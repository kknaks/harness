---
id: adr-0011
title: Base Hoisting
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-06-base-hoisting]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
related_to:
  - "[[adr-0009-harness-hooks]]"
  - "[[adr-0010-harness-mcp]]"
---

# Base Hoisting

## Context

(승격 원본: `docs/spec/spec-06-base-hoisting.md`)

harness plugin 은 6 role (기획·PM·프론트·백엔드·QA·인프라) 각각에 별도 plugin 으로 배포된다. 사전에 "어떤 자산이 모두 공통이고 어떤 자산이 role 특화인가" 를 완벽히 분할하기는 추측이고, 빈약하거나 과도한 base 가 됨 — *실제 중복이 가장 신뢰할 신호*.

따라서 **사전 분할 X, 운영 중 중복 발생 시 hoisting** 패턴 채택. 단계 간 승격(idea→spec→adr) 과는 직교 — *plugin 자산 차원* 의 정리.

## Decision

### 1. plugin manifest 구조 — base + 6 role 각각

```
plugins/
  base/        plugin.json   (모든 role 공통 자산)
  planner/     plugin.json   (기획)
  pm/          plugin.json
  frontend/    plugin.json
  backend/     plugin.json
  qa/          plugin.json
  infra/       plugin.json
```

base 는 모든 role plugin 의 의존 (사용자가 role plugin 깔면 base 자동 동봉).

### 2. 사전 분할 금지

처음에는 모든 자산을 *해당 role plugin* 에 둠. base 는 비어있는 상태에서 시작 (또는 self-evident 공통 자산만, 예: 메타 도구).

### 3. hoisting 트리거 (수동 판단)

다음 중 하나 충족 시 hoisting 검토:
- 동일 자산이 2개 이상 role plugin 에 복사됨
- 새 role plugin 추가 시 같은 자산이 또 필요해짐
- 메인테이너가 명시적으로 cross-cutting 으로 판단

**메인테이너의 *수동 판단*** — 자동 hash detection 은 v0.1 시점 자산 수가 적어 거짓양성 위험 > 가치. 자산 누적 시점에 알림 도구 도입 재검토.

### 4. manifest 갱신 (도구 자동 실행)

메인테이너 결정 후 `promote-docs` (또는 별도 hoisting 스크립트) 가:

1. `content/harness/plugins/<role>/X` → `content/harness/plugins/base/X` 이동
2. 영향받는 role plugin 들에서 X 제거
3. base/plugin.json 에 자산 추가, role/plugin.json 들에서 제거 — *자동*
4. release 노트에 hoisting 기록

6+1 개 manifest 수동 편집은 누락 위험 ↑ → 도구 자동 갱신 강제.

### 5. 결정 모델 = "사람이 결정, 도구가 안전 실행"

| 책임 | 누가 |
|------|------|
| *어느 자산을 hoist 할지* 결정 | 메인테이너 |
| *manifest 안전 갱신* 실행 | 도구 (스크립트) |

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 사전 base/role 완벽 분할 | 추측. 빈약하거나 과도한 base. 실제 중복이 가장 신뢰할 신호 |
| 자동 hash detection (트리거) | v0.1 자산 수 적음 → 거짓양성 위험. 가치 < 비용 |
| 수동 manifest 갱신 | 6+1 manifest 누락 위험 |
| 자동 + 자동 (감지·갱신 둘 다) | 사람 판단 우회. 의도된 중복도 hoisting |
| 단일 plugin (role 분할 X) | 사용자가 자기 role 의 자산만 받지 못함. 컨텍스트 폭발 |

## Implementation Path

| Action | 누가 | 언제 | 의존 |
|--------|------|------|------|
| `content/harness/plugins/base/` + 6 role 디렉토리 생성 | 메인테이너 | v0.1 release 전 | — |
| 각 role plugin 의 빈 `plugin.json` 스캐폴드 | 메인테이너 | v0.1 | — |
| `promote-docs/scripts/hoist.sh` 작성 (자산 이동 + manifest 갱신) | 메인테이너 | hoisting 첫 사례 발생 시 | [[adr-0001-directory-structure]] |
| 자산 후보 (CLAUDE.md, 시크릿 hook, 커밋 컨벤션 등) base 첫 입주 | 메인테이너 | v0.1 | self-evident 공통만 |

## Consequences

**Pros**
- 추측 분할 회피 → base 가 빈약·과도해질 위험 ↓.
- 메인테이너의 *수동 판단* → 의도된 중복 (예: role 별로 다르게 진화할 자산) 보존.
- *도구 자동 갱신* → 6+1 manifest 누락 위험 회피.
- role 단위 plugin 분배 → 사용자가 자기 role 의 자산만 받음, 컨텍스트 효율 ↑.

**Cons**
- 처음에 base 가 거의 비어있어 *초기 plugin 가치 낮아 보일 수* 있음 — 운영 중 채워짐.
- *수동 판단* 누락 시 중복이 오래 방치될 수 있음 — 자산 누적 시점에 알림 도구 도입 검토.
- role plugin 마다 manifest 따로 → 메인테이너 관리 부담 (도구로 완화).

**Follow-ups**
- [ ] 자산 누적 시점 (예: 자산 N 개 이상) 자동 hash detection 알림 도구 도입 검토.
- [ ] role plugin 추가·제거 시 자동 base manifest 정합성 검사 (CI hook).
- [ ] hoisting 의 *역방향* (base 에서 다시 role 로 분리) 정책 — 운영 후 발생 시 결정.

## Notes

- 2026-04-29: [[spec-06-base-hoisting]] → ADR 승격. OQ 두 개 (자동 detection, manifest 갱신) "사람이 결정, 도구가 안전 실행" 균형 모델로 박제. spec-06 status accepted 유지.
