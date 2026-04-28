---
id: spec-03
title: Frontmatter Naming
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-02-mediness-architecture]]"
owns: frontmatter-naming
tags: [spec]
aliases: []
---
****
# Frontmatter Naming

## Scope

5단 콘텐츠 + 3단 메타의 파일명 패턴, 공통/단계별 프론트매터 필드, 단계별 본문 스켈레톤(spec, adr).

## Summary

5단 콘텐츠 + 3단 메타 모두에 적용되는 파일명 패턴, Obsidian 표준 프론트매터, 단계별 본문 스켈레톤을 정의한다.

## Background

기존 `docs-naming` 컨벤션을 5단으로 일반화. inbox 만 raw 보존 예외. ADR 은 Michael Nygard 표준 본문(Context/Decision/Consequences)을 사용. (idea-02)

## Goals

- 단계별 파일명 패턴 통일
- 공통 프론트매터(`id`, `type`, 관계 4종)
- 단계별 추가 필드(spec 9개, adr 7개) 명시
- 단계별 본문 스켈레톤 정의

## Non-goals

- 콘텐츠 단계별(inbox/sources/wiki/harness) 추가 필드 정의 (해당 레이어 운영 시점에 결정)
- 검증 도구 명세 — 이미 `docs-validate` 가 처리

## Design

**파일명**

| 단계 | 패턴 |
|------|------|
| inbox | 원본 그대로 (raw 보존) |
| sources / wiki / harness | `{stage}-NN-{slug}.md` (NN = 2자리) |
| idea / spec | `{type}-NN-{slug}.md` |
| adr (메타·콘텐츠 공통) | `adr-NNNN-{slug}.md` (NNNN = 4자리, 누적 빠름) |

**공통 프론트매터** (모든 단계)
- 필수: `id`, `type` (단계 이름과 일치)
- 관계 4종 (위키링크 리스트): `sources`, `related_to`, `supersedes`, `depends_on`

**spec 추가 필드** (9개 필수): `title`, `status`, `created`, `updated`, `sources`, `owns`, `tags`

**adr 추가 필드** (7개 필수): `title`, `status` (proposed / accepted / superseded / deprecated), `date`, `sources`, `tags`. `owns` 는 두지 않음 (atomic).

**inbox 최소** 프론트매터: `id`, `type: inbox` (1줄씩만 추가).

**본문 스켈레톤**

spec (6 필수 + 2 선택):
```
## Summary / Background / Goals / Non-goals / Design / Open Questions
<!-- 선택: ## Interface / ## Alternatives Considered -->
```

adr (Michael Nygard 표준):
```
## Context / Decision / Consequences
```

## Open Questions

- [ ]
