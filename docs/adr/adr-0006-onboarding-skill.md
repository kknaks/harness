---
id: adr-0006
title: Onboarding Skill
type: adr
status: accepted
date: 2026-04-29
sources:
  - "[[spec-07-onboarding-skill]]"
tags: [adr]
aliases: []
depends_on:
  - "[[adr-0001-directory-structure]]"
  - "[[adr-0005-version-rollout]]"
related_to:
  - "[[adr-0003-content-pipeline]]"
---

# Onboarding Skill

## Context

(승격 원본: `docs/spec/spec-07-onboarding-skill.md`)

idea-01 에서는 "신입 온보딩 자동화" 가 출발점이었지만, 운영하다 보면 기존 구성원도 동일한 도구가 필요하다는 점이 드러난다 — 역할 변경 (예: 백엔드 → 인프라), 다중 역할 (풀스택), 환경 동기화 (회사 CLAUDE.md 갱신), 정리·재설치, 상태 확인. **6 시나리오 모두 "현재 설치 상태 + 사용자 의도" 를 보고 분기** 하는 공통 구조라, 별도 sub-command 로 쪼개면 학습 비용과 분기 관리 비용 둘 다 ↑.

이 결정은 [[adr-0001-directory-structure]] 의 `content/harness/plugins/` 모노레포 가정과 [[adr-0005-version-rollout]] 의 autoUpdate 위에 동작한다. 사용자는 한 진입점 (`harness` skill) 만 알면 되고, 그 너머의 release flow / 5단 파이프라인 / 권한 모델 ([[adr-0002-permissions-flow]], [[adr-0003-content-pipeline]]) 은 노출되지 않는다.

또한 사용자는 *권한 영역 외* — inbox PR 도 던질 수 있지만 onboarding skill 자체는 *plugin 설치/관리* 만 담당하므로 권한 모델과 직교.

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

메인테이너용 단계 간 승격 스킬 ([[spec-05-promote-skills]]) 과는 명확히 분리된 도구다.

**동작 원칙**

- **idempotent**: harness skill 호출 시 항상 *현재 설치 상태 우선 보고* → 차이만 처리. 부분 install 상태에서 재호출해도 안전.
- **dry-run 우선**: 시나리오 분기 결정 후 사용자에게 *무엇을 할지* 확인 → 동의 시 실행.
- **OS 별 fallback**: bootstrap 자체는 Claude Code (cross-platform) 에 위임. env / git auth 자동 셋업은 OS 차이가 커서 사용자 개입 가이드만 제공.

## Alternatives Considered

배포 채널:

| 후보 | 설명 | 채택 안 한 이유 |
|------|------|------------------|
| curl one-liner | `curl ... \| bash` | 사내 HTTPS 엔드포인트 운영 부담. 셸 보안 issues |
| brew tap | macOS 한정 + 사내 brew tap | OS 한정. tap 유지 부담 |
| npm/pip 글로벌 패키지 | 패키지 매니저로 배포 | 추가 채널 (npm/PyPI) 운영. 회사 registry 가정 |
| **Claude Code plugin marketplace (현재 ✓)** | `claude plugin marketplace add github:medisolve/harness` → install | 외부 인프라 의존 0. Claude Code 자체가 채널 |

스킬 분할:

| 후보 | 설명 | 채택 안 한 이유 |
|------|------|------------------|
| sub-command 분할 (`harness install` / `harness setup` / `harness sync` ...) | 시나리오마다 별도 명령 | 학습 비용 ↑ (6 명령 기억). Claude 가 분기 가능한 영역 |
| **단일 대화형 (현재 ✓)** | `harness` 한 명령, Claude 가 6 시나리오 분기 | LLM 의 의도 파악 능력 활용. 사용자는 한 명령만 |
| GUI 마법사 | 별도 UI | Claude Code 채널 밖 — 인프라 부담 |

**왜 LLM 분기가 안전한가**: harness skill 의 동작은 *idempotent + dry-run 우선* 으로 설계 → Claude 가 분기를 잘못 판단해도 부분 install / 잘못된 uninstall 위험 없음. 분기 실패 시 *상태 확인* 시나리오로 fallback 자연.

