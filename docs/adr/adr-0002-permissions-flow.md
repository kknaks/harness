---
id: adr-0002
title: Permissions Flow
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-04-permissions-flow]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
related_to:
  - "[[adr-0003-content-pipeline]]"
---

# Permissions Flow

## Context

[[adr-0003-content-pipeline]] 의 콘텐츠 5단 파이프라인 위에서 단계별 쓰기 권한과 외부 노출 표면을 정해야 한다.

- 기여자 역할이 다양하다 (6 role: 기획·PM·프론트·백엔드·QA·인프라). 공용 입구가 없으면 비개발 기여가 막힌다 — inbox 는 누구나 던질 수 있어야 한다.
- 가운데 3단 (sources/wiki/adr) 은 정제·승격 부담이 커서 메인테이너 책임으로 두는 것이 자연스럽다 (특히 adr-0003 의 R2 sources 불변 + R3 단계 건너뛰기 위반 catch 책임).
- 사용자 (plugin 소비자) 는 harness 출구만 소비한다 — 외부 노출 표면은 좁을수록 멘탈 모델이 단순하다 (가운데 3단 = 메인테이너 내부 작업장).
- [[adr-0001-directory-structure]] 가 디렉토리 단위 분리를 결정했으므로, 권한도 *디렉토리 단위* 매핑이 자연.

권한 강제 메커니즘 (도구·자동화) 도입 여부는 마찰 vs 안전의 trade-off — 마찰을 먼저 측정한 후 결정한다 (Alternatives 참조).

## Decision

**쓰기 권한**

| 레이어 / 단계 | 누가 쓰기 |
|---------------|-----------|
| 메타 (`docs/idea`, `docs/spec`, `docs/adr`) | 메인테이너 |
| 콘텐츠 inbox | 모든 기여자 (공용) |
| 콘텐츠 sources / wiki / adr / harness | 메인테이너 |

원칙: **inbox 만 공용 입구**, 그 너머는 메인테이너 책임.

**외부 노출**

| 단계 | 인터페이스 | 흐름 |
|------|------------|------|
| inbox | Git PR (입구) | 기여자 PR → 메인테이너 머지 = 등재 |
| sources, wiki, adr | 없음 (내부) | 메인테이너 직접 push |
| harness | plugin 배포 (출구) | 사용자는 이것만 받음 |

**inbox PR 워크플로우**
1. 기여자가 `content/inbox/` 에 파일 추가 PR.
2. 메인테이너 리뷰 → 머지 = inbox 도착.
3. **머지 ≠ 승격** — sources 이상으로 올리는 건 별도 스킬의 책임 ([[spec-05-promote-skills]]).

**강제 모델** (현재 결정)

| 케이스 | 누가 잡음 | 메커니즘 |
|--------|-----------|----------|
| 외부 기여자가 inbox 외 영역 (sources/wiki/adr/harness) PR | 메인테이너 | PR 리뷰 시 닫음. 자동 차단 X |
| 메인테이너가 자기 영역 직접 push | 자기 규율 | 관례 (PR 없이 진행 가능) |
| inbox 머지 = 자동 승격? | — | **NO**. 머지 ≠ 승격. 승격은 별도 스킬 호출 |

권한 강제 도구 (CODEOWNERS / hook 차단 / branch protection 룰) 는 *지금* 도입하지 않는다 — 메인테이너 1-2명 규모 + inbox 외 PR 빈도 낮음 가정. 마찰이나 사고 발생 시 Alternatives 표 따라 단계적 도입.

## Alternatives Considered

권한 강제 메커니즘 후보:

| 후보 | 동작 | 채택 안 한 이유 |
|------|------|------------------|
| **CODEOWNERS** (GitHub) | sources/wiki/adr/harness 영역 PR 에 메인테이너 자동 리뷰어 지정 | 자동 차단 X (리뷰 강제만). 메인테이너 1-2명이라 효익 작음. **운영 후 도입 후보** |
| **GitHub Action 차단 hook** | inbox 외 영역 변경된 외부 PR 자동 close | false positive 위험 (메인테이너의 정상 PR 도 차단될 수 있어 branch protection 우회 필요). 운영 부담 ↑ |
| **branch protection + write 권한 분리** | 메인테이너만 main 직접 push, 외부는 PR 만 | GitHub 의 default 권한 모델로 자연 적용. 별도 결정 X (org 설정에 의존) |
| **자기 규율 (현재 ✓)** | 메인테이너가 inbox 외 PR 닫음. 외부 기여자는 CONTRIBUTING.md 안내로 inbox 만 사용 | 메커니즘 운영 부담 0. 조직 규모 작을 때 충분 |

비개발 채널 후보:
- **Issue → 메인테이너 카피**: 비개발 역할 (QA/기획/PM) 이 PR 부담스러우면 Issue 만 작성, 메인테이너가 inbox PR 로 옮김. *마찰 확인 후 도입.*
- **Issue 자체를 inbox 등재**: GitHub Issue 를 inbox 의 형식으로 인정. 단 _map.md 인덱싱 어려움 (frontmatter 없음). 채택 X.

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `content/inbox/` 디렉토리 생성 | 메인테이너 | 콘텐츠 레이어 가동 시 | [[adr-0001-directory-structure]] |
| `CONTRIBUTING.md` 에 inbox PR 워크플로우 + 권한 표 명시 | 메인테이너 | inbox 가동 시 | — |
| 메인테이너가 inbox 외 PR 닫는 규율 정착 (메시지 템플릿 포함) | 메인테이너 | inbox 가동 시 | — |
| 비개발 PR 마찰 측정 (분기별 검토) | 메인테이너 | 운영 6개월 후 | 마찰 시 Issue 채널 또는 CODEOWNERS 도입 |

**시나리오 예 (외부 기여자가 잘못된 PR 던질 때)**

1. 외부 기여자가 `content/sources/sources-NN-foo.md` 에 PR.
2. 메인테이너 리뷰 → "sources 는 메인테이너 영역. inbox 로 다시 PR 부탁드립니다" 메시지 + PR 닫음.
3. 기여자가 `content/inbox/` 로 다시 PR → 정상 머지.
4. (이후) 메인테이너가 `inbox-to-sources.sh` 호출 → sources 단계로 정체화.

## Consequences

**Pros**
- 권한이 디렉토리 단위로 매핑되어 멘탈 모델이 깔끔.
- 메인테이너가 가운데 3단을 자유롭게 정제·재구성 가능 (PR 없이 직접 push).
- 사용자 노출 표면이 양 끝(inbox 입구, harness 출구)으로 단순화.
- 강제 메커니즘 운영 부담 0 — 조직 규모 작을 때 효율적.

**Cons**
- 비개발 역할 (QA/기획/PM) 이 Git PR 절차에 마찰을 느낄 가능성. 운영 6개월 후 측정.
- 자기 규율 의존 → 메인테이너가 inbox 외 PR 을 일관되게 잡지 못하면 *허용 영역이 알게 모르게 확장* 될 위험.
- 외부 기여자가 잘못된 영역에 PR 던지는 *왕복 비용* 존재 (CONTRIBUTING.md 안내가 충분히 visible 해야).

**Follow-ups**
- [ ] 비개발 PR 마찰이 실제 문제로 드러나는지 운영 6개월 후 판단.
- [ ] 마찰 확인 시 Issue 채널 (Issue → 메인테이너 카피) 도입.
- [ ] 메인테이너 수가 3명+ 이 되거나 외부 기여자 빈도가 높아지면 CODEOWNERS 도입 검토.

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-04-permissions-flow]] status → decided (통째 흡수).
