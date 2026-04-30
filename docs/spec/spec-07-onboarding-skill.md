---
id: spec-07
title: Onboarding Skill
type: spec
status: accepted
created: 2026-04-28
updated: 2026-04-29
sources:
  - "[[idea-01-distribution-strategy]]"
owns: onboarding-skill
tags: [spec]
aliases: []
---

# Onboarding Skill

## Scope

사용자(신입·기존)의 mediness plugin 셋업·역할 변경·동기화·정리를 처리하는 단일 대화형 스킬 (`harness`). 메인테이너용 단계 간 승격 스킬(spec-05)과는 다른 도구.

## Summary

`harness` 한 명령이 모든 사용자 시나리오 진입점. Claude 가 현재 설치 상태 + 사용자 의도 파악 후 적절한 분기.

## Background

idea-01 에서 "신입 온보딩 자동화" 가 시작점이었지만, 기존 구성원도 역할 변경·동기화 등으로 같은 도구가 필요. 분리된 sub-command 보다 단일 진입점이 단순.

## Goals

- 사용자 시나리오 6개를 한 스킬에서 처리: 처음 셋업 / 역할 변경 / 다중 역할 / 환경 동기화 / 정리·재설치 / 상태 확인
- 메인테이너 도구(spec-05) 와 명확히 분리
- bootstrap 은 한 번만 (Claude Code 설치 + marketplace add + harness install)
- plugin 채널 안에서 모든 자동화 (외부 HTTPS 엔드포인트 의존 X)

## Non-goals

- 메인테이너용 단계 간 승격 스킬 — `[[spec-05-promote-skills]]`
- plugin 디렉토리 자체 — `[[spec-02-directory-structure]]`
- hook 정렬·버전 관리 — `[[spec-08-hook-precedence]]`, `[[spec-09-version-rollout]]`

## Design

**Bootstrap (한 번, 수동)**:
1. Claude Code 설치
2. `claude plugin marketplace add github:medisolve/harness`
3. `claude plugin install harness` (또는 base 의 slash command)

**시나리오 분기** (`harness` 호출 시 Claude 가 현재 상태 + 의도 보고 결정):

| 시나리오 | 동작 |
|---------|------|
| 처음 셋업 (신입 / 첫 도입) | 역할 prompt → base + role plugin install + env 셋업 |
| 역할 변경 (예: 백엔드 → 인프라) | 기존 role uninstall + 새 role install |
| 다중 역할 (풀스택) | 추가 role plugin install |
| 환경 동기화 (정기) | 회사 CLAUDE.md / 공통 settings 갱신 |
| 정리·재설치 | 전체 uninstall + reinstall |
| 상태 확인 | 현재 설치된 plugin·역할 보고 |

**왜 다른 옵션 안 선택**

(a) curl one-liner / (b) brew / (c) npm-pip 글로벌 — 사내 HTTPS 엔드포인트 또는 별도 패키지 매니저 운영 부담. plugin 채널 안에서 끝나는 게 우선.

## Open Questions

- [ ] sub-command 분할 시점 (사용 패턴 보고 결정)
- [ ] env / git auth 자동 셋업의 OS 별 차이 (mac/win/linux) 처리
