---
id: adr-0005
title: Version Rollout
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-09-version-rollout]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
related_to:
  - "[[adr-0006-onboarding-skill]]"
---

# Version Rollout

## Context

[[adr-0001-directory-structure]] 의 결정으로 모든 plugin 이 `content/harness/plugins/{base,planning,...}` 에 모노레포 형태로 모인다. 이 구조의 핵심 효과는 **cross-plugin breaking change 가 항상 한 PR 에 묶여** 배포된다는 점이다. 즉:

- 사용자 환경에서 plugin 간 *runtime skew* (서로 호환 안 되는 버전 조합) 가 거의 발생할 수 없음.
- 따라서 호환성 매트릭스나 version pinning 운영의 실익이 없음.

이 가정 위에서, 운영 모델은 다음 trade-off 사이의 선택:

| 축 | 한쪽 (사용자 통제 ↑) | 반대쪽 (사용자 통제 ↓) |
|----|---------------------|-------------------------|
| 업데이트 시점 | 사용자가 manual update 명령 호출 | autoUpdate 자동 반영 |
| 버전 고정 | semver pinning 허용 | 항상 최신만 |
| 호환성 표 | 매트릭스 운영 | 미운영 |

소규모 사내 운영 (메인테이너 1-2명 + 사용자 6 role × 수십 명) 에서는 *사용자 통제* 옵션이 모두 *마찰* 만 추가하고 *안전성 이득* 은 모노레포가 이미 흡수. → autoUpdate + 단계 release + bad release 안전망 (force update + post-mortem) 조합으로 결정.

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

**dogfood 24h 근거**: (a) 회귀 발견 평균 시간 = 메인테이너 일과 1일 + (b) 다른 timezone 보유 시 한 번 사용 시간. 24h 는 *초기 임의값* — 변경 종류별 (manifest/skill/hook/내용) 차등은 운영 후 결정 (Follow-ups).

**bad release 정의**: 전 사용자 환경에서 정상 동작하던 기능이 안 되거나, 사용자 환경을 손상시키는 변경. 트리거는 (a) 메인테이너 dogfood 단계 회귀 발견, (b) 사용자 보고 + 메인테이너가 회귀 재현. 정량 기준 (예: N 명 보고 시 자동 롤백) 은 운영 후 결정.

**강제 룰**

| 룰 | 검증 대상 | 위반 시 |
|----|-----------|---------|
| **V1** CI 통과 | lint + manifest 스키마 + frontmatter 룰 ([[adr-0004-frontmatter-naming]] R4-R9) | **차단** (merge 불가) |
| **V2** 단계 순서 | dogfood tag 가 release tag 보다 먼저 존재. CI → dogfood → release skip 금지 | **차단** (release tag push 시 dogfood tag 부재면 reject) |
| **V3** release tag 권한 | release tag push 는 메인테이너만 (GitHub branch protection / tag protection) | **차단** |

## Alternatives Considered

| 후보 | 설명 | 채택 안 한 이유 |
|------|------|------------------|
| 호환성 매트릭스 + version pinning | plugin 간 호환 조합을 표로 운영, 사용자가 특정 버전 선택 | 모노레포 + 한 PR 묶음 release 가 이미 skew 를 0 으로 만듦. 매트릭스 운영 부담 ↑ 효익 ≈ 0 |
| 메이저 버전 분기 (LTS / current) | LTS 유지 + 신규 current 병행 | 메인테이너 1-2명에 부담 과중. 모노레포 모델과 어긋남 |
| semver 강제 + 사용자 manual update | 사용자가 update 명령 호출, breaking change 시 사용자 승인 | 사내 환경에선 사용자 통제 가치 < 마찰 비용. 6 role 사용자에게 update 부담 |
| **autoUpdate + 단계 release + force update 안전망 (현재 ✓)** | 모든 plugin autoUpdate, dogfood 24h 후 release, bad 시 force rollback | 모노레포 가정 위에서 가장 단순 |

post-mortem 작성 채널 후보:
- **인라인 (별도 ADR)** — 매번 새 ADR 로 기록. 누적 빠름.
- **Notes append** — 실패한 release 의 변경 PR 에 Notes 로 누적. ADR 안 만들고 가벼움.
- **결정**: post-mortem 자체가 *왜 그 결정을 다시 안 할 건가* 의 ADR 로 가치. 별도 ADR 채택. (단 자릿수 누적은 NNNN 4자리가 흡수.)

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `.github/workflows/ci.yml` 작성 (V1: lint + manifest 스키마 + frontmatter 룰) | 메인테이너 | v0.1 release 전 | [[adr-0004-frontmatter-naming]] R4-R9 |
| dogfood tag → release tag 전이 자동화 (GitHub Release 워크플로우) | 메인테이너 | v0.1 release 전 | 24h 대기 + 회귀 체크 manual gate |
| tag protection 룰 (release tag = 메인테이너만) | 메인테이너 | v0.1 release 전 | GitHub repo settings |
| post-mortem ADR scaffold 스크립트 (`pmadr.sh`) | 메인테이너 도구 | bad release 첫 발생 시 | [[spec-05-promote-skills]] 의 변형 |
| 각 plugin manifest 에 `autoUpdate: true` 기본값 | 메인테이너 | 모든 plugin scaffold 시 | — |

**시나리오 예 (정상 release v0.1)**

1. PR 머지 → CI (V1) 통과 → main 에 반영
2. 메인테이너가 `git tag dogfood-v0.1` push → 24h 운영, 회귀 모니터링
3. 회귀 없음 확인 → `git tag v0.1` push (V2/V3 검증)
4. autoUpdate 로 모든 사용자에게 자동 반영

**시나리오 예 (bad release 롤백)**

1. v0.2 release 후 사용자 보고: "A 기능 안 됩니다"
2. 메인테이너가 dogfood 환경에서 재현 확인
3. `git tag v0.2-rollback` 으로 직전 release (v0.1) 를 force update tag
4. autoUpdate 가 v0.1 로 사용자 환경 되돌림
5. `pmadr.sh` 호출 → post-mortem ADR scaffold → 본문 채움 → release 안전망 정식화

## Consequences

**Pros**
- 사용자는 update 명령 불필요 — autoUpdate 로 항상 최신 상태.
- 호환성 매트릭스 관리 부담 없음 — 모노레포 가정이 흡수.
- bad release 시 직전 release tag 로 force update, 빠른 롤백 가능.
- 단계 release (CI → dogfood → release) 가 *최소한의 안전망* — 자동 차단으로 메인테이너 실수 방지.

**Cons**
- dogfood 24h 가 변경 규모에 따라 짧을 수 있음 — 변경 종류별 차등 검토 필요 (Follow-up).
- bad release 발생마다 post-mortem ADR 작성 의무 → ADR 누적 속도 ↑.
- autoUpdate 거부 메커니즘 없음 — 사용자가 특정 버전을 *유지* 하고 싶은 경우 불가능 (예: 데모 직전 버전 고정 등).
- bad release 정의가 메인테이너 판단 의존 — 정량 트리거 부재.

**Follow-ups**
- [ ] dogfood 대기 시간 변경 종류별 차등 (manifest 12h / skill 24h / hook 48h 등) 운영 후 결정.
- [ ] bad release 정량 트리거 (N 명 보고 시 자동 롤백) 도입 여부.
- [ ] 사용자 manual pinning 요청이 누적되면 *제한적 pinning* (마지막 release 만) 도입 검토.

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-09-version-rollout]] status → decided (통째 흡수).
