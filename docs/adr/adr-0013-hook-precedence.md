---
id: adr-0013
title: Hook Precedence
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-08-hook-precedence]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0011-base-hoisting]]"
related_to:
  - "[[adr-0009-harness-hooks]]"
  - "[[adr-0002-permissions-flow]]"
---

# Hook Precedence

## Context

(승격 원본: `docs/spec/spec-08-hook-precedence.md`)

base + 6 role plugin ([[adr-0011-base-hoisting]]) 이 동시 등록되면 같은 이벤트 (예: PreToolUse) 에 hook 충돌 가능. 명시적 정책 없으면 운영 시 디버깅 어려움.

**2026-04-29 외부 조사 결과** ([code.claude.com/docs/en/hooks.md](https://code.claude.com/docs/en/hooks.md)):

- `hookPriority` 같은 manifest 필드 **native 미지원** — 우선순위 번호 정렬 X.
- 순서 = **array 선언 순서만 보장** (같은 plugin 안). 플러그인 간 순서 보장 X.
- **Precedence chain 존재** — PreToolUse 는 `permissionDecision` 값 기준 `deny > defer > ask > allow`. strictest wins.
- PostToolUse = 누적, exit 2 = 즉시 차단.

이 사실 위에 정책 박음. 옛 디자인 (계층별 priority 번호) 폐기.

## Decision

### 1. 책임 분리 컨벤션 (충돌 회피 우선)

같은 이벤트를 *여러 plugin 이 동시에 잡지 않도록* 책임 영역 사전 분리:

| 책임 | 담당 plugin |
|------|-------------|
| 보안·시크릿 검증 | **base 만** |
| 환경 검증 (Docker/Node 등) | **base 만** |
| 사용자 자산 변경 알림 (`medi_docs/**`) | **base 만** ([[adr-0009-harness-hooks]] H1) |
| 스택별 lint·format | **role 만** (해당 stack role) |
| 파일 종류별 검증 (.sql, .py, .ts 등) | **role 만** (가장 가까운 role) |

→ 충돌 자체가 발생 X. priority 번호 불필요.

### 2. 같은 plugin 안 hook 순서

`hooks/hooks.json` 의 `hooks[]` array *선언 순서대로 실행*. 컨벤션:

- 가벼운 검증 → 무거운 검증 (early exit 효율)
- gate 성격 hook 이 위에, 부수 효과 hook 이 아래

### 3. gate hook = strictest-wins 활용

PreToolUse 의 결정 값 (`permissionDecision`) 으로 gate 결정. Claude Code 의 precedence chain 이 *가장 strict 한 값* 자동 우승 — **순서 무관**.

| 결정 | 출력 |
|------|------|
| 거부 | `permissionDecision: "deny"` 또는 `exit 2` |
| 보류 | `permissionDecision: "defer"` |
| 묻기 | `permissionDecision: "ask"` |
| 허용 | `permissionDecision: "allow"` 또는 silent |

다른 plugin 의 더 strict 한 결정이 자동 우선 — base 든 role 이든.

### 4. PostToolUse = 누적, override 의존 금지

모든 PostToolUse hook 실행, override X. 따라서:

- PostToolUse hook = *부수 효과* 만 (검증·알림·기록).
- 다른 hook 의 결과 덮어쓰기 가정 금지.
- 누적 출력 어수선 방지 — *간결한 메시지*.

### 5. 신규 role plugin 추가 시 검증 가이드

| 단계 | 항목 |
|------|------|
| 1 | §1 책임 분리 표에서 신규 role 의 책임 영역 식별 |
| 2 | 같은 영역에 다른 plugin hook 있나 확인 |
| 3 | 충돌 시 → 책임 영역 재정의 또는 hook 단일 plugin 으로 합치기 |
| 4 | gate 성격이면 §3 패턴 |
| 5 | 부수 효과면 §4 패턴 |

priority 번호 할당 규칙 X — 책임 분리만 지키면 됨.

## Alternatives Considered

| 후보 | 채택 안 한 이유 |
|------|------------------|
| 계층별 priority 번호 (옛 디자인: base 0~99, role 100~199) | Claude Code native 미지원. 작동 X |
| plugin 등록 순서 의존 | 공식 보장 없음. 환경별 다름 |
| 같은 이벤트에 여러 plugin 자유 hook + 사후 dedup | 어수선·디버깅 어려움. 책임 분리가 더 가벼움 |
| 우선순위를 plugin 이름 alphabetical 로 합의 | 인위적·취약. 순서 의존 패턴은 strictest-wins 로 충분 |

## Implementation Path

| Action | 누가 | 언제 |
|--------|------|------|
| 책임 분리 표 (§1) 를 메인테이너 가이드 (CLAUDE.md 또는 별도 doc) 에 박기 | 메인테이너 | v0.1 release 전 |
| base plugin 의 보안·환경 검증 hook 작성 | 메인테이너 | v0.1 (base 자산 첫 입주 시) |
| role plugin 추가 시 §5 가이드 적용 (체크리스트 형태) | 메인테이너 | role plugin 추가 시점 |
| 위반 detection (예: 같은 이벤트에 base + role 동시 hook) 검증 도구 | — | 운영 후 결정 |

## Consequences

**Pros**
- 외부 사실 (hookPriority 미지원) 기반 → 작동하는 디자인.
- 책임 분리가 *충돌 자체를 줄임* → 순서 디버깅 부담 ↓.
- strictest-wins 활용 → 다중 plugin 간 안전한 보수적 결정 자동 보장.
- 신규 role 추가 절차 명확.

**Cons**
- *책임 영역 경계* 가 모호한 hook (예: 파일 변경 알림이 보안인지 lint 인지) 에 사람이 판단 필요.
- 같은 plugin 안 hook 순서는 array 의존 → 메인테이너가 *주의 깊게 정렬* 해야.
- precedence chain 의 strictest-wins 가 *의도된 강한 거부 외* 의 케이스에선 과보수적일 수 있음.
- 위반 (책임 영역 침범) 자동 검증 도구 없음 → 코드 리뷰 의존.

**Follow-ups**
- [ ] 책임 영역 경계 모호 케이스 — 운영 중 발견 시 §1 표 갱신.
- [ ] §1 책임 분리 위반 자동 detection 도구 (예: 같은 event 에 base + role 동시 hook 검출).
- [ ] PostToolUse 출력 *간결성 가이드* 구체화 (메시지 길이·포맷 컨벤션).
- [ ] *책임 영역* 자체를 plugin manifest 에 명시 (예: `responsibility: "security"`) 하는 어휘 도입 검토.

## Notes

- 2026-04-29: [[spec-08-hook-precedence]] → ADR 승격. 외부 조사로 옛 priority 번호 디자인 폐기, *책임 분리 + strictest-wins* 로 박제. spec-08 status accepted 유지.
