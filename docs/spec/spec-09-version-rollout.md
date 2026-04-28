---
id: spec-09
title: Version Rollout
type: spec
status: draft
created: 2026-04-28
updated: 2026-04-28
sources:
  - "[[idea-01-distribution-strategy]]"
owns: version-rollout
tags: [spec]
aliases: []
---

# Version Rollout

## Scope

plugin 버전 갱신·릴리즈·롤백 정책. autoUpdate 운영 + 단계 release(CI → dogfood → release → 문제 시 force update). 호환성 매트릭스는 운영 X.

## Summary

모든 plugin 은 항상 최신 — autoUpdate 자동 반영. 모노레포라 cross-plugin 변경은 한 PR 에 묶임. bad release 시 직전 tag 로 force update + post-mortem ADR.

## Background

idea-01 검토 시 호환성 매트릭스 운영 필요성 제기됐으나, 모노레포 + autoUpdate 조합이면 매트릭스가 거의 무의미. 단순 운영 + bad release 안전망에 집중.

## Goals

- 모든 plugin `autoUpdate: true`
- 호환성 매트릭스 미운영 (모노레포 PR 동기화로 skew 거의 없음)
- bad release 시 신속 롤백 메커니즘
- 단계 release (CI → dogfood → release) 강제

## Non-goals

- plugin 자체 manifest 표준 — `[[spec-02-directory-structure]]` 가 다룸
- 단계 간 승격 도구 — `[[spec-05-promote-skills]]`
- onboarding 시점 — `[[spec-07-onboarding-skill]]`

## Design

**Release 단계**

| 단계 | 조건 | 동작 |
|------|------|------|
| 1. CI 통과 | lint / 단위 검증 / manifest 스키마 | merge 가능 상태 |
| 2. dogfood tag | 메인테이너 환경에서 24h 운영, 회귀 없음 | 내부 검증 |
| 3. release tag | dogfood 통과 | autoUpdate 로 모든 사용자 반영 |
| 4. 롤백 | 문제 발견 | 직전 release tag 로 force update + post-mortem ADR |

**Breaking change 처리**:
- 관련 plugin 들을 한 번에 갱신해 release (모노레포 PR).
- 사용자는 항상 최신 조합. version pinning X.

**Roadmap — 첫 release 단계** (idea-01 통합):
- v0.1: base + backend (가장 빨리 dogfood)
- v0.2: + frontend, + infra
- v0.3: + qa
- v0.4: + planning, + pm

각 버전은 자체로 사용 가능 — 후속 plugin 은 별도 install 추가.

## Open Questions

- [ ] dogfood 24h 가 적정한가 — 변경 종류별 차등?
- [ ] release tag 와 plugin manifest version 의 관계 (모든 plugin 동일 version vs 독립)
- [ ] post-mortem ADR 의 작성 절차 (자동 트리거?)
