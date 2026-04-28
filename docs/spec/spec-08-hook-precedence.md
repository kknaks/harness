---
id: spec-08
title: Hook Precedence
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-01-distribution-strategy]]"
owns: hook-precedence
tags: [spec]
aliases: []
---

# Hook Precedence

## Scope

여러 plugin 의 hook 이 같은 이벤트에 등록될 때 실행 순서 정책. base ↔ role 계층 + 다중 role 보유 시 role 간 정렬. 권한 정책(spec-04)·자산 hoisting(spec-06) 과 다른 차원.

## Summary

**base = gate(먼저), role = override(나중)**. 다중 role 보유 시 role 간에도 우선순위 (인프라 > 백엔드 > 프론트 > 기획자 > pm > qa). manifest 의 `hookPriority` 필드로 명시.

## Background

base + role 두 plugin 이 같은 이벤트(예: PreToolUse)에 hook 을 걸면 순서·결정·중복·메시지 충돌 위험. 명시적 계층 정책 없으면 운영 시 디버깅 어려움.

## Goals

- 하향 계층 정의: base → role
- 다중 role 의 inter-priority 정의
- manifest 필드(`hookPriority`)로 강제

## Non-goals

- 디렉토리 권한 — `[[spec-04-permissions-flow]]`
- plugin 자산 hoisting — `[[spec-06-base-hoisting]]`
- Claude Code 의 hook 시스템 자체 (외부 사양)

## Design

**계층** (작은 숫자 = 먼저 실행 = gate)

| 계층 | hookPriority | 역할 |
|------|--------------|------|
| base plugin | 0~99 | gate keeper (보안·환경 검증) |
| role plugin (개발자) | 100~199 | infra 100, backend 110, frontend 120 |
| role plugin (기획) | 200~299 | planning 200, pm 210 |
| role plugin (qa) | 300~399 | qa 300 |

**다중 role 보유 시 정렬**:
- 1순위 개발자 그룹: 인프라 > 백엔드 > 프론트
- 2순위 기획 그룹: 기획자 > pm
- 3순위 qa

**책임 분리 원칙** (충돌 자체를 줄임):
- 보안·시크릿 검증 = base 만
- 스택별 lint = role 만
- 같은 이벤트를 base 와 role 이 동시에 잡지 않도록 컨벤션 우선

**override semantics**:
- 같은 이벤트의 결과는 마지막 hook 이 결정 (override).
- gate 가 reject 하면 short-circuit, role 까지 가지 않음.

## Open Questions

- [ ] Claude Code 의 hook 시스템이 `hookPriority` manifest 필드 지원? (또는 plugin 추가 순으로만?)
- [ ] short-circuit vs 누적 의 hook 종류별 적용 (PreToolUse 는 short-circuit 자연, PostToolUse 는 누적?)
- [ ] 신규 role 추가 시 priority 번호 할당 규칙