## Implementation Path

| Action | 누가 | 언제 | 의존 / 산출 |
|--------|------|------|--------------|
| `harness` skill 작성 (`content/harness/plugins/base/skills/harness/SKILL.md` + 분기 가이드) | 메인테이너 | v0.1 release 전 | [[spec-13-skill-authoring-rules]] 룰 따름 |
| bootstrap 3단계 안내 README + CONTRIBUTING.md | 메인테이너 | v0.1 release 전 | — |
| `harness` skill 의 *상태 확인* 시나리오 우선 구현 | 메인테이너 | v0.1 release 전 | dry-run 기본 |
| 처음 셋업 / 역할 변경 / 다중 역할 시나리오 | 메인테이너 | v0.1 release 전 | base + role plugin 의 install/uninstall 명령 의존 |
| 환경 동기화 / 정리·재설치 시나리오 | 메인테이너 | v0.2 release 전 | autoUpdate ([[adr-0005-version-rollout]]) 와 협력 |
| OS 별 env / git auth 가이드 (mac / win / linux) | 메인테이너 | 운영 6개월 후 | 사용자 개입 단계 명시 |

**시나리오 예 (신입 처음 셋업)**

1. 신입이 Claude Code 설치 → `claude plugin marketplace add github:medisolve/harness` → `claude plugin install harness`.
2. `harness` 호출 → skill 이 *현재 상태 확인* → "설치된 plugin 0개" → "처음 셋업" 분기.
3. 역할 prompt: "어떤 역할인가요? (기획·PM·프론트·백엔드·QA·인프라)".
4. 사용자: "백엔드".
5. dry-run: "base + backend plugin 설치 + env 셋업할게요. 진행?".
6. 동의 → 실행 → autoUpdate 자동 활성.

**시나리오 예 (역할 변경: 백엔드 → 인프라)**

1. 기존 사용자가 `harness` 호출.
2. skill 이 상태 확인 → "현재 base + backend 설치됨".
3. 의도 파악 → "역할 변경" 분기.
4. dry-run: "backend uninstall + infra install. 진행?".
5. 동의 → 실행.

## Consequences

**Pros**

- 단일 진입점으로 사용자 학습 비용 감소 (한 명령만 기억).
- plugin marketplace 채널 안에 닫혀 있어 외부 인프라 (사내 HTTPS, brew tap, npm registry) 운영 부담이 없다.
- 메인테이너 도구 ([[spec-05-promote-skills]]) 와 사용자 도구의 책임 경계가 명확.
- idempotent + dry-run 으로 분기 실수 시에도 안전.

**Cons**

- 단일 스킬 안에 6 시나리오를 응집시키므로 분기 로직이 비대해질 위험. 운영하며 사용 패턴 본 뒤 sub-command 분할 재검토.
- env / git auth 자동 셋업은 OS 별 차이가 커서 사용자 개입이 일부 남는다.
- LLM 분기 판단 의존 — Claude 가 시나리오를 잘못 식별하면 사용자가 *상태 확인* 으로 명시 호출해야 (비용은 idempotent 가 흡수).
- bootstrap 3단계가 *수동* — 자동화 불가 (Claude Code 자체 설치는 OS 종속).

**Follow-ups**

- [ ] 사용 패턴 누적 후 sub-command 분할 가치 재평가.
- [ ] OS 별 env / git auth 자동화 깊이 확장.
- [ ] LLM 분기 정확도 측정 (*상태 확인* fallback 발동 빈도).

## Notes

- 2026-04-29: status proposed → accepted. source [[spec-07-onboarding-skill]] status → accepted (통째 흡수).
- 2026-04-29: `harness` skill 위치를 `.claude/skills/harness/` → `content/harness/plugins/base/skills/harness/` 로 정정. 사용자 호출 = 플러그인용 영역 ([[adr-0007-skill-authoring-rules]] §1 두 영역 분류).
