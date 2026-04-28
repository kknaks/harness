---
id: spec-01
title: CLI Shape
type: spec
status: draft
created: 2026-04-27
updated: 2026-04-27
sources:
  - "[[idea-02-cli-shape]]"
  - "[[idea-07-shell-completion]]"
owns: cli-shape
tags: [spec, harness]
aliases: []
related_to:
  - "[[idea-12-shell-history]]"
  - "[[spec-02-runtime-overview]]"
supersedes:
  - "[[spec-00-legacy-cli]]"
depends_on:
  - "[[spec-03-config-format]]"
---

# CLI Shape

> 두 idea 가 이 spec 으로 병합 (`sources`). `supersedes`/`depends_on`/`related_to` 로
> 다른 문서와의 관계를 선언. `_map.md` 의 Relations 섹션이 모두 인덱싱.

## Goal

하네스 CLI 의 사용자 진입점 형태와 셸 통합을 정의한다.

## Non-goals

- 내부 모듈 분할
- 배포 전략

## Design

(idea-02 + idea-07 본문에서 통합 구체화)

## Open Questions

- [ ] 서브커맨드 vs 단일 커맨드?
