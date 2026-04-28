---
id: spec-01
title: Content Pipeline
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-02-mediness-architecture]]"
owns: content-pipeline
tags: [spec]
aliases: []
---

# Content Pipeline

## Scope

5단 콘텐츠 파이프라인의 단계 의미·관계 규칙·6 role 분류. 단계별 동작·도구·디렉토리 명세는 다른 spec 에서.

## Summary

mediness 콘텐츠 5단 파이프라인(inbox → sources → wiki → adr → harness)의 단계별 의미·관계 규칙·역할 분류를 정의한다.

## Background

Karpathy LLM Wiki 패턴(Raw → Wiki → Schema)을 사내 맥락에 맞게 5단으로 확장. **점점 정제되는 단방향 파이프라인 + 위키 누적** 이 뿌리. (idea-02)

## Goals

- 5단 단계 의미 명확화: inbox(집합소), sources(원본), wiki(합성), adr(결정), harness(배포)
- 단계 간 관계 규칙: 수직 단방향 승격, 수평 양방향 연관
- 6 role 정착

## Non-goals

- 디렉토리 구조 — `[[spec-02-directory-structure]]`
- 파일명·프론트매터 — `[[spec-03-frontmatter-naming]]`
- 권한·외부 노출 — `[[spec-04-permissions-flow]]`
- 승격 도구·자동화 — `[[spec-05-promote-skills]]`

## Design

| 단계 | 이름 | 역할 | 입력 | 산출 |
|------|------|------|------|------|
| 1 | inbox | 집합소 | 사용자 제안, 레거시 자산 | raw dump |
| 2 | sources | 1차 가공 = 원본 | inbox 항목 | 네이밍 + 목적 명시. 이후 불변 |
| 3 | wiki | 합성·정리 | sources 문서 | 비슷한·연관 내용 묶고 다듬은 지식 노드 |
| 4 | adr | 결정본 (ADR) | wiki 결과 | atomic 결정 로그 |
| 5 | harness | 배포 | adr | 배포 준비된 plugin |

핵심: 한 단계 위로 갈수록 **결정**이 늘고 **자유도**가 준다.

**관계 규칙**
- 수평(같은 레벨): 양방향 `related_to` 가능.
- 수직(상위로): 단방향 승격만. 상위가 `sources` 로 출처를 가리킴.
- 어휘는 메타 레이어(idea/spec/adr) 와 공용: `sources`, `related_to`, `supersedes`, `depends_on`.

**6 role**: 기획 · PM · 프론트 · 백엔드 · QA · 인프라.

## Open Questions

- [ ]
