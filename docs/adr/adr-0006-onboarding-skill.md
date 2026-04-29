---
id: adr-0006
title: Onboarding Skill
type: adr
status: proposed
date: 2026-04-28
sources:
  - "[[spec-07-onboarding-skill]]"
tags: [adr]
aliases: []
---

# Onboarding Skill

## Context

idea-01 에서는 "신입 온보딩 자동화" 가 출발점이었지만, 기존 구성원도 역할 변경·환경 동기화·정리·재설치 등으로 같은 도구가 필요하다는 점이 드러났다. 사용자 시나리오마다 별도 sub-command 를 두면 학습 비용과 분기 관리 비용이 모두 늘어난다.

배포 채널 후보로 (a) curl one-liner, (b) brew, (c) npm/pip 글로벌 패키지가 있었으나, 셋 모두 사내 HTTPS 엔드포인트 운영 또는 별도 패키지 매니저 채널 유지 부담을 지운다. Claude Code plugin marketplace 채널 안에서 끝낼 수 있다면 외부 인프라 의존을 제거할 수 있다.

(승격 원본: `docs/spec/spec-07-onboarding-skill.md`)

## Decision

사용자(신입·기존)의 mediness plugin 셋업·역할 변경·동기화·정리를 처리하는 **단일 대화형 스킬 `harness`** 를 채택한다. sub-command 로 분할하지 않고 한 진입점에서 Claude 가 현재 설치 상태 + 사용자 의도를 보고 분기한다.

**Bootstrap (한 번, 수동, 3단계)**:

1. Claude Code 설치
2. `claude plugin marketplace add github:medisolve/harness`
3. `claude plugin install harness`

이후 모든 자동화는 plugin 채널 안에서 수행 (외부 HTTPS 엔드포인트 의존 없음).

**시나리오 분기 (`harness` 한 호출이 6개 케이스 처리)**:

| 시나리오 | 동작 |
|---------|------|
| 처음 셋업 | 역할 prompt → base + role plugin install + env 셋업 |
| 역할 변경 | 기존 role uninstall + 새 role install |
| 다중 역할 | 추가 role plugin install |
| 환경 동기화 | 회사 CLAUDE.md / 공통 settings 갱신 |
| 정리·재설치 | 전체 uninstall + reinstall |
| 상태 확인 | 현재 설치된 plugin·역할 보고 |

메인테이너용 단계 간 승격 스킬(`spec-05-promote-skills`) 과는 명확히 분리된 도구다.

## Consequences

**Pros**

- 단일 진입점으로 사용자 학습 비용 감소 (한 명령만 기억).
- plugin marketplace 채널 안에 닫혀 있어 외부 인프라(사내 HTTPS, brew tap, npm registry) 운영 부담이 없다.
- 메인테이너 도구(spec-05) 와 사용자 도구의 책임 경계가 명확.

**Cons**

- 단일 스킬 안에 6 시나리오를 응집시키므로 분기 로직이 비대해질 위험이 있다. 운영하며 사용 패턴을 본 뒤 sub-command 분할을 재검토해야 한다.
- env / git auth 자동 셋업은 OS(mac/win/linux) 별 차이가 커서 bootstrap 이후 단계에서도 사용자 개입이 일부 남을 수 있다.

## Notes

_(시간순 append: status 전이, 적용 결과, 후속 학습, 관련 spec 추가 등)_
