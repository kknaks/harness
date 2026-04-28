---
id: spec-05
title: Promote Skills
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-02-mediness-architecture]]"
owns: promote-skills
tags: [spec]
aliases: []
---

# Promote Skills

## Scope

단계 간 승격을 처리하는 스킬·스크립트 (idea→spec, spec→adr 등). 사용자 온보딩 스킬은 별개.

## Summary

5단 콘텐츠 + 3단 메타의 단계 간 승격을 모두 **대화형 스킬**(메인테이너 + Claude)로 시작하고, 빈도·오류율 기준으로 단계별 자동화로 점진 전환한다.

## Background

idea→spec 의 `promote-docs` 스킬이 검증된 패턴(스크립트 + Claude 합성). 이를 일반화해 모든 단계 간 승격에 적용. (idea-02)

## Goals

- 모든 승격 = 메인테이너 + Claude 대화형 스킬 호출
- 단계 간 전환마다 분리된 sh (스크립트 분리는 [[spec-03-frontmatter-naming]] 의 단계별 스켈레톤 차이 때문)
- 검증된 스크립트 재사용·확장
- "자동화" = 사람 호출 없이 훅·스케줄로 동작. 빈도·오류율 기준 점진 적용

## Non-goals

- 자동화 우선순위 결정 (운영하며 결정)
- 콘텐츠 단계별 sh 즉시 구현 (메타에서 검증 후 콘텐츠로 확장)
- 통합 sh + stage 인자 방식 (현재는 단계별 분리)

## Design

**전환 케이스 7개** (6 콘텐츠 + 1 메타 추가)

| 케이스 | 스크립트 | 상태 |
|--------|----------|------|
| idea → spec | `idea-to-spec.sh` | ✓ 구현 |
| spec → adr (메타) | `spec-to-adr.sh` | ✓ 구현 |
| inbox → sources | `inbox-to-sources.sh` | 미구현 |
| sources → wiki | `sources-to-wiki.sh` | 미구현 |
| wiki → adr (콘텐츠) | `wiki-to-adr.sh` | 미구현 |
| adr → harness | `adr-to-harness.sh` | 미구현 |
| (병합) idea → 기존 spec | `merge.sh` | ✓ 구현 |

**스킬 구조**
- skill: `promote-docs` (idea→spec 전용에서 일반화 완료)
- 모든 sh 가 같은 skill 의 `scripts/` 안.
- Claude 가 사용자와 대화하며 sh 호출 → 산출 문서 본문 합성·다듬기.

**자동화 진입 기준**
- 동일 케이스가 자주 반복 (예: inbox → sources 가 매주 다수 발생)
- 사람 합성이 거의 동일한 패턴으로 굳음
- 합성 오류율이 낮음 (검증 단계가 잡아낼 수 있음)

이 기준 충족 시 해당 sh 를 훅(예: PR 머지 후 자동 호출) 또는 스케줄로 승격.

## Open Questions

- [ ] 콘텐츠 단계별 sh 4개의 입력·산출 명세 (해당 레이어 운영 시작 시)
- [ ] skill 이름을 `promote-docs` 로 일반화 시점
