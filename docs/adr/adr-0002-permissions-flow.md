---
id: adr-0002
title: Permissions Flow
type: adr
status: proposed
date: 2026-04-28
sources:
  - "[[spec-04-permissions-flow]]"
tags: [adr]
aliases: []
---

# Permissions Flow

## Context

콘텐츠 5단 파이프라인(`inbox → sources → wiki|adr → harness`, idea-02) 위에서 단계별 쓰기 권한과 외부 노출 표면을 정해야 한다.

- 기여자 역할이 다양하다(개발/QA/기획/PM/디자인 등). 공용 입구가 없으면 비개발 기여가 막힌다 — 따라서 inbox 는 누구나 던질 수 있어야 한다.
- 가운데 3단(sources/wiki/adr)은 정제·승격 부담이 커서 메인테이너 책임으로 두는 것이 자연스럽다.
- 사용자(plugin 소비자)는 harness 출구만 소비한다 — 외부 노출 표면은 좁을수록 멘탈 모델이 단순하다.

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
3. **머지 ≠ 승격** — sources 이상으로 올리는 건 별도 스킬의 책임.

권한 강제 메커니즘(CODEOWNERS / 훅 차단)은 도입하지 않는다 — 관례 + 메인테이너 자기 규율로 충분.

## Consequences

**Pros**
- 권한이 디렉토리 단위로 매핑되어 멘탈 모델이 깔끔.
- 메인테이너가 가운데 3단을 자유롭게 정제·재구성 가능.
- 사용자 노출 표면이 양 끝(inbox 입구, harness 출구)으로 단순화.

**Cons**
- 비개발 역할(QA/기획/PM/디자인)이 Git PR 절차에 마찰을 느낄 가능성.

**Follow-ups**
- [ ] 비개발 PR 마찰이 실제 문제로 드러나는지 운영 후 판단.
- [ ] 마찰이 확인되면 2번째 입구(Issue → 메인테이너 카피) 도입 시점 논의.

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 spec 추가 등)_
