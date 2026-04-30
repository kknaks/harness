---
id: spec-08
title: Hook Precedence
type: spec
status: accepted
created: 2026-04-28
updated: 2026-04-29
sources:
  - "[[idea-01-distribution-strategy]]"
owns: hook-precedence
tags: [spec]
aliases: []
related_to:
  - "[[spec-04-permissions-flow]]"
  - "[[spec-06-base-hoisting]]"
  - "[[spec-14-harness-hooks]]"
  - "[[adr-0013-hook-precedence]]"
---

# Hook Precedence

## Scope

여러 plugin (base + role) 의 hook 이 같은 이벤트에 등록될 때 충돌 처리·실행 순서 정책. spec-14 (harness 자체 hook 자산) 와 직교 — 이쪽은 *충돌 메커니즘* 만.

## Summary

Claude Code 가 *플러그인 간 hook 우선순위 필드* 를 native 미지원 → spec-08 옛 디자인 (`hookPriority` 0~99 / 100~199 등) 폐기. 대신 **책임 분리 컨벤션 + Claude Code 의 strictest-wins precedence chain** 활용. 다중 plugin 간 순서는 보장 X 라고 인정하고, 그 위에 안전한 충돌 회피 패턴 박는다.

## Background

base + role 두 plugin 이 같은 이벤트(예: PreToolUse) 에 hook 을 걸면 순서·결정·중복·메시지 충돌 위험. 명시적 정책 없으면 운영 시 디버깅 어려움.

2026-04-29 외부 조사 결과:
- **`hookPriority` 같은 manifest 필드 native 미지원** — 우선순위 번호로 정렬 X.
- **순서 = array 선언 순서만 보장** (같은 plugin 안). 플러그인 간 순서 보장 X.
- **Precedence chain 존재** — PreToolUse 는 `permissionDecision` 값 기준 `deny > defer > ask > allow`. strictest wins.
- **PostToolUse = 누적**, exit 2 = 즉시 차단.

이 사실 위에 spec-08 디자인 재정렬.

## Goals

- 플러그인 간 충돌 *발생 자체를 줄이는* 책임 분리 컨벤션 정의
- gate hook 의 *순서 의존 X 안전 결정* 패턴 (strictest wins 활용)
- 같은 plugin 안 hook 들의 array 순서 컨벤션
- 신규 role plugin 추가 시 충돌 회피 가이드

## Non-goals

- 디렉토리 권한 → [[spec-04-permissions-flow]]
- plugin 자산 hoisting → [[spec-06-base-hoisting]]
- harness 자체 hook 자산 정의 → [[spec-14-harness-hooks]]
- Claude Code hook 시스템 자체 (외부 사양 — 우리가 결정 X)

## Design

### D1. 책임 분리 컨벤션 (충돌 회피 우선)

같은 이벤트를 *여러 plugin 이 동시에 잡지 않도록* 책임 영역 분리:

| 책임 | 담당 plugin |
|------|-------------|
| 보안·시크릿 검증 | **base 만** |
| 환경 검증 (Docker/Node 설치 등) | **base 만** |
| 스택별 lint·format | **role 만** (해당 stack role) |
| 파일 종류별 검증 (sql, py, ts ...) | **role 만** (가장 가까운 role) |
| 사용자 자산 변경 알림 (medi_docs/ 변경 등) | **base 만** ([[spec-14-harness-hooks]] H1) |

→ 충돌 자체가 발생 X. priority 번호 불필요.

### D2. 같은 plugin 안 hook array 순서

`hooks/hooks.json` 의 `hooks[]` array 안 *선언 순서대로 실행*. 따라서 한 plugin 안에서는:

- 가벼운 검증 → 무거운 검증 순서 (early exit 효율)
- *gate 성격* hook 이 위에, *부수 효과* hook 이 아래

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [
        {"type": "command", "command": "lightweight-check.sh"},  // 1
        {"type": "command", "command": "heavy-validate.sh"}       // 2
      ]
    }]
  }
}
```

### D3. gate hook = strictest-wins 활용

PreToolUse 의 *결정 값* (`permissionDecision`) 으로 gate 결정. 여러 plugin 의 결정이 합쳐질 때 **가장 strict 한 값이 우승** (`deny > defer > ask > allow`) — 순서 무관.

따라서 gate 결과 안전 패턴:
- 거부: `permissionDecision: "deny"` 출력 또는 `exit 2`
- 허용: `permissionDecision: "allow"` 또는 silent
- 다른 plugin 의 더 strict 한 결정이 자동 우선

→ *순서 의존 X*. base 든 role 이든 가장 보수적 결정이 자동 채택.

### D4. PostToolUse = 누적 가정

모든 hook 실행, override X. 따라서:

- PostToolUse hook 은 *부수 효과* 만 (검증·알림·기록).
- *결과 override 의존 금지* — 다른 hook 의 결과 덮어쓰기 가정 X.
- 누적 메시지가 어수선해지지 않도록 *간결한 출력*.

### D5. 신규 role plugin 추가 시 가이드

| 단계 | 검증 항목 |
|------|-----------|
| 1 | D1 책임 분리 표 확인 — 신규 role 이 *어느 책임 영역* 인지 |
| 2 | 같은 책임 영역에 다른 plugin 이 이미 hook 걸었나 확인 |
| 3 | 충돌 시 → 책임 영역 재정의 또는 hook 합치기 (한 plugin 으로) |
| 4 | gate 성격이면 D3 패턴 (`permissionDecision` 또는 exit 2) 사용 |
| 5 | 부수 효과면 D4 패턴 (silent / 간결한 메시지) |

priority 번호 X — 책임 분리만 지키면 됨.

## Open Questions

- [x] Claude Code hook 시스템 `hookPriority` 필드 지원 — **확인 (2026-04-29)**: native 미지원. spec-08 옛 디자인 폐기, 책임 분리 + strictest-wins 패턴으로 재정렬.
- [x] short-circuit vs 누적 적용 — **확인 (2026-04-29)**: PreToolUse 는 precedence chain (strictest wins, exit 2 즉시 차단), PostToolUse 는 누적. Claude Code 공식 정의.
- [x] 신규 role 추가 시 priority 번호 할당 — **무관 (2026-04-29)**: hookPriority 폐기됨. 대신 D5 책임 분리 검증 가이드.

## Notes

- 2026-04-29: 외부 조사 후 디자인 재정렬. 옛 디자인 (계층 priority 번호) 폐기, native 사실에 맞춰 *책임 분리 + strictest-wins* 로 박제. status draft → accepted.
