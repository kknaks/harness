---
id: spec-06
title: Base Hoisting
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-01-distribution-strategy]]"
owns: base-hoisting
tags: [spec]
aliases: []
---

# Base Hoisting

## Scope

`base` plugin 에 어떤 자산을 둘지 결정하는 정책 — 사전 분할 X, 운영 중 중복 발생 시 hoisting. 단계 간 승격(spec-05) 과 다른 차원 (plugin 자산 차원).

## Summary

`base` 콘텐츠를 미리 완벽히 분할하지 않는다. 모든 자산은 처음 해당 role plugin 에 두고 시작, **여러 role 이 같은 자산을 복제** 하기 시작하면 그때 `base` 로 hoisting.

## Background

idea-01 검토 시 "base 에 뭐가 들어가야 하나" 가 큰 미결. 추측으로 미리 분할하면 빈약하거나 과도한 base 가 됨. 실제 중복이 가장 신뢰할 신호.

## Goals

- base 사전 분할 금지 — 처음에는 모든 자산을 role plugin 에 둠
- 중복 발생 시 hoisting 트리거 — 여러 role 이 같은 자산을 복제하면 base 로 이동
- hoisting 의 단위와 절차 명시

## Non-goals

- 단계 간 승격(idea→spec→adr) — `[[spec-05-promote-skills]]`
- hook 실행 순서 — `[[spec-08-hook-precedence]]`
- plugin 디렉토리 트리 — `[[spec-02-directory-structure]]`

## Design

**Trigger 조건** — 다음 중 하나 충족 시 hoisting 검토:
1. 동일 자산이 2개 이상 role plugin 에 복사됨
2. 새 role plugin 추가 시 같은 자산이 또 필요해짐
3. 메인테이너가 명시적으로 cross-cutting 으로 판단

**hoisting 절차**:
1. base 로 이동 — `content/harness/plugins/<role>/X` → `content/harness/plugins/base/X`
2. 영향받는 role plugin 들에서 X 제거
3. base 의존성 명시 (모든 role plugin 이 자동 base 깔림)
4. release 노트에 hoisting 기록

**자산 후보군** (관찰 기반, 미확정):
- 회사 CLAUDE.md
- 시크릿 누출 차단 훅
- 커밋 컨벤션
- 메타 도구(idea→spec→adr)
- 공통 PR 템플릿

## Open Questions

- [ ] hoisting 의 자동 detection (동일 파일 hash 비교?) vs 수동 판단
- [ ] hoisting 후 role plugin manifest 갱신 방법
