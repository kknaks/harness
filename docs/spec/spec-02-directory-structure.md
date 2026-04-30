---
id: spec-02
title: Directory Structure
type: spec
status: accepted
created: 2026-04-28
updated: 2026-04-29
sources:
  - "[[idea-02-mediness-architecture]]"
  - "[[idea-01-distribution-strategy]]"
owns: directory-structure
tags: [spec]
aliases: []
---

# Directory Structure

> **이 spec 은 [[adr-0001-directory-structure]] 으로 흡수됨 (2026-04-28).** 트리 자체와 plugin 내부 표준·슬러그 컨벤션·영역 분리 등 모든 결정의 SSOT 는 ADR-0001 본문. 본 spec 은 lineage 박제용 stub.

## Scope

하네스 레포의 디렉토리 트리 — docs/ + content/ + content/harness 의 plugin 모노레포 영역. 파일 컨벤션·권한·도구는 다른 spec.

## Summary

메타와 콘텐츠를 형제 디렉토리(`docs/`, `content/`)로 분리하고, 메타 레이어를 3단(idea → spec → adr)으로 확장한다. 상세 트리·정책은 [[adr-0001-directory-structure]].

## Background

5단 콘텐츠 파이프라인이 idea/spec 수준의 메타 의사결정과 다른 lifecycle 을 가지므로 레이어 분리 필요. 메타 레이어도 ADR 도입으로 idea→spec→adr 3단 대칭. (idea-02)

## Goals

[[adr-0001-directory-structure]] 본문 참조 — 트리 SSOT 이전.

## Non-goals

- 단계별 파일명·프론트매터 — `[[spec-03-frontmatter-naming]]`
- 권한·노출 정책 — `[[spec-04-permissions-flow]]`
- plugin 자산 hoisting — `[[spec-06-base-hoisting]]`
- 사용자 onboarding 스킬 — `[[spec-07-onboarding-skill]]`
- hook 실행 순서 — `[[spec-08-hook-precedence]]`
- 버전·롤백 — `[[spec-09-version-rollout]]`
- SKILL 작성 규칙 — `[[spec-13-skill-authoring-rules]]`
- 첫 출시 hook 셋 — `[[spec-14-harness-hooks]]`
- 첫 출시 MCP 셋 — `[[spec-15-harness-mcp]]`

## Design

[[adr-0001-directory-structure]] §Decision 본문 (전체 트리 / Plugin 슬러그 컨벤션 / Plugin 내부 표준 / 영역 분리 / Role plugin 책임 예시 / 부속 결정) 참조.

## Open Questions

- [x] `harness/` 를 `content/` 안에 둘지, 레포 루트로 분리 노출할지 — **결정 ([[adr-0001-directory-structure]] §부속결정)**: `content/` 안에 둠.
