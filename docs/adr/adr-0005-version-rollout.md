---
id: adr-0005
title: Version Rollout
type: adr
status: proposed
date: 2026-04-28
sources:
  - "[[spec-09-version-rollout]]"
tags: [adr]
aliases: []
---

# Version Rollout

## Context

idea-01 검토 시 plugin 간 호환성 매트릭스 운영 필요성이 제기됐다. 그러나 이 프로젝트는 모노레포 구조이므로 cross-plugin breaking change 는 항상 한 PR 에 묶여 배포된다. 이 조합이면 runtime skew 가 거의 발생하지 않아 별도 호환성 매트릭스나 version pinning 의 실익이 없다. 따라서 단순 운영(autoUpdate) + bad release 안전망(force update + post-mortem) 조합으로 결정한다.

## Decision

모든 plugin 은 `autoUpdate: true` 로 운영한다. 릴리즈는 아래 4단계를 반드시 거친다.

| 단계 | 조건 | 동작 |
|------|------|------|
| 1. CI 통과 | lint / 단위 검증 / manifest 스키마 | merge 가능 상태 |
| 2. dogfood tag | 메인테이너 환경에서 24h 운영, 회귀 없음 | 내부 검증 |
| 3. release tag | dogfood 통과 | autoUpdate 로 모든 사용자 자동 반영 |
| 4. 롤백 | 문제 발견 | 직전 release tag 로 force update + post-mortem ADR |

**Breaking change 처리**: 관련 plugin 들을 한 PR 에 묶어 release. 사용자는 항상 최신 조합을 받으며 version pinning 은 허용하지 않는다.

**Roadmap — 첫 release 단계**:
- v0.1: base + backend (가장 먼저 dogfood)
- v0.2: + frontend, + infra
- v0.3: + qa
- v0.4: + planning, + pm

각 버전은 자체로 사용 가능하며, 후속 plugin 은 별도 install 로 추가한다.

## Consequences

**Pros**
- 사용자는 update 명령 불필요 — autoUpdate 로 항상 최신 상태.
- 호환성 매트릭스 관리 부담 없음.
- bad release 시 직전 release tag 로 force update, 빠른 롤백 가능.

**Cons**
- dogfood 24h 가 변경 규모에 따라 짧을 수 있음 — 변경 종류별 차등 검토 필요.
- bad release 발생마다 post-mortem ADR 작성 의무 발생.
- autoUpdate 거부 메커니즘 없음 — 사용자 의도와 어긋날 가능성.

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 spec 추가 등)_
